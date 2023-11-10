import 'dart:typed_data';
import 'package:coinlib/src/common/hex.dart';

import 'checks.dart';

/// Thrown when attempting to read or write beyond the boundary of data
class OutOfData implements Exception {
  final int position;
  final int readLength;
  final int bytesLength;
  OutOfData(this.position, this.readLength, this.bytesLength);
  @override
  String toString()
    => "Cannot read $readLength bytes at position $position for bytes with "
    "length $bytesLength";
}

abstract class _ReadWriteBase {

  int offset;
  final ByteData bytes;

  _ReadWriteBase(Uint8List bytes, [this.offset = 0])
      : bytes = bytes.buffer.asByteData();

  T _requireBytes<T>(int n, T Function() f) {
    if (offset+n > bytes.lengthInBytes) {
      throw OutOfData(offset, n, bytes.lengthInBytes);
    }
    return f();
  }

  bool get atEnd => offset == bytes.lengthInBytes;

}

/// Reads serialized data from a Uint8List. Throws an [OutOfData] exception if
/// there is not enough data to read. If there is an error, the offset may be
/// different than before.
class BytesReader extends _ReadWriteBase {

  BytesReader(super.bytes, [super.offset = 0]);

  int readUInt8() => _requireBytes(1, () => bytes.getUint8(offset++));
  int readUInt16() => _requireBytes(
    2, () => bytes.getUint16((offset += 2) - 2, Endian.little),
  );
  int readUInt32() => _requireBytes(
    4, () => bytes.getUint32((offset += 4) - 4, Endian.little),
  );
  int readInt32() => _requireBytes(
    4, () => bytes.getInt32((offset += 4) - 4, Endian.little),
  );

  /// Returns a BigInt to ensure that a full 64 unsigned bits are represented.
  /// Web targets do not have enough precision and native ints are signed.
  BigInt readUInt64() => _requireBytes(
    8, () => BigInt.from(readUInt32()) | (BigInt.from(readUInt32()) << 32),
  );

  /// Reads [n] bytes
  Uint8List readSlice(int n) => _requireBytes(
    n, () => Uint8List.fromList(bytes.buffer.asUint8List((offset += n) - n, n)),
  );

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
  void writeUInt8(int i);
  void writeUInt16(int i);
  void writeUInt32(int i);
  void writeInt32(int i);
  /// A [BigInt] is necessary to encode large 64-bit integers due to limits on
  /// the size of Javascript integers
  void writeUInt64(BigInt i);
  void writeSlice(Uint8List slice);
  void writeVarInt(BigInt i);

  /// Writes bytes with the length encoded as a varint
  void writeVarSlice(Uint8List slice) {
    writeVarInt(BigInt.from(slice.length));
    writeSlice(slice);
  }

  /// Writes a list of Uint8List bytes with the length of the vector given by a
  /// varint.
  void writeVector(List<Uint8List> vector) {
    writeVarInt(BigInt.from(vector.length));
    for (final bytes in vector) {
      writeVarSlice(bytes);
    }
  }

}

/// Writes serialized data to a Uint8List. Throws an [OutOfData] exception if
/// there is not enough space in the bytes to write to.
class BytesWriter extends _ReadWriteBase with Writer {

  BytesWriter(super.bytes, [super.offset = 0]);

  @override
  writeUInt8(int i) {
    checkUint8(i);
    _requireBytes(1, () => bytes.setUint8(offset++, i));
  }

  @override
  writeUInt16(int i) {
    checkUint16(i);
    _requireBytes(
      2, () => bytes.setUint16((offset += 2) - 2, i, Endian.little),
    );
  }

  @override
  writeUInt32(int i) {
    checkUint32(i);
    _requireBytes(
      4, () => bytes.setUint32((offset += 4) - 4, i, Endian.little),
    );
  }

  @override
  writeInt32(int i) {
    checkInt32(i);
    _requireBytes(
      4, () => bytes.setInt32((offset += 4) - 4, i, Endian.little),
    );
  }

  @override
  writeUInt64(BigInt i) {
    checkUint64(i);
    _requireBytes(
      8, () {
        writeUInt32(i.toUnsigned(32).toInt());
        writeUInt32((i >> 32).toUnsigned(32).toInt());
      },
    );
  }

  @override
  /// Writes an expected number of bytes without any varint
  writeSlice(Uint8List slice) => _requireBytes(
    slice.length, () {
      bytes.buffer.asUint8List().setAll(offset, slice);
      offset += slice.length;
    },
  );

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

  static int varIntSizeOf(BigInt i) {
    if (i.compareTo(BigInt.from(0xfd)) < 0) return 1;
    if (i.compareTo(BigInt.from(0xffff)) <= 0) return 3;
    if (i.compareTo(BigInt.from(0xffffffff)) <= 0) return 5;
    return 9;
  }
  static int varIntSizeOfInt(int i) => varIntSizeOf(BigInt.from(i));

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
  writeVarInt(BigInt i) => size += varIntSizeOf(i);

}

/// Classes that use this mixin are serializable to a [Writer] via [write] and
/// return cached bytes via [toBytes]. These classes should be immutable as the
/// bytes are written to only once.
mixin Writable {

  Uint8List? _cache;
  int? _sizeCache;

  /// Override to write data into [writer]
  void write(Writer writer);

  /// Obtains a cached [Uint8List] with data serialized for this object
  Uint8List toBytes() {
    if (_cache != null) return _cache!;
    final bytes = Uint8List(size);
    final writer = BytesWriter(bytes);
    write(writer);
    _sizeCache = bytes.length;
    return _cache = bytes;
  }

  String toHex() => bytesToHex(toBytes());

  /// Obtains the cached size of the object
  int get size {
    if (_sizeCache != null) return _sizeCache!;
    final measure = MeasureWriter();
    write(measure);
    return _sizeCache = measure.size;
  }

}
