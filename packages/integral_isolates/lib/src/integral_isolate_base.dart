// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'dart:developer';
import 'dart:isolate';

import 'package:async/async.dart';
import 'package:integral_isolates/integral_isolates.dart';
import 'package:integral_isolates/src/backpressure/backpressure_strategy.dart';
import 'package:integral_isolates/src/isolate_configuration.dart';
import 'package:meta/meta.dart';

@internal
mixin IsolateBase<Q, R> {
  late StreamQueue _isolateToMainPort;
  late SendPort _mainToIsolatePort;
  SendPort? _closePort;
  Completer<void>? _initCompleter;

  /// Implementations of [StatefulIsolate] has to override this to specify a
  /// backpressureStrategy.
  BackpressureStrategy<Q, R> get backpressureStrategy;

  /// Initializes the isolate for use.
  ///
  /// It is fine to call this function more than once, initialization will only
  /// be run once anyway.
  @mustCallSuper
  Future init() async {
    if (_initCompleter != null) return _initCompleter;
    _initCompleter = Completer<void>();

    final isolateToMainPort = ReceivePort();
    _isolateToMainPort = StreamQueue(isolateToMainPort);
    await Isolate.spawn(
      _isolate,
      isolateToMainPort.sendPort,
    );

    final isolateSetupResponse =
        await _isolateToMainPort.next as _IsolateSetupResponse;
    _mainToIsolatePort = isolateSetupResponse.mainToIsolatePort;
    _closePort = isolateSetupResponse.closePort;

    handleIsolateCall();
    _initCompleter!.complete();
  }

  /// Internal helper function to wrap creation of an isolate call, add it to
  /// queue and start running the queue.
  @internal
  void addIsolateCall(
    BackpressureConfiguration<Q, R> Function(Flow flow)
        createBackpressureConfiguration,
  ) {
    final Flow flow = Flow.begin();
    backpressureStrategy.add(createBackpressureConfiguration(flow));
    handleIsolateCall();
  }

  /// If the worker is currently running, this bool will be set to true
  bool _isRunning = false;
  bool _disposed = false;

  @internal
  Future handleIsolateCall() async {
    if (_initCompleter == null) {
      throw InitException();
    } else if (!_initCompleter!.isCompleted) {
      await _initCompleter!.future;
    }
    if (!_isRunning && backpressureStrategy.hasNext()) {
      _isRunning = true;
      final configuration = backpressureStrategy.takeNext();

      try {
        if (_disposed) {
          configuration.closeError(IsolateClosedDropException());
          return;
        }

        _mainToIsolatePort.send(configuration.configuration);

        await configuration.handleResponse(_isolateToMainPort);
      } catch (e, stackTrace) {
        configuration.closeError(e, stackTrace);
      }
      _isRunning = false;
      handleIsolateCall();
    }
  }

  /// Closes down the isolate and cancels all jobs currently in queue.
  ///
  /// This function should always be called when you are done with the isolate
  /// to not leak memory and isolates.
  ///
  /// After this function is called, you cannot continue using the isolate.
  @mustCallSuper
  Future dispose() async {
    _disposed = true;
    _closePort?.send('close');
    _isolateToMainPort.cancel();
    backpressureStrategy.dispose();
  }
}

Future _isolate(SendPort isolateToMainPort) async {
  final mainToIsolateStream = ReceivePort();
  final closePort = ReceivePort();

  isolateToMainPort.send(
    _IsolateSetupResponse(
      mainToIsolateStream.sendPort,
      closePort.sendPort,
    ),
  );

  closePort.first.then((_) {
    mainToIsolateStream.close();
    closePort.close();
  });

  await for (final data in mainToIsolateStream) {
    try {
      if (data is IsolateConfiguration) {
        try {
          if (data is FutureIsolateConfiguration) {
            isolateToMainPort.send(
              SuccessIsolateResponse(
                data.flowId,
                await data.applyAndTime(),
              ),
            );
          } else if (data is StreamIsolateConfiguration) {
            await for (final event in data.applyAndTime()) {
              isolateToMainPort.send(
                PartialSuccessIsolateResponse._(
                  data.flowId,
                  await event,
                ),
              );
            }
            isolateToMainPort.send(
              StreamClosedIsolateResponse._(data.flowId),
            );
          }
        } catch (error, stackTrace) {
          isolateToMainPort.send(
            IsolateResponse.error(data.flowId, error, stackTrace),
          );
        }
      } else {
        isolateToMainPort.send(null);
      }
    } catch (_) {
      isolateToMainPort.send(null);
    }
  }
}

@immutable
class _IsolateSetupResponse {
  const _IsolateSetupResponse(this.mainToIsolatePort, this.closePort);

  final SendPort mainToIsolatePort;
  final SendPort closePort;
}

@internal
abstract class IsolateResponse<R> {
  final int flowId;

  const IsolateResponse(this.flowId);

  const factory IsolateResponse.error(
    int flowId,
    Object error,
    StackTrace stackTrace,
  ) = ErrorIsolateResponse._;
}

@internal
class SuccessIsolateResponse<R> extends IsolateResponse<R> {
  final R response;

  @internal
  const SuccessIsolateResponse(super.flowId, this.response);
}

@internal
class PartialSuccessIsolateResponse<R> extends SuccessIsolateResponse<R> {
  const PartialSuccessIsolateResponse._(super.flowId, super.response);
}

@internal
class StreamClosedIsolateResponse<R> extends IsolateResponse<R> {
  const StreamClosedIsolateResponse._(super.flowId);
}

@internal
class ErrorIsolateResponse<R> extends IsolateResponse<R> {
  final Object error;
  final StackTrace stackTrace;

  const ErrorIsolateResponse._(super.flowId, this.error, this.stackTrace);
}
