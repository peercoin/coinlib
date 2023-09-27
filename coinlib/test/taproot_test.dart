import 'package:coinlib/coinlib.dart';
import 'package:test/test.dart';

import 'vectors/taproot.dart';

void main() {

  group("Taproot", () {

    setUpAll(loadCoinlib);

    test("valid tweaked key derivation", () {

      for (final vec in taprootVectors) {
        expect(
          bytesToHex(
            Taproot(
              internalKey: ECPublicKey.fromXOnlyHex(vec.xInternalPubKeyHex),
            ).tweakedKey.x,
          ),
          vec.xTweakedKeyHex,
        );
      }

    });

  });

}
