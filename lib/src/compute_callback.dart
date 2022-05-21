import 'dart:async';

typedef ComputeCallback<Q, R> = FutureOr<R> Function(Q message);
