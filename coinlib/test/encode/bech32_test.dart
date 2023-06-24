import 'package:coinlib/coinlib.dart';
import 'package:test/test.dart';
import '../vectors/bech32.dart';

void main() {

  group("Bech32", () {

    throwsInvalidWithMsg(String msg) => throwsA(
      allOf(
        isA<InvalidBech32>(),
        predicate<InvalidBech32>((e) => e.message == msg),
      ),
    );

    expectValidVectors(List<String> vectors, Bech32Type type) {
      for (final vector in vectors) {
        final b32 = Bech32.decode(vector);
        expect(b32.encode(), vector, reason: vector);
        expect(b32.type, type, reason: vector);
      }
    }

    test(
      "valid bech32", () => expectValidVectors(validBech32, Bech32Type.bech32),
    );

    test(
      "valid bech32m",
      () => expectValidVectors(validBech32m, Bech32Type.bech32m),
    );

    test("invalid bech32", () {
      for (final vector in invalidBech32) {
        expect(
          () => Bech32.decode(vector.first),
          throwsInvalidWithMsg(vector.last),
          reason: vector.first,
        );
      }
    });

    test("invalid bech32 checksum", () {
      for (final vector in invalidBech32Checksum) {
        expect(
          () => Bech32.decode(vector),
          throwsA(isA<InvalidBech32Checksum>()),
          reason: vector,
        );
      }
    });

    test("validates HRP and words", () {

      expect(
        () => Bech32(hrp: "", words: [], type: Bech32Type.bech32),
        throwsInvalidWithMsg("Missing HRP"),
      );

      expect(
        () => Bech32(hrp: "€", words: [], type: Bech32Type.bech32),
        throwsInvalidWithMsg("€ is an invalid bech32 HRP"),
      );

      for (final badWords in [[0, -1], [32, 1], [0xffffffff]]) {
        expect(
          () => Bech32(hrp: "bc", words: badWords, type: Bech32Type.bech32),
          throwsInvalidWithMsg("Words outside of 5-bit range"),
        );
      }

      expect(
        () => Bech32(
          hrp: "bc",
          // 83 + 2 + 6 = 91
          words: List.generate(83, (i) => i % 32),
          type: Bech32Type.bech32,
        ),
        throwsInvalidWithMsg("Bech32 too long"),
      );

    });

    test("encodes correctly given HRP and words", () {

      expectBech32(
        String hrp, List<int> words, Bech32Type type, String expected,
      ) => expect(
        Bech32(hrp: hrp, words: words, type: type).encode(), expected,
      );

      expectBech32(
        "bc",
        List.generate(53, (i) => 0),
        Bech32Type.bech32,
        "bc1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqthqst8",
      );

      expectBech32(
        "bc",
        [0] + List.generate(51, (i) => 31) + [16],
        Bech32Type.bech32,
        "bc1qlllllllllllllllllllllllllllllllllllllllllllllllllllsffrpzs",
      );

      expectBech32(
        "an83characterlonghumanreadablepartthatcontainsthetheexcludedcharactersbioandnumber1",
        [],
        Bech32Type.bech32m,
        "an83characterlonghumanreadablepartthatcontainsthetheexcludedcharactersbioandnumber11sg7hg6",
      );

      expectBech32(
        "abcdef",
        List.generate(32, (i) => i).reversed.toList(),
        Bech32Type.bech32m,
        "abcdef1l7aum6echk45nj3s0wdvt2fg8x9yrzpqzd3ryx",
      );

    });

    test(".words cannot be mutated", () {
      final bech32 = Bech32(hrp: "a", words: [1], type: Bech32Type.bech32);
      expect(() => bech32.words[0] = 0, throwsA(anything));
      expect(bech32.words, [1]);
    });

  });

}
