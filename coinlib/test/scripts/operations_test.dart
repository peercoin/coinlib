import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:coinlib/coinlib.dart';
import '../vectors/keys.dart';
import '../vectors/signatures.dart';
import 'common.dart';

class OperationVector {
  final String? inputAsm;
  final String inputHex;
  final bool isPush;
  final String? outputAsm;
  final String? outputHex;
  final int? number;
  OperationVector({
    this.inputAsm,
    required this.inputHex,
    required this.isPush,
    this.outputAsm,
    this.outputHex,
    this.number,
  });
}

final vectors = [

  // Basic numbers
  OperationVector(
    inputAsm: "0",
    inputHex: "00",
    isPush: false,
    number: 0,
  ),
  OperationVector(
    inputAsm: "-1",
    inputHex: "4f",
    isPush: false,
    number: -1,
  ),
  OperationVector(
    inputAsm: "01",
    inputHex: "51",
    isPush: false,
    number: 1,
  ),
  OperationVector(
    inputAsm: "10",
    inputHex: "60",
    isPush: false,
    number: 16,
  ),

  // Opcode
  OperationVector(
    inputAsm: "OP_NOP",
    inputHex: "61",
    isPush: false,
  ),
  OperationVector(
    inputAsm: "OP_INVALIDOPCODE",
    inputHex: "ff",
    isPush: false,
  ),

  // Soft-fork activated opcode
  OperationVector(
    inputAsm: "OP_CHECKLOCKTIMEVERIFY",
    inputHex: "b1",
    isPush: false,
  ),
  OperationVector(
    inputAsm: "OP_NOP2",
    outputAsm: "OP_CHECKLOCKTIMEVERIFY",
    inputHex: "b1",
    isPush: false,
  ),
  OperationVector(
    inputAsm: "OP_CHECKSEQUENCEVERIFY",
    inputHex: "b2",
    isPush: false,
  ),
  OperationVector(
    inputAsm: "OP_NOP3",
    outputAsm: "OP_CHECKSEQUENCEVERIFY",
    inputHex: "b2",
    isPush: false,
  ),

  // Push data
  OperationVector(
    inputAsm: "11",
    inputHex: "0111",
    isPush: true,
    number: 17,
  ),
  OperationVector(
    inputAsm: "0100000000",
    inputHex: "050100000000",
    isPush: true,
  ),
  OperationVector(
    inputAsm: "000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f404142434445464748494a",
    inputHex: "4b000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f404142434445464748494a",
    isPush: true,
  ),
  OperationVector(
    inputAsm: "000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f404142434445464748494a4b",
    inputHex:
    "4c4c000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f404142434445464748494a4b",
    isPush: true,
  ),
  OperationVector(
    inputAsm: "0f000000",
    inputHex: "040f000000",
    isPush: true,
    number: 15,
  ),
  OperationVector(
    inputAsm: "0000",
    inputHex: "020000",
    isPush: true,
    number: 0,
  ),

  // Alternative ASM
  OperationVector(
    inputAsm: "00",
    outputAsm: "0",
    inputHex: "00",
    isPush: false,
    number: 0,
  ),
  OperationVector(
    inputAsm: "f",
    outputAsm: "0f",
    inputHex: "5f",
    isPush: false,
    number: 15,
  ),
  OperationVector(
    inputAsm: "OP_1NEGATE",
    outputAsm: "-1",
    inputHex: "4f",
    isPush: false,
    number: -1,
  ),
  OperationVector(
    inputAsm: "OP_0",
    outputAsm: "0",
    inputHex: "00",
    isPush: false,
    number: 0,
  ),
  OperationVector(
    inputAsm: "OP_16",
    outputAsm: "10",
    inputHex: "60",
    isPush: false,
    number: 16,
  ),
  OperationVector(
    inputAsm: "OP_1",
    outputAsm: "01",
    inputHex: "51",
    isPush: false,
    number: 1,
  ),
  OperationVector(
    inputAsm: "OP_TRUE",
    outputAsm: "01",
    inputHex: "51",
    isPush: false,
    number: 1,
  ),
  OperationVector(
    inputAsm: "100000000",
    outputAsm: "0100000000",
    inputHex: "050100000000",
    isPush: true,
  ),

  // Non-compressed hex input
  OperationVector(
    inputHex: "4e050000000102030405",
    outputHex: "050102030405",
    outputAsm: "0102030405",
    isPush: true,
  ),
  OperationVector(
    inputHex: "0100",
    outputHex: "00",
    outputAsm: "0",
    isPush: false,
    number: 0,
  ),
  OperationVector(
    inputHex: "0110",
    outputHex: "60",
    outputAsm: "10",
    isPush: false,
    number: 16,
  ),
  OperationVector(
    inputHex: "4c0111",
    outputHex: "0111",
    outputAsm: "11",
    isPush: true,
    number: 17,
  ),

  // Push nothing treated as zero
  OperationVector(
    inputHex: "4c00",
    outputHex: "00",
    outputAsm: "0",
    isPush: false,
    number: 0,
  ),
  OperationVector(
    inputHex: "4e00000000",
    outputHex: "00",
    outputAsm: "0",
    isPush: false,
    number: 0,
  ),

  // Leading significant bit determines sign of number
  OperationVector(
    inputAsm: "80",
    outputAsm: "0",
    inputHex: "0180",
    outputHex: "00",
    isPush: false,
    number: 0,
  ),
  OperationVector(
    inputAsm: "82",
    inputHex: "0182",
    isPush: true,
    number: -2,
  ),
  OperationVector(
    inputAsm: "ff",
    inputHex: "01ff",
    isPush: true,
    number: -127,
  ),
  OperationVector(
    inputAsm: "ffffffff",
    inputHex: "04ffffffff",
    isPush: true,
    number: -2147483647,
  ),
  OperationVector(
    inputAsm: "ff000080",
    inputHex: "04ff000080",
    isPush: true,
    number: -255,
  ),
  OperationVector(
    inputAsm: "01000080",
    inputHex: "0401000080",
    isPush: true,
    number: -1,
  ),

  // 0x81 should be OP_1NEGATE
  OperationVector(
    inputAsm: "81",
    outputAsm: "-1",
    inputHex: "0181",
    outputHex: "4f",
    isPush: false,
    number: -1,
  ),

  // New Tapscript op code
  OperationVector(inputHex: "ba", outputAsm: "OP_CHECKSIGADD", isPush: false),

  // Unknown op code
  OperationVector(inputHex: "bb", outputAsm: "OP_UNKNOWN", isPush: false),

];

void main() {

  group("ScriptOp", () {

    test("valid operations", () {

      for (final vec in vectors) {

        expectScriptOpVec(ScriptOp op) {
          expectScriptOp(
            op,
            vec.outputAsm ?? vec.inputAsm!,
            vec.outputHex ?? vec.inputHex,
            vec.number,
            vec.isPush,
          );
        }

        if (vec.inputAsm != null) expectScriptOpVec(ScriptOp.fromAsm(vec.inputAsm!));
        expectScriptOpVec(ScriptOp.fromReader(BytesReader(hexToBytes(vec.inputHex))));
        if (vec.number != null && !vec.isPush) {
          expectScriptOpVec(ScriptOp.fromNumber(vec.number!));
        }

      }

    });

    test("invalid ASM", () {

      for (final invalid in [
        "", "OP_NOTACODE", "OP_0 OP_1", "op_1", "OP_dup", "invalid", "-2",
        "OP_DUPP",
      ]) {
        expect(
          () => ScriptOp.fromAsm(invalid),
          throwsA(isA<InvalidScriptAsm>()),
          reason: invalid,
        );
      }

    });

    test("fromReader() long pushdata", () {

      expectLongPush(int length, List<int> compilePrefix) {

        final bytes = Uint8List.fromList(List<int>.generate(length, (i) => i));
        final compiled = Uint8List.fromList([...compilePrefix, ...bytes]);

        final fromReader = ScriptOp.fromReader(
          BytesReader(compiled), requireMinimal: true,
        ) as ScriptPushData;
        final direct = ScriptPushData(bytes);

        for (final op in [fromReader, direct]) {
          expect(op.compiled, compiled);
          expect(op.asm, bytesToHex(bytes));
          expect(op.data, bytes);
        }

      }

      expectLongPush(0x100, [0x4d, 0x00, 0x01]);
      expectLongPush(0x10000, [0x4e, 0x00, 0x00, 0x01, 0x00]);

    });

    test("invalid number", () {
      for (final invalid in [-2, 0x100000000]) {
        expect(() => ScriptOp.fromNumber(invalid), throwsArgumentError);
      }
    });

  });

  group("ScriptOpCode()", () {

    test("match() matches identical op codes", () {
      expect(ScriptOp.fromAsm("0").match(ScriptOp.fromAsm("00")), true);
      expect(ScriptOpCode(0x87).match(ScriptOpCode(0x87)), true);
      expect(
        ScriptOp.fromReader(BytesReader(hexToBytes("52")))
        .match(ScriptOpCode(0x52)),
        true,
      );
    });

    test("match() returns false for non-identical op-codes", () {
      expect(ScriptOpCode(0).match(ScriptPushData(hexToBytes("00"))), false);
      expect(ScriptOpCode(0).match(ScriptOpCode(1)), false);
    });

  });

  group("ScriptPushData()", () {

    setUpAll(loadCoinlib);

    test("pushdata compresses to op-code", () {
      expectScriptOp(ScriptPushData(Uint8List(0)), "0", "00", 0, true);
      expectScriptOp(ScriptPushData(hexToBytes("00")), "0", "00", 0, true);
      expectScriptOp(ScriptPushData(hexToBytes("10")), "10", "60", 16, true);
      // No compression with two bytes
      expectScriptOp(
        ScriptPushData(hexToBytes("0000")), "0000", "020000", 0, true,
      );
    });

    test("pushdata is copied", () {
      final data = Uint8List(2);
      final pushdata = ScriptPushData(data);
      pushdata.data[0] = 0xff;
      data[1] = 0xff;
      expect(pushdata.data, Uint8List(2));
    });

    test("require minimal pushdata", () {

      for (final ok in [
        "00", "0111", "60", "4f",
        "4b000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f404142434445464748494a",
        "4c4c000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f404142434445464748494a4b",
      ]) {
        expect(
          ScriptOp.fromReader(BytesReader(hexToBytes(ok)), requireMinimal: true),
          isA<ScriptOp>(),
        );
      }

      for (final bad in [
        // Incorrect for 0
        "0100", "4c00", "0180",
        // Incorrect for 16
        "0110",
        // Incorrect for 1NEGATE
        "0181",
        // PUSHDATA1 when 0x4b suffices
        "4c4b000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f404142434445464748494a",
        // PUSHDATA2 used when PUSHDATA1 suffices
        "4dff00000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f404142434445464748494a4b4c4d4e4f505152535455565758595a5b5c5d5e5f606162636465666768696a6b6c6d6e6f707172737475767778797a7b7c7d7e7f808182838485868788898a8b8c8d8e8f909192939495969798999a9b9c9d9e9fa0a1a2a3a4a5a6a7a8a9aaabacadaeafb0b1b2b3b4b5b6b7b8b9babbbcbdbebfc0c1c2c3c4c5c6c7c8c9cacbcccdcecfd0d1d2d3d4d5d6d7d8d9dadbdcdddedfe0e1e2e3e4e5e6e7e8e9eaebecedeeeff0f1f2f3f4f5f6f7f8f9fafbfcfdfe",
        // PUSHDATA4 when PUSHDATA2 suffices
        "4e00010000000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f404142434445464748494a4b4c4d4e4f505152535455565758595a5b5c5d5e5f606162636465666768696a6b6c6d6e6f707172737475767778797a7b7c7d7e7f808182838485868788898a8b8c8d8e8f909192939495969798999a9b9c9d9e9fa0a1a2a3a4a5a6a7a8a9aaabacadaeafb0b1b2b3b4b5b6b7b8b9babbbcbdbebfc0c1c2c3c4c5c6c7c8c9cacbcccdcecfd0d1d2d3d4d5d6d7d8d9dadbdcdddedfe0e1e2e3e4e5e6e7e8e9eaebecedeeeff0f1f2f3f4f5f6f7f8f9fafbfcfdfeff",
      ]) {
        expect(
          () => ScriptOp.fromReader(BytesReader(hexToBytes(bad)), requireMinimal: true),
          throwsA(isA<PushDataNotMinimal>()),
          reason: bad,
        );
      }

    });

    final matchHex = "01020304";
    final matchOp = ScriptPushData(hexToBytes(matchHex));

    test("match() returns true", () {
      expect(matchOp.match(matchOp), true);
      expect(matchOp.match(ScriptPushData(hexToBytes(matchHex))), true);
      expect(matchOp.match(ScriptPushDataMatcher(4)), true);
    });

    test("match() returns false", () {
      expect(
        ScriptPushData(hexToBytes("0100"))
        .match(ScriptOp.fromNumber(1)),
        false,
      );
      expect(matchOp.match(ScriptPushDataMatcher(3)), false);
      expect(matchOp.match(ScriptPushDataMatcher(5)), false);
      expect(matchOp.match(ScriptPushData(hexToBytes("01020303"))), false);
    });

    test("provides ecdsaSig", () {
      final der = hexToBytes(validDerSigs[0]);
      final bytes = Uint8List.fromList([ ...der, SigHashType.all().value]);
      final insig = ScriptPushData(bytes).ecdsaSig;
      expect(insig, isNotNull);
      expect(insig!.signature.der, der);
      expect(insig.hashType.all, true);
    });

    test("provides schnorrSig", () {
      final sig = hexToBytes(validSchnorrSig);
      final insig = ScriptPushData(sig).schnorrSig;
      expect(insig, isNotNull);
      expect(insig!.signature.data, sig);
      expect(insig.hashType, SigHashType.schnorrDefault());
    });

    test("provides public key", () {
      final bytes = hexToBytes(pubkeyVec);
      final pk = ScriptPushData(bytes).publicKey;
      expect(pk, isNotNull);
      expect(pk!.hex, pubkeyVec);
    });

  });

  group("ScriptPushDataMatcher()", () {

    final matcher = ScriptPushDataMatcher(3);

    test("match() returns true", () {
      expect(matcher.match(ScriptPushData(Uint8List(3))), true);
      expect(matcher.match(ScriptPushData(hexToBytes("ffffff"))), true);
      expect(matcher.match(ScriptPushDataMatcher(3)), true);
    });

    test("match() returns false", () {
      expect(matcher.match(ScriptPushData(Uint8List(2))), false);
      expect(matcher.match(ScriptPushData(Uint8List(4))), false);
      expect(matcher.match(ScriptPushDataMatcher(2)), false);
      expect(matcher.match(ScriptPushDataMatcher(4)), false);
      expect(matcher.match(ScriptOpCode(0)), false);
    });

    test("asm shows number of bytes", () => expect(matcher.asm, "<3-bytes>"));
    test(
      "compiled gives empty push",
      () => expect(bytesToHex(matcher.compiled), "03000000"),
    );

    test("constructed from asm", () {
      final matcher = ScriptOp.fromAsm("<30-bytes>");
      expect(matcher, isA<ScriptPushDataMatcher>());
      expect(matcher.asm, "<30-bytes>");
      expect(
        matcher.compiled,
        Uint8List.fromList([30, ...List<int>.filled(30, 0)]),
      );
      expect((matcher as ScriptPushDataMatcher).size, 30);
    });

    test("doesn't allow bytes of 0 or over 0xffffffff", () {
      expect(
        () => ScriptOp.fromAsm("<0-bytes>"),
        throwsA(isA<InvalidScriptAsm>()),
      );
      expect(
        () => ScriptOp.fromAsm("<4294967296-bytes>"),
        throwsA(isA<InvalidScriptAsm>()),
      );
      expect(
        () => ScriptOp.fromAsm("<18446744073709551616-bytes>"),
        throwsA(isA<InvalidScriptAsm>()),
      );
      expect(() => ScriptPushDataMatcher(0), throwsArgumentError);
      expect(() => ScriptPushDataMatcher(0x100000000), throwsArgumentError);
    });

  });

}
