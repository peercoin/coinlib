import 'dart:typed_data';
import 'package:coinlib/coinlib.dart';
import 'package:test/test.dart';
import '../vectors/taproot.dart';

void main() {

  group("Taproot", () {

    late ECPublicKey exampleKey;
    setUpAll(() async {
      await loadCoinlib();
      exampleKey = taprootVectors[0].object.internalKey;
    });

    final exampleLeaf = leafFromHex("050102030405");
    final identicalLeaf = leafFromHex("050102030405");
    final otherLeaf = leafFromHex("0401020304");

    test("valid tweaked key derivation", () {

      for (final vec in taprootVectors) {
        expect(bytesToHex(vec.object.tweakScalar), vec.tweakScalarHex);
        expect(bytesToHex(vec.object.tweakedKey.x), vec.xTweakedKeyHex);
        expect(vec.object.leaves.length, vec.leafHashes.length);
        expect(
          vec.object.leaves.map((leaf) => bytesToHex(leaf.hash)),
          vec.leafHashes,
        );
        expect(
          vec.object.leaves.map(
            (leaf) => bytesToHex(vec.object.controlBlockForLeaf(leaf)),
          ),
          vec.controlBlocks,
        );
      }

    });

    test("duplicate leaves not allowed", () {
      expectNoDuplicates(TapBranch mast) => expect(
        () => Taproot(internalKey: exampleKey, mast: mast),
        throwsArgumentError,
      );
      expectNoDuplicates(TapBranch(exampleLeaf, exampleLeaf));
      expectNoDuplicates(TapBranch(exampleLeaf, identicalLeaf));
    });

    test("controlBlockForLeaf()", () {

      final noMast = Taproot(internalKey: exampleKey);
      final withMast = Taproot(internalKey: exampleKey, mast: exampleLeaf);

      // Require MAST
      expect(() => noMast.controlBlockForLeaf(exampleLeaf), throwsArgumentError);

      // Require identical leaf
      expect(() => withMast.controlBlockForLeaf(otherLeaf), throwsArgumentError);
      expect(withMast.controlBlockForLeaf(exampleLeaf), isA<Uint8List>());
      expect(withMast.controlBlockForLeaf(identicalLeaf), isA<Uint8List>());

    });

    test(".tweakPrivateKey()", () {

      final expTweaked
        = "2405b971772ad26915c8dcdf10f238753a9b837e5f8e6a86fd7c0cce5b7296d9";

      expectTweak(String internalPrivHex) {
        final internalPriv = ECPrivateKey.fromHex(internalPrivHex);
        final tr = Taproot(internalKey: internalPriv.pubkey);
        final tweaked = tr.tweakPrivateKey(internalPriv);
        expect(bytesToHex(tweaked.data), expTweaked);
        expect(tweaked.pubkey, tr.tweakedKey);
      }

      // Even-y
      expectTweak(
        "6b973d88838f27366ed61c9ad6367663045cb456e28335c109e30717ae0c6baa",
      );

      // Odd-y
      expectTweak(
        "9468c2777c70d8c99129e36529c9899bb652288fccc56a7ab5ef57752229d597",
      );

    });

    test(".leaves cannot be mutated", () {
      final taproot = Taproot(
        internalKey: exampleKey,
        mast: TapBranch(exampleLeaf, otherLeaf),
      );
      expect(() => taproot.leaves[0] = identicalLeaf, throwsA(anything));
      expect(() => taproot.leaves.add(identicalLeaf), throwsA(anything));

    });

  });

}
