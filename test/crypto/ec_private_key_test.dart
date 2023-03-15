import 'package:coinlib/coinlib.dart';
import 'package:test/test.dart';

void main() {

  setUpAll(() => loadCoinlib());

  group(".pubkey", () {

    test("converts private key to public key", () {

      // TODO: Use more extensive fixtures. This is just a simple test to
      // demonstrate WASM

      final privKey = ECPrivateKey.fromHex(
        "0000000000000000000000000000000000000000000000000000000000000001",
      );
      // Should work twice with cache
      for (int i = 0; i < 2; i++) {
        expect(
          privKey.pubkey.hex,
          "0279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798",
        );
      }

    });

  });

}
