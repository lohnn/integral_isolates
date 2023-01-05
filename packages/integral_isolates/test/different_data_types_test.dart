import 'dart:isolate';

import 'package:integral_isolates/integral_isolates.dart';
import 'package:test/test.dart';

void main() {
  group('Exceptions when queuing jobs should not break upcoming jobs', () {
    final isolated = Isolated();
    final isolate = isolated.isolate;

    test('Send different data types and expect answers', () async {
      expect(
        await isolate((number) => number + 2, 1),
        equals(3),
      );

      expect(
        await isolate((text) => 'prefix: $text', 'testing'),
        equals('prefix: testing'),
      );
    });

    test('Send unsupported data type should throw exception', () async {
      expect(
        await isolate((number) => number + 2, 1),
        equals(3),
      );

      await expectLater(
        isolate(
          print,
          ReceivePort(),
        ),
        throwsArgumentError,
      );

      expect(
        await isolate((number) => number + 2, 5),
        equals(7),
      );
    });

    test('Trying to return unsupported data type should throw exception',
        () async {
      expect(
        await isolate((number) => number + 8, 1),
        equals(9),
      );

      await expectLater(
        isolate(
          (_) {
            return ReceivePort();
          },
          'Test String',
        ),
        throwsArgumentError,
      );

      expect(
        await isolate((number) => number + 5, 25),
        equals(30),
      );
    });

    tearDownAll(isolated.dispose);
  });
}
