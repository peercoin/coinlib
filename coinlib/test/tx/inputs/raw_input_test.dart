import 'dart:typed_data';
import 'package:coinlib/coinlib.dart';
import 'package:test/test.dart';

void main() {

  group("RawInput", () {

    test("requires uint32 sequence", () {
      for (final n in [-1, 0x100000000]) {
        expect(
          () => RawInput(
            prevOut: OutPoint(Uint8List(32), 0),
            scriptSig: Script.fromAsm("0").compiled,
            sequence: n,
          ),
          throwsArgumentError,
        );
      }
    });


    final hashBytes = Uint8List.fromList(List<int>.generate(32, (i) => i));

    test("can be read and written and is always complete", () {

      final bytes = Uint8List.fromList([
        ...hashBytes, // Hash
        1,2,3,4, // n
        1, 0, // OP_0
        0xa4, 0xa3, 0xa2, 0xa1, // Sequence
      ]);

      expectRaw(RawInput input) {
        expect(input.prevOut.hash, hashBytes);
        expect(input.prevOut.n, 0x04030201);
        expect(bytesToHex(input.scriptSig), "00");
        expect(input.script!.asm, "0");
        expect(input.sequence, 0xa1a2a3a4);
        expect(input.complete, true);
        expect(input.size, bytes.length);
        expect(input.toBytes(), bytes);
      }

      final raw = RawInput(
        prevOut: OutPoint(hashBytes, 0x04030201),
        scriptSig: Script.fromAsm("0").compiled,
        sequence: 0xa1a2a3a4,
      );

      expectRaw(raw);
      expectRaw(RawInput.fromReader(BytesReader(bytes)));
      final matched = Input.match(raw);
      expect(matched, isA<RawInput>());
      expectRaw(matched as RawInput);

    });

    test("non-script scriptSig", () {

      final bytes = Uint8List.fromList([
        ...hashBytes, // Hash
        1,2,3,4, // n
        4, 1, 2, 3, 4, // Not a valid script
        0xff, 0xff, 0xff, 0xff, // Sequence
      ]);

      final scriptSig = Uint8List.fromList([1,2,3,4]);

      expectNullScript(RawInput raw) {
        expect(raw.script, null);
        expect(raw.scriptSig, scriptSig);
        expect(raw.sequence, 0xffffffff);
      }

      expectNullScript(RawInput.fromReader(BytesReader(bytes)));
      expectNullScript(
        RawInput(
          prevOut: OutPoint(hashBytes, 0x04030201),
          scriptSig: scriptSig,
        ),
      );

    });

    test("default max sequence", () {
      expect(
        RawInput(
          prevOut: OutPoint(Uint8List(32), 0),
          scriptSig: Script.fromAsm("0").compiled,
        ).sequence,
        0xffffffff,
      );
    });

  });

}
