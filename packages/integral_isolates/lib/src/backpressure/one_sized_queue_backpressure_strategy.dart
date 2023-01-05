import 'dart:async';

import 'package:integral_isolates/src/backpressure/backpressure_strategy.dart';
import 'package:integral_isolates/src/isolate_configuration.dart';

/// Mixin to help out with a queue of one size for [BackpressureStrategy].
abstract class OneSizedQueueBackPressureStrategy<Q, R>
    extends BackpressureStrategy<Q, R> {
  /// The next item in queue for execution.
  BackpressureConfiguration<Q, R>? queue;

  Q combineFunction<O, N>(
    O oldData,
    N newData,
  );

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

  @override
  bool hasNext() => queue != null;

  @override
  BackpressureConfiguration<Q, R> takeNext() {
    final toReturn = queue!;
    queue = null;
    return toReturn;
  }

  @override
  Future dispose() async {
    if (hasNext()) drop(takeNext());
  }
}
