import 'package:coinlib/coinlib.dart';
import 'package:coinlib/src/common/hex.dart';
import 'package:test/test.dart';

void main() {

  group("P2WPKH", () {

    final hash = "000102030405060708090a0b0c0d0e0f10111213";
    final asm = "0 000102030405060708090a0b0c0d0e0f10111213";
    final script = Script.fromAsm(asm);

    expectP2WPKH(P2WPKH p2wpkh) {
      expect(bytesToHex(p2wpkh.pkHash), hash);
      expect(p2wpkh.script.match(script), true);
    }

    test("decompile() success", () {
      expectP2WPKH(
        P2WPKH.decompile(
          hexToBytes("0014000102030405060708090a0b0c0d0e0f10111213"),
        ),
      );
    });

    test("fromAsm() success", () => expectP2WPKH(P2WPKH.fromAsm(asm)));

    test("fromHash() success", () {
      expectP2WPKH(P2WPKH.fromHash(hexToBytes(hash)));
    });

    test("Program.match()", () => expectP2WPKH(Program.fromAsm(asm) as P2WPKH));

    test("decompile() fail", () {
      for (final bad in [
        "5114000102030405060708090a0b0c0d0e0f10111213",
        "0014000102030405060708090a0b0c0d0e0f1011121300",
        "0013000102030405060708090a0b0c0d0e0f101112",
        "0015000102030405060708090a0b0c0d0e0f1011121314",
        "00", ""
      ]) {
        expect(() => P2WPKH.decompile(hexToBytes(bad)), throwsA(isA<NoProgramMatch>()));
      }
    });

    test("fromAsm() fail", () {
      for (final bad in [
        "0 000102030405060708090a0b0c0d0e0f101112",
        "0 000102030405060708090a0b0c0d0e0f1011121314",
        "000102030405060708090a0b0c0d0e0f10111213",
        "01 000102030405060708090a0b0c0d0e0f10111213",
        "0 000102030405060708090a0b0c0d0e0f10111213 0",
      ]) {
        expect(() => P2WPKH.fromAsm(bad), throwsA(isA<NoProgramMatch>()));
      }
    });

    test("fromHash() fail", () {
      for (final bad in [
        "000102030405060708090a0b0c0d0e0f101112",
        "000102030405060708090a0b0c0d0e0f1011121314",
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
