import 'package:integral_isolates/integral_isolates.dart';
import 'package:test/test.dart';

void main() {
  group('Lifecycle errors', () {
    test('Throws error when running after dispose', () async {
      final isolated = TailoredStatefulIsolate<int, int>();
      final isolate = isolated.isolate;

      expect(
        await isolate((number) => number + 2, 1),
        equals(3),
      );

      isolated.dispose();

      await expectLater(
        isolate((number) => number + 2, 5),
        throwsA(isA<IsolateClosedDropException>()),
      );
    });
  });
}
