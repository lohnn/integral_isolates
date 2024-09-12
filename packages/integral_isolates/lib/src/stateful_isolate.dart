import 'dart:async';
import 'dart:isolate';

import 'package:integral_isolates/integral_isolates.dart';
import 'package:integral_isolates/src/backpressure/backpressure_strategy.dart';
import 'package:integral_isolates/src/integral_isolate_base.dart';
import 'package:integral_isolates/src/isolate_configuration.dart';
import 'package:meta/meta.dart';

/// Data type of the implementation of the computation function.
///
/// Can be used as data type for the computation function, for example when
/// returning the [StatefulIsolate.compute] as a return type of a function.
typedef IsolateComputeImpl = Future<R> Function<Q, R>(
  IsolateComputeCallback<Q, R> callback,
  Q message, {
  String? debugLabel,
});

/// Data type of the implementation of the stream function.
///
/// Can be used as data type for the stream function, for example when returning
/// the [StatefulIsolate.stream] as a return type of a function.
typedef IsolateStreamComputeImpl = Future<R> Function<Q, R>(
  IsolateStream<R> callback,
  Q message, {
  String? debugLabel,
});

/// Interface for exposing the [compute] function for a [StatefulIsolate].
///
/// Useful when wrapping the functionality and just want to expose the
/// computation functions.
abstract class IsolateGetter {
  /// The compute function, used in the same way as Dart's [Isolate.run]
  /// computation function, but for a long lived isolate.
  Future<R> run<R>(IsolateRunCallback<R> computation, {String? debugLabel});

  /// A computation function that returns a [Stream] of responses from the
  /// long lived isolate.
  ///
  /// Very similar to the [run] function, but instead of returning a
  /// [Future], a [Stream] is returned to allow for a response in multiple
  /// parts. Every stream event will be sent individually through from the
  /// isolate.
  @experimental
  Stream<R> stream<R>(
    IsolateStream<R> callback, {
    String? debugLabel,
  });
}

/// A class that makes running code in an isolate almost as easy as running
/// Flutter's compute function.
///
/// Using [backpressureStrategy], you can decide how to handle the case when too
/// many calls to the isolate are made for it to handle in time.
///
/// The [compute] function is used the same way as the compute function
/// in the Flutter library.
///
/// The following code is similar to the example from Flutter's compute
/// function, but allows for reusing the same isolate for multiple calls.
///
/// ```dart
/// void main() async {
///   final statefulIsolate = StatefulIsolate();
///   print(await statefulIsolate.compute(_isPrime, 7));
///   print(await statefulIsolate.compute(_isPrime, 42));
///   print(await statefulIsolate.compute(_isPrime, 50));
///   print(await statefulIsolate.compute(_parseBool, false));
///   print(await statefulIsolate.compute(_isPrime, 70));
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
  Future<R> run<R>(IsolateRunCallback<R> computation, {String? debugLabel}) {
    final completer = Completer<R>();
    addIsolateCall((flow) {
      final isolateConfiguration = FutureIsolateRunConfiguration(
        computation,
        debugLabel,
        flow.id,
      );
      return FutureBackpressureRunConfiguration(
        completer,
        isolateConfiguration,
      );
    });
    return completer.future;
  }

  @mustCallSuper
  Future<R> compute<Q, R>(
    IsolateComputeCallback<Q, R> callback,
    Q message, {
    String? debugLabel,
  }) {
    return run(() => callback(message), debugLabel: debugLabel);
  }

  @experimental
  @override
  Stream<R> stream<R>(
    IsolateStream<R> callback, {
    String? debugLabel,
  }) {
    // TODO(lohnn): Implement onListen?
    // TODO(lohnn): Implement onPause?
    // TODO(lohnn): Implement onResume?
    final streamController = StreamController<R>();

    addIsolateCall((flow) {
      final isolateConfiguration = StreamIsolateConfiguration(
        callback,
        debugLabel,
        flow.id,
      );
      return StreamBackpressureConfiguration(
        streamController,
        isolateConfiguration,
      );
    });

    return streamController.stream;
  }

  Stream<R> computeStream<Q, R>(
    TailoredIsolateStream<Q, R> callback,
    Q message, {
    String? debugLabel,
  }) {
    return stream(() => callback(message), debugLabel: debugLabel);
  }
}
