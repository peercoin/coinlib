import 'dart:typed_data';
import 'package:coinlib/coinlib.dart';
import 'package:test/test.dart';

void main() {

  group("RawInput", () {

    test("requires uint32 sequence", () {
      for (final n in [-1, 0x100000000]) {
        expect(
          () => RawInput(
            prevOut: OutPoint(Uint8List(32), -1),
            scriptSig: Script.fromAsm("0"),
            sequence: n,
          ),
          throwsArgumentError,
        );
      }
    });

    test("can be read and written and is always complete", () {

      final hashBytes = Uint8List.fromList(List<int>.generate(32, (i) => i));

      final bytes = Uint8List.fromList([
        ...hashBytes, // Hash
        1,2,3,4, // n
        1, 0, // OP_0
        4,3,2,1 // Sequence
      ]);

      expectRaw(RawInput input) {
        expect(input.prevOut.hash, hashBytes);
        expect(input.prevOut.n, 0x04030201);
        expect(input.scriptSig.asm, "0");
        expect(input.sequence, 0x01020304);
        expect(input.complete, true);
        expect(input.size, bytes.length);
        expect(input.toBytes(), bytes);
      }

      expectRaw(RawInput.fromReader(BytesReader(bytes)));
      expectRaw(
        RawInput(
          prevOut: OutPoint(hashBytes, 0x04030201),
          scriptSig: Script.fromAsm("0"),
          sequence: 0x01020304,
        ),
      );

    });

  });

}
