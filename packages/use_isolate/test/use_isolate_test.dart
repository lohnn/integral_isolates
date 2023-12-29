import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:use_isolate/src/use_isolate.dart';

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
}