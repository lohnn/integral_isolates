import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:integral_isolates/integral_isolates.dart';

export 'package:integral_isolates/integral_isolates.dart';

/// A hook that exposes a computation function using a long living isolate.
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
///         var isPrime = await isolate(_isPrime, number.value);
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
IsolateComputeImpl useIsolate({BackpressureStrategy? backpressureStrategy}) {
  return use(_IsolateHook(backpressureStrategy));
}

class _IsolateHook extends Hook<IsolateComputeImpl> {
  final BackpressureStrategy? backpressureStrategy;

  const _IsolateHook(this.backpressureStrategy);

  @override
  _IsolateHookState createState() => _IsolateHookState();
}

class _IsolateHookState extends HookState<IsolateComputeImpl, _IsolateHook> {
  late final Isolated _isolate;

  @override
  Future initHook() async {
    _isolate = Isolated(
      backpressureStrategy:
          hook.backpressureStrategy ?? NoBackPressureStrategy(),
    );
  }

  @override
  IsolateComputeImpl build(BuildContext context) => _isolate.isolate;
}
