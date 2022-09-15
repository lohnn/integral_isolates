import 'package:integral_isolates/src/backpressure/backpressure_strategy.dart';
import 'package:integral_isolates/src/backpressure/mixins/one_sized_queue.dart';

/// An implementation of [BackpressureStrategy] that has a job queue with size
/// one, and as long as the queue is populated all new jobs will be dropped.
class DiscardNewBackPressureStrategy extends BackpressureStrategy
    with OneSizedQueue {
  @override
  void add(BackpressureConfiguration configuration) {
    if (hasNext()) {
      drop(configuration);
    } else {
      nextUp = configuration;
    }
  }
}
