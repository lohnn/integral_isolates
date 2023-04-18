import 'dart:isolate';

import 'package:integral_isolates/integral_isolates.dart';
import 'package:test/test.dart';

void main() {
  group('IsolateStream tests', () {
    final isolate = StatefulIsolate();

    test('Send different data types and expect answers', () async {
      expectLater(
        isolate.isolateStream(
          (_) => Stream.fromIterable([2, 3, 5, 42]),
          const Object(),
        ),
        emitsInOrder([2, 3, 5, 42]),
      );

      expectLater(
        isolate.isolateStream(
          (_) => Stream.fromFutures([
            Future.delayed(const Duration(milliseconds: 100), () => 'are'),
            Future.value('Async calls'),
            Future.delayed(
              const Duration(milliseconds: 200),
              () => 'difficult',
            ),
          ]),
          const Object(),
        ),
        emitsInOrder(['Async calls', 'are', 'difficult']),
      );
    });

    test('Send unsupported data type should throw exception', () async {
      expectLater(
        isolate.isolateStream(
          (_) => Stream.fromIterable([2, 3, 5, 42]),
          const Object(),
        ),
        emitsInOrder([2, 3, 5, 42]),
      );

      expectLater(
        isolate
            .isolateStream(
              (_) => Stream.fromIterable([2, 3, 5, 42]),
              ReceivePort(),
            )
            .toList(),
        throwsArgumentError,
      );

      expect(
        await isolate.isolate((number) => number + 2, 5),
        equals(7),
      );
    });

    test('Trying to return unsupported data type should throw exception',
        () async {
      expectLater(
        await isolate.isolate((number) => number + 8, 1),
        equals(9),
      );

      expectLater(
        isolate
            .isolateStream(
              (_) => Stream.value(ReceivePort()),
              'Test String',
            )
            .toList(),
        throwsArgumentError,
      );

      expectLater(
        isolate.isolateStream(
          (_) => Stream.fromIterable([2, 3, 5, 42]),
          const Object(),
        ),
        emitsInOrder([2, 3, 5, 42]),
      );
    });

    tearDownAll(isolate.dispose);
  });

  group('Tailored IsolateStream tests', () {
    final isolate = TailoredStatefulIsolate<int, int>();

    test('Send different data types and expect answers', () async {
      await expectLater(
        await isolate.isolate((number) => number + 2, 1),
        equals(3),
      );

      await expectLater(
        isolate.isolateStream(
          (_) => Stream.fromIterable([2, 3, 5, 42]),
          2,
        ),
        emitsInOrder([2, 3, 5, 42]),
      );
    });

    tearDownAll(isolate.dispose);
  });
}
