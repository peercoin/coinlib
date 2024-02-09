import 'package:coinlib/src/crypto/ec_private_key.dart';
import 'package:coinlib/src/crypto/ecdsa_signature.dart';
import 'package:coinlib/src/scripts/script.dart';
import 'package:coinlib/src/tx/sighash/legacy_signature_hasher.dart';
import 'package:coinlib/src/tx/sighash/sighash_type.dart';
import 'package:coinlib/src/tx/transaction.dart';
import 'input.dart';
import 'input_signature.dart';
import 'p2pkh_input.dart';
import 'p2sh_multisig_input.dart';
import 'raw_input.dart';

/// Inputs that are not witness inputs: [P2PKHInput] and [P2SHMultisigInput].
abstract class LegacyInput extends RawInput {

  LegacyInput({
    required super.prevOut,
    required super.scriptSig,
    super.sequence = Input.sequenceFinal,
  });

  /// Signs the input given the [tx], input number ([inputN]) and a private
  /// [key] using the specifified [hashType].
  /// Implemented by specific subclasses.
  LegacyInput sign({
    required Transaction tx,
    required int inputN,
    required ECPrivateKey key,
    SigHashType hashType = const SigHashType.all(),
  });

  /// Creates a signature for the input. Used by subclasses to implement
  /// signing.
  ECDSAInputSignature createInputSignature({
    required Transaction tx,
    required int inputN,
    required ECPrivateKey key,
    required Script scriptCode,
    SigHashType hashType = const SigHashType.all(),
  }) => ECDSAInputSignature(
    ECDSASignature.sign(
      key,
      LegacySignatureHasher(
        tx: tx,
        inputN: inputN,
        scriptCode: scriptCode,
        hashType: RawInput.checkHashTypeNotSchnorr(hashType),
      ).hash,
    ),
    hashType,
  );

}
