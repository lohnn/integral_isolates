import 'package:integral_isolates/integral_isolates.dart';
import 'package:test/test.dart';

void main() {
  group('Lifecycle errors', () {
    test('Throws error when running after dispose', () async {
      final isolate = TailoredStatefulIsolate<int, int>();

      expect(
        await isolate.compute((number) => number + 2, 1),
        equals(3),
      );

      isolate.dispose();

      await expectLater(
        isolate.compute((number) => number + 2, 5),
        throwsA(isA<IsolateClosedDropException>()),
      );
    });
  });
}
