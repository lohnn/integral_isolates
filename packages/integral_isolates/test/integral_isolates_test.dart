import 'dart:isolate';
import 'dart:typed_data';

import 'package:integral_isolates/integral_isolates.dart';
import 'package:test/test.dart';

void main() {
  group('Send huge ByteArray through to isolate', () {
    final isolate = Isolated(
      backpressureStrategy: DiscardNewBackPressureStrategy(),
    );

    final commonList = List.generate(50000000, (index) => index);

    group("Just list", () {
      for (int i = 0; i < 15; i++) {
        test(i, () async {
          final before = DateTime.now();
          final sum = await isolate.isolate(_sum, commonList);
          print(DateTime.now().difference(before).inMilliseconds);
          expect(sum, 1249999975000000);
        });
      }
    });

    group("Immutable list", () {
      for (int i = 0; i < 15; i++) {
        test(i, () async {
          final before = DateTime.now();
          final unmodifiable = List.unmodifiable(commonList);
          final sum = await isolate.isolate(_sum, unmodifiable.cast<int>());
          print(DateTime.now().difference(before).inMilliseconds);
          expect(sum, 1249999975000000);
        });
      }
    });

    group("Uint8List", () {
      for (int i = 0; i < 15; i++) {
        test(i, () async {
          final before = DateTime.now();
          final uint8List = Uint32List.fromList(commonList);
          final sum = await isolate.isolate(_sumUint32List, uint8List);
          print(DateTime.now().difference(before).inMilliseconds);
          expect(sum, 1249999975000000);
        });
      }
    });

    group("TransferableTypedData", () {
      for (int i = 0; i < 15; i++) {
        final copiedList = Uint32List.fromList(commonList);
        test(i, () async {
          final before = DateTime.now();
          final transferable = TransferableTypedData.fromList([copiedList]);
          final sum = await isolate.isolate(_sumTransferable, transferable);
          print(DateTime.now().difference(before).inMilliseconds);
          expect(sum, 1249999975000000);
        });
      }
    });

    tearDownAll(isolate.dispose);
  });
}

int _sumTransferable(TransferableTypedData data) {
  return _sumUint32List(data.materialize().asUint32List());
}

int _sumUint32List(Uint32List data) {
  return _sum(data.toList());
}

int _sum(Iterable<int> values) {
  return values.cast<int>().fold(0, (a, b) => a + b);
}
