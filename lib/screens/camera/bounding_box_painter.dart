import 'package:flutter/material.dart';
import '../../models/detection_result.dart';

class BoundingBoxPainter extends CustomPainter {
  final List<DetectionResult> detections;
  final Size imageSize;

  BoundingBoxPainter({
    required this.detections,
    required this.imageSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (imageSize.width == 0 || imageSize.height == 0) return;

    final scaleX = size.width / imageSize.width;
    final scaleY = size.height / imageSize.height;

    for (final detection in detections) {
      final color = _colorForConfidence(detection.confidence, detection.cloudMetadata?.verified);
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;

      final scaledBox = Rect.fromLTWH(
        detection.boundingBox.left * scaleX,
        detection.boundingBox.top * scaleY,
        detection.boundingBox.width * scaleX,
        detection.boundingBox.height * scaleY,
      );

      canvas.drawRect(scaledBox, paint);
      _drawLabel(canvas, scaledBox, detection, color);
    }
  }

  void _drawLabel(Canvas canvas, Rect box, DetectionResult detection, Color color) {
    final cloudVerified = detection.cloudMetadata?.verified == true;
    final brand = detection.cloudMetadata?.brand;
    final model = detection.cloudMetadata?.model;

    String labelText = detection.label;
    if (brand != null) labelText += ' · $brand';
    if (model != null) labelText += ' $model';
    labelText += ' ${(detection.confidence * 100).toStringAsFixed(0)}%';
    if (cloudVerified) labelText += ' ✓';

    final textSpan = TextSpan(
      text: labelText,
      style: TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        backgroundColor: color.withOpacity(0.8),
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: box.width + 40);

    final labelY = (box.top - textPainter.height - 4).clamp(0.0, double.infinity);
    textPainter.paint(canvas, Offset(box.left, labelY));

    if (cloudVerified) {
      final badgePaint = Paint()..color = Colors.greenAccent;
      canvas.drawCircle(
        Offset(box.right - 8, box.top + 8),
        8,
        badgePaint,
      );
      const checkSpan = TextSpan(
        text: '✓',
        style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
      );
      final checkPainter = TextPainter(
        text: checkSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      checkPainter.paint(
        canvas,
        Offset(box.right - 8 - checkPainter.width / 2, box.top + 8 - checkPainter.height / 2),
      );
    }
  }

  Color _colorForConfidence(double confidence, bool? cloudVerified) {
    if (cloudVerified == true) return Colors.greenAccent;
    if (confidence >= 0.7) return Colors.green;
    if (confidence >= 0.5) return Colors.yellow;
    return Colors.redAccent;
  }

  @override
  bool shouldRepaint(BoundingBoxPainter oldDelegate) {
    return oldDelegate.detections != detections ||
        oldDelegate.imageSize != imageSize;
  }
}
