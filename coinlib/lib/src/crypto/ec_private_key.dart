import 'dart:typed_data';
import 'package:coinlib/src/bindings/secp256k1.dart';
import 'package:coinlib/src/common/hex.dart';
import 'package:coinlib/src/crypto/ec_public_key.dart';
import 'package:coinlib/src/crypto/ecdsa_signature.dart';
import 'package:coinlib/src/crypto/random.dart';
import 'package:coinlib/src/encode/base58.dart';

class WifVersionMismatch implements Exception {}
class InvalidWif implements Exception {}
class InvalidPrivateKey implements Exception {}

/// Represents an ECC private key for use with the secp256k1 curve
class ECPrivateKey {

  static const privateKeyLength = 32;

  /// 32-byte private key scalar
  final Uint8List data;
  /// True if the derived public key should be in compressed format
  final bool compressed;

  /// Constructs a private key from a 32-byte scalar. The public key may be
  /// in the [compressed] format which is the default. [InvalidPrivateKey] will
  /// be thrown if the private key is not within the secp256k1 order.
  ECPrivateKey(this.data, { this.compressed = true }) {
    if (data.length != privateKeyLength) {
      throw ArgumentError(
        "Private key scalars should be $privateKeyLength-bytes",
        "this.data",
      );
    }
    if (!secp256k1.privKeyVerify(data)) throw InvalidPrivateKey();
  }

  /// Constructs a private key from HEX encoded data. The public key may be in
  /// the [compressed] format which is the default.
  ECPrivateKey.fromHex(String hex, { bool compressed = true})
    : this(hexToBytes(hex), compressed: compressed);

  /// Constructs a private key from a [wif] encoded string. [WifVersionMismatch]
  /// is thrown if the [version] does not match the WIF. [InvalidWif] is thrown
  /// if the base58 is valid but the data doesn't meet the correct format. If no
  /// [version] is specified, any version will be accepted. May throw
  /// [InvalidBase58] or [InvalidBase58Checksum] when decoding the WIF.
  factory ECPrivateKey.fromWif(String wif, { int? version }) {

    final data = base58Decode(wif);

    // Determine if the data meets the compressed or uncompressed formats
    final compressed = data.length == 34;
    if (!compressed && data.length != 33) throw InvalidWif();
    if (compressed && data.last != 1) throw InvalidWif();

    if (version != null && version != data.first) throw WifVersionMismatch();

    return ECPrivateKey(data.sublist(1, 33), compressed: compressed);

  }

  /// Generates a private key using a CSPRING.
  ECPrivateKey.generate({ bool compressed = true }) : this(
    // The chance that a random private key is outside the secp256k1 field order
    // is extremely miniscule.
    generateRandomBytes(privateKeyLength), compressed: compressed,
  );

  ECPublicKey? _pubkeyCache;
  /// The public key associated with this private key
  get pubkey => _pubkeyCache ??= ECPublicKey(
    secp256k1.privToPubKey(data, compressed),
  );

  /// Takes a 32-byte message [hash] and produces an ECDSA signature using this
  /// private key. The signature will be generated deterministically and shall
  /// be the same for a given hash and key.
  ECDSASignature signEcdsa(Uint8List hash) => ECDSASignature.fromCompact(
    secp256k1.ecdsaSign(hash, data),
  );

}
