import 'dart:async';

import 'package:integral_isolates/src/backpressure/backpressure_strategy.dart';

/// Mixin to help out with a queue of one size for [BackpressureStrategy].
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
