// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'dart:async';

import 'package:integral_isolates/src/backpressure/backpressure_strategy.dart';
import 'package:integral_isolates/src/backpressure/mixins/one_sized_queue.dart';
import 'package:integral_isolates/src/isolate_configuration.dart';

class ReplaceBackpressureStrategy extends BackpressureStrategy
    with OneSizedQueue {
  @override
  Future add(MapEntry<Completer, IsolateConfiguration> configuration) async {
    if (nextUp != null) drop(nextUp!);

    nextUp = configuration;

    if (!hasNext.isCompleted) hasNext.complete(true);
  }
}
