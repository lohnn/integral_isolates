import 'dart:isolate';

import 'package:integral_isolates/integral_isolates.dart';
import 'package:test/test.dart';

void main() {
  group('Exceptions when queuing jobs should not break upcoming jobs', () {
    final isolate = StatefulIsolate();

    test('Send different data types and expect answers', () async {
      expect(
        isolate.compute((number) => number + 2, 1),
        completion(3),
      );

      expect(
        isolate.compute((text) => 'prefix: $text', 'testing'),
        completion('prefix: testing'),
      );
    });

    test('Send unsupported data type should throw exception', () async {
      expect(
        await isolate.compute((number) => number + 2, 1),
        equals(3),
      );

      expectLater(
        isolate.compute(
          (_) {},
          ReceivePort(),
        ),
        throwsArgumentError,
      );

      expect(
        await isolate.compute((number) => number + 2, 5),
        equals(7),
      );
    });

    test('Trying to return unsupported data type should throw exception',
        () async {
      expect(
        await isolate.compute((number) => number + 8, 1),
        equals(9),
      );

      expectLater(
        isolate.compute(
          (_) {
            return ReceivePort();
          },
          'Test String',
        ),
        throwsArgumentError,
      );

      expect(
        await isolate.compute((number) => number + 5, 25),
        equals(30),
      );
    });

    tearDownAll(isolate.dispose);
  });
}
