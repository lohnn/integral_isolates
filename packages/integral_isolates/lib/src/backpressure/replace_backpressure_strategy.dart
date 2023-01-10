import 'dart:async';

import 'package:integral_isolates/src/backpressure/backpressure_strategy.dart';
import 'package:integral_isolates/src/backpressure/mixins/one_sized_queue.dart';
import 'package:integral_isolates/src/isolate_configuration.dart';

/// An implementation of [BackpressureStrategy] that has a job queue with size
/// one, and discards the queue upon adding a new job.
///
/// Marble diagram to visualize timeline:
///
/// --a--b--c---d--e--f-----|
///
/// ---------a-c-------d--f-|
class ReplaceBackpressureStrategy<Q, R> extends BackpressureStrategy<Q, R>
    with OneSizedQueue<Q, R> {
  @override
  Future add(
    Completer completer,
    IsolateConfiguration<Q, R> isolateConfiguration,
  ) async {
    if (hasNext()) drop(takeNext());

    queue = BackpressureConfiguration(completer, isolateConfiguration);
  }
}
