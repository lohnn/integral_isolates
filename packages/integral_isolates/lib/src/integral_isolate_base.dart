part of 'integral_isolates.dart';

mixin _IsolateBase<Q, R> {
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

    _isolateToMainPort = _isolateToMainPort;

    final isolateSetupResponse =
        await _isolateToMainPort.next as _IsolateSetupResponse;
    _mainToIsolatePort = isolateSetupResponse.mainToIsolatePort;
    _closePort = isolateSetupResponse.closePort;

    _handleIsolateCall();
    _initCompleter!.complete();
  }

  /// If the worker is currently running, this bool will be set to true
  bool _isRunning = false;
  bool _disposed = false;

  Future _handleIsolateCall() async {
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
          configuration.key.completeError(IsolateClosedDropException());
          return;
        }

        _mainToIsolatePort.send(configuration.value);

        final response = await _isolateToMainPort.next;
        if (response is _SuccessIsolateResponse) {
          configuration.key.complete(response.response as R);
        } else if (response is _ErrorIsolateResponse) {
          configuration.key.completeError(response.error, response.stackTrace);
        } else {
          // TODO(lohnn): Should not be possible? Notify the developer of issue?
        }
      } catch (e, stackTrace) {
        configuration.key.completeError(e, stackTrace);
      }
      _isRunning = false;
      _handleIsolateCall();
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
          isolateToMainPort.send(
            _IsolateResponse.success(
              data.flowId,
              await data.applyAndTime(),
            ),
          );
        } catch (error, stackTrace) {
          isolateToMainPort.send(
            _IsolateResponse.error(data.flowId, error, stackTrace),
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

abstract class _IsolateResponse<R> {
  final int flowId;

  const _IsolateResponse(this.flowId);

  const factory _IsolateResponse.success(int flowId, R response) =
      _SuccessIsolateResponse;

  const factory _IsolateResponse.error(
    int flowId,
    Object error,
    StackTrace stackTrace,
  ) = _ErrorIsolateResponse;
}

class _SuccessIsolateResponse<R> extends _IsolateResponse<R> {
  final R response;

  const _SuccessIsolateResponse(super.flowId, this.response);
}

class _ErrorIsolateResponse<R> extends _IsolateResponse<R> {
  final Object error;
  final StackTrace stackTrace;

  const _ErrorIsolateResponse(super.flowId, this.error, this.stackTrace);
}
