import 'dart:async';

import 'package:integral_isolates/src/backpressure/backpressure_strategy.dart';

/// Mixin to help out with a queue of one size for [BackpressureStrategy].
mixin TailoredOneSizedQueue<Q, R> on TailoredBackpressureStrategy<Q, R> {
  /// The next item in queue for execution.
  TailoredBackpressureConfiguration<Q, R>? queue;

  @override
  bool hasNext() => queue != null;

  @override
  TailoredBackpressureConfiguration<Q, R> takeNext() {
    final toReturn = queue!;
    queue = null;
    return toReturn;
  }

  @override
  Future dispose() async {
    if (hasNext()) drop(takeNext());
  }
}
