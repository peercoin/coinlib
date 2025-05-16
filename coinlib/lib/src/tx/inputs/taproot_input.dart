import 'package:coinlib/src/crypto/ec_private_key.dart';
import 'package:coinlib/src/crypto/schnorr_signature.dart';
import 'package:coinlib/src/tx/sighash/taproot_signature_hasher.dart';
import 'package:coinlib/src/tx/sign_details.dart';
import 'input.dart';
import 'input_signature.dart';
import 'witness_input.dart';

/// Represents v1 Taproot program inputs
abstract class TaprootInput extends WitnessInput {

  TaprootInput({
    required super.prevOut,
    required super.witness,
    super.sequence = Input.sequenceFinal,
  });

  /// Creates a signature for the input. Used by subclasses to implement
  /// signing.
  SchnorrInputSignature createInputSignature({
    required ECPrivateKey key,
    required TaprootSignDetails details,
  }) => SchnorrInputSignature(
    SchnorrSignature.sign(key, TaprootSignatureHasher(details).hash),
    details.hashType,
  );

  /// The signed size when SIGHASH_DEFAULT is used for all signatures
  int? get defaultSignedSize => signedSize;

}
