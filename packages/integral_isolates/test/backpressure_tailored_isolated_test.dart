import 'dart:io';

import 'package:integral_isolates/integral_isolates.dart';
import 'package:test/test.dart';

int _testFunction(int input) {
  sleep(const Duration(milliseconds: 300));
  return input;
}

void main() {
  group('Simple iterable responses from backpressure', () {
    List<int> iterable() => [1, 2, 3, 4, 5].toList();

    Future<List<int>> runIsolate(
      BackpressureStrategy<int, int> strategy,
    ) async {
      final isolate = TailoredStatefulIsolate<int, int>(
        backpressureStrategy: strategy,
        autoInit: false,
      );
      await isolate.init();

      final responses = <int>[];

      Future temp(int number) async {
        await Future.delayed(Duration(milliseconds: 50 * number));

        try {
          final value = await isolate.compute(_testFunction, number);
          responses.add(value);
        } catch (e) {
          // Noop
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
      final responses = <int>[];

      await Future.wait([
        for (final int in iterable())
          isolate.compute(_testFunction, int).then(responses.add),
      ]);

      isolate.dispose();

      expect(responses, [1, 2, 3, 4, 5]);
    });

    test('No backpressure strategy', () async {
      expect(
        runIsolate(NoBackPressureStrategy()),
        completion([1, 2, 3, 4, 5]),
      );
    });

    test('Discard new backpressure strategy', () async {
      expect(
        runIsolate(DiscardNewBackPressureStrategy()),
        completion([1, 2]),
      );
    });

    test('Replace backpressure strategy', () async {
      expect(
        runIsolate(ReplaceBackpressureStrategy()),
        completion([1, 5]),
      );
    });

    test('Combine backpressure strategy', () async {
      final isolate = TailoredStatefulIsolate<int, int>(
        backpressureStrategy: CombineBackPressureStrategy(
          (oldData, newData) => oldData + newData,
        ),
      );
      isolate.compute((message) => message + 2, 2);

      final future = runIsolate(
        CombineBackPressureStrategy<int, int>((oldData, newData) {
          return oldData + newData;
        }),
      );
       expect(
        future,
        completion([1, 14]),
      );
    });
  });
}
