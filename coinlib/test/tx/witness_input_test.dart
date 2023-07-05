import 'dart:typed_data';
import 'package:coinlib/coinlib.dart';
import 'package:test/test.dart';

void main() {

  group("WitnessInput", () {

    final prevOutHash = Uint8List(32);
    final prevOutN = 0xfeedbeef;
    final sequence = 0xbeeffeed;

    final rawBytes = Uint8List.fromList([
      ...prevOutHash,
      0xef, 0xbe, 0xed, 0xfe,
      0,
      0xed, 0xfe, 0xef, 0xbe,
    ]);
    final raw = RawInput.fromReader(BytesReader(rawBytes));
    final witness = [Uint8List.fromList([0, 1, 0xff])];

    test("matches witness inputs", () {
      for (final witIn in [
        Input.match(raw, witness), WitnessInput.match(raw, witness),
      ]) {
        expect(witIn, isA<WitnessInput>());
        expect(witIn!.prevOut.hash, prevOutHash);
        expect(witIn.prevOut.n, prevOutN);
        expect(witIn.scriptSig.length, 0);
        expect(witIn.scriptSig.ops, isEmpty);
        expect(witIn.sequence, sequence);
        expect((witIn as WitnessInput).witness, witness);
        expect(witIn.complete, true);
      }
    });

    test("doesn't match non witness inputs", () {
      expect(WitnessInput.match(raw, []), null);
      final rawWithScriptSig = RawInput(
        prevOut: raw.prevOut,
        scriptSig: Script.fromAsm("0"),
        sequence: 0,
      );
      expect(WitnessInput.match(rawWithScriptSig, witness), null);
    });

  });

}
