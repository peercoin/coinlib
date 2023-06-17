import 'package:coinlib/coinlib.dart';
import 'package:coinlib/src/common/hex.dart';
import 'package:test/test.dart';
import '../../vectors/keys.dart';

void main() {

  group("P2WPKH", () {

    setUpAll(loadCoinlib);

    final asm = "0 $pubkeyhashVec";
    final script = Script.fromAsm(asm);

    expectP2WPKH(P2WPKH p2wpkh) {
      expect(bytesToHex(p2wpkh.pkHash), pubkeyhashVec);
      expect(bytesToHex(p2wpkh.program), pubkeyhashVec);
      expect(p2wpkh.script.match(script), true);
    }

    test("decompile() success", () {
      expectP2WPKH(P2WPKH.decompile(hexToBytes("0014$pubkeyhashVec")));
    });

    test("fromAsm() success", () => expectP2WPKH(P2WPKH.fromAsm(asm)));

    test("fromHash() success", () {
      expectP2WPKH(P2WPKH.fromHash(hexToBytes(pubkeyhashVec)));
    });

    test("fromPublicKey() success", () {
      expectP2WPKH(P2WPKH.fromPublicKey(ECPublicKey.fromHex(pubkeyVec)));
    });

    test("Program.match()", () => expectP2WPKH(Program.fromAsm(asm) as P2WPKH));

    test("decompile() fail", () {
      for (final bad in [
        "5114$pubkeyhashVec",
        "0014${pubkeyhashVec}00",
        "0013000102030405060708090a0b0c0d0e0f101112",
        "0015${pubkeyhashVec}14",
        "00", ""
      ]) {
        expect(() => P2WPKH.decompile(hexToBytes(bad)), throwsA(isA<NoProgramMatch>()));
      }
    });

    test("fromAsm() fail", () {
      for (final bad in [
        "0 000102030405060708090a0b0c0d0e0f101112",
        "0 ${pubkeyhashVec}14",
        pubkeyhashVec,
        "01 $pubkeyhashVec",
        "0 $pubkeyhashVec 0",
      ]) {
        expect(() => P2WPKH.fromAsm(bad), throwsA(isA<NoProgramMatch>()));
      }
    });

    test("fromHash() fail", () {
      for (final bad in [
        "000102030405060708090a0b0c0d0e0f101112",
        "${pubkeyhashVec}14",
        ""
      ]) {
        expect(
          () => P2WPKH.fromHash(hexToBytes(bad)),
          throwsA(isA<ArgumentError>()),
        );
      }
    });

  });

}