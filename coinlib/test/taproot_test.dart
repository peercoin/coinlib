import 'package:coinlib/coinlib.dart';
import 'package:test/test.dart';

void main() {

  group("Taproot", () {

    setUpAll(loadCoinlib);

    test("key-path tweak", () {

      expect(
        bytesToHex(
          Taproot(
            internalKey: ECPublicKey.fromXOnlyHex(
              "d6889cb081036e0faefa3a35157ad71086b123b2b144b649798b494c300a961d",
            ),
          ).tweakedKey.x,
        ),
        "53a1f6e454df1aa2776a2814a721372d6258050de330b3c6d10ee8f4e0dda343",
      );

    });

  });

}
