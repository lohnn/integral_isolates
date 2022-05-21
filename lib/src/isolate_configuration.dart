import 'dart:async';
import 'dart:developer';

import 'package:integral_isolates/src/compute_callback.dart';
import 'package:meta/meta.dart';

@immutable
class IsolateConfiguration<Q, R> {
  const IsolateConfiguration(
    this.callback,
    this.message,
    this.debugLabel,
    this.flowId,
  );

  final ComputeCallback<Q, R> callback;
  final Q message;
  final String debugLabel;
  final int flowId;

  FutureOr<R> applyAndTime() {
    return Timeline.timeSync(
      debugLabel,
      () => callback(message),
      flow: Flow.step(flowId),
    );
  }
}
