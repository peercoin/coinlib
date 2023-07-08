import 'package:coinlib/src/common/serial.dart';
import 'package:coinlib/src/scripts/operations.dart';
import 'package:coinlib/src/scripts/program.dart';
import 'package:coinlib/src/tx/input_signature.dart';
import 'package:coinlib/src/tx/outpoint.dart';
import '../scripts/programs/multisig.dart';
import '../scripts/script.dart';
import 'raw_input.dart';

/// An input for a Pay-to-Script-Hash output ([P2SH]) with a multisig
/// redeemScript and any number of required signatures that may be provided with
/// [replaceSignatures].
class P2SHMultisigInput extends RawInput {

  final MultisigProgram program;
  final List<InputSignature> sigs;

  P2SHMultisigInput({
    required OutPoint prevOut,
    required int sequence,
    required this.program,
    required List<InputSignature> sigs,
  }) : sigs = List.unmodifiable(sigs), super(
    prevOut: prevOut,
    scriptSig: Script([
      ScriptOp.fromNumber(0),
      ...sigs.map((sig) => ScriptPushData(sig.bytes)),
      ScriptPushData(program.script.compiled),
    ]),
    sequence: sequence,
  ) {
    if (sigs.length > program.threshold) {
      throw ArgumentError(
        "P2SHMultisigInput signatures n=${sigs.length} over "
        "${program.threshold} threshold",
      );
    }
  }

  /// Checks if the [RawInput] matches the expected format for a
  /// [P2SHMultisigInput] with any number of signatures. If it does it returns a
  /// [P2SHMultisigInput] for the input or else it returns null.
  static P2SHMultisigInput? match(RawInput raw) {

    final ops = raw.scriptSig.ops;
    if (ops.length < 2) return null;

    // Check that the first item is 0 which is necessary for CHECKMULTISIG
    if (ops[0].number != 0) return null;

    // Last push needs to be the redeemScript
    if (ops.last is! ScriptPushData) return null;

    // Check redeemScript is multisig
    late MultisigProgram multisig;
    try {
      multisig = MultisigProgram.decompile((ops.last as ScriptPushData).data);
    } on NoProgramMatch {
      return null;
    } on PushDataNotMinimal {
      return null;
    } on OutOfData {
      return null;
    }

    // Can only have upto threshold sigs plus OP_0 and redeemScript
    if (ops.length > 2 + multisig.threshold) return null;

    // Convert signature data into InputSignatures
    final sigs = ops.getRange(1, ops.length-1).map((op) => op.insig).toList();
    // Fail if any signature is null
    if (sigs.any((sig) => sig == null)) return null;

    return P2SHMultisigInput(
      prevOut: raw.prevOut,
      sequence: raw.sequence,
      program: multisig,
      // Cast necessary to ensure non-null, despite checking for null above
      sigs: sigs.whereType<InputSignature>().toList(),
    );

  }

  /// Returns a new [P2SHMultisigInput] with the signature list replaced with a
  /// new one. The signatures must be ordered in the same order as the public
  /// keys.
  P2SHMultisigInput replaceSignatures(List<InputSignature> newSigs)
    => P2SHMultisigInput(
    prevOut: prevOut,
    sequence: sequence,
    program: program,
    sigs: newSigs,
  );

  @override
  bool get complete => sigs.length == program.threshold;

}
