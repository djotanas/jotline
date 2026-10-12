import 'package:jotline/core/clock/clock.dart';
import 'package:jotline/core/ids/id_generator.dart';

class FakeClock implements Clock {
  new(DateTime initial) : _now = _validated(initial);

  DateTime _now;

  DateTime get current => _now;

  set current(DateTime value) => _now = _validated(value);

  @override
  DateTime now() => _now;

  static DateTime _validated(DateTime value) {
    if (!value.isUtc) {
      throw ArgumentError.value(value, 'value', 'must be UTC');
    }
    if (value.microsecond != 0) {
      throw ArgumentError.value(
        value,
        'value',
        'must be aligned to the millisecond',
      );
    }
    return value;
  }
}

class SequentialIdGenerator implements IdGenerator {
  int _next = 0;

  @override
  String newId() {
    final suffix = (_next++).toRadixString(16).padLeft(12, '0');
    return '01900000-0000-7000-8000-$suffix';
  }
}
