import 'dart:typed_data';
import 'package:coinlib/src/common/hex.dart';
import 'package:test/test.dart';
import 'package:coinlib/coinlib.dart';

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

  // Push data
  OperationVector(
    inputAsm: "11",
    inputHex: "0111",
    isPush: true,
    number: 17,
  ),
  OperationVector(
    inputAsm: "ffffffff",
    inputHex: "04ffffffff",
    isPush: true,
    number: 0xffffffff,
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
    outputAsm: "0f000000",
    inputHex: "040f000000",
    isPush: true,
    number: 15,
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

  // Push nothing treated as zero
  OperationVector(
    inputHex: "4c00",
    outputHex: "00",
    outputAsm: "0",
    isPush: true,
    number: 0,
  ),
  OperationVector(
    inputHex: "4e00000000",
    outputHex: "00",
    outputAsm: "0",
    isPush: true,
    number: 0,
  ),

  // Unknown op code
  OperationVector(inputHex: "ba", outputAsm: "OP_UNKNOWN", isPush: false),

];

void main() {

  group("ScriptOp", () {

    test("valid operations", () {

      for (final vec in vectors) {

        expectScriptOp(ScriptOp op) {
          expect(op, vec.isPush ? isA<ScriptPushData>() : isA<ScriptOpCode>());
          expect(op.asm, vec.outputAsm ?? vec.inputAsm);
          expect(bytesToHex(op.compiled), vec.outputHex ?? vec.inputHex);
          expect(op.number, vec.number);
        }

        if (vec.inputAsm != null) expectScriptOp(ScriptOp.fromAsm(vec.inputAsm!));
        expectScriptOp(ScriptOp.fromReader(BytesReader(hexToBytes(vec.inputHex))));
        if (vec.number != null && !vec.isPush) {
          expectScriptOp(ScriptOp.fromNumber(vec.number!));
        }

      }

    });

    test("invalid ASM", () {

      for (final invalid in [
        "", "OP_NOTACODE", "OP_0 OP_1", "op_1", "OP_dup", "invalid", "-2",
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
          BytesReader(compiled),
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

  });

}

