import 'dart:typed_data';
import 'package:coinlib/src/bindings/secp256k1.dart';
import 'package:coinlib/src/bindings/secp256k1_base.dart';
import 'package:coinlib/src/common/bytes.dart';
import 'package:coinlib/src/common/hex.dart';
import 'ec_private_key.dart';
import 'ec_public_key.dart';

class InvalidECDSASignature implements Exception {}

class ECDSASignature {

  static const compactLength = 64;

  /// A compact representation of a ECDSASignature containing a big-endian
  /// 32-byte value and big-endian 32-byte S value.
  final Uint8List compact;

  /// Takes a 64-byte compact signature representation. See [this.compact].
  /// [InvalidECDSASignature] will be thrown if the signature is not valid.
  ECDSASignature.fromCompact(this.compact) {
    if (compact.length != compactLength) {
      throw ArgumentError(
        "Compact signatures should be $compactLength-bytes",
        "this.compact",
      );
    }
    if (!secp256k1.ecdsaCompactSignatureVerify(compact)) {
      throw InvalidECDSASignature();
    }
  }

  /// Takes a HEX encoded 64-byte compact signature representation. See
  /// [ECDSASignature.fromCompact].
  ECDSASignature.fromCompactHex(String hex) : this.fromCompact(hexToBytes(hex));

  /// Takes a BIP66 DER formatted [signature].
  /// [InvalidECDSASignature] will be thrown only if it is not formatted
  /// correctly.
  /// R and S values outside the order are accepted and will be set to 0 such
  /// that signatures will fail verification with a public key.
  factory ECDSASignature.fromDer(Uint8List signature) {
    try {
      return ECDSASignature.fromCompact(
        secp256k1.ecdsaSignatureFromDer(signature),
      );
    } on Secp256k1Exception {
      throw InvalidECDSASignature();
    }
  }

  /// Takes a BIP66 DER formatted [signature] as a HEX string.
  /// See [ECDSASignature.fromDer].
  factory ECDSASignature.fromDerHex(String hex)
    => ECDSASignature.fromDer(hexToBytes(hex));

  /// Creates a signature using a private key ([privkey]) for a given [hash].
  /// The signature will be generated deterministically and shall be the same
  /// for a given hash and key.
  factory ECDSASignature.sign(ECPrivateKey privkey, Bytes32 hash) {

    final sig = ECDSASignature.fromCompact(
      secp256k1.ecdsaSign(hash.u8List, privkey.data),
    );

    // Verify signature to protect against computation errors. Cosmic rays etc.
    if (!sig.verify(privkey.pubkey, hash)) throw InvalidECDSASignature();

    return sig;

  }

  /// Takes a 32-byte message [hash] and [publickey] and returns true if the
  /// signature is valid for the public key and hash. This accepts malleable
  /// signatures with high and low S-values.
  bool verify(ECPublicKey publickey, Bytes32 hash)
    => secp256k1.ecdsaVerify(
      secp256k1.ecdsaSignatureNormalize(compact),
      hash.u8List,
      publickey.data,
    );

  /// Returns the DER encoding for the signature
  Uint8List get der => secp256k1.ecdsaSignatureToDer(compact);

}
