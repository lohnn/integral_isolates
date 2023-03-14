import 'dart:async';
import 'dart:developer';

import 'package:integral_isolates/integral_isolates.dart';
import 'package:integral_isolates/src/integral_isolate_base.dart';
import 'package:integral_isolates/src/isolate_configuration.dart';
import 'package:meta/meta.dart';

/// Data type of the implementation of the computation function.
///
/// Can be used as data type for the computation function, for example when
/// returning the [StatefulIsolate.isolate] as a return type of a function.
typedef IsolateComputeImpl = Future<R> Function<Q, R>(
  IsolateCallback<Q, R> callback,
  Q message, {
  String? debugLabel,
});

/// Interface for exposing the [isolate] function for a [StatefulIsolate].
///
/// Useful for when wrapping the functionality and just want to expose the
/// computation function.
abstract class IsolateGetter {
  /// The computation function, a function used the same way as Flutter's
  /// compute function, but for a long lived isolate.
  Future<R> isolate<Q, R>(
    IsolateCallback<Q, R> callback,
    Q message, {
    String? debugLabel,
  });
}

/// A class that makes running code in an isolate almost as easy as running
/// Flutter's compute function.
///
/// Using [backpressureStrategy], you can decide how to handle the case when too
/// many calls to the isolate are made for it to handle in time.
///
/// Usage of the [isolate] function is used the same way as the compute function
/// in the Flutter library.
///
/// The following code is similar to the example from Flutter's compute
/// function, but allows for reusing the same isolate for multiple calls.
///
/// ```dart
/// void main() async {
///   final statefulIsolate = StatefulIsolate();
///   final computation = statefulIsolate.isolate;
///   print(await computation(_isPrime, 7));
///   print(await computation(_isPrime, 42));
///   print(await computation(_isPrime, 50));
///   print(await computation(_parseBool, false));
///   print(await computation(_isPrime, 70));
///   statefulIsolate.dispose();
/// }
///
/// String _parseBool(bool value) {
///   return value.toString();
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
///
/// See also:
///
///  * [TailoredStatefulIsolate], to create a long lived isolate that only takes
///  specific input and output types.
class StatefulIsolate with IsolateBase implements IsolateGetter {
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
  StatefulIsolate({
    BackpressureStrategy? backpressureStrategy,
    bool autoInit = true,
  }) : backpressureStrategy = backpressureStrategy ?? NoBackPressureStrategy() {
    if (autoInit) init();
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

    backpressureStrategy.add(completer, isolateConfiguration);
    handleIsolateCall();
    return completer.future;
  }
}
