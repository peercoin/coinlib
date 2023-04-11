import 'package:coinlib/coinlib.dart';
import 'package:coinlib/src/common/hex.dart';
import 'package:test/test.dart';
import '../vectors/keys.dart';

void main() {

  setUpAll(() => loadCoinlib());

  group("ECPrivateKey", () {

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
