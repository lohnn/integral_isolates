import 'dart:async';

import 'package:integral_isolates/src/backpressure/backpressure_strategy.dart';
import 'package:integral_isolates/src/backpressure/mixins/one_sized_queue.dart';
import 'package:integral_isolates/src/isolate_configuration.dart';

// TODO(lohnn): Document that you should ALWAYS return the data type of the newData
class CombineBackPressureStrategy<Q, R> extends BackpressureStrategy<Q, R>
    with OneSizedQueue {
  final Q Function(
    Q oldData,
    Q newData,
  ) combineFunction;

  CombineBackPressureStrategy(this.combineFunction);

  @override
  void add(
    Completer completer,
    IsolateConfiguration<Q, R> isolateConfiguration,
  ) {
    if (hasNext()) {
      final queuedConfiguration = takeNext();
      drop(queuedConfiguration);

      final newMessage = combineFunction(
        queuedConfiguration.value.message,
        isolateConfiguration.message,
      );

      final combinedConfiguration = isolateConfiguration.copyWith(
        message: newMessage,
      );

      queue = BackpressureConfiguration(completer, combinedConfiguration);
    } else {
      queue = BackpressureConfiguration(completer, isolateConfiguration);
    }
  }
}
