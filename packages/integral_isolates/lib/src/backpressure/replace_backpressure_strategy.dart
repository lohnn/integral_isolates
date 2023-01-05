import 'package:integral_isolates/src/backpressure/backpressure_strategy.dart';
import 'package:integral_isolates/src/backpressure/one_sized_queue_backpressure_strategy.dart';

/// An implementation of [BackpressureStrategy] that has a job queue with size
/// one, and discards the queue upon adding a new job.
///
/// Marble diagram to visualize timeline:
///
/// --a--b--c---d--e--f-----|
///
/// ---------a-c-------d--f-|
class ReplaceBackpressureStrategy<Q, R>
    extends OneSizedQueueBackPressureStrategy<Q, R> {
  @override
  @override
  Q combineFunction<O, N>(
    O oldData,
    N newData,
  ) {
    return newData as Q;
  }
}
