import 'dart:typed_data';
import 'package:coinlib/coinlib.dart';
import 'package:test/test.dart';

void main() {

  group("OutPoint", () {

    test("requires 32 byte hash", () {
      expect(() => OutPoint(Uint8List(31), 0), throwsArgumentError);
    });

    test("requires uint32 n", () {
      expect(() => OutPoint(Uint8List(32), -1), throwsArgumentError);
      expect(() => OutPoint(Uint8List(32), 0x100000000), throwsArgumentError);
    });

    test("can be read and written", () {
      final bytes = Uint8List.fromList([
        ...List<int>.generate(32, (i) => i),
        1,2,3,4,
      ]);
      final op = OutPoint.fromReader(BytesReader(bytes));
      expect(op.size, 36);
      expect(op.hash, bytes.sublist(0, 32));
      expect(op.n, 0x04030201);
      expect(op.toBytes(), bytes);
    });

    test("hash cannot be mutated", () {
      final data = Uint8List(32);
      final op = OutPoint(data, 0);
      op.hash[0] = 0xff;
      data[1] = 0xff;
      expect(op.hash, Uint8List(32));
    });

  });

}
