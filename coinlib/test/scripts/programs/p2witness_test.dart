import 'package:coinlib/coinlib.dart';
import 'package:test/test.dart';

void main() {

  group("P2Witness", () {

    setUpAll(loadCoinlib);

    expectP2Witness(P2Witness p2witness, int version, String program) {
      expect(p2witness.version, version);
      expect(bytesToHex(p2witness.data), program);
      expect(
        p2witness.script.match(
          Script.fromAsm("${version.toRadixString(16)} $program"),
        ),
        true,
      );
    }

    final shortBytes = "0001";
    final longBytes = "000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f2021222324252627";

    test("decompile() success", () {
      expectDecompile(String compiled, int version, String program)
        => expectP2Witness(
          P2Witness.decompile(hexToBytes(compiled)),
          version,
          program,
        );
      expectDecompile("0002$shortBytes", 0, shortBytes);
      expectDecompile("6028$longBytes", 16, longBytes);
    });

    test("fromAsm() success", () {
      expectAsm(String asm, int version, String program) {
        expectP2Witness(P2Witness.fromAsm(asm), version, program);
        expectP2Witness(Program.fromAsm(asm) as P2Witness, version, program);
      }
      expectAsm("0 $shortBytes", 0, shortBytes);
      expectAsm("10 $longBytes", 16, longBytes);
    });

    test("fromData() success", () {
      expectProgram(int version, String program) => expectP2Witness(
        P2Witness.fromData(version, hexToBytes(program)), version, program,
      );
      expectProgram(16, shortBytes);
      expectProgram(16, longBytes);
    });

    test("decompile() fail", () {
      for (final bad in [
        "0001ff",
        "00",
        "0000",
        "020102",
        "61020001",
        "0028${longBytes}00",
        "0029${longBytes}00",
        "4f020102",
        "",
      ]) {
        expect(
          () => P2Witness.decompile(hexToBytes(bad)),
          throwsA(isA<NoProgramMatch>()),
          reason: bad,
        );
      }
    });

    test("fromAsm() fail", () {
      for (final bad in [
        "0 ff",
        "0",
        "0 0",
        shortBytes,
        "11 $shortBytes",
        "0 $shortBytes 0",
        "0 ${longBytes}00",
        "-1 $longBytes",
      ]) {
        expect(() => P2Witness.fromAsm(bad), throwsA(isA<NoProgramMatch>()));
      }
    });

    test("fromData() fail", () {
      expectFail(int version, String program) {
        expect(
          () => P2Witness.fromData(version, hexToBytes(program)),
          throwsArgumentError,
        );
      }
      expectFail(-1, shortBytes);
      expectFail(17, shortBytes);
      expectFail(0, "00");
      expectFail(0, "${longBytes}00");
    });

    test(".data is copied and cannot be mutated", () {
      final prog = hexToBytes("0000");
      final witness = P2Witness.fromData(16, prog);
      witness.data[0] = 0xff;
      prog[1] = 0xff;
      expect(bytesToHex(witness.data), "0000");
    });

  });

}
