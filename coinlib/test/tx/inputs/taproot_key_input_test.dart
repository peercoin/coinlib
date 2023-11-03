import 'dart:typed_data';
import 'package:coinlib/coinlib.dart';
import 'package:test/test.dart';
import '../../vectors/signatures.dart';
import '../../vectors/inputs.dart';

void main() {

  group("TaprootKeyInput", () {

    late SchnorrInputSignature insig;

    setUpAll(() async {
      await loadCoinlib();
      insig = SchnorrInputSignature(
        SchnorrSignature.fromHex(validSchnorrSig),
        SigHashType.none(),
      );
    });

    getWitness(bool hasSig) => [if (hasSig) insig.bytes];

    test("valid key-path taproot inputs inc. addSignature", () {

      expectTaprootKeyInput(TaprootKeyInput input, bool hasSig) {

        expectInput(input);

        expect(input.complete, hasSig);
        expect(input.insig, hasSig ? isNotNull : null);
        expect(input.scriptSig.isEmpty, true);
        expect(input.script!.length, 0);

        if (hasSig) {
          expect(bytesToHex(input.insig!.signature.data), validSchnorrSig);
          expect(input.insig!.hashType.none, true);
        }

        expect(input.witness, getWitness(hasSig));
        expect(input.size, rawWitnessInputBytes.length);
        expect(input.toBytes(), rawWitnessInputBytes);

      }

      final noSig = TaprootKeyInput(prevOut: prevOut, sequence: sequence);

      final withSig = TaprootKeyInput(
        prevOut: prevOut,
        sequence: sequence,
        insig: insig,
      );

      expectTaprootKeyInput(noSig, false);
      expectTaprootKeyInput(withSig, true);
      expectTaprootKeyInput(noSig.addSignature(insig), true);

      // Expect match only when there is a Schnorr signature present, as there
      // is no way to distinguish otherwise
      final matched = Input.match(
        RawInput.fromReader(BytesReader(rawWitnessInputBytes)),
        getWitness(true),
      );
      expect(matched, isA<TaprootKeyInput>());
      expectTaprootKeyInput(matched as TaprootKeyInput, true);

    });

    test("doesn't match non key-spend inputs", () {

      expectNoMatch(String asm, List<Uint8List> witness) => expect(
        TaprootKeyInput.match(
          RawInput(
            prevOut: prevOut,
            scriptSig: Script.fromAsm(asm).compiled,
            sequence: 0,
          ),
          witness,
        ),
        null,
      );

      expectNoMatch("0", getWitness(true));
      // Doesn't match without signature
      expectNoMatch("", getWitness(false));
      expectNoMatch("", [...getWitness(true), ...getWitness(true)]);
      // Not allowing annex
      expectNoMatch("", [...getWitness(true), hexToBytes("5001020304")]);
      expectNoMatch(
        "",
        [
          Uint8List.fromList([
            ...hexToBytes(validDerSigs[0]),
            SigHashType.noneValue,
          ]),
        ],
      );

    });

    test("filterSignatures", () {
      final input = TaprootKeyInput(prevOut: prevOut, insig: insig);
      expect(input.filterSignatures((insig) => false).insig, isNull);
      expect(input.filterSignatures((insig) => true).insig, isNotNull);
    });

  });

}
