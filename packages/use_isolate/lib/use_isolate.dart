library use_isolate;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:integral_isolates/integral_isolates.dart';

ComputeImpl useIsolate({BackpressureStrategy? backpressureStrategy}) {
  return use(_IsolateHook(backpressureStrategy));
}

class _IsolateHook extends Hook<ComputeImpl> {
  final BackpressureStrategy? backpressureStrategy;

  const _IsolateHook(this.backpressureStrategy);

  @override
  _IsolateHookState createState() => _IsolateHookState(
        backpressureStrategy ?? NoBackPressureStrategy(),
      );
}

class _IsolateHookState extends HookState<ComputeImpl, _IsolateHook>
    with StatefulIsolate {
  _IsolateHookState(this.backpressureStrategy);

  @override
  final BackpressureStrategy backpressureStrategy;

  @override
  Future initHook() async {
    init();
  }

  @override
  ComputeImpl build(BuildContext context) => isolate;
}
