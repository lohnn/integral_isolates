import 'dart:io';

import 'package:integral_isolates/integral_isolates.dart';
import 'package:test/test.dart';

int _testFunction(int input) {
  sleep(const Duration(milliseconds: 300));
  return input;
}

String _testFunctionStr(String text) {
  sleep(const Duration(milliseconds: 100));
  return 'prefix: $text';
}

void main() {
  group('Simple iterable responses from backpressure', () {
    List iterable() => [1, 'test', 2, 3, 4, 5].toList();

    Future<List> runIsolate(BackpressureStrategy strategy) async {
      final isolated = Isolated(
        backpressureStrategy: strategy,
        autoInit: false,
      );
      await isolated.init();

      final responses = [];

      Future temp(dynamic input) async {
        if (input is String) {
          try {
            final value = await isolated.isolate(_testFunctionStr, input);
            responses.add(value);
          } catch (e) {
            // Noop
          }
        } else if (input is int) {
          await Future.delayed(Duration(milliseconds: 50 * input));
          try {
            final value = await isolated.isolate(_testFunction, input);
            responses.add(value);
          } catch (e) {
            // Noop
          }
        }
      }

      await Future.wait([
        for (final number in iterable()) temp(number),
      ]);

      isolated.dispose();

      return responses;
    }

    test('Default (no) strategy', () async {
      final isolate = Isolated();
      final responses = [];

      await Future.wait([
        for (final input in iterable())
          if (input is String)
            isolate.isolate(_testFunctionStr, input).then(responses.add)
          else if (input is int)
            isolate.isolate(_testFunction, input).then(responses.add),
      ]);

      isolate.dispose();

      expect(responses, [1, 'prefix: test', 2, 3, 4, 5]);
    });

    test('No backpressure strategy', () async {
      final responses = await runIsolate(NoBackPressureStrategy());
      expect(responses, ['prefix: test', 1, 2, 3, 4, 5]);
    });

    test('Discard new backpressure strategy', () async {
      final responses = await runIsolate(DiscardNewBackPressureStrategy());
      expect(responses, ['prefix: test', 1, 3]);
    });

    test('Replace backpressure strategy', () async {
      final responses = await runIsolate(ReplaceBackpressureStrategy());
      expect(responses, ['prefix: test', 2, 5]);
    });
  });
}
