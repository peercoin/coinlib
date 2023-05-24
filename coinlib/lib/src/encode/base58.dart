import 'dart:typed_data';
import 'package:coinlib/src/crypto/hash.dart';
import 'package:dart_base_x/dart_base_x.dart';

final _codec = BaseXCodec("123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz");

class InvalidBase58 implements Exception {}
class InvalidBase58Checksum implements Exception {}

Uint8List _checksum(Uint8List data) => sha256DoubleHash(data).sublist(0, 4);

/// Encodes a checksumed base58 string
String base58Encode(Uint8List data) {
  final checksum = _checksum(data);
  final fullData = Uint8List.fromList([...data, ...checksum]);
  return _codec.encode(fullData);
}

/// Decodes a checksumed base58 string. This will throw a [InvalidBase58]
/// exception if the base58 encoding is invalid, or [InvalidBase58Checksum] if the
/// checksum is wrong.
Uint8List base58Decode(String b58) {

  late Uint8List fullData;
  try {
    fullData = _codec.decode(b58);
  } on Exception {
    throw InvalidBase58();
  }

  // Check room for checksum
  if (fullData.length < 4) throw InvalidBase58();

  final data = fullData.sublist(0, fullData.length-4);
  final expChecksum = fullData.sublist(fullData.length-4);
  final actualChecksum = _checksum(data);

  if (
    expChecksum[0] != actualChecksum[0]
    || expChecksum[1] != actualChecksum[1]
    || expChecksum[2] != actualChecksum[2]
    || expChecksum[3] != actualChecksum[3]
  ) {
    throw InvalidBase58Checksum();
  }

  return data;

}
