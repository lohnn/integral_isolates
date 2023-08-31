import 'package:integral_isolates/integral_isolates.dart';
import 'package:test/test.dart';

void main() {
  test('First test', () async {
    final isolate = StatefulIsolate(pool: IsolatePools.io);
    final sum = await isolate.isolate((_) => 42, null);
    expect(sum, 42);
  });
}
