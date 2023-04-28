import 'package:coinlib/coinlib.dart';
import 'package:coinlib/src/common/hex.dart';
import 'package:test/test.dart';
import '../vectors/signatures.dart';

void main() {

  group("ECDSASignature", () {

    setUpAll(loadCoinlib);

    test("requires 64-bytes", () {

      for (final failing in [
        // Too small
        "a951b0cf98bd51c614c802a65a418fa42482dc5c45c9394e39c0d98773c51cd530104fdc36d91582b5757e1de73d982e803cc14d75e82c65daf924e38d27d8",
        // Too large
        "a951b0cf98bd51c614c802a65a418fa42482dc5c45c9394e39c0d98773c51cd530104fdc36d91582b5757e1de73d982e803cc14d75e82c65daf924e38d27d834ff",
      ]) {
        expect(
          () => ECDSASignature.fromCompactHex(failing),
          throwsA(isA<ArgumentError>()),
        );
      }

    });

    test("accepts valid signatures", () {
      for (final sig in validSignatures) {
        expect(ECDSASignature.fromCompactHex(sig), isA<ECDSASignature>());
      }
    });

    test("rejects invalid R and S values", () {
      for (final sig in invalidSignatures) {
        expect(
          () => ECDSASignature.fromCompactHex(sig),
          throwsA(isA<InvalidECDSASignature>()),
          reason: sig,
        );
      }
    });

    test(".fromDerHex valid", () {
      for (final sig in validDerSigs) {
        expect(
          bytesToHex(ECDSASignature.fromDerHex(sig).der),
          sig,
          reason: sig,
        );
      }
    });

    test(".fromDerHex invalid", () {
      for (final sig in invalidDerSigs) {
        expect(
          () => ECDSASignature.fromDerHex(sig),
          throwsA(isA<InvalidECDSASignature>()),
          reason: sig,
        );
      }
    });

    test(".fromDerHex allows invalid R and S set to zero", () {
      expect(
        bytesToHex(
          ECDSASignature.fromDerHex(
            "3026022100fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141020101",
          ).der,
        ),
        "3006020100020101",
      );
      expect(
        bytesToHex(
          ECDSASignature.fromDerHex(
            "3026020101022100fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141",
          ).der,
        ),
        "3006020101020100",
      );
    });

    test(".der", () {
      // Takes a high s-value signature and returns the DER encoding
      expect(
        bytesToHex(
          ECDSASignature.fromCompactHex(
            "813ef79ccefa9a56f7ba805f0e478584fe5f0dd5f567bc09b5123ccbc9832365900e75ad233fcc908509dbff5922647db37c21f4afd3203ae8dc4ae7794b0f87",
          ).der,
        ),
        "3046022100813ef79ccefa9a56f7ba805f0e478584fe5f0dd5f567bc09b5123ccbc9832365022100900e75ad233fcc908509dbff5922647db37c21f4afd3203ae8dc4ae7794b0f87",
      );
    });

    group(".sign()", () {

      late ECPrivateKey key, keyMutated1, keyMutated2;
      late Hash256 msgHash, msgMutated1, msgMutated2;

      setUpAll(() {
        key = ECPrivateKey.fromHex(
          "0000000000000000000000000000000000000000000000000000000000000001",
        );
        keyMutated1 = ECPrivateKey.fromHex(
          "0000000000000000000000000000000000000000000000000000000000000002",
        );
        keyMutated2 = ECPrivateKey.fromHex(
          "8000000000000000000000000000000000000000000000000000000000000001",
        );
        final msgHashBytes = hexToBytes(
          "000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f",
        );
        final msgMutated1Bytes = msgHashBytes.sublist(0);
        msgMutated1Bytes[31] = 0x1e;
        final msgMutated2Bytes = msgHashBytes.sublist(0);
        msgMutated2Bytes[0] = 0x01;
        msgHash = Hash256.fromHashBytes(msgHashBytes);
        msgMutated1 = Hash256.fromHashBytes(msgMutated1Bytes);
        msgMutated2 = Hash256.fromHashBytes(msgMutated2Bytes);
      });

      test("provides a correct signature", () {
        // This signature has been determined to be correct. secp256k1 has more
        // exhaustive tests and this method is a wrapper around that.
        // Should be the same each time
        for (int x = 0; x < 2; x++) {
          final sig = ECDSASignature.sign(key, msgHash);
          expect(
            bytesToHex(sig.compact),
            "a951b0cf98bd51c614c802a65a418fa42482dc5c45c9394e39c0d98773c51cd530104fdc36d91582b5757e1de73d982e803cc14d75e82c65daf924e38d27d834",
          );
          expect(sig.verify(key.pubkey, msgHash), true);
        }
      });

      test("slight change in hash gives different signatures", () {

        final sig1 = ECDSASignature.sign(key, msgHash).compact;
        final sig2 = ECDSASignature.sign(key, msgMutated1).compact;
        final sig3 = ECDSASignature.sign(key, msgMutated2).compact;

        expect(sig1, isNot(equals(sig2)));
        expect(sig1, isNot(equals(sig3)));
        expect(sig2, isNot(equals(sig3)));

      });

      test("slight change in private key gives different signatures", () {

        final sig1 = ECDSASignature.sign(key, msgHash).compact;
        final sig2 = ECDSASignature.sign(keyMutated1, msgHash).compact;
        final sig3 = ECDSASignature.sign(keyMutated2, msgHash).compact;

        expect(sig1, isNot(equals(sig2)));
        expect(sig1, isNot(equals(sig3)));
        expect(sig2, isNot(equals(sig3)));

      });

    });

    group(".verify", () {

      late Hash256 msgHash;
      late ECPublicKey pubKey;

      setUpAll(() {
        // Data taken from wycheproof vectors
        final msg = hexToBytes("313233343030");
        // Wycheproof only uses single SHA256
        msgHash = sha256Hash(msg);
        pubKey = ECPublicKey.fromHex(
          "04b838ff44e5bc177bf21189d0766082fc9d843226887fc9760371100b7ee20a6ff0c9d75bfba7b31a6bca1974496eeb56de357071955d83c4b1badaa0b21832e9",
        );
      });

      expectSig(String sigHex, bool valid) => expect(
        ECDSASignature.fromCompactHex(sigHex).verify(pubKey, msgHash),
        valid,
      );

      test("verifies low s-value signature", () {
        expectSig(
          "813EF79CCEFA9A56F7BA805F0E478584FE5F0DD5F567BC09B5123CCBC98323656FF18A52DCC0336F7AF62400A6DD9B810732BAF1FF758000D6F613A556EB31BA",
          true,
        );
      });

      test("verifies high s-value signature", () {
        expectSig(
          "813EF79CCEFA9A56F7BA805F0E478584FE5F0DD5F567BC09B5123CCBC9832365900E75AD233FCC908509DBFF5922647DB37C21F4AFD3203AE8DC4AE7794B0F87",
          true,
        );
      });

      test("rejects false signature", () {
        // Wrong R
        expectSig(
          "813EF79CCEFA9A56F7BA805F0E478584FE5F0DD5F567BC09B5123CCBC98323666FF18A52DCC0336F7AF62400A6DD9B810732BAF1FF758000D6F613A556EB31BA",
          false,
        );
        // Wrong S
        expectSig(
          "813EF79CCEFA9A56F7BA805F0E478584FE5F0DD5F567BC09B5123CCBC98323656FF18A52DCC0336F7AF62400A6DD9B810732BAF1FF758000D6F613A556EB31BB",
          false,
        );
      });

    });
  });

}
