import 'dart:typed_data';
import 'package:coinlib/coinlib.dart';
import 'package:test/test.dart';
import '../../vectors/keys.dart';
import '../../vectors/signatures.dart';
import '../../vectors/inputs.dart';
import '../../vectors/tx.dart';

void main() {

  group("TaprootKeyInput", () {

    setUpAll(loadCoinlib);

    getWitness(bool hasSig) => [hasSig ? schnorrInSig.bytes : Uint8List(0)];

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
        insig: schnorrInSig,
      );

      expectTaprootKeyInput(noSig, false);
      expectTaprootKeyInput(withSig, true);
      expectTaprootKeyInput(noSig.addSignature(schnorrInSig), true);

      // Matches when signature is present or not
      for (final hasSig in [false, true]) {
        final matched = Input.match(
          RawInput.fromReader(BytesReader(rawWitnessInputBytes)),
          getWitness(hasSig),
        );
        expect(matched, isA<TaprootKeyInput>());
        expectTaprootKeyInput(matched as TaprootKeyInput, hasSig);
      }

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
      expectNoMatch("", [...getWitness(true), ...getWitness(true)]);
      // Not allowing annex
      expectNoMatch("", [...getWitness(true), hexToBytes("5001020304")]);
      expectNoMatch(
        "",
        [
          Uint8List.fromList([
            ...hexToBytes(validDerSigs[0]),
            SigHashType.none().value,
          ]),
        ],
      );

    });

    test(".filterSignatures()", () {
      final input = TaprootKeyInput(prevOut: prevOut, insig: schnorrInSig);
      expect(input.filterSignatures((schnorrInSig) => false).insig, isNull);
      expect(input.filterSignatures((schnorrInSig) => true).insig, isNotNull);
    });

    test(".sign() should sign as SIGHASH_DEFAULT by default", () {
      final input = TaprootKeyInput(prevOut: prevOut);
      final signedInput = input.sign(
        details: TaprootKeySignDetails(
          tx: Transaction(inputs: [input], outputs: [exampleOutput]),
          inputN: 0,
          prevOuts: [
            Output.fromProgram(
              BigInt.from(10000),
              P2TR.fromTweakedKey(keyPairVectors[0].publicObj),
            ),
          ],
        ),
        key: keyPairVectors[0].privateObj,
      );
      expect(signedInput.insig!.hashType.schnorrDefault, true);
    });

  });

}
