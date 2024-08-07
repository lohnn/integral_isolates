import 'dart:isolate';

import 'package:integral_isolates/integral_isolates.dart';
import 'package:test/test.dart';

void main() {
  group('Receiving streams from Isolate', () {
    final isolate = StatefulIsolate();

    test('Send different data types and expect answers', () async {
      expectLater(
        isolate.computeStream(
          (_) => Stream.fromIterable([2, 3, 5, 42]),
          const Object(),
        ),
        emitsInOrder([2, 3, 5, 42]),
      );

      expectLater(
        isolate.computeStream(
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
        isolate.computeStream(
          (_) => Stream.fromIterable([2, 3, 5, 42]),
          const Object(),
        ),
        emitsInOrder([2, 3, 5, 42]),
      );

      expectLater(
        isolate
            .computeStream(
              (_) => Stream.fromIterable([2, 3, 5, 42]),
              ReceivePort(),
            )
            .toList(),
        throwsArgumentError,
      );

      expect(
        await isolate.compute((number) => number + 2, 5),
        equals(7),
      );
    });

    test('Trying to return unsupported data type should throw exception',
        () async {
      expectLater(
        await isolate.compute((number) => number + 8, 1),
        equals(9),
      );

      expectLater(
        isolate
            .computeStream(
              (_) => Stream.value(ReceivePort()),
              'Test String',
            )
            .toList(),
        throwsArgumentError,
      );

      expectLater(
        isolate.computeStream(
          (_) => Stream.fromIterable([2, 3, 5, 42]),
          const Object(),
        ),
        emitsInOrder([2, 3, 5, 42]),
      );
    });

    tearDownAll(isolate.dispose);
  });

  group('Sending Stream to isolate', () {
    final isolate = StatefulIsolate();

    test('Send Future and expect answers', () async {
      expectLater(
        isolate.compute(
          (input) async {
            return (await input) + 1;
          },
          Future.value(2),
        ),
        completion(3),
      );
    });

    test('Send Stream and expect answers', () async {
      expectLater(
        isolate.computeStream(
          (inputs) async* {
            await for (final input in inputs) {
              yield input + 1;
            }
          },
          Stream.fromIterable([2, 3, 5, 42]),
        ),
        emitsInOrder([3, 4, 6, 43]),
      );

      expectLater(
        isolate.computeStream(
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

    tearDownAll(isolate.dispose);
  });

  group('Tailored IsolateStream tests', () {
    final isolate = TailoredStatefulIsolate<int, int>();

    test('Send different data types and expect answers', () async {
      await expectLater(
        await isolate.compute((number) => number + 2, 1),
        equals(3),
      );

      await expectLater(
        isolate.computeStream(
          (_) => Stream.fromIterable([2, 3, 5, 42]),
          2,
        ),
        emitsInOrder([2, 3, 5, 42]),
      );
    });

    tearDownAll(isolate.dispose);
  });
}
