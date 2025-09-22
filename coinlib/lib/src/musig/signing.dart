import 'dart:typed_data';
import 'package:coinlib/src/crypto/ec_public_key.dart';
import 'package:coinlib/src/secp256k1/secp256k1.dart';
import 'package:coinlib/src/musig/keys.dart';

/// A MuSig signing session state to be used for one signing session only.
///
/// This class is stateful unlike most of the classes in the library. This is to
/// prevent re-use of earlier parts of the signing session, ensuring signing
/// nonces are used no more than once.
class MuSigStatefulSigningSession {

  final MuSigPublicKeys keys;
  final ECPublicKey ourPublicKey;

  late final MuSigSecretNonce _ourSecretNonce;
  late final Uint8List ourPublicNonce;

  /// Starts a signing session with the MuSig [keys] and specifying the public
  /// key for the signer with [ourPublicKey].
  MuSigStatefulSigningSession({
    required this.keys,
    required this.ourPublicKey,
  }) {
    final (secret, public) = secp256k1.muSigGenerateNonce(ourPublicKey.data);
    _ourSecretNonce = secret;
    ourPublicNonce = public;
  }

}
