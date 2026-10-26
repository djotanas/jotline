import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import '../../integration_test/perf/frame_stats.dart';

FrameTiming _frame(int buildMicros, int frame) => FrameTiming(
  vsyncStart: frame * 20000,
  buildStart: frame * 20000,
  buildFinish: frame * 20000 + buildMicros,
  rasterStart: frame * 20000 + buildMicros,
  rasterFinish: frame * 20000 + buildMicros + 2000,
  rasterFinishWallTime: frame * 20000 + buildMicros + 2000,
  frameNumber: frame,
);

void main() {
  test('LOAD-04: frames building in 4 ms average 4 ms', () {
    final collector = FrameCollector()
      ..add([for (var i = 0; i < 50; i++) _frame(4000, i)]);

    expect(collector.summary()['average_frame_build_time_millis'], 4);
  });

  test('LOAD-04: slow frames push the average over the 16 ms target', () {
    final collector = FrameCollector()
      ..add([
        for (var i = 0; i < 50; i++) _frame(4000, i),
        for (var i = 50; i < 100; i++) _frame(40000, i),
      ]);

    final average =
        collector.summary()['average_frame_build_time_millis']! as double;

    expect(average, 22);
    expect(average, greaterThan(16));
  });
}
