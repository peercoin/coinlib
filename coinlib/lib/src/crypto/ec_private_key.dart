import 'dart:typed_data';
import 'package:coinlib/src/bindings/secp256k1.dart';
import 'package:coinlib/src/common/hex.dart';
import 'package:coinlib/src/crypto/ec_public_key.dart';

/// Represents an ECC private key for use with the secp256k1 curve
class ECPrivateKey {

  /// 32-byte private key scalar
  final Uint8List data;

  /// Constructs a private key from a 32-byte scalar
  ECPrivateKey(this.data) {
    if (data.length != 32) {
      throw ArgumentError(
        "Private key scalars should be 32-bytes",
        "this.data",
      );
    }
  }

  ECPrivateKey.fromHex(String hex) : this(hexToBytes(hex));

  ECPublicKey? _pubkeyCache;
  /// The public key associated with this private key
  get pubkey => _pubkeyCache ??= ECPublicKey(secp256k1.privToPubKey(data));

}
