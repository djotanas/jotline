import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

/// Collects the engine's frame timings without the VM service, which wireless
/// adb cannot reach. Its summary uses the same keys as the timeline summary
/// of `flutter_driver` (`average_frame_build_time_millis`).
class FrameCollector {
  final List<FrameTiming> _timings = [];

  void add(List<FrameTiming> timings) => _timings.addAll(timings);

  void start() => SchedulerBinding.instance.addTimingsCallback(add);

  /// Waits for the engine to deliver the batched timings, stops collecting
  /// and returns the summary.
  Future<Map<String, dynamic>> stop() async {
    while (_timings.isEmpty) {
      await Future<void>.delayed(const Duration(seconds: 2));
    }
    SchedulerBinding.instance.removeTimingsCallback(add);
    return summary();
  }

  Map<String, dynamic> summary() => FrameTimingSummarizer(
    _timings,
    newGenGCCount: -1,
    oldGenGCCount: -1,
  ).summary;
}
