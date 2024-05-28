import 'dart:typed_data';
import 'package:coinlib/coinlib.dart';
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
          throwsArgumentError,
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

    test("tweak() produces correct key and keeps compression flag", () {

      expectTweak(String keyHex, String tweakHex, String resultHex, bool compressed) {
        final key = ECPrivateKey.fromHex(keyHex, compressed: compressed);
        final tweak = hexToBytes(tweakHex);
        final result = ECPrivateKey.fromHex(resultHex, compressed: compressed);
        final newKey = key.tweak(tweak);
        expect(newKey?.data, result.data);
        expect(newKey?.compressed, result.compressed);
        expect(newKey?.compressed, compressed);
      }

      expectTweak(
        "0000000000000000000000000000000000000000000000000000000000000001",
        "2bfe58ab6d9fd575bdc3a624e4825dd2b375d64ac033fbc46ea79dbab4f69a3e",
        "2bfe58ab6d9fd575bdc3a624e4825dd2b375d64ac033fbc46ea79dbab4f69a3f",
        false,
      );

      expectTweak(
        "fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364140",
        "2bfe58ab6d9fd575bdc3a624e4825dd2b375d64ac033fbc46ea79dbab4f69a3e",
        "2bfe58ab6d9fd575bdc3a624e4825dd2b375d64ac033fbc46ea79dbab4f69a3d",
        true,
      );

      expectTweak(
        "fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364140",
        "0000000000000000000000000000000000000000000000000000000000000000",
        "fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364140",
        true,
      );

    });

    test("invalid tweak scalar returns null", () {
      for (final invalid in invalidTweaks) {
        expect(keyPairVectors[0].privateObj.tweak(hexToBytes(invalid)), null);
      }
    });

    test(".diffieHellman()", () {
      final k1 = keyPairVectors.first.privateObj;
      final k2 = keyPairVectors.last.privateObj;
      final s1 = k1.diffieHellman(k2.pubkey);
      final s2 = k2.diffieHellman(k1.pubkey);
      final other = k1.diffieHellman(k1.pubkey);
      // Secrets match
      expect(bytesToHex(s1), bytesToHex(s2));
      // Not the same as secret generated not by same key pairs
      expect(bytesToHex(s1), isNot(bytesToHex(other)));
    });

    test(".xonly", () {

      // Already even-y = 1
      final privEvenHex
        = "0000000000000000000000000000000000000000000000000000000000000001";
      final privEven = ECPrivateKey.fromHex(privEvenHex);
      expect(privEven.pubkey.yIsEven, true);
      // Gives same object
      expect(privEven.xonly, privEven);

      // Odd-y = order - 1
      final privOdd = ECPrivateKey.fromHex(
        "fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364140",
      );
      expect(privOdd.pubkey.yIsEven, false);
      // Negates back to 1
      expect(bytesToHex(privOdd.xonly.data), privEvenHex);

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

    test("data is copied and cannot be mutated", () {

      final expectedData = Uint8List(32);
      expectedData.last = 1;

      final data = Uint8List.fromList(expectedData);

      final key = ECPrivateKey(data);
      key.data[0] = 0xff;
      data[1] = 0xff;

      expect(key.data, expectedData);

    });

  });

}
