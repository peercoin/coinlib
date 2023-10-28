import 'dart:typed_data';
import 'package:coinlib/coinlib.dart';
import 'package:test/test.dart';
import '../../vectors/inputs.dart';
import '../../vectors/tx.dart';

void main() {

  group("WitnessInput", () {

    final prevOutHash = Uint8List(32);
    final prevOutN = 0xfeedbeef;
    final sequence = 0xbeeffeed;

    final raw = RawInput.fromReader(BytesReader(rawWitnessInputBytes));
    final witness = [Uint8List.fromList([0, 1, 0xff])];

    test("matches witness inputs", () {
      for (final witIn in [
        Input.match(raw, witness), WitnessInput.match(raw, witness),
      ]) {
        expect(witIn, isA<WitnessInput>());
        expect(witIn!.prevOut.hash, prevOutHash);
        expect(witIn.prevOut.n, prevOutN);
        expect(witIn.scriptSig, isEmpty);
        expect(witIn.script!.length, 0);
        expect(witIn.sequence, sequence);
        expect((witIn as WitnessInput).witness, witness);
        expect(witIn.complete, true);
      }
    });

    test("doesn't match non witness inputs", () {
      expect(WitnessInput.match(raw, []), null);
      final rawWithScriptSig = RawInput(
        prevOut: raw.prevOut,
        scriptSig: Script.fromAsm("0").compiled,
        sequence: 0,
      );
      expect(WitnessInput.match(rawWithScriptSig, witness), null);
    });

    test("witness elements are immutable", () {

      final mutatedWitness = [hexToBytes("0000")];

      final input = WitnessInput(
        prevOut: examplePrevOut,
        witness: mutatedWitness,
      );

      mutatedWitness[0] = hexToBytes("ffff");
      expect(input.witness, [hexToBytes("0000")]);

      expect(() => input.witness[0] = Uint8List(1), throwsA(anything));

    });

  });

}
