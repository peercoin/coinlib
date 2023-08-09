import 'package:coinlib/coinlib.dart';
import 'package:test/test.dart';
import '../vectors/keys.dart';

void main() {

  group("WIF", () {

    setUpAll(loadCoinlib);

    test("provides correct data however constructed", () {
      for (final vector in keyPairVectors) {

        expectAsVector(WIF wif) {
          expect(wif.privkey.data, hexToBytes(vector.private));
          expect(wif.privkey.compressed, vector.compressed);
          expect(wif.version, vector.version);
          expect(wif.toString(), vector.wif);
        }

        expectAsVector(WIF.fromString(vector.wif));
        expectAsVector(WIF.fromString(vector.wif, version: vector.version));
        expectAsVector(
          WIF(privkey: vector.privateObj, version: vector.version),
        );

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
        expect(() => WIF.fromString(failing), throwsA(isA<InvalidWif>()));
      }

    });

    test("throws WifVersionMismatch for wrong version", () {
      for (final vector in keyPairVectors) {
        expect(
          () => WIF.fromString(
            vector.wif, version: (vector.version+1) % 0xff,
          ),
          throwsA(isA<WifVersionMismatch>()),
        );
      }
    });

  });

}
