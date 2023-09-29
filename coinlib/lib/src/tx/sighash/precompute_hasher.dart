import 'dart:typed_data';
import 'package:coinlib/src/common/serial.dart';
import 'package:coinlib/src/crypto/hash.dart';

abstract class PrecomputeHasher with Writable {
  Uint8List get singleHash => sha256Hash(toBytes());
  Uint8List get doubleHash => sha256DoubleHash(toBytes());
}
