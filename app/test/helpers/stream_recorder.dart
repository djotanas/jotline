import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

class StreamRecorder<T> {
  new(Stream<T> stream) {
    _subscription = stream.listen(
      emissions.add,
      onError: errors.add,
      onDone: () => isDone = true,
    );
  }

  late final StreamSubscription<T> _subscription;
  final List<T> emissions = [];
  final List<Object> errors = [];
  bool isDone = false;

  Future<List<T>> settle() async {
    await pumpEventQueue();
    return emissions;
  }

  Future<void> cancel() => _subscription.cancel();
}
