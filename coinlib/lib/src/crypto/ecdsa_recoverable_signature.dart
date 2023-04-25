import 'dart:typed_data';
import 'package:coinlib/src/bindings/secp256k1.dart';
import 'package:coinlib/src/common/hex.dart';

import 'ec_public_key.dart';

class InvalidECDSARecoverableSignature implements Exception {}

/// An [ECDSARecoverableSignature] is similar to an [ECDSASignature] but
/// contains an additional byte that encodes a "recid" and compression flag that
/// allows for the public key to be recovered from the message hash and
/// signature.
class ECDSARecoverableSignature {

  static const compactLength = 65;

  /// A compact 64-byte signaure
  final Uint8List signature;
  /// The recovery ID needed to recover the public key
  final int recid;
  /// Whether the recovered public key should be in compressed format or not
  final bool compressed;

  ECDSARecoverableSignature._(this.signature, this.recid, this.compressed);

  /// Takes a 65-byte compact recoverable signature representation.
  /// [InvalidECDSARecoverableSignature] will be thrown if the signature is not
  /// valid.
  factory ECDSARecoverableSignature.fromCompact(Uint8List compact) {

    if (compact.length != compactLength) {
      throw ArgumentError(
        "Compact recoverable signatures should be $compactLength-bytes",
        "this.compact",
      );
    }

    // Extract recid and public key compression from first byte
    final recid = (compact[0] - 27) & 3;
    final compressed = ((compact[0] - 27) & 4) != 0;
    final signature = compact.sublist(1);

    if (!secp256k1.ecdsaCompactRecoverableSignatureVerify(signature, recid)) {
      throw InvalidECDSARecoverableSignature();
    }

    return ECDSARecoverableSignature._(signature, recid, compressed);

  }

  /// Takes a HEX encoded 65-byte compact recoverable signature representation.
  /// See [ECDSARecoverableSignature.fromCompact].
  factory ECDSARecoverableSignature.fromCompactHex(String hex)
    => ECDSARecoverableSignature.fromCompact(hexToBytes(hex));

  /// Given a 32-byte message [hash], returns a public key recovered from the
  /// signature and hash. This can be compared against the expected public key
  /// or public key hash to determine if the message was signed correctly.
  /// If a public key cannot be extracted, null shall be returned.
  ECPublicKey? recover(Uint8List hash) {
    final pkBytes = secp256k1.ecdaSignatureRecoverPubKey(
      signature, recid, hash, compressed,
    );
    return pkBytes != null ? ECPublicKey(pkBytes) : null;
  }

}
