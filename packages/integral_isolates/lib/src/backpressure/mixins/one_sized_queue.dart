import 'dart:async';
import 'dart:developer';

import 'package:integral_isolates/src/backpressure/backpressure_strategy.dart';
import 'package:integral_isolates/src/isolate_configuration.dart';

mixin OneSizedQueue on BackpressureStrategy {
  MapEntry<Completer, IsolateConfiguration>? nextUp;
  Completer<bool> hasNext = Completer();

  @override
  Stream<MapEntry<Completer, IsolateConfiguration>> get stream async* {
    while (await hasNext.future) {
      log('${DateTime.now()}: Yielding next configuration');
      yield nextUp!;
      log('${DateTime.now()}: Yielded next configuration');
      nextUp = null;
      hasNext = Completer();
    }
    log('ReplaceBackpressure: stream ended');
  }

  @override
  Future dispose() async {
    if (!hasNext.isCompleted) hasNext.complete(false);
  }
}
