import 'package:flutter/widgets.dart';
import 'package:flutter_integral_isolates/flutter_integral_isolates.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<String?> _readSharedPreferences(Object? _) async {
  final sharedPreferences = await SharedPreferences.getInstance();
  return sharedPreferences.getString('store');
}

Future<void> _writeSharedPreferences(String value) async {
  final sharedPreferences = await SharedPreferences.getInstance();
  sharedPreferences.setString('store', value);
}

void main() {
  setUp(() async {
    final sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.clear();
  });
  tearDown(() async {
    final sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.clear();
  });

  testWidgets(
    'Running platform code works in isolate',
    (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(Container());
        final isolate = StatefulIsolate(autoInit: false);
        await isolate.init();

        // final rootIsolateToken = RootIsolateToken.instance!;
        // await isolate.compute(_initPluginForIsolate, rootIsolateToken);

        await expectLater(
          isolate.compute(
            _readSharedPreferences,
            null,
          ),
          completion(null),
        );

        await expectLater(
          isolate.compute(
            _writeSharedPreferences,
            'Some data!',
          ),
          completes,
        );

        await expectLater(
          isolate.compute(
            _readSharedPreferences,
            null,
          ),
          completion(equals('Some data!')),
        );
      });
    },
  );
}
