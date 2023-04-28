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

    group(".signEcdsa()", () {

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
          final sig = key.signEcdsa(msgHash);
          expect(
            bytesToHex(sig.compact),
            "a951b0cf98bd51c614c802a65a418fa42482dc5c45c9394e39c0d98773c51cd530104fdc36d91582b5757e1de73d982e803cc14d75e82c65daf924e38d27d834",
          );
          expect(key.pubkey.verify(sig, msgHash), true);
        }
      });

      test("slight change in hash gives different signatures", () {

        final sig1 = key.signEcdsa(msgHash).compact;
        final sig2 = key.signEcdsa(msgMutated1).compact;
        final sig3 = key.signEcdsa(msgMutated2).compact;

        expect(sig1, isNot(equals(sig2)));
        expect(sig1, isNot(equals(sig3)));
        expect(sig2, isNot(equals(sig3)));

      });

      test("slight change in private key gives different signatures", () {

        final sig1 = key.signEcdsa(msgHash).compact;
        final sig2 = keyMutated1.signEcdsa(msgHash).compact;
        final sig3 = keyMutated2.signEcdsa(msgHash).compact;

        expect(sig1, isNot(equals(sig2)));
        expect(sig1, isNot(equals(sig3)));
        expect(sig2, isNot(equals(sig3)));

      });

    });

  });

}
