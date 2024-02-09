import 'package:coinlib/src/crypto/ec_private_key.dart';
import 'package:coinlib/src/crypto/ecdsa_signature.dart';
import 'package:coinlib/src/scripts/script.dart';
import 'package:coinlib/src/tx/inputs/raw_input.dart';
import 'package:coinlib/src/tx/sighash/sighash_type.dart';
import 'package:coinlib/src/tx/sighash/witness_signature_hasher.dart';
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

  /// Signs the input given the [tx], input number ([inputN]), private
  /// [key] and input [value] using the specifified [hashType]. Should throw
  /// [CannotSignInput] if the key cannot sign the input.
  /// Implemented by specific subclasses.
  LegacyWitnessInput sign({
    required Transaction tx,
    required int inputN,
    required ECPrivateKey key,
    required BigInt value,
    SigHashType hashType = const SigHashType.all(),
  });

  /// Creates a signature for the input. Used by subclasses to implement
  /// signing.
  ECDSAInputSignature createInputSignature({
    required Transaction tx,
    required int inputN,
    required ECPrivateKey key,
    required Script scriptCode,
    required BigInt value,
    SigHashType hashType = const SigHashType.all(),
  }) => ECDSAInputSignature(
    ECDSASignature.sign(
      key,
      WitnessSignatureHasher(
        tx: tx,
        inputN: inputN,
        scriptCode: scriptCode,
        value: value,
        hashType: RawInput.checkHashTypeNotSchnorr(hashType),
      ).hash,
    ),
    hashType,
  );

}
