import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_phone_vision/core/temporal_tracker.dart';
import 'package:mobile_phone_vision/models/detection_result.dart';

DetectionResult _makeDetection(Rect box, String label, double confidence) {
  return DetectionResult(
    id: 'test_${label}_${box.left.round()}',
    boundingBox: box,
    label: label,
    confidence: confidence,
  );
}

void main() {
  group('TemporalTracker', () {
    test('creates new tracks for first detections', () {
      final tracker = TemporalTracker(minHits: 1);
      final detections = [
        _makeDetection(
            const Rect.fromLTWH(0, 0, 100, 100), 'cell phone', 0.9),
      ];
      tracker.update(detections);
      expect(tracker.activeTracks, hasLength(1));
    });

    test('matches detection to existing track via IoU', () {
      final tracker = TemporalTracker(minHits: 1);
      final box1 = const Rect.fromLTWH(10, 10, 100, 100);
      final box2 = const Rect.fromLTWH(15, 15, 100, 100); // overlaps significantly

      tracker.update([_makeDetection(box1, 'cell phone', 0.9)]);
      tracker.update([_makeDetection(box2, 'cell phone', 0.85)]);

      expect(tracker.activeTracks, hasLength(1));
    });

    test('creates separate tracks for non-overlapping detections', () {
      final tracker = TemporalTracker(minHits: 1);
      final box1 = const Rect.fromLTWH(0, 0, 50, 50);
      final box2 = const Rect.fromLTWH(500, 500, 50, 50);

      tracker.update([
        _makeDetection(box1, 'cell phone', 0.9),
        _makeDetection(box2, 'person', 0.8),
      ]);

      expect(tracker.activeTracks, hasLength(2));
    });

    test('removes stale tracks after maxAge', () {
      final tracker = TemporalTracker(minHits: 1, maxAge: 2);
      tracker.update([
        _makeDetection(const Rect.fromLTWH(0, 0, 100, 100), 'car', 0.9),
      ]);
      // No detections for 3 frames
      tracker.update([]);
      tracker.update([]);
      tracker.update([]);
      expect(tracker.activeTracks, isEmpty);
    });

    test('reset clears all tracks', () {
      final tracker = TemporalTracker(minHits: 1);
      tracker.update([
        _makeDetection(const Rect.fromLTWH(0, 0, 100, 100), 'laptop', 0.8),
      ]);
      tracker.reset();
      expect(tracker.activeTracks, isEmpty);
    });

    test('findBestMatch returns track with highest IoU', () {
      final tracker = TemporalTracker(minHits: 1);
      final box = const Rect.fromLTWH(10, 10, 100, 100);
      tracker.update([_makeDetection(box, 'cell phone', 0.9)]);

      final match = tracker.findBestMatch(const Rect.fromLTWH(12, 12, 100, 100));
      expect(match, isNotNull);
      expect(match!.label, 'cell phone');
    });
  });
}
