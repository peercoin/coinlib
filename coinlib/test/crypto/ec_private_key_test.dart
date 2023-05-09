import 'package:coinlib/coinlib.dart';
import 'package:coinlib/src/common/hex.dart';
import 'package:test/test.dart';
import '../vectors/keys.dart';

void main() {

  group("ECPrivateKey", () {

    setUpAll(loadCoinlib);

    test("requires 32 bytes", () {

      for (final failing in [
        // Too small
        "000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e",
        // Too large
        "000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f20",
      ]) {
        expect(
          () => ECPrivateKey.fromHex(failing),
          throwsA(isA<ArgumentError>()),
        );
      }

    });

    test("requires key is within 1 to order-1", () {

      for (final failing in [
        "0000000000000000000000000000000000000000000000000000000000000000",
        "fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141",
      ]) {
        expect(
          () => ECPrivateKey.fromHex(failing),
          throwsA(isA<InvalidPrivateKey>()),
        );
      }

    });

    test(".generate() gives new key each time", () {
      final key1 = ECPrivateKey.generate();
      final key2 = ECPrivateKey.generate(compressed: false);
      expect(key1.compressed, true);
      expect(key2.compressed, false);
      expect(key1.data, isNot(equals(key2.data)));
    });

    test(".data", () {
      for (final vector in keyPairVectors) {
        expect(bytesToHex(vector.privateObj.data), vector.private);
      }
    });

    test(".compressed", () {
      for (final vector in keyPairVectors) {
        expect(vector.privateObj.compressed, vector.compressed);
      }
    });

    test(".pubkey", () {
      for (final vector in keyPairVectors) {
        // Should work twice with cache
        for (int i = 0; i < 2; i++) {
          expect(vector.privateObj.pubkey.hex, vector.public);
        }
      }
    });

  });

}
