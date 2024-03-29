import 'dart:async';

import 'package:integral_isolates/integral_isolates.dart';
import 'package:integral_isolates/src/backpressure/backpressure_strategy.dart';
import 'package:integral_isolates/src/integral_isolate_base.dart';
import 'package:integral_isolates/src/isolate_configuration.dart';
import 'package:meta/meta.dart';

/// Data type of the implementation of the computation function.
///
/// Can be used as data type for the computation function, for example when
/// returning the [TailoredStatefulIsolate.compute] as a return type of a
/// function.
///
/// [Q] is the input parameter type.
///
/// [R] is the response type.
typedef TailoredIsolateComputeImpl<Q, R> = Future<R> Function(
  IsolateCallback<Q, R> callback,
  Q message, {
  String? debugLabel,
});

/// Interface for exposing the [compute] function for a
/// [TailoredStatefulIsolate].
///
/// Useful for when wrapping the functionality and just want to expose the
/// computation function.
abstract class TailoredIsolateGetter<Q, R> {
  /// The computation function, a function used the same way as Flutter's
  /// compute function, but for a long lived isolate.
  Future<R> compute(
    IsolateCallback<Q, R> callback,
    Q message, {
    String? debugLabel,
  });

  /// A computation function that returns a [Stream] of responses from the
  /// long lived isolate.
  ///
  /// Very similar to the [compute] function, but instead of returning a
  /// [Future], a [Stream] is returned to allow for a response in multiple
  /// parts. Every stream event will be sent individually through from the
  /// isolate.
  @experimental
  Stream<R> computeStream(
    IsolateStream<Q, R> callback,
    Q message, {
    String? debugLabel,
  });
}

/// A class that makes running code in an isolate almost as easy as running
/// Flutter's compute function.
///
/// This is a tailored version of [StatefulIsolate], where you can specify what
/// input type and output type is allowed.
///
/// * The generic type [Q] is used for input type.
/// * The generic type [R] is used for output type.
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
///   final statefulIsolate = TailoredStatefulIsolate<int, bool>();
///   print(await statefulIsolate.compute(_isPrime, 7));
///   print(await statefulIsolate.compute(_isPrime, 42));
///   print(await statefulIsolate.compute(_isPrime, 50));
///   print(await statefulIsolate.compute(_isPrime, 70));
///   statefulIsolate.dispose();
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
///  * [StatefulIsolate], to create a long lived isolate that has no predefined
///  input and output typed, but rather decides type per call to the [compute]
///  function.
final class TailoredStatefulIsolate<Q, R>
    with IsolateBase<Q, R>
    implements TailoredIsolateGetter<Q, R> {
  @override
  final BackpressureStrategy<Q, R> backpressureStrategy;

  /// Creates a minimal isolate that requires a specific input type [Q], and
  /// that can only be used with functions returning type [R]
  ///
  /// If [backpressureStrategy] is set, this instance will use provided
  /// strategy. If is is not provided [NoBackPressureStrategy] will be used as
  /// default.
  ///
  /// If [autoInit] is set to false, you have to call function [init] before
  /// starting to use the isolate.
  TailoredStatefulIsolate({
    BackpressureStrategy<Q, R>? backpressureStrategy,
    bool autoInit = true,
  }) : backpressureStrategy = backpressureStrategy ?? NoBackPressureStrategy() {
    if (autoInit) init();
  }

  @override
  Future<R> compute(
    IsolateCallback<Q, R> callback,
    Q message, {
    String? debugLabel,
  }) {
    final completer = Completer<R>();

    addIsolateCall((flow) {
      final isolateConfiguration = FutureIsolateConfiguration(
        callback,
        message,
        debugLabel,
        flow.id,
      );
      return FutureBackpressureConfiguration(
        completer,
        isolateConfiguration,
      );
    });

    return completer.future;
  }

  @experimental
  @override
  Stream<R> computeStream(
    IsolateStream<Q, R> callback,
    Q message, {
    String? debugLabel,
  }) {
    // TODO(lohnn): Implement onListen?
    // TODO(lohnn): Implement onPause?
    // TODO(lohnn): Implement onResume?
    final streamController = StreamController<R>();

    addIsolateCall((flow) {
      final isolateConfiguration = StreamIsolateConfiguration(
        callback,
        message,
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
}
