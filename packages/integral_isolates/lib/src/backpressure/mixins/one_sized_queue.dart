import 'dart:async';

import 'package:integral_isolates/src/backpressure/backpressure_strategy.dart';

/// Mixin to help out with a queue of one size for [BackpressureStrategy].
mixin OneSizedQueue<Q, R> on BackpressureStrategy<Q, R> {
  /// The next item in queue for execution.
  BackpressureConfiguration<Q, R>? queue;

  @override
  bool hasNext() => queue != null;

  @override
  BackpressureConfiguration<Q, R> takeNext() {
    final toReturn = queue!;
    queue = null;
    return toReturn;
  }

  @override
  Future dispose() async {
    if (hasNext()) drop(takeNext());
  }
}
