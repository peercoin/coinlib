import 'dart:typed_data';
import 'package:coinlib/coinlib.dart';
import 'package:test/test.dart';
import '../vectors/keys.dart';

final scalar = Uint8List(32)..last = 1;

final tweakedOne
  = "020c296b69754e42345ac62909461bb8340927b79a66d792326b3b3f03aa394eda";
final tweakedTwo
  = "020a8111534296d6fef2b23ad86d0d982b7b2f0fe6a48f03b1827954da2026f8dc";

void main() {

  setUpAll(loadCoinlib);

  group("MuSigPublicKeys", () {

    test(
      "requires one or more keys",
      () => expect(() => MuSigPublicKeys({}), throwsArgumentError),
    );

    test("pubKeys is immutable", () {
      final keySet = getMuSigKeys().pubKeys;
      expect(() => keySet.remove(keySet.first), throwsA(anything));
    });

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

      final musig = getMuSigKeys();

      // Do twice to ensure cache doesn't mutate
      for (int i = 0; i < 2; i++) {
        final tweaked = musig.tweak(scalar);
        expect(tweaked.pubKeys, musig.pubKeys);
        expect(tweaked.aggregate.hex, tweakedOne);
        expect(tweaked.tweak(scalar).aggregate.hex, tweakedTwo);
      }

    });

  });

  group("MuSigPrivate", () {

    test(".tweak", () {
      final privMuSig = getMuSigPrivate(0);
      final first = privMuSig.tweak(scalar);
      expect(first.public.aggregate.hex, tweakedOne);
      expect(first.privateKey.pubkey, privMuSig.privateKey.pubkey);
      final second = first.tweak(scalar);
      expect(second.public.aggregate.hex, tweakedTwo);
    });

  });

}
