import 'package:coinlib/coinlib.dart';
import 'package:test/test.dart';

import '../../vectors/taproot.dart';

void main() {

  group("P2TR", () {

    setUpAll(loadCoinlib);

    final tweakedKey = "53a1f6e454df1aa2776a2814a721372d6258050de330b3c6d10ee8f4e0dda343";
    final asm = "1 $tweakedKey";
    final script = Script.fromAsm(asm);

    expectP2TR(P2TR p2tr) {
      expect(p2tr.version, 1);
      expect(p2tr.tweakedKey, ECPublicKey.fromXOnlyHex(tweakedKey));
      expect(bytesToHex(p2tr.data), tweakedKey);
      expect(p2tr.script.match(script), true);
    }

    test(
      "decompile() success",
      () => expectP2TR(P2TR.decompile(hexToBytes("5120$tweakedKey"))),
    );

    test("fromAsm() success", () => expectP2TR(P2TR.fromAsm(asm)));

    test(
      "fromTweakedKeyX() success",
      () => expectP2TR(P2TR.fromTweakedKeyX(hexToBytes(tweakedKey))),
    );

    test(
      "fromTweakedKey() success",
      () => expectP2TR(
        P2TR.fromTweakedKey(ECPublicKey.fromXOnlyHex(tweakedKey)),
      ),
    );

    test(
      "fromTaproot() success",
      () => expectP2TR(P2TR.fromTaproot(taprootVectors[0].object)),
    );

    test("Program.match()", () => expectP2TR(Program.fromAsm(asm) as P2TR));

    test("decompile() fail", () {
      for (final bad in [
        "511f000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e",
        "5121${tweakedKey}20",
        "0020$tweakedKey",
        "5120${tweakedKey}00",
        "",
      ]) {
        expect(() => P2TR.decompile(hexToBytes(bad)), throwsA(isA<NoProgramMatch>()));
      }
    });

    test("fromAsm() fail", () {
      for (final bad in [
        "01 000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e",
        "01 ${tweakedKey}20",
        "01 $tweakedKey 0",
        "0 $tweakedKey",
      ]) {
        expect(
          () => P2TR.fromAsm(bad),
          throwsA(isA<NoProgramMatch>()),
          reason: bad,
        );
      }
    });

  });

}
