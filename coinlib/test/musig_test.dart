import 'dart:typed_data';
import 'package:coinlib/coinlib.dart';
import 'package:test/test.dart';

void main() {

  group("MuSigPublicKeys", () {

    setUpAll(loadCoinlib);

    test(
      "requires one or more keys",
      () => expect(() => MuSigPublicKeys({}), throwsArgumentError),
    );

    test("aggregation works regardless of format", () {

      Set<ECPublicKey> getKeys(bool compressed) => Iterable.generate(
        3,
        (i) => ECPrivateKey(
          Uint8List(32)..last = i+1,
          compressed: compressed,
        ).pubkey,
      ).toSet();

      final compressed = MuSigPublicKeys(getKeys(true)).aggregate;
      final uncompressed = MuSigPublicKeys(getKeys(false)).aggregate;

      expect(compressed, uncompressed);
      expect(
        compressed.hex,
        "020a8111534296d6fef2b23ad86d0d982b7b2f0fe6a48f03b1827954da2026f8dc",
      );

    });

  });

}

