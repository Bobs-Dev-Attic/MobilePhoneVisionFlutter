import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_phone_vision/core/inference_manager.dart';
import 'package:mobile_phone_vision/models/app_settings.dart';
import 'package:mobile_phone_vision/models/cloud_response.dart';
import 'package:mobile_phone_vision/models/detection_result.dart';
import 'package:mobile_phone_vision/services/cloud_detection_service.dart';
import 'package:mobile_phone_vision/services/local_detection_service.dart';
import 'package:mobile_phone_vision/services/network_monitor.dart';

class _FakeLocalService extends LocalDetectionService {
  final List<DetectionResult> results;
  _FakeLocalService(this.results);

  @override
  Future<List<DetectionResult>> detect(Uint8List frameData,
      {int width = 0, int height = 0}) async {
    return results;
  }

  @override
  void dispose() {}
}

class _FakeCloudService extends CloudDetectionService {
  _FakeCloudService()
      : super(settings: const AppSettings(cloudProvider: CloudProvider.custom));

  @override
  Future<List<DetectionResult>> detect(Uint8List frameData,
      {int width = 0, int height = 0}) async {
    return [];
  }

  @override
  Future<CloudResponse> analyzeRoi(Uint8List frameData, Rect boundingBox,
      {String label = ''}) async {
    return const CloudResponse(verified: true, brand: 'Apple', model: 'iPhone 15');
  }
}

class _FakeNetworkMonitor extends NetworkMonitor {
  final bool connected;
  final int ping;

  _FakeNetworkMonitor({this.connected = true, this.ping = 50});

  @override
  Future<bool> isConnected() async => connected;

  @override
  Future<int> measurePing() async => ping;
}

void main() {
  group('InferenceManager', () {
    test('initial state is idle', () {
      final manager = InferenceManager(
        settings: const AppSettings(),
        localService: _FakeLocalService([]),
        cloudService: _FakeCloudService(),
        networkMonitor: _FakeNetworkMonitor(),
      );
      expect(manager.state, InferenceState.idle);
      manager.dispose();
    });

    test('processes frame and updates detections', () async {
      final detection = DetectionResult(
        id: 'test',
        boundingBox: const Rect.fromLTWH(0, 0, 100, 100),
        label: 'cell phone',
        confidence: 0.9,
      );
      final manager = InferenceManager(
        settings: const AppSettings(inferenceMode: InferenceMode.localOnly),
        localService: _FakeLocalService([detection]),
        cloudService: _FakeCloudService(),
        networkMonitor: _FakeNetworkMonitor(),
      );

      await manager.processFrame(
        Uint8List.fromList([1, 2, 3]),
        width: 640,
        height: 480,
      );

      expect(manager.currentDetections, isNotEmpty);
      manager.dispose();
    });

    test('activates fallback when network is slow', () async {
      final detection = DetectionResult(
        id: 'test',
        boundingBox: const Rect.fromLTWH(0, 0, 100, 100),
        label: 'cell phone',
        confidence: 0.3,
      );
      final manager = InferenceManager(
        settings: const AppSettings(
          inferenceMode: InferenceMode.hybrid,
          minConfidence: 0.5,
        ),
        localService: _FakeLocalService([detection]),
        cloudService: _FakeCloudService(),
        networkMonitor: _FakeNetworkMonitor(ping: 9999),
      );

      await manager.processFrame(
        Uint8List.fromList([1, 2, 3]),
        width: 640,
        height: 480,
      );

      // Allow async cloud trigger to run
      await Future.delayed(const Duration(milliseconds: 100));
      expect(manager.isCloudFallback, isTrue);
      manager.dispose();
    });

    test('reset clears detections and fallback', () async {
      final manager = InferenceManager(
        settings: const AppSettings(),
        localService: _FakeLocalService([]),
        cloudService: _FakeCloudService(),
        networkMonitor: _FakeNetworkMonitor(),
      );
      manager.reset();
      expect(manager.currentDetections, isEmpty);
      expect(manager.isCloudFallback, isFalse);
      manager.dispose();
    });

    test('updateSettings changes settings', () {
      final manager = InferenceManager(
        settings: const AppSettings(targetFps: 30),
        localService: _FakeLocalService([]),
        cloudService: _FakeCloudService(),
        networkMonitor: _FakeNetworkMonitor(),
      );
      manager.updateSettings(const AppSettings(targetFps: 15));
      expect(manager.settings.targetFps, 15);
      manager.dispose();
    });
  });
}
