import 'dart:typed_data';

class Secp256k1Exception implements Exception {
  final String what;
  Secp256k1Exception(this.what);
  @override
  String toString() => what;
}

abstract class Secp256k1Interface {

  static const contextNone = 1;
  static const compressionFlags = 258;
  static const privkeySize = 32;
  static const pubkeySize = 64;
  static const compressedPubkeySize = 33;

  /// Asynchronously load the library. `await` must be used to ensure the
  /// library is loaded
  Future<void> load();

  /// Converts a 32-byte [privKey] into a 33-byte compressed public key
  Uint8List privToPubKey(Uint8List privKey);

}
