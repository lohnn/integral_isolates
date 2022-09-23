// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'dart:developer';

import 'package:integral_isolates/integral_isolates.dart';
import 'package:meta/meta.dart';

@protected
@immutable
class IsolateConfiguration<Q, R> {
  const IsolateConfiguration(
    this.callback,
    this.message,
    this.debugLabel,
    this.flowId,
  );

  final IsolateCallback<Q, R> callback;
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

  @override
  String toString() {
    return 'IsolateConfiguration(message: $message, debugLabel: $debugLabel, flowId: $flowId)';
  }
}
