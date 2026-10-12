import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/clock/clock.dart';

import '../../helpers/lib_scan.dart';

void main() {
  test('TIME-01: now() is in UTC', () {
    expect(const SystemClock().now().isUtc, isTrue);
  });

  test('TIME-04: now() has no microseconds', () {
    for (var i = 0; i < 200; i++) {
      expect(const SystemClock().now().microsecond, 0);
    }
  });

  test('TIME-01: clockProvider returns a SystemClock', () {
    final container = ProviderContainer.test();

    expect(container.read(clockProvider), isA<SystemClock>());
  });

  test('TIME-03: only clock.dart calls DateTime.now()', () {
    final offenders = [
      for (final (file, source) in libSources(
        exclude: {'lib/core/clock/clock.dart'},
      ))
        if (source.contains('DateTime.now(')) file.path,
    ];

    expect(offenders, isEmpty);
  });
}
