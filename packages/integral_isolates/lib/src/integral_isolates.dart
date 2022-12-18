library use_isolate;

import 'dart:async';
import 'dart:developer';
import 'dart:isolate';

import 'package:async/async.dart';
import 'package:integral_isolates/integral_isolates.dart';
import 'package:integral_isolates/src/isolate_configuration.dart';
import 'package:meta/meta.dart';

/// Minimal class that wraps [StatefulIsolate] that supports changing
/// backpressure strategy and auto init from constructor.
///
/// Usage of the [isolate] function is used the same way as the compute function
/// in the Flutter library.
///
/// The following code is similar to the example from Flutter's compute
/// function, but allows for reusing the same isolate for multiple calls.
///
/// ```dart
/// void main() async {
///   final isolated = Isolated();
///   final isolate = isolated.isolate;
///   print(await isolate(_isPrime, 7));
///   print(await isolate(_isPrime, 42));
///   print(await isolate(_isPrime, 50));
///   print(await isolate(_isPrime, 70));
///   isolated.dispose();
/// }
///
/// bool _isPrime(int value) {
///   if (value == 1) {
///     return false;
///   }
///   for (int i = 2; i < value; ++i) {
///     if (value % i == 0) {
///       return false;
///     }
///   }
///   return true;
/// }
/// ```
class Isolated extends StatefulIsolate {
  @override
  final BackpressureStrategy backpressureStrategy;

  /// Creates a minimal isolate.
  ///
  /// If [backpressureStrategy] is set, this instance will use provided
  /// strategy. If is is not provided [NoBackPressureStrategy] will be used as
  /// default.
  ///
  /// If [autoInit] is set to false, you have to call function [init] before
  /// starting to use the isolate.
  Isolated({BackpressureStrategy? backpressureStrategy, bool autoInit = true})
      : backpressureStrategy =
            backpressureStrategy ?? NoBackPressureStrategy() {
    if (autoInit) init();
  }
}

/// Interface for exposing just the [isolate] function.
///
/// The abstract class [StatefulIsolate] contains  all the logic for
/// integral_isolates. Most likely implementing the [IsolateGetter] interface
/// should just extend the [StatefulIsolate] class.
abstract class IsolateGetter {
  /// The compute function to implement.
  ///
  /// Example could be [StatefulIsolate.isolate].
  Future<R> isolate<Q, R>(
    IsolateCallback<Q, R> callback,
    Q message, {
    String? debugLabel,
  });
}

/// Abstract class for the whole inner workings of stateful_isolates.
///
/// [Isolated] is extending this class and is a class for simple use of the
/// [isolate] function.
abstract class StatefulIsolate implements IsolateGetter {
  late StreamQueue _isolateToMainPort;
  late SendPort _mainToIsolatePort;
  SendPort? _closePort;
  Completer<void>? _initCompleter;

  /// Implementations of [StatefulIsolate] has to override this to specify a
  /// backpressureStrategy.
  BackpressureStrategy get backpressureStrategy;

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

  /// A function that runs the provided `callback` on the long running isolate
  /// and (eventually) returns the value returned by `callback`.
  ///
  /// Same footprint as the function compute from flutter, but runs on the
  /// long running thread and allows running in a pure Dart environment.
  @override
  @mustCallSuper
  Future<R> isolate<Q, R>(
    IsolateCallback<Q, R> callback,
    Q message, {
    String? debugLabel,
  }) {
    debugLabel ??= 'compute';

    final Flow flow = Flow.begin();

    final completer = Completer<R>();
    final isolateConfiguration = IsolateConfiguration(
      callback,
      message,
      debugLabel,
      flow.id,
    );

    backpressureStrategy.add(MapEntry(completer, isolateConfiguration));
    _handleIsolateCall();
    return completer.future;
  }

  /// Closes down the isolate and cancels all jobs currently in queue.
  ///
  /// This function should always be called when you are done with the isolate
  /// to not leak memory and isolates.
  ///
  /// After this function is called, you cannot continue using the isolate.
  @mustCallSuper
  Future dispose() async {
    // TODO(lohnn): prevent user from adding more work to the isolate after this function is called.
    _closePort?.send('close');
    _isolateToMainPort.cancel();
    backpressureStrategy.dispose();
  }

  /// If the worker is currently running, this bool will be set to true
  bool _isRunning = false;

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
        _mainToIsolatePort.send(configuration.value);

        final response = await _isolateToMainPort.next;
        if (response is _SuccessIsolateResponse) {
          configuration.key.complete(response.response);
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

/// Signature for the callback passed to [StatefulIsolate.isolate].
///
/// Instances of [IsolateCallback] must be functions that can be sent to an
/// isolate.
///
/// For more information on how this can be used, take a look at
/// [foundation.ComputeCallback](https://api.flutter.dev/flutter/foundation/ComputeCallback.html)
/// from the official Flutter documentation.
typedef IsolateCallback<Q, R> = FutureOr<R> Function(Q message);

/// Data type of the implementation of the computation function.
///
/// Can be used as data type for the computation function
/// [StatefulIsolate.isolate].
typedef IsolateComputeImpl = Future<R> Function<Q, R>(
  IsolateCallback<Q, R> callback,
  Q message, {
  String? debugLabel,
});

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
