// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'dart:developer';
import 'dart:isolate';

import 'package:integral_isolates/src/integral_isolate_base.dart';
import 'package:integral_isolates/src/integral_isolates.dart';
import 'package:meta/meta.dart';

@internal
@immutable
sealed class IsolateConfiguration<Q, R> {
  const IsolateConfiguration(
    this.message,
    String? debugLabel,
    this.flowId,
  ) : debugLabel = debugLabel ?? 'compute';

  final Q message;
  final String debugLabel;
  final int flowId;

  IsolateConfiguration<Q, R> copyWith({required Q message});

  @override
  String toString() {
    return 'IsolateConfiguration('
        'message: $message, '
        'debugLabel: $debugLabel, '
        'flowId: $flowId'
        ')';
  }

  /// Internal function that is called to let the [IsolateConfiguration]
  /// implementation handle the isolate call.
  @internal
  Future<void> handleCall(SendPort isolateToMainPort);
}

final class FutureIsolateConfiguration<Q, R>
    extends IsolateConfiguration<Q, R> {
  const FutureIsolateConfiguration(
    this.callback,
    super.message,
    super.debugLabel,
    super.flowId,
  );

  final IsolateCallback<Q, R> callback;

  FutureOr<R> applyAndTime() {
    return Timeline.timeSync(
      debugLabel,
      () => callback(message),
      flow: Flow.step(flowId),
    );
  }

  @override
  IsolateConfiguration<Q, R> copyWith({required Q message}) {
    return FutureIsolateConfiguration(
      callback,
      message,
      debugLabel,
      flowId,
    );
  }

  @override
  Future<void> handleCall(SendPort isolateToMainPort) async {
    isolateToMainPort.send(
      SuccessIsolateResponse(flowId, await applyAndTime()),
    );
  }
}

final class StreamIsolateConfiguration<Q, R>
    extends IsolateConfiguration<Q, R> {
  const StreamIsolateConfiguration(
    this._stream,
    super.message,
    super.debugLabel,
    super.flowId,
  );

  final IsolateStream<Q, R> _stream;

  Stream<FutureOr<R>> applyAndTime() {
    return Timeline.timeSync(
      debugLabel,
      () => _stream(message),
      flow: Flow.step(flowId),
    );
  }

  @override
  IsolateConfiguration<Q, R> copyWith({required Q message}) {
    return StreamIsolateConfiguration(
      _stream,
      message,
      debugLabel,
      flowId,
    );
  }

  @override
  Future<void> handleCall(SendPort isolateToMainPort) async {
    await for (final event in applyAndTime()) {
      isolateToMainPort.send(
        PartialSuccessIsolateResponse(
          flowId,
          await event,
        ),
      );
    }
    isolateToMainPort.send(
      StreamClosedIsolateResponse(flowId),
    );
  }
}
