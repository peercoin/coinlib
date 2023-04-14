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

    group(".fromWif", () {

      test("constructs corresponding private key", () {
        for (final vector in keyPairVectors) {

          expectAsVector(ECPrivateKey key) {
            expect(key.data, hexToBytes(vector.private));
            expect(key.compressed, vector.compressed);
          }

          expectAsVector(ECPrivateKey.fromWif(vector.wif));
          expectAsVector(ECPrivateKey.fromWif(vector.wif, version: vector.version));

        }
      });

      test("throws InvalidWif for incorrect format", () {

        for (final failing in [
          // Wrong final byte for compressed
          "KwFfpDsaF7yxCELuyrH9gP5XL7TAt5b9HPWC1xCQbmrxvhUSDecD",
          // Too small
          "yNgx2GS4gtpsqofv9mu8xN4ajx5hvs67v88NDsDNeBPzC3yfR",
          // Too large
          "2SaTkKRpDjKpNcZttqvWHJpSxsMUWcTFhZLKqdCdMAV1XrGkPFT2g6",
        ]) {
          expect(
            () => ECPrivateKey.fromWif(failing),
            throwsA(isA<InvalidWif>()),
          );
        }

      });

      test("throws WifVersionMismatch for wrong version", () {
        for (final vector in keyPairVectors) {
          expect(
            () => ECPrivateKey.fromWif(
              vector.wif, version: (vector.version+1) % 0xff,
            ),
            throwsA(isA<WifVersionMismatch>()),
          );
        }
      });

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
