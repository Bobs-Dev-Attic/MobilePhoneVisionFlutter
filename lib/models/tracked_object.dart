import 'dart:ui';

class TrackedObject {
  final int trackId;
  Rect boundingBox;
  String label;
  double confidence;
  int age;
  int hitStreak;
  int timeSinceUpdate;
  List<Rect> history;

  TrackedObject({
    required this.trackId,
    required this.boundingBox,
    required this.label,
    required this.confidence,
    this.age = 0,
    this.hitStreak = 1,
    this.timeSinceUpdate = 0,
  }) : history = [boundingBox];

  void update(Rect newBox, String newLabel, double newConfidence) {
    history.add(boundingBox);
    if (history.length > 10) history.removeAt(0);
    boundingBox = newBox;
    label = newLabel;
    confidence = newConfidence;
    timeSinceUpdate = 0;
    hitStreak++;
    age++;
  }

  void predict() {
    timeSinceUpdate++;
    age++;
  }

  Rect get predictedBox {
    if (history.isEmpty) return boundingBox;
    final dx = boundingBox.left - history.last.left;
    final dy = boundingBox.top - history.last.top;
    return Rect.fromLTWH(
      boundingBox.left + dx,
      boundingBox.top + dy,
      boundingBox.width,
      boundingBox.height,
    );
  }
}
