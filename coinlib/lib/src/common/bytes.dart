import 'dart:typed_data';
import 'package:collection/collection.dart';
import 'hex.dart';

_copyCheckBytes(List<int> bytes, int length) {
  if (bytes.length != length) {
    throw ArgumentError("Hash should be $length bytes", "bytes");
  }
  return Uint8List.fromList(bytes);
}

// Encapsulates a [Uint8List] that must be of a certain length and can be
// directly compared for equality.
abstract class FixedBytes {

  final Uint8List u8List;

  FixedBytes.fromList(List<int> list, int requiredLen)
    : u8List = _copyCheckBytes(list, requiredLen);

  FixedBytes.fromHex(String hex, int requiredLen)
    : this.fromList(hexToBytes(hex), requiredLen);

  @override
  bool operator ==(Object other)
    => (other is FixedBytes) && ListEquality().equals(u8List, other.u8List);

  @override
  int get hashCode => u8List[1] | u8List[2] << 8 | u8List[3] << 16 | u8List[4] << 24;

}

/// Encapsulates 32 bytes
class Bytes32 extends FixedBytes {
  Bytes32.fromList(List<int> list) : super.fromList(list, 32);
  Bytes32.fromHex(String hex) : super.fromHex(hex, 32);
}

/// Encapsulates 20 bytes
class Bytes20 extends FixedBytes {
  Bytes20.fromList(List<int> list) : super.fromList(list, 20);
  Bytes20.fromHex(String hex) : super.fromHex(hex, 20);
}
