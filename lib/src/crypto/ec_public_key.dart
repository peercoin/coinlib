
import 'dart:typed_data';

/// Represents an ECC public key on the secp256k1 curve that has an associated
/// private key
class ECPublicKey {

  /// Compressed 33-byte data
  final Uint8List data;

  /// Constructs a public key using a 33-byte compressed representation
  ECPublicKey(this.data) {
    if (data.length != 33) {
      throw ArgumentError(
        "Compressed public keys should be 33-bytes",
        "this.data",
      );
    }
  }

}

