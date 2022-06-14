library flame_isolate;

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:integral_isolates/integral_isolates.dart';

mixin FlameIsolate on Component implements IsolateGetter {
  final _isolate = Isolated();

  @override
  Future onMount() async {
    _isolate.init();
    return super.onMount();
  }

  @override
  void onRemove() {
    _isolate.dispose();
  }

  @override
  Future<R> isolate<Q, R>(
    ComputeCallback<Q, R> callback,
    Q message, {
    String? debugLabel,
  }) =>
      _isolate.isolate(callback, message, debugLabel: debugLabel);
}
