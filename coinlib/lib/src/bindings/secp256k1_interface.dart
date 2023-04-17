import 'dart:typed_data';

class Secp256k1Exception implements Exception {
  final String what;
  Secp256k1Exception(this.what);
  @override
  String toString() => what;
}

abstract class Secp256k1Interface {

  static const contextNone = 1;
  static const compressedFlags = 258;
  static const uncompressedFlags = 2;
  static const privkeySize = 32;
  static const hashSize = 32;
  static const pubkeySize = 64;
  static const compressedPubkeySize = 33;
  static const uncompressedPubkeySize = 65;
  static const sigSize = 64;

  /// Asynchronously load the library. `await` must be used to ensure the
  /// library is loaded
  Future<void> load();

  /// Returns true if a 32-byte [privKey] is valid.
  bool privKeyVerify(Uint8List privKey);

  /// Converts a 32-byte [privKey] into a either a 33-byte compressed or a
  /// 65-byte uncompressed public key.
  Uint8List privToPubKey(Uint8List privKey, bool compressed);

  /// Constructs a signature in the compact format using a 32-byte message
  /// [hash] and 32-byte [privKey] scalar. The signature contains a 32-byte
  /// big-endian R value followed by a 32-byte big-endian low-S value.
  /// Signatures are deterministic according to RFC6979.
  Uint8List ecdsaSign(Uint8List hash, Uint8List privKey);

}
