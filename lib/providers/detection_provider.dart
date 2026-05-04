import 'package:flutter/foundation.dart';
import '../models/detection_result.dart';
import '../core/inference_manager.dart';
import '../models/telemetry_snapshot.dart';

class DetectionProvider extends ChangeNotifier {
  InferenceState _inferenceState = InferenceState.idle;
  List<DetectionResult> _detections = [];
  bool _cloudFallback = false;
  TelemetrySnapshot _telemetry = const TelemetrySnapshot.zero();

  InferenceState get inferenceState => _inferenceState;
  List<DetectionResult> get detections => _detections;
  bool get isCloudFallback => _cloudFallback;
  TelemetrySnapshot get telemetry => _telemetry;

  void updateFromManager(InferenceManager manager) {
    _inferenceState = manager.state;
    _detections = manager.currentDetections.toList();
    _cloudFallback = manager.isCloudFallback;
    _telemetry = manager.telemetry;
    notifyListeners();
  }

  void clear() {
    _detections = [];
    _inferenceState = InferenceState.idle;
    notifyListeners();
  }
}
