import 'package:coinlib/coinlib.dart';
import 'package:test/test.dart';
import '../vectors/base58.dart';

void main() {

  group("base58Encode", () {
    test("encodes to expected string", () {
      for (final vector in base58ValidVectors) {
        expect(base58Encode(vector.data), vector.encoded);
      }
    });
  });

  group("base58Decode", () {

    test("decodes correct checksumed base58", () {
      for (final vector in base58ValidVectors) {
        expect(base58Decode(vector.encoded), vector.data);
      }
    });

    test("throws InvalidBase58 on invalid base58", () {
      for (final vector in base58InvalidVectors) {
        expect(
          () => base58Decode(vector),
          throwsA(isA<InvalidBase58>()),
        );
      }
    });

    test("throws InvalidBase58Checksum for incorrect checksum", () {
      for (final vector in base58InvalidChecksumVectors) {
        expect(
          () => base58Decode(vector),
          throwsA(isA<InvalidBase58Checksum>()),
          reason: "while testing vector: $vector",
        );
      }
    });

  });

}
