import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:use_isolate/src/use_tailored_isolate.dart';

void main() {
  testWidgets(
    'useTailoredIsolate creates a TailoredStatefulIsolate',
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
}
