import 'ec_private_key.dart';
import 'schnorr_signature.dart';
import 'package:coinlib/src/secp256k1/secp256k1.dart';

/// A Schnorr signature where the nonce has been adapted by a point. The
/// signature can be adapted (decrypted) using [adapt] with the discrete-log of
/// the point (private key to a public key). The signature will be complete and
/// valid if the correct adaptor was given.
class SchnorrAdaptorSignature {

  /// The signature that contains the adapted nonce but requires the adaptor
  /// scalar
  final SchnorrSignature preSig;
  /// True when the nonce y-coord is odd
  final bool parity;

  SchnorrAdaptorSignature(this.preSig, this.parity);

  /// Adapts the adaptor signature with the discrete log to the adaptor point
  /// given as an [ECPrivateKey]. The resulting signature is not verified.
  /// Either the [adaptorScalar] should be known to be correct or the signature
  /// can be verified afterwards.
  ///
  /// If the signature has malformed data, this may throw
  /// [InvalidSchnorrSignature].
  SchnorrSignature adapt(ECPrivateKey adaptorScalar) {
    try {
      return SchnorrSignature(
        secp256k1.adaptSchnorr(preSig.data, adaptorScalar.data, parity),
      );
    } on Secp256k1Exception {
      throw InvalidSchnorrSignature();
    }
  }

  /// Extracts the adaptor scalar using the [completeSig]. The scalar is
  /// provided as an [ECPrivateKey].
  ///
  /// The [completeSig] must be a different signature or else
  /// [InvalidPrivateKey] will be thrown. It should also be verified as the
  /// correct valid signature to obtain the correct adaptor scalar.
  ///
  /// If either signature has malformed data, this may also throw
  /// [InvalidSchnorrSignature].
  ECPrivateKey extract(SchnorrSignature completeSig) {
    try {
      return ECPrivateKey(
        secp256k1.extractSchnorrAdaptor(preSig.data, completeSig.data, parity),
      );
    } on Secp256k1Exception {
      throw InvalidSchnorrSignature();
    }
  }

}
