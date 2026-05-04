class TelemetrySnapshot {
  final double fps;
  final int droppedFrames;
  final int fallbackEvents;
  final int totalRoiCalls;
  final int successfulRoiCalls;
  final Duration avgCloudLatency;

  const TelemetrySnapshot({
    required this.fps,
    required this.droppedFrames,
    required this.fallbackEvents,
    required this.totalRoiCalls,
    required this.successfulRoiCalls,
    required this.avgCloudLatency,
  });

  const TelemetrySnapshot.zero()
      : fps = 0,
        droppedFrames = 0,
        fallbackEvents = 0,
        totalRoiCalls = 0,
        successfulRoiCalls = 0,
        avgCloudLatency = Duration.zero;
}
