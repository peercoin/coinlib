import 'dart:typed_data';
import 'package:coinlib/coinlib.dart';
import 'package:coinlib/src/common/hex.dart';
import 'package:test/test.dart';
import '../vectors/keys.dart';

void main() {

  group("ECPublicKey", () {

    setUpAll(loadCoinlib);

    test("requires 33 or 65 bytes", () {

      for (final failing in [
        // Too small
        "000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f",
        "000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f",
        // Too large
        "000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f2021",
        "000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f2021",
      ]) {
        expect(
          () => ECPublicKey.fromHex(failing),
          throwsA(isA<ArgumentError>()),
        );
      }

    });

    test("accepts compressed, uncompressed and hybrid types", () {
      for (final pk in validPubKeys) {
        expect(ECPublicKey.fromHex(pk).hex, pk);
      }
    });

    test("rejects invalid public keys", () {
      for (final pk in invalidPubKeys) {
        expect(() => ECPublicKey.fromHex(pk), throwsA(isA<InvalidPublicKey>()));
      }
    });

    test(".hex", () {
      for (final vector in keyPairVectors) {
        expect(vector.publicObj.hex, vector.public);
      }
    });

    test(".compressed", () {
      for (final vector in keyPairVectors) {
        expect(vector.publicObj.compressed, vector.compressed);
      }
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
        pubKey.verify(ECDSASignature.fromCompactHex(sigHex), msgHash),
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

    test(".equal", () {
      for (int i = 0; i < validPubKeys.length; i++) {
        expect(
          ECPublicKey.fromHex(validPubKeys[i]),
          ECPublicKey.fromHex(validPubKeys[i]),
        );
        for (int j = 0; j < i; j++) {
          expect(
            ECPublicKey.fromHex(validPubKeys[i]),
            isNot(equals(ECPublicKey.fromHex(validPubKeys[j]))),
          );
        }
      }
    });

  });

}
