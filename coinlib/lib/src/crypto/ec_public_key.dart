import 'dart:typed_data';
import 'package:coinlib/src/common/hex.dart';

/// Represents an ECC public key on the secp256k1 curve that has an associated
/// private key
class ECPublicKey {

  /// Compressed 33-byte data
  final Uint8List data;

  /// Constructs a public key from a 33-byte compressed or 65-byte uncompressed
  /// representation
  ECPublicKey(this.data) {
    if (data.length != 33 && data.length != 65) {
      throw ArgumentError(
        "Public keys should be 33 or 65 bytes", "this.data",
      );
    }
  }

  get hex => bytesToHex(data);
  get compressed => data.length == 33;

}
