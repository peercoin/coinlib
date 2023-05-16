import 'dart:typed_data';

abstract class _ReadWriteBase {
  int offset;
  final ByteData bytes;
  _ReadWriteBase(Uint8List bytes, [this.offset = 0])
      : bytes = bytes.buffer.asByteData();
  bool get atEnd => offset == bytes.lengthInBytes;
}

/// Reads serialized data from a Uint8List. Will throw a [RangeError] if there
/// is not enough data to read. If there is an error, the offset may be
/// different than before.
class BytesReader extends _ReadWriteBase {

  BytesReader(super.bytes, [super.offset = 0]);

  int readUInt8() => bytes.getUint8(offset++);
  int readUInt16() => bytes.getUint16((offset += 2) - 2, Endian.little);
  int readUInt32() => bytes.getUint32((offset += 4) - 4, Endian.little);
  int readInt32() => bytes.getInt32((offset += 4) - 4, Endian.little);

  /// Returns a BigInt to ensure that a full 64 unsigned bits are represented.
  /// Web targets do not have enough precision and native ints are signed.
  BigInt readUInt64() => BigInt.from(readUInt32()) | (BigInt.from(readUInt32()) << 32);

  /// Reads [n] bytes
  Uint8List readSlice(int n)
    => Uint8List.fromList(bytes.buffer.asUint8List((offset += n) - n, n));

  BigInt readVarInt() {

    final first = readUInt8();

    if (first < 0xfd) {
      // 8 bit
      return BigInt.from(first);
    } else if (first == 0xfd) {
      // 16 bit
      return BigInt.from(readUInt16());
    } else if (first == 0xfe) {
      // 32 bit
      return BigInt.from(readUInt32());
    } else {
      // 64 bit
      return readUInt64();
    }

  }

  /// Reads a varint and then returns a number of bytes equal to that varint
  Uint8List readVarSlice() => readSlice(readVarInt().toInt());

  /// Reads a varint that provides the number of slices to read with
  /// [readVarSlice()] and returns then in a list.
  List<Uint8List> readVector()
    => List<Uint8List>.generate(readVarInt().toInt(), (i) => readVarSlice());

}

/// Methods to handle the writing of data
mixin Writer {
  writeUInt8(int i);
  writeUInt16(int i);
  writeUInt32(int i);
  writeInt32(int i);
  /// A [BigInt] is necessary to encode large 64-bit integers due to limits on
  /// the size of Javascript integers
  writeUInt64(BigInt i);
  writeSlice(Uint8List slice);
  writeVarInt(BigInt i);

  /// Writes bytes with the length encoded as a varint
  writeVarSlice(Uint8List slice) {
    writeVarInt(BigInt.from(slice.length));
    writeSlice(slice);
  }

  /// Writes a list of Uint8List bytes with the length of the vector given by a
  /// varint.
  writeVector(List<Uint8List> vector) {
    writeVarInt(BigInt.from(vector.length));
    for (final bytes in vector) {
      writeVarSlice(bytes);
    }
  }

}

/// Writes serialized data to a Uint8List
class BytesWriter extends _ReadWriteBase with Writer {

  BytesWriter(super.bytes, [super.offset = 0]);

  @override
  writeUInt8(int i) => bytes.setUint8(offset++, i);
  @override
  writeUInt16(int i) => bytes.setUint16((offset += 2) - 2, i, Endian.little);
  @override
  writeUInt32(int i) => bytes.setUint32((offset += 4) - 4, i, Endian.little);
  @override
  writeInt32(int i) => bytes.setInt32((offset += 4) - 4, i, Endian.little);
  @override
  writeUInt64(BigInt i) {
    writeUInt32(i.toUnsigned(32).toInt());
    writeUInt32((i >> 32).toUnsigned(32).toInt());
  }

  @override
  /// Writes an expected number of bytes without any varint
  writeSlice(Uint8List slice) {
    bytes.buffer.asUint8List().setAll(offset, slice);
    offset += slice.length;
  }

  @override
  writeVarInt(BigInt i) {
    if (i.compareTo(BigInt.from(0xfd)) < 0) {
      // 8 bit
      writeUInt8(i.toInt());
    } else if (i.compareTo(BigInt.from(0xffff)) <= 0) {
      // 16 bit
      writeUInt8(0xfd);
      writeUInt16(i.toInt());
    } else if (i.compareTo(BigInt.from(0xffffffff)) <= 0) {
      // 32 bit
      writeUInt8(0xfe);
      writeUInt32(i.toInt());
    } else {
      // 64 bit
      writeUInt8(0xff);
      writeUInt64(i);
    }
  }

}

/// Measures the serialized size of data written to it without writing to a
/// Uint8List
class MeasureWriter with Writer {
  int size = 0;
  @override
  writeUInt8(int i) => size++;
  @override
  writeUInt16(int i) => size += 2;
  @override
  writeUInt32(int i) => size += 4;
  @override
  writeInt32(int i) => size += 4;
  @override
  writeUInt64(BigInt i) => size += 8;
  @override
  writeSlice(Uint8List slice) => size += slice.length;
  @override
  writeVarInt(BigInt i) {
    if (i.compareTo(BigInt.from(0xfd)) < 0) {
      size++;
    } else if (i.compareTo(BigInt.from(0xffff)) <= 0) {
      // 16 bit
      size += 3;
    } else if (i.compareTo(BigInt.from(0xffffffff)) <= 0) {
      // 32 bit
      size += 5;
    } else {
      // 64 bit
      size += 9;
    }
  }
}
