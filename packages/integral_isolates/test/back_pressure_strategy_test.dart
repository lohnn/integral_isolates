import 'dart:io';

import 'package:integral_isolates/integral_isolates.dart';
import 'package:test/test.dart';

int _testFunction(int input) {
  sleep(const Duration(milliseconds: 300));
  return input;
}

String _testFunctionStr(String text) {
  sleep(const Duration(milliseconds: 50));
  return 'prefix: $text';
}

void main() {
  group('Simple iterable responses from backpressure', () {
    List iterable() => [1, 'test', 2, 3, 4, 5].toList();

    Future<List> runIsolate(BackpressureStrategy strategy) async {
      final isolate = StatefulIsolate(
        backpressureStrategy: strategy,
        autoInit: false,
      );
      await isolate.init();

      final responses = [];

      int delayMultiplier = 0;
      Future temp(dynamic input) async {
        await Future.delayed(Duration(milliseconds: 50 * delayMultiplier++));
        if (input is String) {
          try {
            final value = await isolate.compute(_testFunctionStr, input);
            responses.add(value);
          } catch (e) {
            // Noop
          }
        } else if (input is int) {
          try {
            final value = await isolate.compute(_testFunction, input);
            responses.add(value);
          } catch (e) {
            // Noop
          }
        }
      }

      await Future.wait([
        for (final number in iterable()) temp(number),
      ]);

      isolate.dispose();

      return responses;
    }

    test('Default (no) strategy', () async {
      final isolate = StatefulIsolate();
      final responses = [];

      await Future.wait([
        for (final input in iterable())
          if (input is String)
            isolate.compute(_testFunctionStr, input).then(responses.add)
          else if (input is int)
            isolate.compute(_testFunction, input).then(responses.add),
      ]);

      isolate.dispose();

      expect(responses, [1, 'prefix: test', 2, 3, 4, 5]);
    });

    test('No backpressure strategy', () async {
      await expectLater(
        runIsolate(NoBackPressureStrategy()),
        completion([1, 'prefix: test', 2, 3, 4, 5]),
      );
    });

    test('Discard new backpressure strategy', () async {
      await expectLater(
        runIsolate(DiscardNewBackPressureStrategy()),
        completion([1, 'prefix: test']),
      );
    });

    test('Replace backpressure strategy', () async {
      await expectLater(
        runIsolate(ReplaceBackpressureStrategy()),
        completion([1, 5]),
      );
    });

    test('Combine backpressure strategy', () async {
      final future = runIsolate(
        CombineBackPressureStrategy((oldData, newData) {
          if (oldData is num && newData is num) return oldData + newData;
          return newData;
        }),
      );
      expect(future, completion([1, 14]));
    });
  });
}
