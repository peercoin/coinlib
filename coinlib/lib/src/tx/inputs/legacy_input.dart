import 'package:coinlib/src/crypto/ec_private_key.dart';
import 'package:coinlib/src/crypto/ecdsa_signature.dart';
import 'package:coinlib/src/tx/sighash/legacy_signature_hasher.dart';
import 'package:coinlib/src/tx/sign_details.dart';
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

  /// Signs the input given the sign [details] and [key].
  /// Implemented by specific subclasses.
  LegacyInput sign({
    required LegacySignDetails details,
    required ECPrivateKey key,
  });

  /// Creates a signature for the input. Used by subclasses to implement
  /// signing.
  ECDSAInputSignature createInputSignature({
    required LegacySignDetailsWithScript details,
    required ECPrivateKey key,
  }) => ECDSAInputSignature(
    ECDSASignature.sign(key, LegacySignatureHasher(details).hash),
    details.hashType,
  );

}
