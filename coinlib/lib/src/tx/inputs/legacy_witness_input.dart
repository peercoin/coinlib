import 'package:coinlib/src/crypto/ec_private_key.dart';
import 'package:coinlib/src/crypto/ecdsa_signature.dart';
import 'package:coinlib/src/tx/sighash/witness_signature_hasher.dart';
import 'package:coinlib/src/tx/sign_details.dart';
import 'package:coinlib/src/tx/transaction.dart';
import 'input.dart';
import 'input_signature.dart';
import 'witness_input.dart';

/// Represents v0 witness program inputs
abstract class LegacyWitnessInput extends WitnessInput {

  LegacyWitnessInput({
    required super.prevOut,
    required super.witness,
    super.sequence = Input.sequenceFinal,
  });

  /// Signs the input given the [details] and [key]. Should throw
  /// [CannotSignInput] if the key cannot sign the input.
  /// Implemented by specific subclasses.
  LegacyWitnessInput sign({
    required LegacyWitnessSignDetails details,
    required ECPrivateKey key,
  });

  /// Creates a signature for the input. Used by subclasses to implement
  /// signing.
  ECDSAInputSignature createInputSignature({
    required LegacyWitnessSignDetailsWithScript details,
    required ECPrivateKey key,
  }) => ECDSAInputSignature(
    ECDSASignature.sign(key, WitnessSignatureHasher(details).hash),
    details.hashType,
  );

}
