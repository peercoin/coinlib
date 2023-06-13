import 'dart:typed_data';
import 'package:coinlib/src/common/hex.dart';
import 'package:coinlib/src/common/serial.dart';
import 'codes.dart';

class InvalidScriptAsm implements Exception {}
class PushDataNotMinimal implements Exception {}

/// Represents a single operation or script pushdata
abstract class ScriptOp {

  static int op1Negate = scriptOpNameToCode["1NEGATE"]!;
  static int op1 = scriptOpNameToCode["1"]!;
  static int op16 = scriptOpNameToCode["16"]!;
  static int pushData1 = scriptOpNameToCode["PUSHDATA1"]!;
  static int pushData2 = pushData1+1;
  static int pushData4 = pushData2+1;

  /// The compiled bytes for this operation
  Uint8List get compiled;
  /// The ASM string representation of this operation
  String get asm;
  /// Returns an integer if the operation pushes a number, or null
  int? get number;

  /// Interpret a single script ASM string into a [ScriptOp].
  factory ScriptOp.fromAsm(String asm) {

    if (asm.isEmpty) throw InvalidScriptAsm();

    // If it starts with OP_, then it is an opcode
    if (asm.startsWith("OP_")) {

      final code = scriptOpNameToCode[asm.substring(3)];
      if (code == null) throw InvalidScriptAsm();

      // Do not allow push data opcodes
      if (code >= pushData1 && code <= pushData4) throw InvalidScriptAsm();

      return ScriptOpCode(code);

    }

    // If "-1" or "81", then it is a 1NEGATE op code
    if (asm == "-1" || asm == "81") return ScriptOpCode(op1Negate);

    // If "80" then it is zero
    if (asm == "80") return ScriptOpCode(0);

    // Otherwise assume hex. Provide opcode if available or else pushdata

    late Uint8List bytes;
    try {
      bytes = hexToBytes(asm);
    } on FormatException {
      throw InvalidScriptAsm();
    }

    return bytes.length == 1 ? ScriptOp.fromNumber(bytes[0]) : ScriptPushData(bytes);

  }

  /// Reads a single operation from a [BytesReader]. [OutOfData] will be thrown
  /// if there is not enough data to read.
  /// If [requireMinimal] is true, a pushdata operation must be encoded
  /// minimally or else [PushDataNotMinimal] will be thrown.
  factory ScriptOp.fromReader(
    BytesReader reader, { bool requireMinimal = false, }
  ) {

    final code = reader.readUInt8();

    int readN = -1;

    // Push n=code bytes
    if (code > 0 && code < pushData1) readN = code;
    if (code == pushData1) readN = reader.readUInt8();
    if (code == pushData2) readN = reader.readUInt16();
    if (code == pushData4) readN = reader.readUInt32();

    // If not push data, then opcode
    if (readN == -1) return ScriptOpCode(code);

    if (requireMinimal) {
      // Push data opcode should be minimal for length
      if (code == pushData1 && readN < pushData1) throw PushDataNotMinimal();
      if (code == pushData2 && readN <= 0xff) throw PushDataNotMinimal();
      if (code == pushData4 && readN <= 0xffff) throw PushDataNotMinimal();
    }

    // If pushdata is empty, return 0 opcode. If it is one byte between 0-16,
    // return numerical opcode. If it is 0x81, then OP_1NEGATE.

    final bytes = reader.readSlice(readN);

    if (bytes.isEmpty) return ScriptOpCode(0);

    if (bytes.length == 1) {
      final n = bytes[0];
      if (requireMinimal && (n == 0x81 || n == 0x80 || n <= 16)) {
        throw PushDataNotMinimal();
      }
      if (n == 0 || n == 0x80) return ScriptOpCode(0);
      if (n <= 16) return ScriptOpCode(n + op1 - 1);
      if (n == 0x81) return ScriptOpCode(op1Negate);
    }

    return ScriptPushData(bytes);

  }

  /// Constructs an [ScriptOp] from a number, returning the smallest
  /// representation
  factory ScriptOp.fromNumber(int n) {

    if (n < -1 || n > 0xffffffff) {
      throw ArgumentError.value(n, "n", "out of range");
    }

    if (n == -1) return ScriptOpCode(op1Negate);
    if (n == 0) return ScriptOpCode(0);
    if (n >= 1 && n <= 16) return ScriptOpCode(n + op1 - 1);

    final bytes = [n];
    if (n > 0xff) bytes.add(n >> 8);
    if (n > 0xffff) bytes.add(n >> 16);
    if (n > 0xffffff) bytes.add(n >> 24);
    return ScriptPushData(Uint8List.fromList(bytes));

  }

}

/// Represents a [ScriptOp] that is an op code
class ScriptOpCode implements ScriptOp {

  final int code;
  ScriptOpCode(this.code);

  @override
  Uint8List get compiled => Uint8List.fromList([code]);

  @override
  String get asm {
    // If numerical: return -1 if OP_1NEGATE, 0 if zero, or hex
    final n = number;
    if (n == 0) return "0";
    if (n == -1) return "-1";
    if (n != null) return n.toRadixString(16).padLeft(2, "0");
    // All other opcodes given by name
    return "OP_${scriptOpCodeToName[code] ?? "UNKNOWN"}";
  }

  @override
  int? get number {
    if (code == 0) return 0;
    if (code == ScriptOp.op1Negate) return -1;
    if (code >= ScriptOp.op1 && code <= ScriptOp.op16) {
      return code - ScriptOp.op1 + 1;
    }
    return null;
  }

}

/// Represents a [ScriptOp] that is a pushdata
class ScriptPushData implements ScriptOp {

  final Uint8List _data;

  ScriptPushData(this._data);

  List<int> _compiledList() {

    // Compress down to numerical opcode
    if (_data.length == 1) {
      final val = _data[0];
      if (val == 0) return [0];
      if (val >= 1 && val <= 16) return [ScriptOp.op1 + val - 1];
    }

    if (_data.length < ScriptOp.pushData1) {
      return [_data.length, ..._data];
    }

    if (_data.length <= 0xff) {
      return [ScriptOp.pushData1, _data.length, ..._data];
    }

    if (_data.length <= 0xffff) {
      return [ScriptOp.pushData2, _data.length, _data.length >> 8, ..._data];
    }

    return [
      ScriptOp.pushData4,
      _data.length,
      _data.length >> 8,
      _data.length >> 16,
      _data.length >> 24,
      ..._data,
    ];

  }

  @override
  Uint8List get compiled => Uint8List.fromList(_compiledList());

  @override
  String get asm {
    // Zero condition
    if (_data.isEmpty || (_data.length == 1 && _data[0] == 0)) return "0";
    // -1 condition
    if (_data.length == 1 && _data[0] == 0x81) return "-1";
    // Everything else, including integers as little-endian hex
    return bytesToHex(_data);
  }

  @override
  int? get number {

    // Only number if no more than 4 bytes
    if (_data.length > 4) return null;

    if (_data.isEmpty) return 0;

    // Calculate negative numbers as done by Peercoin
    final isNeg = (_data.last & 0x80) == 0x80;

    // Absolute number with sign bit removed
    final abs = (
      _data[0]
      | (_data.length > 1 ? _data[1] << 8 : 0)
      | (_data.length > 2 ? _data[2] << 16 : 0)
      | (_data.length > 3 ? _data[3] << 24 : 0)
    // Remove sign bit
    ) & 0x7fffffff >> (8*(4-_data.length));

    return isNeg ? -abs : abs;

  }

  /// Returns a copy of the push data
  Uint8List get data => Uint8List.fromList(_data);

}
