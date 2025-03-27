import 'dart:typed_data';

import 'package:coinlib/coinlib.dart';
import 'package:test/test.dart';
import '../vectors/keys.dart';

void main() {

  group("ECPublicKey", () {

    setUpAll(loadCoinlib);

    test("requires 33 or 65 bytes", () {

      for (final failing in [
        // Too small
        pubkeyVec.substring(0, 32*2),
        longPubkeyVec.substring(0, 32*2),
        // Too large
        "${pubkeyVec}ff",
        "${longPubkeyVec}ff",
      ]) {
        expect(
          () => ECPublicKey.fromHex(failing),
          throwsA(isA<InvalidPublicKey>()),
        );
      }

    });

    test("accepts compressed, uncompressed and hybrid types", () {
      for (final vec in validPubKeys) {
        final pk = ECPublicKey.fromHex(vec.hex);
        expect(pk.hex, vec.hex);
        expect(pk.compressed, vec.compressed);
        expect(pk.yIsEven, vec.evenY);
      }
    });

    test("rejects invalid public keys", () {
      for (final pk in invalidPubKeys) {
        expect(() => ECPublicKey.fromHex(pk), throwsA(isA<InvalidPublicKey>()));
      }
    });

    test(".fromXOnly", () {

      expect(
        ECCompressedPublicKey.fromXOnlyHex(xOnlyPubkeyVec).hex,
        "02$xOnlyPubkeyVec",
      );

      for (final invalid in [
        "eefdea4cdb677750a420fee807eacf21eb9898ae79b9768766e4faa04a2d4a34",
        "fffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc30",
      ]) {
        expect(
          () => ECPublicKey.fromXOnlyHex(invalid),
          throwsA(isA<InvalidPublicKey>()),
        );
      }

      for (final wrongSize in [31, 33]) {
        expect(
          () => ECPublicKey.fromXOnly(Uint8List(wrongSize)),
          throwsArgumentError,
        );
      }

    });

    test(".hex and .xhex", () {
      for (final vector in keyPairVectors) {
        expect(vector.publicObj.hex, vector.public);
        expect(vector.publicObj.xhex, vector.public.substring(2, 66));
      }
    });

    test(".compressed", () {
      for (final vector in keyPairVectors) {
        expect(vector.publicObj.compressed, vector.compressed);
      }
    });

    test("allows equality comparison", () {
      for (int i = 0; i < validPubKeys.length; i++) {
        expect(
          ECPublicKey.fromHex(validPubKeys[i].hex),
          ECPublicKey.fromHex(validPubKeys[i].hex),
        );
        for (int j = 0; j < i; j++) {
          expect(
            ECPublicKey.fromHex(validPubKeys[i].hex),
            isNot(equals(ECPublicKey.fromHex(validPubKeys[j].hex))),
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
      final hex = validPubKeys[0].hex;
      final data = hexToBytes(hex);
      final key = ECPublicKey(data);
      key.data[0] = 0xff;
      data[1] = 0xff;
      expect(bytesToHex(key.data), hex);
    });

  });

}
