import 'dart:async';

import 'package:integral_isolates/integral_isolates.dart';

/// Signature for the callback passed to [StatefulIsolate.compute].
///
/// Instances of [IsolateComputeCallback] must be functions that can be sent to an
/// isolate.
///
/// For more information on how this can be used, take a look at
/// [foundation.ComputeCallback](https://api.flutter.dev/flutter/foundation/ComputeCallback.html)
/// from the official Flutter documentation.
typedef IsolateComputeCallback<Q, R> = FutureOr<R> Function(Q message);
typedef IsolateRunCallback<R> = FutureOr<R> Function();

/// Signature for the callback passed to [StatefulIsolate.stream].
///
/// Instances of [IsolateStream] must be functions that can be sent to an
/// isolate.
typedef IsolateStream<R> = Stream<R> Function();
typedef TailoredIsolateStream<Q, R> = Stream<R> Function(Q message);
