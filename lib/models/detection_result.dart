import 'dart:ui';
import 'cloud_response.dart';

class DetectionResult {
  final String id;
  final Rect boundingBox;
  final String label;
  final double confidence;
  final int? trackId;
  CloudResponse? cloudMetadata;
  final DateTime timestamp;

  DetectionResult({
    required this.id,
    required this.boundingBox,
    required this.label,
    required this.confidence,
    this.trackId,
    this.cloudMetadata,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  DetectionResult copyWith({
    String? id,
    Rect? boundingBox,
    String? label,
    double? confidence,
    int? trackId,
    CloudResponse? cloudMetadata,
  }) {
    return DetectionResult(
      id: id ?? this.id,
      boundingBox: boundingBox ?? this.boundingBox,
      label: label ?? this.label,
      confidence: confidence ?? this.confidence,
      trackId: trackId ?? this.trackId,
      cloudMetadata: cloudMetadata ?? this.cloudMetadata,
      timestamp: timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'confidence': confidence,
      'trackId': trackId,
      'timestamp': timestamp.toIso8601String(),
      'boundingBox': {
        'left': boundingBox.left,
        'top': boundingBox.top,
        'width': boundingBox.width,
        'height': boundingBox.height,
      },
      if (cloudMetadata != null) 'cloudMetadata': cloudMetadata!.toMap(),
    };
  }
}
