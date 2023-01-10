library use_isolate;

import 'dart:async';
import 'dart:developer';
import 'dart:isolate';

import 'package:async/async.dart';
import 'package:integral_isolates/integral_isolates.dart';
import 'package:integral_isolates/src/isolate_configuration.dart';
import 'package:meta/meta.dart';

part 'integral_isolate_base.dart';

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

  /// Creates a minimal isolate that requires a specific input type [R].
  ///
  /// If [backpressureStrategy] is set, this instance will use provided
  /// strategy. If is is not provided [NoBackPressureStrategy] will be used as
  /// default.
  ///
  /// If [autoInit] is set to false, you have to call function [init] before
  /// starting to use the isolate.
  static _TailoredStatefulIsolate<Q, R> tailored<Q, R>({
    BackpressureStrategy<Q, R>? backpressureStrategy,
    bool autoInit = true,
  }) {
    return _TailoredStatefulIsolate<Q, R>(
      backpressureStrategy: backpressureStrategy,
      autoInit: autoInit,
    );
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
abstract class StatefulIsolate with _IsolateBase implements IsolateGetter {
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

    backpressureStrategy.add(completer, isolateConfiguration);
    _handleIsolateCall();
    return completer.future;
  }
}

/// Interface for exposing just the [isolate] function for a
/// [_TailoredStatefulIsolate].
///
/// The abstract class [TailoredStatefulIsolate] contains  all the logic for
/// integral_isolates. Most likely implementing the [IsolateGetter] interface
/// should just extend the [StatefulIsolate] class.
abstract class TailoredIsolateGetter<Q, R> {
  /// The compute function to implement.
  ///
  /// Example could be [StatefulIsolate.isolate].
  Future<R> isolate(
    IsolateCallback<Q, R> callback,
    Q message, {
    String? debugLabel,
  });
}

class _TailoredStatefulIsolate<Q, R>
    with _IsolateBase<Q, R>
    implements TailoredIsolateGetter<Q, R> {
  @override
  final BackpressureStrategy<Q, R> backpressureStrategy;

  _TailoredStatefulIsolate({
    BackpressureStrategy<Q, R>? backpressureStrategy,
    bool autoInit = true,
  }) : backpressureStrategy = backpressureStrategy ?? NoBackPressureStrategy() {
    if (autoInit) init();
  }

  @override
  Future<R> isolate(
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

    backpressureStrategy.add(completer, isolateConfiguration);
    _handleIsolateCall();
    return completer.future;
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
