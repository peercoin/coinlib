import 'package:coinlib/src/crypto/ec_public_key.dart';
import 'package:coinlib/src/scripts/operations.dart';
import 'package:coinlib/src/tx/input_signature.dart';
import 'package:coinlib/src/tx/outpoint.dart';
import '../scripts/script.dart';
import 'raw_input.dart';

/// An input for a Pay-to-Public-Key-Hash output ([P2PKH]). This contains the
/// public key that should match the hash in the associated output. It is either
/// signed or unsigned and the [addSignature] method can be used to add a signature.
class P2PKHInput extends RawInput {

  final ECPublicKey publicKey;
  final InputSignature? insig;

  P2PKHInput({
    required OutPoint prevOut,
    required int sequence,
    required this.publicKey,
    this.insig,
  }) : super(
    prevOut: prevOut,
    scriptSig: Script([
      if (insig != null) ScriptPushData(insig.bytes),
      ScriptPushData(publicKey.data),
    ]),
    sequence: sequence,
  );

  /// Checks if the [RawInput] matches the expected format for a P2PKHInput,
  /// with or without a signature. If it does it returns a [P2PKHInput] for the
  /// input or else it returns null.
  static P2PKHInput? match(RawInput raw) {

    final ops = raw.scriptSig.ops;
    if (ops.isEmpty || ops.length > 2) return null;

    final insig = ops.length == 2 ? ops[0].insig : null;
    if (insig == null && ops.length == 2) return null;

    final publicKey = ops.last.publicKey;
    if (publicKey == null) return null;

    return P2PKHInput(
      prevOut: raw.prevOut,
      sequence: raw.sequence,
      publicKey: publicKey,
      insig: insig,
    );

  }

  /// Returns a new [P2PKHInput] with the [InputSignature] added. Any existing
  /// signature is replaced.
  P2PKHInput addSignature(InputSignature insig) => P2PKHInput(
    prevOut: prevOut,
    sequence: sequence,
    publicKey: publicKey,
    insig: insig,
  );

  @override
  bool get complete => insig != null;

}
