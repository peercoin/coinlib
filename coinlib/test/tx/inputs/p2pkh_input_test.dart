import 'dart:typed_data';
import 'package:coinlib/coinlib.dart';
import 'package:test/test.dart';
import '../../vectors/keys.dart';
import '../../vectors/signatures.dart';
import '../../vectors/inputs.dart';

void main() {

  group("P2PKHInput", () {

    final der = validDerSigs[0];
    late ECPublicKey pk;
    late ECDSAInputSignature insig;
    setUpAll(() async {
      await loadCoinlib();
      pk = ECPublicKey.fromHex(pubkeyVec);
      insig = ECDSAInputSignature(
        ECDSASignature.fromDerHex(der),
        SigHashType.single(),
      );

    });

    test("valid p2pkh inputs inc. addSignature", () {

      final noSigScript = Script.fromAsm(pubkeyVec).compiled;
      final sigScript = Script.fromAsm("${der}03 $pubkeyVec").compiled;

      void expectP2PKHInput(P2PKHInput input, bool hasSig, bool finalSeq) {

        final script = hasSig ? sigScript : noSigScript;
        final bytes = Uint8List.fromList([
          ...prevOutHash,
          0xef, 0xbe, 0xed, 0xfe,
          script.length, ...script,
          finalSeq ? 0xff : 0xfe, 0xff, 0xff, 0xff,
        ]);

        for (final input in [
          input, Input.match(RawInput.fromReader(BytesReader(bytes))),
        ]) {

          input as P2PKHInput;

          expectInput(
            input,
            finalSeq
            ? InputSequence.finalWithoutLocktime
            : InputSequence.enforceLocktime,
          );

          expect(input.publicKey.hex, pubkeyVec);
          expect(input.complete, hasSig);
          expect(input.insig, hasSig ? isNotNull : null);

          expect(input.scriptSig, script);
          expect(input.script.match(Script.decompile(script)), true);

          if (hasSig) {
            expect(bytesToHex(input.insig!.signature.der), validDerSigs[0]);
            expect(input.insig!.hashType.single, true);
          }

          expect(input.size, bytes.length);
          expect(input.toBytes(), bytes);

        }

      }

      final noSig = P2PKHInput(prevOut: prevOut, publicKey: pk);
      final withSig = P2PKHInput(prevOut: prevOut, publicKey: pk, insig: insig);
      final withFinal = P2PKHInput(
        prevOut: prevOut,
        publicKey: pk,
        sequence: InputSequence.finalWithoutLocktime,
      );

      expectP2PKHInput(noSig, false, false);
      expectP2PKHInput(withSig, true, false);
      expectP2PKHInput(noSig.addSignature(insig), true, false);
      expectP2PKHInput(withFinal, false, true);
      expectP2PKHInput(withFinal.addSignature(insig), true, true);

    });

    test("doesn't match non p2pkh inputs", () {
      for (final asm in [
        "",
        "0",
        "0 0",
        "${der}02",
        "$der $pubkeyVec",
        "${der}02 $pubkeyVec 0",
        "${der}02 ${pubkeyVec}00",
        "${der}02 OP_DUP",
      ]) {
        expect(
          P2PKHInput.match(
            RawInput(
              prevOut: prevOut,
              scriptSig: Script.fromAsm(asm).compiled,
            ),
          ),
          null,
        );
      }
    });

    test("filterSignatures", () {

      final input = P2PKHInput(
        prevOut: prevOut,
        publicKey: pk,
        insig: insig,
      );

      expect(input.filterSignatures((insig) => false).insig, isNull);
      expect(input.filterSignatures((insig) => true).insig, isNotNull);

    });

  });

}
