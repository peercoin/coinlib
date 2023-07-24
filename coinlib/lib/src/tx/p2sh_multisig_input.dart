import 'dart:typed_data';
import 'package:coinlib/src/common/serial.dart';
import 'package:coinlib/src/crypto/ec_public_key.dart';
import 'package:coinlib/src/scripts/operations.dart';
import 'package:coinlib/src/scripts/program.dart';
import 'package:coinlib/src/scripts/programs/multisig.dart';
import 'package:coinlib/src/scripts/script.dart';
import 'package:coinlib/src/tx/input_signature.dart';
import 'package:coinlib/src/tx/outpoint.dart';
import 'input.dart';
import 'raw_input.dart';
import 'sighash_type.dart';

/// An input for a Pay-to-Script-Hash output ([P2SH]) with a multisig
/// redeemScript and any number of required signatures that may be provided with
/// [replaceSignatures].
class P2SHMultisigInput extends RawInput {

  final MultisigProgram program;
  final List<InputSignature> sigs;

  P2SHMultisigInput({
    required OutPoint prevOut,
    required this.program,
    Iterable<InputSignature> sigs = const [],
    int sequence = Input.sequenceFinal,
  }) : sigs = List.unmodifiable(sigs), super(
    prevOut: prevOut,
    scriptSig: Script([
      ScriptOp.fromNumber(0),
      ...sigs.map((sig) => ScriptPushData(sig.bytes)),
      ScriptPushData(program.script.compiled),
    ]).compiled,
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

    final script = raw.script;
    if (script == null) return null;
    final ops = script.ops;
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
      program: multisig,
      // Cast necessary to ensure non-null, despite checking for null above
      sigs: sigs.whereType<InputSignature>().toList(),
      sequence: raw.sequence,
    );

  }

  /// Returns a new [P2SHMultisigInput] with the new signature added in order.
  /// The [pubkey] should be the public key for the signature to ensure that it
  /// matches. [getSigHash] obtains the signature hash for a given type so that
  /// existing signatures can be checked.
  /// If existing signatures are not in-order then they may not be fully matched
  /// and included in the resulting input.
  /// If there are more signatures than the required threshold, the last
  /// signature will be removed.
  P2SHMultisigInput insertSignature(
    InputSignature insig,
    ECPublicKey pubkey,
    Uint8List Function(SigHashType hashType) getSigHash,
  ) {

    final pubkeys = program.pubkeys;

    // Create list that will match signatures to the public keys in order
    List<InputSignature?> positionedSigs = List.filled(pubkeys.length, null);

    // Iterate both public key positions and signatures sequentially as they
    // should already be in order
    for (int pos = 0, sigI = 0; pos < pubkeys.length; pos++) {

      // Check existing first to ensure they get matched
      if (
        // Check all signatures have not already been matched
        sigI != sigs.length
        // Do not add any more when threshold is reached
        && positionedSigs.whereType<InputSignature>().length < program.threshold
        // Check signature against candidate public key and message hash
        && sigs[sigI].signature.verify(
          pubkeys[pos], getSigHash(sigs[sigI].hashType),
        )
      ) {
        // Existing signature matched for this public key
        positionedSigs[pos] = sigs[sigI++];
      }

      // Check new signature last to ensure it gets included
      if (pubkey == pubkeys[pos]) positionedSigs[pos] = insig;

    }

    return P2SHMultisigInput(
      prevOut: prevOut,
      program: program,
      // Remove nulls leaving actual signatures and trim down to threshold if
      // needed
      sigs: positionedSigs.whereType<InputSignature>().take(program.threshold),
      sequence: sequence,
    );

  }

  @override
  P2SHMultisigInput filterSignatures(bool Function(InputSignature insig) predicate)
    => P2SHMultisigInput(
      prevOut: prevOut,
      program: program,
      sigs: sigs.where((sig) => predicate(sig)),
      sequence: sequence,
    );

  @override
  bool get complete => sigs.length == program.threshold;

  @override
  Script get script => super.script!;


}
