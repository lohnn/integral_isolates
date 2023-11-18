import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:integral_isolates/integral_isolates.dart';

export 'package:integral_isolates/integral_isolates.dart';

/// A hook that exposes a [StatefulIsolate].
///
/// The hook allows for overriding the default backpressure strategy by setting
/// [backpressureStrategy].
///
/// This example uses the hook for checking if a number is a prime value on
/// each click of a button.
///
/// ```dart
/// class TestingIsolateHook extends HookWidget {
///   const TestingIsolateHook({super.key});
///
///   @override
///   Widget build(BuildContext context) {
///     final isolate = useIsolate();
///     final number = useState(1);
///
///     return TextButton(
///       onPressed: () async {
///         var isPrime = await isolate.compute(_isPrime, number.value);
///         print('${number.value} is a prime number? ${isPrime}');
///         number.value += 1;
///       },
///       child: Text(
///         'Check if ${number.value} is a prime number',
///       ),
///     );
///   }
///
///   static bool _isPrime(int value) {
///     if (value == 1) {
///       return false;
///     }
///     for (int i = 2; i < value; ++i) {
///       if (value % i == 0) {
///         return false;
///       }
///     }
///     return true;
///   }
/// }
/// ```
StatefulIsolate useIsolate({BackpressureStrategy? backpressureStrategy}) {
  return use(_IsolateHook(backpressureStrategy));
}

class _IsolateHook extends Hook<StatefulIsolate> {
  final BackpressureStrategy? backpressureStrategy;

  const _IsolateHook(this.backpressureStrategy);

  @override
  _IsolateHookState createState() => _IsolateHookState();
}

class _IsolateHookState extends HookState<StatefulIsolate, _IsolateHook> {
  late final StatefulIsolate _isolate;

  @override
  Future initHook() async {
    _isolate = StatefulIsolate(
      backpressureStrategy:
          hook.backpressureStrategy ?? NoBackPressureStrategy(),
    );
  }

  @override
  void dispose() {
    _isolate.dispose();
    super.dispose();
  }

  @override
  StatefulIsolate build(BuildContext context) => _isolate;
}
