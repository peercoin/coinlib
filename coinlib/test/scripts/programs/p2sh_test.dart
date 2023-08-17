import 'package:coinlib/coinlib.dart';
import 'package:test/test.dart';

void main() {

  group("P2SH", () {

    setUpAll(loadCoinlib);

    final redeemScript = Script.fromAsm("0");
    final scriptHash = "9f7fd096d37ed2c0e3f7f0cfc924beef4ffceb68";
    final asm = "OP_HASH160 $scriptHash OP_EQUAL";
    final script = Script.fromAsm(asm);

    expectP2SH(P2SH p2sh) {
      expect(bytesToHex(p2sh.scriptHash), scriptHash);
      expect(p2sh.script.match(script), true);
    }

    test("decompile() success", () {
      expectP2SH(P2SH.decompile(hexToBytes("a914${scriptHash}87")));
    });

    test("fromAsm() success", () => expectP2SH(P2SH.fromAsm(asm)));

    test("fromHash() success", () {
      expectP2SH(P2SH.fromHash(hexToBytes(scriptHash)));
    });

    test("fromRedeemScript() success", () {
      expectP2SH(P2SH.fromRedeemScript(redeemScript));
    });

    test("Program.match()", () => expectP2SH(Program.fromAsm(asm) as P2SH));

    test("decompile() fail", () {
      for (final bad in [
        "a913000102030405060708090a0b0c0d0e0f10111287",
        "a915${scriptHash}1487",
        "aa14${scriptHash}87",
        "a914$scriptHash",
        "a914${scriptHash}8700",
        "",
      ]) {
        expect(() => P2SH.decompile(hexToBytes(bad)), throwsA(isA<NoProgramMatch>()));
      }
    });

    test("fromAsm() fail", () {
      for (final bad in [
        "OP_HASH160 000102030405060708090a0b0c0d0e0f101112 OP_EQUAL",
        "OP_HASH160 ${scriptHash}14 OP_EQUAL",
        "OP_HASH160 $scriptHash",
        "OP_HASH160 $scriptHash OP_EQUALVERIFY",
        "OP_HASH256 $scriptHash OP_EQUAL",
      ]) {
        expect(() => P2SH.fromAsm(bad), throwsA(isA<NoProgramMatch>()));
      }
    });

    test("fromHash() fail", () {
      for (final bad in [
        "000102030405060708090a0b0c0d0e0f101112",
        "${scriptHash}14",
        "",
      ]) {
        expect(
          () => P2SH.fromHash(hexToBytes(bad)),
          throwsArgumentError,
        );
      }
    });

    test(".scriptHash is copied and cannot be mutated", () {
      final hex = "0000000000000000000000000000000000000000";
      final hash = hexToBytes(hex);
      final p2sh = P2SH.fromHash(hash);
      p2sh.scriptHash[0] = 0xff;
      hash[1] = 0xff;
      expect(bytesToHex(p2sh.scriptHash), hex);
    });

  });

}
