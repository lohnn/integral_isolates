library use_isolate;

import 'dart:async';

import 'package:integral_isolates/integral_isolates.dart';

@Deprecated('Use StatefulIsolate directly instead')
// ignore: public_member_api_docs
class Isolated extends StatefulIsolate {
  // ignore: public_member_api_docs
  @Deprecated('Use StatefulIsolate directly instead')
  Isolated({super.backpressureStrategy, super.autoInit});
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

typedef IsolateStreamCallback<Q, R> = Stream<R> Function(Q message);
