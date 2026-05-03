import 'dart:ui';
import '../models/detection_result.dart';
import '../models/tracked_object.dart';

class TemporalTracker {
  final double iouThreshold;
  final int maxAge;
  final int minHits;

  final Map<int, TrackedObject> _tracks = {};
  int _nextId = 1;

  TemporalTracker({
    this.iouThreshold = 0.3,
    this.maxAge = 10,
    this.minHits = 3,
  });

  List<TrackedObject> get activeTracks =>
      _tracks.values
          .where((t) => t.timeSinceUpdate == 0 && t.hitStreak >= minHits)
          .toList();

  List<TrackedObject> update(List<DetectionResult> detections) {
    for (final track in _tracks.values) {
      track.predict();
    }

    if (detections.isNotEmpty && _tracks.isNotEmpty) {
      _matchDetectionsToTracks(detections);
    } else if (detections.isNotEmpty) {
      for (final det in detections) {
        _createTrack(det);
      }
    }

    _tracks.removeWhere((_, t) => t.timeSinceUpdate > maxAge);
    return activeTracks;
  }

  void _matchDetectionsToTracks(List<DetectionResult> detections) {
    final trackList = _tracks.values.toList();
    final matched = <int>{};
    final matchedTracks = <int>{};

    for (int di = 0; di < detections.length; di++) {
      double bestIou = iouThreshold;
      int bestTrackIdx = -1;

      for (int ti = 0; ti < trackList.length; ti++) {
        if (matchedTracks.contains(ti)) continue;
        final iou = _computeIou(detections[di].boundingBox, trackList[ti].boundingBox);
        if (iou > bestIou) {
          bestIou = iou;
          bestTrackIdx = ti;
        }
      }

      if (bestTrackIdx >= 0) {
        trackList[bestTrackIdx].update(
          detections[di].boundingBox,
          detections[di].label,
          detections[di].confidence,
        );
        matched.add(di);
        matchedTracks.add(bestTrackIdx);
      }
    }

    for (int di = 0; di < detections.length; di++) {
      if (!matched.contains(di)) {
        _createTrack(detections[di]);
      }
    }
  }

  void _createTrack(DetectionResult det) {
    _tracks[_nextId] = TrackedObject(
      trackId: _nextId,
      boundingBox: det.boundingBox,
      label: det.label,
      confidence: det.confidence,
    );
    _nextId++;
  }

  double _computeIou(Rect a, Rect b) {
    final interLeft = a.left > b.left ? a.left : b.left;
    final interTop = a.top > b.top ? a.top : b.top;
    final interRight = a.right < b.right ? a.right : b.right;
    final interBottom = a.bottom < b.bottom ? a.bottom : b.bottom;

    if (interRight <= interLeft || interBottom <= interTop) return 0.0;

    final intersection = (interRight - interLeft) * (interBottom - interTop);
    final union = a.width * a.height + b.width * b.height - intersection;
    return union <= 0 ? 0.0 : intersection / union;
  }

  TrackedObject? findBestMatch(Rect box) {
    double bestIou = 0.0;
    TrackedObject? best;
    for (final track in _tracks.values) {
      final iou = _computeIou(box, track.boundingBox);
      if (iou > bestIou) {
        bestIou = iou;
        best = track;
      }
    }
    return best;
  }

  void reset() {
    _tracks.clear();
    _nextId = 1;
  }
}
