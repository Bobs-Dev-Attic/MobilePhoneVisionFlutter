import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/app_settings.dart';
import '../models/detection_result.dart';
import '../models/tracked_object.dart';
import '../services/local_detection_service.dart';
import '../services/cloud_detection_service.dart';
import '../services/network_monitor.dart';
import 'frame_buffer.dart';
import 'temporal_tracker.dart';

enum InferenceState { idle, localInference, cloudInference, fallback }

/// Sentinel value used as trackId when no track has been matched.
const int kNoTrackId = -1;

class InferenceManager extends ChangeNotifier {
  final LocalDetectionService _localService;
  final CloudDetectionService _cloudService;
  final NetworkMonitor _networkMonitor;
  final TemporalTracker _tracker = TemporalTracker();
  final FrameBuffer _frameBuffer = FrameBuffer();

  AppSettings _settings;
  InferenceState _state = InferenceState.idle;
  List<DetectionResult> _currentDetections = [];
  bool _isProcessing = false;
  bool _cloudFallback = false;

  InferenceManager({
    required AppSettings settings,
    required LocalDetectionService localService,
    required CloudDetectionService cloudService,
    required NetworkMonitor networkMonitor,
  })  : _settings = settings,
        _localService = localService,
        _cloudService = cloudService,
        _networkMonitor = networkMonitor;

  InferenceState get state => _state;
  List<DetectionResult> get currentDetections => List.unmodifiable(_currentDetections);
  bool get isCloudFallback => _cloudFallback;
  int get droppedFrames => _frameBuffer.droppedFrames;
  AppSettings get settings => _settings;

  void updateSettings(AppSettings newSettings) {
    _settings = newSettings;
    notifyListeners();
  }

  Future<void> processFrame(Uint8List frameData, {int width = 0, int height = 0}) async {
    final accepted = _frameBuffer.push(frameData, metadata: {'width': width, 'height': height});
    if (!accepted) return;
    if (_isProcessing) return;
    _isProcessing = true;
    try {
      final entry = _frameBuffer.pop();
      if (entry == null) {
        _isProcessing = false;
        return;
      }
      await _runInference(entry.data,
          width: (entry.metadata['width'] as int?) ?? width,
          height: (entry.metadata['height'] as int?) ?? height);
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _runInference(Uint8List frameData, {int width = 0, int height = 0}) async {
    final mode = _cloudFallback ? InferenceMode.localOnly : _settings.inferenceMode;
    List<DetectionResult> detections = [];

    if (mode == InferenceMode.localOnly || mode == InferenceMode.hybrid) {
      _state = InferenceState.localInference;
      try {
        detections = await _localService.detect(frameData, width: width, height: height);
      } catch (e) {
        debugPrint('[InferenceManager] Local detection error: $e');
      }
    }

    if (mode == InferenceMode.cloudOnly) {
      _state = InferenceState.cloudInference;
      try {
        final cloudDetections = await _cloudService.detect(frameData, width: width, height: height);
        detections = cloudDetections;
      } catch (e) {
        debugPrint('[InferenceManager] Cloud detection error: $e');
      }
    }

    final tracked = _tracker.update(detections);

    if (mode == InferenceMode.hybrid) {
      for (final det in detections) {
        final shouldSendToCloud = det.confidence < _settings.minConfidence ||
            _settings.detailedAnalysisWhitelist
                .any((w) => det.label.toLowerCase().contains(w.toLowerCase()));
        if (shouldSendToCloud) {
          _triggerCloudAnalysis(det, frameData);
        }
      }
    }

    _currentDetections = _mergeWithTracked(detections, tracked);
    _state = InferenceState.idle;
    notifyListeners();
  }

  Future<void> _triggerCloudAnalysis(DetectionResult det, Uint8List frameData) async {
    if (!await _networkMonitor.isConnected()) {
      _activateFallback();
      return;
    }
    final ping = await _networkMonitor.measurePing();
    if (ping > 500) {
      _activateFallback();
      return;
    }
    try {
      final response = await _cloudService.analyzeRoi(
        frameData,
        det.boundingBox,
        label: det.label,
      );
      final matchedTrack = _tracker.findBestMatch(det.boundingBox);
      if (matchedTrack != null) {
        final idx = _currentDetections.indexWhere(
          (d) => d.trackId == matchedTrack.trackId,
        );
        if (idx >= 0) {
          _currentDetections = List.of(_currentDetections);
          _currentDetections[idx] = _currentDetections[idx].copyWith(
            cloudMetadata: response,
          );
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('[InferenceManager] Cloud ROI analysis error: $e');
    }
  }

  void _activateFallback() {
    if (!_cloudFallback) {
      _cloudFallback = true;
      _state = InferenceState.fallback;
      notifyListeners();
    }
  }

  void deactivateFallback() {
    _cloudFallback = false;
    notifyListeners();
  }

  List<DetectionResult> _mergeWithTracked(
    List<DetectionResult> detections,
    List<TrackedObject> tracked,
  ) {
    return detections.map((det) {
      final match = _tracker.findBestMatch(det.boundingBox);
      return det.copyWith(trackId: match?.trackId ?? kNoTrackId);
    }).toList();
  }

  void reset() {
    _tracker.reset();
    _frameBuffer.clear();
    _currentDetections = [];
    _cloudFallback = false;
    _state = InferenceState.idle;
    notifyListeners();
  }

  @override
  void dispose() {
    _localService.dispose();
    super.dispose();
  }
}
