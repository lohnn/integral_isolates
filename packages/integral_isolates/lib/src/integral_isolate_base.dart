import 'dart:async';
import 'dart:developer';
import 'dart:isolate';

import 'package:async/async.dart';
import 'package:integral_isolates/integral_isolates.dart';
import 'package:integral_isolates/src/backpressure/backpressure_strategy.dart';
import 'package:integral_isolates/src/isolate_configuration.dart';
import 'package:meta/meta.dart';

abstract class PostInitStuff<T> {
  @internal
  InitThingie<T>? postInit() => null;
}

@internal
abstract class IsolateBase<Q, R, PostInitType>
    extends PostInitStuff<PostInitType> {
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
    final postInit = this.postInit();
    final setupConfiguration = IsolateSetupConfiguration(
      isolateToMainPort.sendPort,
      extraInit: postInit,
    );
    _isolateToMainPort = StreamQueue(isolateToMainPort);
    await Isolate.spawn(
      _isolate,
      setupConfiguration,
    );

    final isolateSetupResponse =
        await _isolateToMainPort.next as _IsolateSetupResponse;
    _mainToIsolatePort = isolateSetupResponse.mainToIsolatePort;
    _closePort = isolateSetupResponse.closePort;

    if (postInit != null) {
      final postInitResponse =
          await _isolateToMainPort.next as _IsolateInitResponse;
      if (postInitResponse is _IsolateInitFailureResponse) {
        // TODO(lohnn): before release - maybe better logging telling user that it failed on postInit?
        _initCompleter!.completeError(
          postInitResponse.error,
          postInitResponse.stackTrace,
        );
        return;
      }
    }

    _handleIsolateCall();
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
    _handleIsolateCall();
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
          configuration.closeError(const IsolateClosedDropException());
          return;
        }

        _mainToIsolatePort.send(configuration.configuration);

        await configuration.handleResponse(_isolateToMainPort);
      } catch (e, stackTrace) {
        configuration.closeError(e, stackTrace);
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
  /// After this function is called, trying to use the isolate will throw a
  /// [IsolateClosedDropException].
  @mustCallSuper
  Future dispose() async {
    _disposed = true;
    _closePort?.send('close');
    _isolateToMainPort.cancel();
    backpressureStrategy.dispose();
  }
}

Future _isolate(IsolateSetupConfiguration setupConfiguration) async {
  final mainToIsolateStream = ReceivePort();
  final closePort = ReceivePort();

  final isolateToMainPort = setupConfiguration.isolateToMainPort;

  isolateToMainPort.send(
    _IsolateSetupResponse(
      mainToIsolateStream.sendPort,
      closePort.sendPort,
    ),
  );

  // Try run postInit and respond accordingly
  try {
    if ((setupConfiguration.callback, setupConfiguration.message)
        case (final initCallback?, final message)) {
      await initCallback(message);
      isolateToMainPort.send(const _IsolateInitSuccessResponse());
    }
  } catch (e, stackTrace) {
    isolateToMainPort.send(_IsolateInitFailureResponse(e, stackTrace));
  }

  closePort.first.then((_) {
    mainToIsolateStream.close();
    closePort.close();
  });

  await for (final configuration in mainToIsolateStream) {
    try {
      if (configuration is IsolateConfiguration) {
        try {
          await configuration.handleCall(isolateToMainPort);
        } catch (error, stackTrace) {
          isolateToMainPort.send(
            IsolateResponse.error(configuration.flowId, error, stackTrace),
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
final class _IsolateSetupResponse {
  const _IsolateSetupResponse(this.mainToIsolatePort, this.closePort);

  final SendPort mainToIsolatePort;
  final SendPort closePort;
}

sealed class _IsolateInitResponse {
  const _IsolateInitResponse();
}

final class _IsolateInitSuccessResponse extends _IsolateInitResponse {
  const _IsolateInitSuccessResponse();
}

final class _IsolateInitFailureResponse extends _IsolateInitResponse {
  final Object error;
  final StackTrace stackTrace;

  const _IsolateInitFailureResponse(this.error, this.stackTrace);
}

@internal
sealed class IsolateResponse<R> {
  final int flowId;

  const IsolateResponse(this.flowId);

  const factory IsolateResponse.error(
    int flowId,
    Object error,
    StackTrace stackTrace,
  ) = ErrorIsolateResponse._;
}

@internal
final class SuccessIsolateResponse<R> extends IsolateResponse<R> {
  final R response;

  @internal
  const SuccessIsolateResponse(super.flowId, this.response);
}

@internal
final class PartialSuccessIsolateResponse<R> extends SuccessIsolateResponse<R> {
  @internal
  const PartialSuccessIsolateResponse(super.flowId, super.response);
}

@internal
final class StreamClosedIsolateResponse<R> extends IsolateResponse<R> {
  @internal
  const StreamClosedIsolateResponse(super.flowId);
}

@internal
final class ErrorIsolateResponse<R> extends IsolateResponse<R> {
  final Object error;
  final StackTrace stackTrace;

  const ErrorIsolateResponse._(super.flowId, this.error, this.stackTrace);
}
