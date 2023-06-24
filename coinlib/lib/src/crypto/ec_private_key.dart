import 'dart:typed_data';
import 'package:coinlib/src/bindings/secp256k1.dart';
import 'package:coinlib/src/common/bytes.dart';
import 'package:coinlib/src/common/hex.dart';
import 'ec_public_key.dart';
import 'random.dart';

class InvalidPrivateKey implements Exception {}

/// Represents an ECC private key for use with the secp256k1 curve
class ECPrivateKey {

  static const privateKeyLength = 32;

  /// 32-byte private key scalar
  final Uint8List _data;
  /// True if the derived public key should be in compressed format
  final bool compressed;

  /// Constructs a private key from a 32-byte scalar. The public key may be
  /// in the [compressed] format which is the default. [InvalidPrivateKey] will
  /// be thrown if the private key is not within the secp256k1 order.
  ECPrivateKey(Uint8List data, { this.compressed = true })
    : _data = copyCheckBytes(data, privateKeyLength, name: "Private key data") {
    if (!secp256k1.privKeyVerify(data)) throw InvalidPrivateKey();
  }

  /// Constructs a private key from HEX encoded data. The public key may be in
  /// the [compressed] format which is the default.
  ECPrivateKey.fromHex(String hex, { bool compressed = true})
    : this(hexToBytes(hex), compressed: compressed);

  /// Generates a private key using a CSPRING.
  ECPrivateKey.generate({ bool compressed = true }) : this(
    // The chance that a random private key is outside the secp256k1 field order
    // is extremely miniscule.
    generateRandomBytes(privateKeyLength), compressed: compressed,
  );

  ECPublicKey? _pubkeyCache;
  /// The public key associated with this private key
  ECPublicKey get pubkey => _pubkeyCache ??= ECPublicKey(
    secp256k1.privToPubKey(_data, compressed),
  );
  Uint8List get data => Uint8List.fromList(_data);

  /// Tweaks the private key with a scalar. In the instance a new key cannot be
  /// created (practically impossible for random 32-bit scalars), then null will
  /// be returned.
  ECPrivateKey? tweak(Uint8List scalar) {
    checkBytes(scalar, 32, name: "Scalar");
    final newScalar = secp256k1.privKeyTweak(_data, scalar);
    return newScalar == null ? null : ECPrivateKey(newScalar, compressed: compressed);
  }

}
