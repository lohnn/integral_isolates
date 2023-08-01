import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:integral_isolates/integral_isolates.dart';

export 'package:integral_isolates/integral_isolates.dart';

/// A hook that exposes a typed computation function using a long living isolate.
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
///     final isolate = useTailoredIsolate<int, bool>();
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
TailoredIsolateComputeImpl<Q, R> useTailoredIsolate<Q, R>({
  BackpressureStrategy<Q, R>? backpressureStrategy,
}) {
  return use(_IsolateHook<Q, R>(backpressureStrategy)).isolate;
}

class _IsolateHook<Q, R> extends Hook<TailoredStatefulIsolate<Q, R>> {
  final BackpressureStrategy<Q, R>? backpressureStrategy;

  const _IsolateHook(this.backpressureStrategy);

  @override
  _IsolateHookState<Q, R> createState() => _IsolateHookState<Q, R>();
}

class _IsolateHookState<Q, R>
    extends HookState<TailoredStatefulIsolate<Q, R>, _IsolateHook<Q, R>> {
  late final TailoredStatefulIsolate<Q, R> _isolated;

  @override
  Future initHook() async {
    _isolated = TailoredStatefulIsolate<Q, R>(
      backpressureStrategy:
          hook.backpressureStrategy ?? NoBackPressureStrategy<Q, R>(),
    );
  }

  @override
  void dispose() {
    _isolated.dispose();
    super.dispose();
  }

  @override
  TailoredStatefulIsolate<Q, R> build(BuildContext context) {
    return _isolated;
  }
}
