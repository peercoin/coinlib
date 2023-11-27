import 'dart:typed_data';
import 'package:coinlib/src/secp256k1/secp256k1.dart';
import 'package:coinlib/src/common/bytes.dart';
import 'package:coinlib/src/common/hex.dart';
import 'ec_private_key.dart';
import 'ec_public_key.dart';
import 'ecdsa_signature.dart';

class InvalidECDSARecoverableSignature implements Exception {}

/// An [ECDSARecoverableSignature] is similar to an [ECDSASignature] but
/// contains an additional byte that encodes a "recid" and compression flag that
/// allows for the public key to be recovered from the message hash and
/// signature.
class ECDSARecoverableSignature {

  static const compactLength = 65;

  /// A compact 64-byte signaure
  final Uint8List _signature;
  /// The recovery ID needed to recover the public key
  final int recid;
  /// Whether the recovered public key should be in compressed format or not
  final bool compressed;

  ECDSARecoverableSignature._(
    this._signature, this.recid, this.compressed,
  );

  /// Takes a 65-byte compact recoverable signature representation.
  /// [InvalidECDSARecoverableSignature] will be thrown if the signature is not
  /// valid.
  factory ECDSARecoverableSignature.fromCompact(Uint8List compact) {

    checkBytes(compact, compactLength, name: "Compact recoverable signature");

    // Extract recid and public key compression from first byte
    final bits = (compact[0] - 27);
    final recid = bits & 3;
    final compressed = (bits & 4) != 0;
    final signature = compact.sublist(1);

    if (!secp256k1.ecdsaCompactRecoverableSignatureVerify(signature, recid)) {
      throw InvalidECDSARecoverableSignature();
    }

    return ECDSARecoverableSignature._(signature, recid, compressed);

  }

  /// Creates a recoverable signature using a private key ([privkey]) for a
  /// given 32-byte [hash].
  factory ECDSARecoverableSignature.sign(ECPrivateKey privkey, Uint8List hash) {
    checkBytes(hash, 32);

    final sigAndId = secp256k1.ecdsaSignRecoverable(hash, privkey.data);
    final recSig = ECDSARecoverableSignature._(
      sigAndId.signature, sigAndId.recid, privkey.compressed,
    );

    // Verify signature to protect against computation errors. Cosmic rays etc.
    if (privkey.pubkey != recSig.recover(hash)) {
      throw InvalidECDSARecoverableSignature();
    }

    return recSig;

  }

  /// Takes a HEX encoded 65-byte compact recoverable signature representation.
  /// See [ECDSARecoverableSignature.fromCompact].
  factory ECDSARecoverableSignature.fromCompactHex(String hex)
    => ECDSARecoverableSignature.fromCompact(hexToBytes(hex));

  /// Given a 32-byte [hash], returns a public key recovered from the signature
  /// and hash. This can be compared against the expected public key or public
  /// key hash to determine if the message was signed correctly. If a public key
  /// cannot be extracted, null shall be returned.
  ECPublicKey? recover(Uint8List hash) {
    checkBytes(hash, 32);
    final pkBytes = secp256k1.ecdaSignatureRecoverPubKey(
      _signature, recid, hash, compressed,
    );
    return pkBytes != null ? ECPublicKey(pkBytes) : null;
  }

  Uint8List get compact => Uint8List.fromList([
    27 + recid + (compressed ? 4 : 0), ..._signature,
  ]);

  ECDSASignature get signature => ECDSASignature.fromCompact(_signature);

}
