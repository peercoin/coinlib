import 'dart:typed_data';
import 'package:coinlib/coinlib.dart';
import 'package:test/test.dart';

void main() {

  group("NUMSPublicKey", () {

    setUpAll(loadCoinlib);

    final exampleTweakHex
      = "2bae58ab6d9fd575bdc3a624e4825dd2b375d64ac033fbc46ea79dbab4f69a3e";

    test("generated key can be reconstructed from rTweak", () {
      final nums = NUMSPublicKey.generate();
      final reconstructed = NUMSPublicKey.fromRTweak(nums.rTweak);
      expect(nums, reconstructed);
    });

    test("produces keys as expected", () {
      expect(
        NUMSPublicKey.fromRTweak(hexToBytes(exampleTweakHex)).hex,
        "0353b6c45433a55b4c83a3d967ca54bc11e0e6329f00a31282f255201c508a7b99",
      );
    });

    test("require 32-byte tweak scalar", () {
      expect(
        () => NUMSPublicKey.fromRTweak(Uint8List(31)), throwsArgumentError,
      );
    });

    test("rTweak is immutable", () {
      final rTweak = hexToBytes(exampleTweakHex);
      final nums = NUMSPublicKey.fromRTweak(rTweak);
      rTweak[0] = 0xff;
      nums.rTweak[1] = 0xff;
      expect(bytesToHex(nums.rTweak), exampleTweakHex);
    });

  });

}
