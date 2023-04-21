import 'package:coinlib/coinlib.dart';
import 'package:coinlib/src/common/hex.dart';
import 'package:coinlib/src/crypto/ecdsa_signature.dart';
import 'package:test/test.dart';

final validSignatures = [
  "a951b0cf98bd51c614c802a65a418fa42482dc5c45c9394e39c0d98773c51cd530104fdc36d91582b5757e1de73d982e803cc14d75e82c65daf924e38d27d834",
  "00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
  "fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364140fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364140",
];

final invalidSignatures = [
  "fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364140",
  "fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364140fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141",
];

final validDerSigs = [
  "3046022100813ef79ccefa9a56f7ba805f0e478584fe5f0dd5f567bc09b5123ccbc9832365022100900e75ad233fcc908509dbff5922647db37c21f4afd3203ae8dc4ae7794b0f87",
  "3046022100fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364140022100fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364140",
  "3006020101020101",
  "3006020100020100",
];

final invalidDerSigs = [
  "300602020000020100",
  "300602010002020000",
  "3006020100020100ff",
  "30060201000201",
  "4006020100020100",
  "3006030100020100",
  "3006020100030100",
  "3006020100020200",
  "3007020100020100",
  "3005020100020100",
];

void main() {

  group("ECDSASignature", () {

    setUpAll(loadCoinlib);

    test("requires 64-bytes", () {

      for (final failing in [
        // Too small
        "a951b0cf98bd51c614c802a65a418fa42482dc5c45c9394e39c0d98773c51cd530104fdc36d91582b5757e1de73d982e803cc14d75e82c65daf924e38d27d8",
        // Too large
        "a951b0cf98bd51c614c802a65a418fa42482dc5c45c9394e39c0d98773c51cd530104fdc36d91582b5757e1de73d982e803cc14d75e82c65daf924e38d27d834ff",
      ]) {
        expect(
          () => ECDSASignature.fromCompactHex(failing),
          throwsA(isA<ArgumentError>()),
        );
      }

    });

    test("accepts valid signatures", () {
      for (final sig in validSignatures) {
        expect(ECDSASignature.fromCompactHex(sig), isA<ECDSASignature>());
      }
    });

    test("rejects invalid R and S values", () {
      for (final sig in invalidSignatures) {
        expect(
          () => ECDSASignature.fromCompactHex(sig),
          throwsA(isA<InvalidECDSASignature>()),
          reason: sig,
        );
      }
    });

    test(".fromDerHex valid", () {
      for (final sig in validDerSigs) {
        expect(
          bytesToHex(ECDSASignature.fromDerHex(sig).der),
          sig,
          reason: sig,
        );
      }
    });

    test(".fromDerHex invalid", () {
      for (final sig in invalidDerSigs) {
        expect(
          () => ECDSASignature.fromDerHex(sig),
          throwsA(isA<InvalidECDSASignature>()),
          reason: sig,
        );
      }
    });

    test(".fromDerHex allows invalid R and S set to zero", () {
      expect(
        bytesToHex(
          ECDSASignature.fromDerHex(
            "3026022100fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141020101",
          ).der,
        ),
        "3006020100020101",
      );
      expect(
        bytesToHex(
          ECDSASignature.fromDerHex(
            "3026020101022100fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141",
          ).der,
        ),
        "3006020101020100",
      );
    });

    test(".der", () {
      // Takes a high s-value signature and returns the DER encoding
      expect(
        bytesToHex(
          ECDSASignature.fromCompactHex(
            "813ef79ccefa9a56f7ba805f0e478584fe5f0dd5f567bc09b5123ccbc9832365900e75ad233fcc908509dbff5922647db37c21f4afd3203ae8dc4ae7794b0f87",
          ).der,
        ),
        "3046022100813ef79ccefa9a56f7ba805f0e478584fe5f0dd5f567bc09b5123ccbc9832365022100900e75ad233fcc908509dbff5922647db37c21f4afd3203ae8dc4ae7794b0f87",
      );
    });

  });

}
