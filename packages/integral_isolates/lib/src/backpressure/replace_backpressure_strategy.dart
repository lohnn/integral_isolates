import 'dart:async';

import 'package:integral_isolates/src/backpressure/backpressure_strategy.dart';
import 'package:integral_isolates/src/backpressure/mixins/one_sized_queue.dart';

/// An implementation of [BackpressureStrategy] that has a job queue with size
/// one, and discards the queue upon adding a new job.
///
/// Marble diagram to visualize timeline:
///
/// --a--b--c---d--e--f-----|
///
/// ---------a-c-------d--f-|
class ReplaceBackpressureStrategy<R> extends BackpressureStrategy<R>
    with OneSizedQueue<R> {
  @override
  Future add(BackpressureConfiguration<R> configuration) async {
    if (hasNext()) drop(takeNext());

    queue = configuration;
  }
}
