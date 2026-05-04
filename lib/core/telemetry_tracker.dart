import '../models/telemetry_snapshot.dart';

class TelemetryTracker {
  final List<DateTime> _processedFrames = [];
  int _fallbackEvents = 0;
  int _totalRoiCalls = 0;
  int _successfulRoiCalls = 0;
  int _totalCloudLatencyMs = 0;

  void recordProcessedFrame() {
    final now = DateTime.now();
    _processedFrames.add(now);
    final cutoff = now.subtract(const Duration(seconds: 1));
    _processedFrames.removeWhere((ts) => ts.isBefore(cutoff));
  }

  void recordFallbackEvent() => _fallbackEvents++;

  void recordCloudAttempt() => _totalRoiCalls++;

  void recordCloudSuccess(Duration latency) {
    _successfulRoiCalls++;
    _totalCloudLatencyMs += latency.inMilliseconds;
  }

  TelemetrySnapshot snapshot({required int droppedFrames}) {
    final avgLatency = _successfulRoiCalls == 0
        ? Duration.zero
        : Duration(milliseconds: (_totalCloudLatencyMs / _successfulRoiCalls).round());
    return TelemetrySnapshot(
      fps: _processedFrames.length.toDouble(),
      droppedFrames: droppedFrames,
      fallbackEvents: _fallbackEvents,
      totalRoiCalls: _totalRoiCalls,
      successfulRoiCalls: _successfulRoiCalls,
      avgCloudLatency: avgLatency,
    );
  }

  void reset() {
    _processedFrames.clear();
    _fallbackEvents = 0;
    _totalRoiCalls = 0;
    _successfulRoiCalls = 0;
    _totalCloudLatencyMs = 0;
  }
}
