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
          throwsA(isA<InvalidPublicKey>()),
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

    test("tweak() produces correct key and keeps compression flag", () {

      expectTweak(String keyHex, String tweakHex, String resultHex) {
        final key = ECPublicKey.fromHex(keyHex);
        final tweak = hexToBytes(tweakHex);
        final result = ECPublicKey.fromHex(resultHex);
        final newKey = key.tweak(tweak);
        expect(newKey?.data, result.data);
        expect(newKey?.compressed, result.compressed);
        expect(newKey?.compressed, key.compressed);
      }

      expectTweak(
        "0479be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8",
        "2bfe58ab6d9fd575bdc3a624e4825dd2b375d64ac033fbc46ea79dbab4f69a3e",
        "04120d346a198b67e465ab743cca6592b325b6ff8c46e5ad9efa99880cdb450a771b83f711e03b67b244a446517f5449f39015a8f766201461e7bc1b1bf2d1020f",
      );

      expectTweak(
        "0379be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798",
        "2bfe58ab6d9fd575bdc3a624e4825dd2b375d64ac033fbc46ea79dbab4f69a3e",
        "028b6047495a053d29e8753fb0432154bc7cb3968772d0dca3819903e31ddca51b",
      );

      expectTweak(
        "0379be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798",
        "0000000000000000000000000000000000000000000000000000000000000000",
        "0379be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798",
      );

    });

    test("invalid tweak scalar returns null", () {
      for (final invalid in invalidTweaks) {
        expect(keyPairVectors[0].publicObj.tweak(hexToBytes(invalid)), null);
      }
    });

    test("data cannot be mutated", () {
      final hex = validPubKeys[0];
      final data = hexToBytes(hex);
      final key = ECPublicKey(data);
      key.data[0] = 0xff;
      data[1] = 0xff;
      expect(bytesToHex(key.data), hex);
    });

  });

}
