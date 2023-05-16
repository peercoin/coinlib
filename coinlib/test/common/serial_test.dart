import 'dart:typed_data';

import 'package:coinlib/coinlib.dart';
import 'package:coinlib/src/common/hex.dart';
import 'package:test/test.dart';

void main() {

  final txData = hexToBytes(
    // 3 unused bytes
    "010203"
    "0100000000010133defbe3e28860007ff3e21222774c220cb35d554fa3e3796d25bf8ee983e1080000000000ffffffff0160ea0000000000001976a914851a33a5ef0d4279bd5854949174e2c65b1d450088ac0248304502210097c3006f0b390982eb47f762b2853773c6cedf83668a22d710f4c13c4fd6b15502205e26ef16a81fc818a37f3a34fc6d0700e61100ea6c6773907c9c046042c440340121038de63cf582d058a399a176825c045672d5ff8ea25b64d28d4375dcdb14c02b2b00000000",
  );

  final prevOutHash = hexToBytes(
    "33defbe3e28860007ff3e21222774c220cb35d554fa3e3796d25bf8ee983e108",
  );
  final outScript = hexToBytes(
    "76a914851a33a5ef0d4279bd5854949174e2c65b1d450088ac",
  );
  final outValue = BigInt.from(60000);
  final witness = [
    hexToBytes("304502210097c3006f0b390982eb47f762b2853773c6cedf83668a22d710f4c13c4fd6b15502205e26ef16a81fc818a37f3a34fc6d0700e61100ea6c6773907c9c046042c4403401"),
    hexToBytes("038de63cf582d058a399a176825c045672d5ff8ea25b64d28d4375dcdb14c02b2b"),
  ];

  group("BytesReader", () {

    test("can read tx", () {

      final reader = BytesReader(txData, 3);

      expect(reader.atEnd, false);

      // Version and flag
      expect(reader.readInt32(), 1);
      expect(reader.readUInt16(), 0x0100);

      // Input
      expect(reader.readVarInt(), BigInt.one);
      expect(reader.readSlice(32), prevOutHash);
      expect(reader.readUInt32(), 0);
      expect(reader.readVarSlice(), []);
      expect(reader.readUInt32(), 0xffffffff);

      // Output
      expect(reader.readVarInt(), BigInt.one);
      expect(reader.readUInt64(), outValue);
      expect(reader.readVarSlice(), outScript);

      // Witness
      expect(reader.readVector(), witness);

      // Locktime
      expect(reader.atEnd, false);
      expect(reader.readUInt32(), 0);

      expect(reader.atEnd, true);

    });

    test("provides error if insufficient data", () {

      expectRangeError(String hex, void Function(BytesReader) f) {
        final reader = BytesReader(hexToBytes(hex));
        expect(() => f(reader), throwsA(isA<RangeError>()));
      }

      expectRangeError("010203", (r) => r.readSlice(4));
      expectRangeError("fd01", (r) => r.readVarInt());
      expectRangeError("030102", (r) => r.readVarSlice());
      expectRangeError("030102020102", (r) => r.readVector());

    });

    expectBigInt(String hex, BigInt Function(BytesReader) f, String intHex) {
      final reader = BytesReader(hexToBytes(hex));
      expect(f(reader), BigInt.parse(intHex, radix: 16));
      expect(reader.atEnd, true);
    }

    test("can read large uint64", () {
      expectBigInt(
        "0102030405060708",
        (r) => r.readUInt64(),
        "0807060504030201",
      );
    });

    test("can read varints", () {

      expectVarInt(String hex, String intHex)
        => expectBigInt(hex, (r) => r.readVarInt(), intHex);

      expectVarInt("fc", "fc");
      expectVarInt("fd0102", "0201");
      expectVarInt("fe01020304", "04030201");
      expectVarInt("ff0102030405060708", "0807060504030201");

    });

  });

  writeTx(Writer writer) {

    // Version and flag
    writer.writeInt32(1);
    writer.writeUInt16(0x0100);

    // Input
    writer.writeVarInt(BigInt.one);
    writer.writeSlice(prevOutHash);
    writer.writeUInt32(0);
    writer.writeVarSlice(Uint8List(0));
    writer.writeUInt32(0xffffffff);

    // Output
    writer.writeVarInt(BigInt.one);
    writer.writeUInt64(outValue);
    writer.writeVarSlice(outScript);

    // Witness
    writer.writeVector(witness);

    // Locktime
    if (writer is BytesWriter) {
      expect(writer.atEnd, false);
    }
    writer.writeUInt32(0);

  }

  group("BytesWriter", () {

    test("can write tx", () {

      final data = Uint8List(195+3);
      data[0] = 1;
      data[1] = 2;
      data[2] = 3;
      final writer = BytesWriter(data, 3);

      expect(writer.atEnd, false);
      writeTx(writer);
      expect(writer.atEnd, true);

      expect(data, txData);

    });

    expectWrite(int length, void Function(BytesWriter) f, String expected) {
      final data = Uint8List(length);
      final writer = BytesWriter(data);
      f(writer);
      expect(bytesToHex(data), expected);
    }

    test("can write large uint64", () {
      expectWrite(
        8,
        (r) => r.writeUInt64(BigInt.parse("0807060504030201", radix: 16)),
        "0102030405060708",
      );
    });

    test("can write varints", () {

      expectWriteVarInt(String intHex, String expected) => expectWrite(
        expected.length ~/ 2,
        (r) => r.writeVarInt(BigInt.parse(intHex, radix: 16)),
        expected,
      );

      expectWriteVarInt("fc", "fc");
      expectWriteVarInt("0201", "fd0102");
      expectWriteVarInt("04030201", "fe01020304");
      expectWriteVarInt("0807060504030201", "ff0102030405060708");

    });

  });

  group("MeasureWriter", () {

    test("can measure tx", () {
      final measure = MeasureWriter();
      expect(measure.size, 0);
      writeTx(measure);
      expect(measure.size, 195);
    });

    test("can measure varints", () {

      expectVarIntMeasure(String intHex, int length) {
        final measure = MeasureWriter();
        measure.writeVarInt(BigInt.parse(intHex, radix: 16));
        expect(measure.size, length);
      }

      expectVarIntMeasure("fc", 1);
      expectVarIntMeasure("0201", 3);
      expectVarIntMeasure("04030201", 5);
      expectVarIntMeasure("0807060504030201", 9);

    });

  });

}
