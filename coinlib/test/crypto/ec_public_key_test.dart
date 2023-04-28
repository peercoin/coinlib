import 'package:coinlib/coinlib.dart';
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
