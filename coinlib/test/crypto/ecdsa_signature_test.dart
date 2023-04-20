import 'package:coinlib/coinlib.dart';
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

  });

}
