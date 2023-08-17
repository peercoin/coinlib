import 'package:coinlib/coinlib.dart';
import 'package:test/test.dart';
import '../../vectors/keys.dart';

void main() {

  group("P2PKH", () {

    setUpAll(loadCoinlib);

    final asm = "OP_DUP OP_HASH160 $pubkeyhashVec OP_EQUALVERIFY OP_CHECKSIG";
    final script = Script.fromAsm(asm);

    expectP2PKH(P2PKH p2pkh) {
      expect(bytesToHex(p2pkh.pkHash), pubkeyhashVec);
      expect(p2pkh.script.match(script), true);
    }

    test("decompile() success", () {
      expectP2PKH(P2PKH.decompile(hexToBytes("76a914${pubkeyhashVec}88ac")));
    });

    test("fromAsm() success", () => expectP2PKH(P2PKH.fromAsm(asm)));

    test("fromHash() success", () {
      expectP2PKH(P2PKH.fromHash(hexToBytes(pubkeyhashVec)));
    });

    test("fromPublicKey() success", () {
      expectP2PKH(P2PKH.fromPublicKey(ECPublicKey.fromHex(pubkeyVec)));
    });

    test("Program.match()", () => expectP2PKH(Program.fromAsm(asm) as P2PKH));

    test("decompile() fail", () {
      for (final bad in [
        "76a913000102030405060708090a0b0c0d0e0f10111288ac",
        "76a915${pubkeyhashVec}1488ac",
        "76a914${pubkeyhashVec}88",
        "76a914${pubkeyhashVec}88ad",
        "77a914${pubkeyhashVec}88ac",
        "",
      ]) {
        expect(() => P2PKH.decompile(hexToBytes(bad)), throwsA(isA<NoProgramMatch>()));
      }
    });

    test("fromAsm() fail", () {
      for (final bad in [

        "OP_DUP OP_HASH160 000102030405060708090a0b0c0d0e0f101112"
        " OP_EQUALVERIFY OP_CHECKSIG",

        "OP_DUP OP_HASH160 ${pubkeyhashVec}14 OP_EQUALVERIFY OP_CHECKSIG",

        "OP_DUP OP_HASH160 $pubkeyhashVec OP_EQUALVERIFY",

        "OP_DUP OP_HASH160 $pubkeyhashVec OP_EQUALVERIFY OP_CHECKMULTISIG",

        "OP_2DUP OP_HASH160 $pubkeyhashVec OP_EQUALVERIFY OP_CHECKSIG",

      ]) {
        expect(() => P2PKH.fromAsm(bad), throwsA(isA<NoProgramMatch>()));
      }
    });

    test("fromHash() fail", () {
      for (final bad in [
        "000102030405060708090a0b0c0d0e0f101112",
        "${pubkeyhashVec}14",
        "",
      ]) {
        expect(
          () => P2PKH.fromHash(hexToBytes(bad)),
          throwsArgumentError,
        );
      }
    });

    test(".pkHash is copied and cannot be mutated", () {
      final hex = "0000000000000000000000000000000000000000";
      final hash = hexToBytes(hex);
      final p2pkh = P2PKH.fromHash(hash);
      p2pkh.pkHash[0] = 0xff;
      hash[1] = 0xff;
      expect(bytesToHex(p2pkh.pkHash), hex);
    });

  });

}
