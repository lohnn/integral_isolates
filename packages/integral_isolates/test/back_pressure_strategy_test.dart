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

    Future<List<int>> runIsolate(BackpressureStrategy strategy) async {
      final isolated = Isolated(
        backpressureStrategy: strategy,
        autoInit: false,
      );
      await isolated.init();

      final responses = <int>[];

      Future temp(int number) async {
        await Future.delayed(Duration(milliseconds: 50 * number));

        try {
          final value = await isolated.isolate(_testFunction, number);
          responses.add(value);
        } catch (e) {
          // Noop
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
      final responses = <int>[];

      await Future.wait([
        for (final int in iterable())
          isolate.isolate(_testFunction, int).then(responses.add),
      ]);

      isolate.dispose();

      expect(responses, [1, 2, 3, 4, 5]);
    });

    test('No backpressure strategy', () async {
      final responses = await runIsolate(NoBackPressureStrategy());
      expect(responses, [1, 2, 3, 4, 5]);
    });

    test('Discard new backpressure strategy', () async {
      final responses = await runIsolate(DiscardNewBackPressureStrategy());
      expect(responses, [1, 2]);
    });

    test('Replace backpressure strategy', () async {
      final responses = await runIsolate(ReplaceBackpressureStrategy());
      expect(responses, [1, 5]);
    });
  });
}
