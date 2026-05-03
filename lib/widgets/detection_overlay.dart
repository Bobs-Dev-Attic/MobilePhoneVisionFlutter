import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../models/detection_result.dart';
import '../screens/camera/bounding_box_painter.dart';

class DetectionOverlay extends StatelessWidget {
  final CameraController controller;
  final List<DetectionResult> detections;
  final Size imageSize;

  const DetectionOverlay({
    super.key,
    required this.controller,
    required this.detections,
    required this.imageSize,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(controller),
        if (detections.isNotEmpty)
          CustomPaint(
            painter: BoundingBoxPainter(
              detections: detections,
              imageSize: imageSize,
            ),
          ),
      ],
    );
  }
}
