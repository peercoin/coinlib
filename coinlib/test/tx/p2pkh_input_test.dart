import 'dart:typed_data';
import 'package:coinlib/coinlib.dart';
import 'package:coinlib/src/common/hex.dart';
import 'package:test/test.dart';
import '../vectors/keys.dart';
import '../vectors/signatures.dart';

void main() {

  group("P2PKHInput", () {

    setUpAll(loadCoinlib);

    final prevOutHash = Uint8List(32);
    final prevOutN = 0xfeedbeef;
    final prevOut = OutPoint(prevOutHash, prevOutN);
    final der = validDerSigs[0];

    test("valid p2pkh inputs inc. addSignature", () {

      final pk = ECPublicKey.fromHex(pubkeyVec);
      final insig = InputSignature(
        ECDSASignature.fromDerHex(der),
        InputSignature.sigHashSingle,
      );
      final sequence = 0xbeeffeed;

      final noSigScript = Script.fromAsm(pubkeyVec);
      final sigScript = Script.fromAsm("${der}02 $pubkeyVec");

      final noSigBytes = Uint8List.fromList([
        ...prevOutHash,
        0xef, 0xbe, 0xed, 0xfe,
        noSigScript.compiled.length, ...noSigScript.compiled,
        0xed, 0xfe, 0xef, 0xbe,
      ]);

      final sigBytes = Uint8List.fromList([
        ...prevOutHash,
        0xef, 0xbe, 0xed, 0xfe,
        sigScript.compiled.length, ...sigScript.compiled,
        0xed, 0xfe, 0xef, 0xbe,
      ]);

      expectP2PKHInput(P2PKHInput input, bool hasSig) {

        expect(input.prevOut.hash, prevOutHash);
        expect(input.prevOut.n, prevOutN);
        expect(input.sequence, sequence);

        expect(input.publicKey.hex, pubkeyVec);
        expect(input.complete, hasSig);
        expect(input.insig, hasSig ? isNotNull : null);
        expect(input.scriptSig.match(hasSig ? sigScript : noSigScript), true);

        if (hasSig) {
          expect(bytesToHex(input.insig!.signature.der), validDerSigs[0]);
          expect(input.insig!.hashType, InputSignature.sigHashSingle);
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
              scriptSig: Script.fromAsm(asm),
              sequence: 0,
            ),
          ),
          null,
        );
      }
    });

  });

}
