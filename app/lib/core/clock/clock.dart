import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Single source of time for the app, always in UTC.
abstract interface class Clock {
  DateTime now();
}

/// Production clock: UTC with the microseconds dropped, so stored dates share
/// one text length and text order matches time order.
final class SystemClock implements Clock {
  const new();

  @override
  DateTime now() {
    final current = DateTime.now().toUtc();
    return DateTime.fromMillisecondsSinceEpoch(
      current.millisecondsSinceEpoch,
      isUtc: true,
    );
  }
}

final clockProvider = Provider<Clock>((ref) => const SystemClock());
