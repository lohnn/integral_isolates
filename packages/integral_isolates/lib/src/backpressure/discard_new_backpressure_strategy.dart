import 'package:integral_isolates/src/backpressure/backpressure_strategy.dart';
import 'package:integral_isolates/src/backpressure/mixins/one_sized_queue.dart';

/// An implementation of [BackpressureStrategy] that has a job queue with size
/// one, and as long as the queue is populated all new jobs will be dropped.
///
/// Marble diagram to visualize timeline:
///
/// --a---b---c---d---e---f--|
///
/// -----a-----b-----d-----e-|
class DiscardNewBackPressureStrategy<R> extends BackpressureStrategy<R>
    with OneSizedQueue<R> {
  @override
  void add(BackpressureConfiguration<R> configuration) {
    if (hasNext()) {
      drop(configuration);
    } else {
      queue = configuration;
    }
  }
}
