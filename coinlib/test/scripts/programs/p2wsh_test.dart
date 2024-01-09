import 'package:coinlib/coinlib.dart';
import 'package:test/test.dart';

void main() {

  group("P2WSH", () {

    setUpAll(loadCoinlib);

    final witnessScript = Script.fromAsm("0");
    final scriptHash = "6e340b9cffb37a989ca544e6bb780a2c78901d3fb33738768511a30617afa01d";
    final asm = "0 $scriptHash";
    final script = Script.fromAsm(asm);

    expectP2WSH(P2WSH p2wsh) {
      expect(p2wsh.version, 0);
      expect(bytesToHex(p2wsh.scriptHash), scriptHash);
      expect(bytesToHex(p2wsh.data), scriptHash);
      expect(p2wsh.script.match(script), true);
    }

    test(
      "decompile() success",
      () => expectP2WSH(P2WSH.decompile(hexToBytes("0020$scriptHash"))),
    );

    test("fromAsm() success", () => expectP2WSH(P2WSH.fromAsm(asm)));

    test(
      "fromHash() success",
      () => expectP2WSH(P2WSH.fromHash(hexToBytes(scriptHash))),
    );

    test("fromWitnessScript() success", () {
      expectP2WSH(P2WSH.fromWitnessScript(witnessScript));
    });

    test("Program.match()", () => expectP2WSH(Program.fromAsm(asm) as P2WSH));

    test("decompile() fail", () {
      for (final bad in [
        "001f000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e",
        "0021${scriptHash}20",
        "5120$scriptHash",
        "0020${scriptHash}00",
        "",
      ]) {
        expect(() => P2WSH.decompile(hexToBytes(bad)), throwsA(isA<NoProgramMatch>()));
      }
    });

    test("fromAsm() fail", () {
      for (final bad in [
        "0 000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e",
        "0 ${scriptHash}20",
        "0 $scriptHash 0",
        "01 $scriptHash",
      ]) {
        expect(
          () => P2WSH.fromAsm(bad),
          throwsA(isA<NoProgramMatch>()),
          reason: bad,
        );
      }
    });

    test("fromHash() fail", () {
      for (final bad in [
        "000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e",
        "${scriptHash}20",
        "",
      ]) {
        expect(
          () => P2WSH.fromHash(hexToBytes(bad)),
          throwsArgumentError,
        );
      }
    });

  });

}
