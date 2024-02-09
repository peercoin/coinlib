import 'dart:typed_data';
import 'package:coinlib/src/secp256k1/secp256k1.dart';
import 'package:coinlib/src/secp256k1/secp256k1_base.dart';
import 'package:coinlib/src/common/bytes.dart';
import 'package:coinlib/src/common/hex.dart';
import 'ec_private_key.dart';
import 'ec_public_key.dart';

class InvalidECDSASignature implements Exception {}

class ECDSASignature {

  static const compactLength = 64;

  final Uint8List _compact;

  /// Takes a 64-byte compact signature representation. See [this.compact].
  /// [InvalidECDSASignature] will be thrown if the signature is not valid.
  ECDSASignature.fromCompact(Uint8List compact)
    : _compact = copyCheckBytes(
      compact, compactLength,
      name: "Compact ECDSA signature",
  ) {
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

  /// Takes a BIP66 DER formatted signature as a HEX string.
  /// See [ECDSASignature.fromDer].
  factory ECDSASignature.fromDerHex(String hex)
    => ECDSASignature.fromDer(hexToBytes(hex));

  /// Creates a signature using a private key ([privkey]) for a given 32-byte
  /// [hash]. The signature will be generated deterministically and shall be the
  /// same for a given hash and key.
  /// If [forceLowR] is true (default), then signatures with high r-values will
  /// be skipped until a signature with a low r-value is found.
  factory ECDSASignature.sign(
    ECPrivateKey privkey,
    Uint8List hash,
    { bool forceLowR = true, }
  ) {
    checkBytes(hash, 32);

    Uint8List compact;

    if (forceLowR) {
      // Loop through incrementing entropy until a low r-value is found
      Uint8List extraEntropy = Uint8List(32);
      do {
        compact = secp256k1.ecdsaSign(hash, privkey.data, extraEntropy);
        for (int i = 0; extraEntropy[i]++ == 255; i++) {}
      } while (compact[0] >= 0x80);
    } else {
      compact = secp256k1.ecdsaSign(hash, privkey.data);
    }

    final sig = ECDSASignature.fromCompact(compact);

    // Verify signature to protect against computation errors. Cosmic rays etc.
    if (!sig.verify(privkey.pubkey, hash)) throw InvalidECDSASignature();

    return sig;

  }

  /// Takes a 32-byte message [hash] and [publickey] and returns true if the
  /// signature is valid for the public key and hash. This accepts malleable
  /// signatures with high and low S-values.
  bool verify(ECPublicKey publickey, Uint8List hash)
    => secp256k1.ecdsaVerify(
      secp256k1.ecdsaSignatureNormalize(_compact),
      checkBytes(hash, 32),
      publickey.data,
    );

  /// Returns the DER encoding for the signature
  Uint8List get der => secp256k1.ecdsaSignatureToDer(_compact);
  /// A compact representation of a ECDSASignature containing a big-endian
  /// 32-byte R value and big-endian 32-byte S value.
  Uint8List get compact => Uint8List.fromList(_compact);

}
