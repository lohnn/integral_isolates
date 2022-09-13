import 'dart:async';

import 'package:integral_isolates/src/backpressure/backpressure_strategy.dart';
import 'package:integral_isolates/src/backpressure/mixins/one_sized_queue.dart';

class ReplaceBackpressureStrategy extends BackpressureStrategy
    with OneSizedQueue {
  @override
  Future add(BackpressureConfiguration configuration) async {
    if (hasNext()) drop(takeNext());

    nextUp = configuration;
  }
}
