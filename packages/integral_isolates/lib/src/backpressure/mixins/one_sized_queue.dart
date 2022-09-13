import 'dart:async';

import 'package:integral_isolates/src/backpressure/backpressure_strategy.dart';

mixin OneSizedQueue on BackpressureStrategy {
  BackpressureConfiguration? nextUp;

  @override
  bool hasNext() => nextUp != null;

  @override
  BackpressureConfiguration takeNext() {
    final toReturn = nextUp!;
    nextUp = null;
    return toReturn;
  }

  @override
  Future dispose() async {
    if (hasNext()) drop(takeNext());
  }
}
