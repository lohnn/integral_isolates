import 'package:integral_isolates/src/backpressure/backpressure_strategy.dart';
import 'package:integral_isolates/src/backpressure/mixins/one_sized_queue.dart';

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
