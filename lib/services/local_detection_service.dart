import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/detection_result.dart';
import '../models/app_settings.dart';

class LocalDetectionService {
  final LocalModel model;
  bool _initialized = false;
  static const _uuid = Uuid();

  LocalDetectionService({this.model = LocalModel.yolov8Tiny});

  Future<void> initialize() async {
    // TODO: Load actual TFLite model via tflite_flutter:
    // final interpreter = await Interpreter.fromAsset(
    //   model == LocalModel.yolov8Tiny
    //       ? 'assets/models/yolov8n.tflite'
    //       : 'assets/models/mobilenet_v3.tflite',
    // );
    _initialized = true;
    debugPrint('[LocalDetectionService] Initialized (stub mode)');
  }

  Future<List<DetectionResult>> detect(
    Uint8List frameData, {
    int width = 0,
    int height = 0,
  }) async {
    if (!_initialized) await initialize();
    await Future.delayed(const Duration(milliseconds: 10));
    return _stubDetections(width, height);
  }

  List<DetectionResult> _stubDetections(int width, int height) {
    if (width == 0 || height == 0) return [];
    final w = width.toDouble();
    final h = height.toDouble();
    return [
      DetectionResult(
        id: _uuid.v4(),
        boundingBox: Rect.fromLTWH(w * 0.1, h * 0.1, w * 0.3, h * 0.4),
        label: 'cell phone',
        confidence: 0.85,
      ),
      DetectionResult(
        id: _uuid.v4(),
        boundingBox: Rect.fromLTWH(w * 0.55, h * 0.2, w * 0.35, h * 0.5),
        label: 'person',
        confidence: 0.45,
      ),
    ];
  }

  void dispose() {
    _initialized = false;
  }
}
