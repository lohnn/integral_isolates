import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:use_isolate/use_isolate.dart';

void main() {
  testWidgets('Testing lifecycle of StatefulIsolate from useIsolate',
      (tester) async {
    await tester.runAsync(() async {
      late StatefulIsolate isolate;

      await tester.pumpWidget(
        HookBuilder(
          builder: (context) {
            isolate = useIsolate();
            return Container();
          },
        ),
      );

      await expectLater(
        isolate.compute(
          (_) => null,
          'message',
        ),
        completes,
      );

      await tester.pumpWidget(Container());

      await expectLater(
        isolate.compute(
          (_) => null,
          'message',
        ),
        throwsA(isA<IsolateClosedDropException>()),
      );
    });
  });

  testWidgets('compute function works for StatefulIsolate from useIsolate',
      (tester) async {
    await tester.runAsync(() async {
      late StatefulIsolate isolate;

      await tester.pumpWidget(
        HookBuilder(
          builder: (context) {
            isolate = useIsolate();
            return Container();
          },
        ),
      );

      await expectLater(
        isolate.compute(
          (input) => input * input,
          4,
        ),
        completion(16),
      );
    });
  });

  testWidgets(
      'computeStream function works for StatefulIsolate from useIsolate',
      (tester) async {
    await tester.runAsync(() async {
      late StatefulIsolate isolate;

      await tester.pumpWidget(
        HookBuilder(
          builder: (context) {
            isolate = useIsolate();
            return Container();
          },
        ),
      );

      await expectLater(
        isolate.computeStream(
          (input) =>
              Stream.fromIterable(Iterable.generate(4, (i) => '$input$i')),
          'message',
        ),
        emitsInOrder([
          'message0',
          'message1',
          'message2',
          'message3',
        ]),
      );
    });
  });
}
