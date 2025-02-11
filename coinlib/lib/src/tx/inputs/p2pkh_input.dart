import 'package:coinlib/src/crypto/ec_private_key.dart';
import 'package:coinlib/src/crypto/ec_public_key.dart';
import 'package:coinlib/src/scripts/operations.dart';
import 'package:coinlib/src/scripts/programs/p2pkh.dart';
import 'package:coinlib/src/scripts/script.dart';
import 'package:coinlib/src/tx/sign_details.dart';
import 'input.dart';
import 'input_signature.dart';
import 'legacy_input.dart';
import 'pkh_input.dart';
import 'raw_input.dart';

/// An input for a Pay-to-Public-Key-Hash output ([P2PKH]). This contains the
/// public key that should match the hash in the associated output. It is either
/// signed or unsigned. The [sign] method can be used to sign the input with the
/// corresponding [ECPrivateKey] or a signature can be added without checks
/// using [addSignature].
class P2PKHInput extends LegacyInput with PKHInput {

  @override
  final ECPublicKey publicKey;
  @override
  final ECDSAInputSignature? insig;
  @override
  final int? signedSize = 147;

  P2PKHInput({
    required super.prevOut,
    required this.publicKey,
    this.insig,
    super.sequence = Input.sequenceFinal,
  }) : super(
    scriptSig: Script([
      if (insig != null) ScriptPushData(insig.bytes),
      ScriptPushData(publicKey.data),
    ]).compiled,
  );

  /// Checks if the [RawInput] matches the expected format for a [P2PKHInput],
  /// with or without a signature. If it does it returns a [P2PKHInput] for the
  /// input or else it returns null.
  static P2PKHInput? match(RawInput raw) {

    final script = raw.script;
    if (script == null) return null;
    final ops = script.ops;
    if (ops.isEmpty || ops.length > 2) return null;

    final insig = ops.length == 2 ? ops[0].ecdsaSig : null;
    if (insig == null && ops.length == 2) return null;

    final publicKey = ops.last.publicKey;
    if (publicKey == null) return null;

    return P2PKHInput(
      prevOut: raw.prevOut,
      publicKey: publicKey,
      insig: insig,
      sequence: raw.sequence,
    );

  }

  @override
  P2PKHInput sign({
    required LegacySignDetails details,
    required ECPrivateKey key,
  }) => addSignature(
    createInputSignature(
      key: checkKey(key),
      details: details.addScript(scriptCode),
    ),
  );

  @override
  /// Returns a new [P2PKHInput] with the [ECDSAInputSignature] added. Any
  /// existing signature is replaced.
  P2PKHInput addSignature(ECDSAInputSignature insig) => P2PKHInput(
    prevOut: prevOut,
    publicKey: publicKey,
    insig: insig,
    sequence: sequence,
  );

  @override
  P2PKHInput filterSignatures(bool Function(InputSignature insig) predicate)
    => insig == null || predicate(insig!) ? this : P2PKHInput(
      prevOut: prevOut,
      publicKey: publicKey,
      insig: null,
      sequence: sequence,
    );

  @override
  Script get script => super.script!;

}
