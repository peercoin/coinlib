import 'package:coinlib/coinlib.dart';
import 'package:test/test.dart';

import 'vectors/taproot.dart';

void main() {

  group("Taproot", () {

    setUpAll(loadCoinlib);

    test("valid tweaked key derivation", () {

      for (final vec in taprootVectors) {
        final taproot = Taproot(
          internalKey: ECPublicKey.fromXOnlyHex(vec.xInternalPubKeyHex),
        );
        expect(bytesToHex(taproot.tweakScalar), vec.tweakScalarHex);
        expect(bytesToHex(taproot.tweakedKey.x), vec.xTweakedKeyHex);
      }

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

  });

}
