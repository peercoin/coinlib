import 'package:coinlib/coinlib.dart';
import 'package:coinlib/src/common/hex.dart';
import 'package:test/test.dart';

void main() {

  group("P2PKH", () {

    final hash = "000102030405060708090a0b0c0d0e0f10111213";
    final asm = "OP_DUP OP_HASH160 000102030405060708090a0b0c0d0e0f10111213"
      " OP_EQUALVERIFY OP_CHECKSIG";
    final script = Script.fromAsm(asm);

    expectP2PKH(P2PKH p2pkh) {
      expect(bytesToHex(p2pkh.pkHash), hash);
      expect(p2pkh.script.match(script), true);
    }

    test("decompile() success", () {
      expectP2PKH(
        P2PKH.decompile(
          hexToBytes("76a914000102030405060708090a0b0c0d0e0f1011121388ac"),
        ),
      );
    });

    test("fromAsm() success", () => expectP2PKH(P2PKH.fromAsm(asm)));

    test("fromHash() success", () {
      expectP2PKH(P2PKH.fromHash(hexToBytes(hash)));
    });

    test("Program.match()", () => expectP2PKH(Program.fromAsm(asm) as P2PKH));

    test("decompile() fail", () {
      for (final bad in [
        "76a913000102030405060708090a0b0c0d0e0f10111288ac",
        "76a915000102030405060708090a0b0c0d0e0f101112131488ac",
        "76a914000102030405060708090a0b0c0d0e0f1011121388",
        "76a914000102030405060708090a0b0c0d0e0f1011121388ad",
        "77a914000102030405060708090a0b0c0d0e0f1011121388ac",
        "",
      ]) {
        expect(() => P2PKH.decompile(hexToBytes(bad)), throwsA(isA<NoProgramMatch>()));
      }
    });

    test("fromAsm() fail", () {
      for (final bad in [

        "OP_DUP OP_HASH160 000102030405060708090a0b0c0d0e0f101112"
        " OP_EQUALVERIFY OP_CHECKSIG",

        "OP_DUP OP_HASH160 000102030405060708090a0b0c0d0e0f1011121314"
        " OP_EQUALVERIFY OP_CHECKSIG",

        "OP_DUP OP_HASH160 000102030405060708090a0b0c0d0e0f10111213"
        " OP_EQUALVERIFY",

        "OP_DUP OP_HASH160 000102030405060708090a0b0c0d0e0f10111213"
        " OP_EQUALVERIFY OP_CHECKMULTISIG",

        "OP_2DUP OP_HASH160 000102030405060708090a0b0c0d0e0f10111213"
        " OP_EQUALVERIFY OP_CHECKSIG",

      ]) {
        expect(() => P2PKH.fromAsm(bad), throwsA(isA<NoProgramMatch>()));
      }
    });

    test("fromHash() fail", () {
      for (final bad in [
        "000102030405060708090a0b0c0d0e0f101112",
        "000102030405060708090a0b0c0d0e0f1011121314",
        ""
      ]) {
        expect(
          () => P2PKH.fromHash(hexToBytes(bad)),
          throwsA(isA<ArgumentError>()),
        );
      }
    });

  });

}
