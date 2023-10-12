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

      final noSigBytes = Uint8List.fromList([
        ...prevOutHash,
        0xef, 0xbe, 0xed, 0xfe,
        noSigScript.length, ...noSigScript,
        0xed, 0xfe, 0xef, 0xbe,
      ]);

      final sigBytes = Uint8List.fromList([
        ...prevOutHash,
        0xef, 0xbe, 0xed, 0xfe,
        sigScript.length, ...sigScript,
        0xed, 0xfe, 0xef, 0xbe,
      ]);

      expectP2PKHInput(P2PKHInput input, bool hasSig) {

        expectInput(input);

        expect(input.publicKey.hex, pubkeyVec);
        expect(input.complete, hasSig);
        expect(input.insig, hasSig ? isNotNull : null);

        final scriptSig = hasSig ? sigScript : noSigScript;
        expect(input.scriptSig, scriptSig);
        expect(input.script.match(Script.decompile(scriptSig)), true);

        if (hasSig) {
          expect(bytesToHex(input.insig!.signature.der), validDerSigs[0]);
          expect(input.insig!.hashType.single, true);
        }

        final bytes = hasSig ? sigBytes : noSigBytes;
        expect(input.size, bytes.length);
        expect(input.toBytes(), bytes);

      }

      final noSig = P2PKHInput(
        prevOut: prevOut,
        sequence: sequence,
        publicKey: pk,
      );

      final withSig = P2PKHInput(
        prevOut: prevOut,
        sequence: sequence,
        publicKey: pk,
        insig: insig,
      );

      expectP2PKHInput(noSig, false);
      expectP2PKHInput(withSig, true);
      expectP2PKHInput(noSig.addSignature(insig), true);

      expectMatched(Uint8List bytes, bool hasSig) {
        final matched = Input.match(RawInput.fromReader(BytesReader(bytes)));
        expect(matched, isA<P2PKHInput>());
        expectP2PKHInput(matched as P2PKHInput, hasSig);
      }

      expectMatched(noSigBytes, false);
      expectMatched(sigBytes, true);

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
              sequence: 0,
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
