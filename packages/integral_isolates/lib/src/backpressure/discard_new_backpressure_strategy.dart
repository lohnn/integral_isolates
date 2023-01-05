import 'package:integral_isolates/src/backpressure/backpressure_strategy.dart';
import 'package:integral_isolates/src/backpressure/one_sized_queue_backpressure_strategy.dart';

/// An implementation of [BackpressureStrategy] that has a job queue with size
/// one, and as long as the queue is populated all new jobs will be dropped.
///
/// Marble diagram to visualize timeline:
///
/// --a---b---c---d---e---f--|
///
/// -----a-----b-----d-----e-|
class DiscardNewBackPressureStrategy<Q, R>
    extends OneSizedQueueBackPressureStrategy<Q, R> {
  @override
  Q combineFunction<O, N>(
    O oldData,
    N newData,
  ) {
    return oldData as Q;
  }
}
