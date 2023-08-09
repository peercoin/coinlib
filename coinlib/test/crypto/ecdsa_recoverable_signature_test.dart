import 'package:coinlib/coinlib.dart';
import 'package:test/test.dart';
import '../vectors/signatures.dart';

void main() {

  group("ECDSARecoverableSignature", () {

    setUpAll(loadCoinlib);

    final hash = hexToBytes(
      "56282d1366c4b5d34a259fff5bdfd44e7013fa8213bc713758fdeed212d62fe8",
    );

    expectRecSig(ECDSARecoverableSignature recSig, RecSigVector vector) {
      expect(recSig.compressed, vector.compressed);
      expect(recSig.recid, vector.recid);
      expect(bytesToHex(recSig.signature.compact), vector.signature);
      expect(recSig.recover(hash)?.hex, vector.pubkey);
      expect(bytesToHex(recSig.compact), vector.compact);
    }

    group(".fromCompactHex()", () {

      test("must be 65 bytes", () {
        for (final failing in [
          // Too small
          "201faf14ade8fd0e1a3e7a426cec7c1298d64a7a647a6fdd5926fc745eda006e4a4bd7ad09896ddb98e7aac15bb0c09b4d95cb48a8099d946d36738c582853a8",
          // Too large
          "201faf14ade8fd0e1a3e7a426cec7c1298d64a7a647a6fdd5926fc745eda006e4a4bd7ad09896ddb98e7aac15bb0c09b4d95cb48a8099d946d36738c582853a876ff",
        ]) {
          expect(
            () => ECDSARecoverableSignature.fromCompactHex(failing),
            throwsArgumentError,
          );
        }

      });

      test("valid signature", () {
        for (final vector in validRecoverableSigs+validRecSigSigns) {
          expectRecSig(
            ECDSARecoverableSignature.fromCompactHex(vector.compact),
            vector,
          );
        }
      });

      test("invalid signatures", () {
        for (final sig in invalidSignatures) {
          expect(
            () => ECDSARecoverableSignature.fromCompactHex("20$sig"),
            throwsA(isA<InvalidECDSARecoverableSignature>()),
            reason: sig,
          );
        }
      });

    });

    group(".sign()", () {

      final privateHex
        = "6c4313b03f2e7324d75e642f0ab81b734b724e13fec930f309e222470236d66b";

      test("produces correct signature", () {
        for (final vector in validRecSigSigns) {
          expectRecSig(
            ECDSARecoverableSignature.sign(
              ECPrivateKey.fromHex(privateHex, compressed: vector.compressed),
              hash,
            ),
            vector,
          );
        }
      });

    });

    test(".signature is copied and cannot be mutated", () {

      final hex = validRecoverableSigs[0].compact;
      final data = hexToBytes(hex);
      final sig = ECDSARecoverableSignature.fromCompact(data);

      // Compact signature ignores first recid byte
      data[1] = 0xff;
      expect(bytesToHex(sig.signature.compact), hex.substring(2));

    });

  });

}
