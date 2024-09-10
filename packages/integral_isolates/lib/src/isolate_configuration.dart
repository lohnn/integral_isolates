// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'dart:developer';
import 'dart:isolate';

import 'package:integral_isolates/src/integral_isolate_base.dart';
import 'package:integral_isolates/src/integral_isolates.dart';
import 'package:meta/meta.dart';

@internal
@immutable
sealed class IsolateConfiguration<R> {
  const IsolateConfiguration(
    String? debugLabel,
    this.flowId,
  ) : debugLabel = debugLabel ?? 'compute';

  final String debugLabel;
  final int flowId;

  @override
  String toString() {
    return 'IsolateConfiguration('
        'debugLabel: $debugLabel, '
        'flowId: $flowId'
        ')';
  }

  /// Internal function that is called to let the [IsolateConfiguration]
  /// implementation handle the isolate call.
  @internal
  Future<void> handleCall(SendPort isolateToMainPort);
}

final class FutureIsolateRunConfiguration<Q, R>
    extends IsolateConfiguration<R> {
  const FutureIsolateRunConfiguration(
    this.computation,
    super.debugLabel,
    super.flowId,
  );

  final IsolateRunCallback<R> computation;

  FutureOr<R> applyAndTime() {
    return Timeline.timeSync(
      debugLabel,
      computation,
      flow: Flow.step(flowId),
    );
  }

  @override
  Future<void> handleCall(SendPort isolateToMainPort) async {
    isolateToMainPort.send(
      SuccessIsolateResponse(flowId, await applyAndTime()),
    );
  }
}

sealed class TailoredIsolateConfiguration<Q, R>
    extends IsolateConfiguration<R> {
  const TailoredIsolateConfiguration(
    this.message,
    super.debugLabel,
    super.flowId,
  );

  final Q message;

  TailoredIsolateConfiguration<Q, R> copyWith({required Q message});
}

final class FutureIsolateComputeConfiguration<Q, R>
    extends TailoredIsolateConfiguration<Q, R> {
  const FutureIsolateComputeConfiguration(
    this.callback,
    super.message,
    super.debugLabel,
    super.flowId,
  );

  final IsolateComputeCallback<Q, R> callback;

  FutureOr<R> applyAndTime() {
    return Timeline.timeSync(
      debugLabel,
      () => callback(message),
      flow: Flow.step(flowId),
    );
  }

  @override
  TailoredIsolateConfiguration<Q, R> copyWith({required Q message}) {
    return FutureIsolateComputeConfiguration(
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

final class StreamIsolateConfiguration<R> extends IsolateConfiguration<R> {
  const StreamIsolateConfiguration(
    this._stream,
    super.debugLabel,
    super.flowId,
  );

  final IsolateStream<R> _stream;

  Stream<FutureOr<R>> applyAndTime() {
    return Timeline.timeSync(
      debugLabel,
      _stream,
      flow: Flow.step(flowId),
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

final class TailoredStreamIsolateConfiguration<Q, R>
    extends TailoredIsolateConfiguration<Q, R> {
  const TailoredStreamIsolateConfiguration(
    this._stream,
    super.message,
    super.debugLabel,
    super.flowId,
  );

  final TailoredIsolateStream<Q, R> _stream;

  Stream<FutureOr<R>> applyAndTime() {
    return Timeline.timeSync(
      debugLabel,
      () => _stream(message),
      flow: Flow.step(flowId),
    );
  }

  @override
  TailoredIsolateConfiguration<Q, R> copyWith({required Q message}) {
    return TailoredStreamIsolateConfiguration(
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
