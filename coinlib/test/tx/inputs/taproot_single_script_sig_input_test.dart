import 'dart:typed_data';
import 'package:coinlib/coinlib.dart';
import 'package:test/test.dart';
import '../../vectors/keys.dart';
import '../../vectors/inputs.dart';
import '../../vectors/signatures.dart';
import '../../vectors/tx.dart';
import '../../vectors/taproot.dart';

final privkey = keyPairVectors.first.privateObj;
final regularLeaf = TapLeafChecksig(privkey.pubkey);
final regularTR = Taproot(internalKey: privkey.pubkey, mast: regularLeaf);
final apoTR = Taproot(
  internalKey: privkey.pubkey,
  mast: TapLeafChecksig.apoInternal,
);
final apoInput = TaprootSingleScriptSigInput.anyPrevOut(
  taproot: apoTR,
  leaf: TapLeafChecksig.apoInternal,
);
final unsignedTx = Transaction(
  inputs: [
    TaprootSingleScriptSigInput(
      prevOut: prevOut,
      taproot: regularTR,
      leaf:regularLeaf,
      sequence: sequence,
    ),
    apoInput,
    apoInput,
  ],
  outputs: [exampleOutput],
);

void main() {

  group("TaprootSingleScriptSigInput", () {

    setUpAll(loadCoinlib);

    test(".sign() success", () {

      void expectSign(
        int i, SigHashType hashType, {
          bool addPrevOutBeforeSign = false,
          bool addPrevOut = false,
        }
      ) {

        var input = unsignedTx.inputs[i] as TaprootSingleScriptSigInput;
        if (addPrevOutBeforeSign) {
          input = input.addPrevOut(examplePrevOut);
        }
        expect(input.complete, false);

        input = input.sign(
          details: TaprootScriptSignDetails(
            tx: unsignedTx,
            inputN: i,
            prevOuts: [if (!hashType.anyPrevOutAnyScript) exampleOutput],
            hashType: hashType,
          ),
          key: privkey,
        );
        expect(input.insig, isNotNull);
        expect(input.complete, !addPrevOut);

        if (!addPrevOut) return;

        input = input.addPrevOut(examplePrevOut);
        expect(input.complete, true);

      }

      // non-APO
      expectSign(0, sigHashAOCP);

      // APO
      expectSign(1, sigHashAPO, addPrevOut: true);

      // APO allows non-APO hash type
      expectSign(1, sigHashAOCP, addPrevOutBeforeSign: true);

      // APOAS
      expectSign(2, sigHashAPOAS, addPrevOut: true);

    });

    test("signatures invalidate on new prevout", () {

      void expectComplete(SchnorrInputSignature inputSig, bool onPrevOut) {
        final input = TaprootSingleScriptSigInput(
          prevOut: examplePrevOut,
          taproot: regularTR,
          leaf: regularLeaf,
          insig: inputSig,
        );
        expect(input.complete, true);
        expect(input.addPrevOut(exampleAltPrevOut).complete, onPrevOut);
      }

      expectComplete(schnorrInSig, false);
      expectComplete(schnorrInSigAPO, true);
      expectComplete(schnorrInSigAPOAS, true);

    });

    test(".sign() cannot sign APO for non-APO key", () {
      final input = unsignedTx.inputs.first as TaprootSingleScriptSigInput;
      expect(
        () => input.sign(
          details: TaprootScriptSignDetails(
            tx: unsignedTx,
            inputN: 0,
            prevOuts: [exampleOutput],
            hashType: sigHashAPO,
          ),
          key: privkey,
        ),
        throwsA(isA<CannotSignInput>()),
      );
    });

    test(".match() success", () {

      for (final withSig in [true, false]) {
        final input = TaprootSingleScriptSigInput.match(
          rawWitnessInput,
          [
            if (withSig) schnorrInSig.bytes,
            regularLeaf.script.compiled,
            exampleControlBlock,
          ],
        );
        expect(input!.complete, withSig);
        expect(input.insig?.bytes, withSig ? schnorrInSig.bytes : null);
      }

    });

    test(".match() fail", () {

      for (final witness in [
        // Doesn't match with more than 3 witness elements
        [
          Uint8List(1),
          schnorrInSig.bytes,
          regularLeaf.script.compiled,
          exampleControlBlock,
        ],
        // Doesn't match invalid signature
        [
          schnorrInSig.bytes.sublist(63),
          regularLeaf.script.compiled,
          exampleControlBlock,
        ],
        // Doesn't match incorrect script
        [
          schnorrInSig.bytes,
          Script.fromAsm("OP_CHECKSIG").compiled,
          exampleControlBlock,
        ],
        // Doesn't match when missing control block and script
        [schnorrInSig.bytes],
      ]) {
        expect(
          TaprootSingleScriptSigInput.match(rawWitnessInput, witness),
          isNull,
        );
      }

    });

  });

}
