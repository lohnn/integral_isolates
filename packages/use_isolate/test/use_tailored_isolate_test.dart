import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:use_isolate/use_isolate.dart';

void main() {
  testWidgets(
    'Testing lifecycle of TailoredStatefulIsolate from useTailoredIsolate',
    (tester) async {
      await tester.runAsync(() async {
        late TailoredStatefulIsolate<double, int> isolate;

        await tester.pumpWidget(
          HookBuilder(
            builder: (context) {
              isolate = useTailoredIsolate<double, int>();
              return Container();
            },
          ),
        );

        await expectLater(
          isolate.compute(
            (_) => 1,
            2,
          ),
          completes,
        );

        await tester.pumpWidget(Container());

        await expectLater(
          isolate.compute(
            (message) => 1,
            2,
          ),
          throwsA(isA<IsolateClosedDropException>()),
        );
      });
    },
  );

  testWidgets(
      'It is possible to set backpressure strategy for useTailoredIsolate',
      (tester) async {
    await tester.runAsync(() async {
      late TailoredStatefulIsolate<double, int> isolate;

      await tester.pumpWidget(
        HookBuilder(
          builder: (context) {
            isolate = useTailoredIsolate<double, int>(
              backpressureStrategy: ReplaceBackpressureStrategy(),
            );
            return Container();
          },
        ),
      );

      expect(
        isolate.backpressureStrategy,
        isA<ReplaceBackpressureStrategy>(),
      );
    });
  });

  testWidgets(
      'compute function works for TailoredStatefulIsolate from useTailoredIsolate',
      (tester) async {
    await tester.runAsync(() async {
      late TailoredStatefulIsolate<String, int> isolate;

      await tester.pumpWidget(
        HookBuilder(
          builder: (context) {
            isolate = useTailoredIsolate();
            return Container();
          },
        ),
      );

      await expectLater(
        isolate.compute(
          (input) => input.length,
          'message',
        ),
        completion(7),
      );
    });
  });

  testWidgets(
      'computeStream function works for TailoredStatefulIsolate from useTailoredIsolate',
      (tester) async {
    await tester.runAsync(() async {
      late TailoredStatefulIsolate<int, String> isolate;

      await tester.pumpWidget(
        HookBuilder(
          builder: (context) {
            isolate = useTailoredIsolate();
            return Container();
          },
        ),
      );

      await expectLater(
        isolate.computeStream(
          (input) =>
              Stream.fromIterable(Iterable.generate(input, (i) => 'message$i')),
          3,
        ),
        emitsInOrder([
          'message0',
          'message1',
          'message2',
        ]),
      );
    });
  });
}
