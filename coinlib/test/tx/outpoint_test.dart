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

    test("fromHex takes reversed hash", () {
      final op = OutPoint.fromHex(
        "6d7ed9914625c73c0288694a6819196a27ef6c08f98e1270d975a8e65a3dc09a", 0,
      );
      expect(
        bytesToHex(op.hash),
        "9ac03d5ae6a875d970128ef9086cef276a1919684a6988023cc7254691d97e6d",
      );
    });

    test("hash cannot be mutated", () {
      final data = Uint8List(32);
      final op = OutPoint(data, 0);
      op.hash[0] = 0xff;
      data[1] = 0xff;
      expect(op.hash, Uint8List(32));
    });

    test("allows equality comparison", () {

      final hash = Uint8List(32);
      final outp = OutPoint(hash, 0);
      final identical = OutPoint(hash, 0);

      final diff1 = OutPoint(hash, 1);

      hash[0] = 1;
      final diff2 = OutPoint(hash, 0);

      expect(outp, identical);
      expect(outp, outp);
      expect(outp, isNot(equals(diff1)));
      expect(outp, isNot(equals(diff2)));

    });

  });

}
