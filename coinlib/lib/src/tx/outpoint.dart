import 'dart:typed_data';
import 'package:coinlib/src/common/bytes.dart';
import 'package:coinlib/src/common/checks.dart';
import 'package:coinlib/src/common/hex.dart';
import 'package:coinlib/src/common/serial.dart';
import 'output.dart';

/// Reference to an [Output] by transaction hash and index
class OutPoint with Writable {

  /// Specify no previous output
  static final nothing = OutPoint(Uint8List(32), 0);

  final Uint8List _hash;
  final int n;

  OutPoint(Uint8List hash, this.n)
    : _hash = copyCheckBytes(hash, 32, name: "Tx hash") {
    checkUint32(n, "this.n");
  }

  /// Takes the reversed transaction hash as hex
  OutPoint.fromHex(String hash, int n)
    : this(Uint8List.fromList(hexToBytes(hash).reversed.toList()), n);

  OutPoint.fromReader(BytesReader reader)
    : _hash = reader.readSlice(32), n = reader.readUInt32();

  @override
  void write(Writer writer) {
    writer.writeSlice(_hash);
    writer.writeUInt32(n);
  }

  Uint8List get hash => Uint8List.fromList(_hash);
  /// True if this out point is the type found in a coinbase
  bool get coinbase => _hash.every((e) => e == 0) && n == 0xffffffff;
  bool get isNothing => _hash.every((e) => e == 0) && n == 0;

  @override
  bool operator ==(Object other)
    => (other is OutPoint)
    && bytesEqual(_hash, other._hash)
    && n == other.n;

  @override
  int get hashCode
    => _hash[1] | _hash[2] << 8 | _hash[3] << 16 | _hash[4] << 24 | n;

}
