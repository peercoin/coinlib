import 'dart:typed_data';
import 'package:coinlib/coinlib.dart';
import 'package:test/test.dart';
import '../vectors/keys.dart';

void main() {

  group("MuSigPublicKeys", () {

    setUpAll(loadCoinlib);

    test(
      "requires one or more keys",
      () => expect(() => MuSigPublicKeys({}), throwsArgumentError),
    );

    test("aggregation works regardless of format", () {

      final compressed = getMuSigKeys(true).aggregate;
      final uncompressed = getMuSigKeys(false).aggregate;

      expect(compressed, uncompressed);
      expect(
        compressed.hex,
        "020a8111534296d6fef2b23ad86d0d982b7b2f0fe6a48f03b1827954da2026f8dc",
      );

    });

    test(".tweak", () {

      final musig = getMuSigKeys(true);
      final scalar = Uint8List(32)..last = 1;

      // Do twice to ensure cache doesn't mutate
      for (int i = 0; i < 2; i++) {
        final tweaked = musig.tweak(scalar);
        expect(tweaked.pubKeys, musig.pubKeys);
        expect(
          tweaked.aggregate.hex,
          "020c296b69754e42345ac62909461bb8340927b79a66d792326b3b3f03aa394eda",
        );
        expect(
          tweaked.tweak(scalar).aggregate.hex,
          "020a8111534296d6fef2b23ad86d0d982b7b2f0fe6a48f03b1827954da2026f8dc",
        );
      }

    });

  });

}
