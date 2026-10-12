import 'package:jotline/core/clock/clock.dart';

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
