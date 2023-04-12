import 'dart:typed_data';
import 'package:coinlib/src/bindings/secp256k1.dart';
import 'package:coinlib/src/common/hex.dart';
import 'package:coinlib/src/crypto/ec_public_key.dart';
import 'package:coinlib/src/encode/base58.dart';

class WifVersionMismatch implements Exception {}
class InvalidWif implements Exception {}

/// Represents an ECC private key for use with the secp256k1 curve
class ECPrivateKey {

  /// 32-byte private key scalar
  final Uint8List data;
  /// True if the derived public key should be in compressed format
  final bool compressed;

  /// Constructs a private key from a 32-byte scalar. The public key may be
  /// in the [compressed] format which is the default.
  ECPrivateKey(this.data, { this.compressed = true }) {
    if (data.length != 32) {
      throw ArgumentError(
        "Private key scalars should be 32-bytes",
        "this.data",
      );
    }
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

  ECPublicKey? _pubkeyCache;
  /// The public key associated with this private key
  get pubkey => _pubkeyCache ??= ECPublicKey(
    secp256k1.privToPubKey(data, compressed),
  );

}
