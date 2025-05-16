import 'dart:typed_data';
import 'package:coinlib/src/crypto/ec_private_key.dart';
import 'package:coinlib/src/taproot/leaves.dart';
import 'package:coinlib/src/taproot/taproot.dart';
import 'package:coinlib/src/tx/outpoint.dart';
import 'package:coinlib/src/tx/sign_details.dart';
import 'package:coinlib/src/tx/transaction.dart';
import 'input.dart';
import 'input_signature.dart';
import 'raw_input.dart';
import 'taproot_input.dart';
import 'taproot_script_input.dart';

/// An input that provides a single signature to satisfy a tapscript [leaf].
class TaprootSingleScriptSigInput extends TaprootInput {

  final TapLeafChecksig leaf;
  final SchnorrInputSignature? insig;

  @override
  // 41 bytes for legacy input data
  // 64 witness signature bytes
  // 1 potential sighash byte
  // 4 bytes for witness varints
  int get signedSize => 41 + 64 + 1 + 4
    + leaf.script.compiled.length
    // Control block
    + witness.last.length;

  @override
  // Minus the sighash byte
  int get defaultSignedSize => signedSize - 1;

  TaprootSingleScriptSigInput._({
    required this.leaf,
    required Uint8List controlBlock,
    required super.sequence,
    OutPoint? prevOut,
    this.insig,
  }) : super(
    prevOut: prevOut ?? OutPoint.nothing,
    witness: [
      if (insig != null) insig.bytes,
      leaf.script.compiled,
      controlBlock,
    ],
  );

  /// Constructs an input with all the information for signing with any sighash
  /// type.
  TaprootSingleScriptSigInput({
    required OutPoint prevOut,
    required Taproot taproot,
    required TapLeafChecksig leaf,
    SchnorrInputSignature? insig,
    int sequence = Input.sequenceFinal,
  }) : this._(
    prevOut: prevOut,
    controlBlock: taproot.controlBlockForLeaf(leaf),
    leaf: leaf,
    insig: insig,
    sequence: sequence,
  );

  /// Create an APO input specifying a [Taproot] and [TapLeaf] that can be
  /// signed using ANYPREVOUT or ANYPREVOUTANYSCRIPT.
  TaprootSingleScriptSigInput.anyPrevOut({
    required Taproot taproot,
    required TapLeafChecksig leaf,
    SchnorrInputSignature? insig,
    int sequence = Input.sequenceFinal,
  }) : this._(
    leaf: leaf,
    controlBlock: taproot.controlBlockForLeaf(leaf),
    insig: insig,
    sequence: sequence,
  );

  /// Matches a [RawInput] as a [TaprootSingleScriptSigInput] if it contains the
  /// control block and [TapLeafChecksig] leaf script.
  static TaprootSingleScriptSigInput? match(
    RawInput raw, List<Uint8List> witness,
  ) {

    // Only match up-to 3 witness items including signature
    if (witness.length > 3) return null;

    // Try to match as generic script input
    final scriptIn = TaprootScriptInput.match(raw, witness);
    if (scriptIn == null) return null;

    // Check if the script is a match
    final leaf = TapLeafChecksig.match(scriptIn.tapscript);
    if (leaf == null) return null;

    try {
      return TaprootSingleScriptSigInput._(
        prevOut: raw.prevOut,
        leaf: leaf,
        controlBlock: scriptIn.controlBlock,
        insig: witness.length == 2
          ? null
          : SchnorrInputSignature.fromBytes(witness[0]),
        sequence: raw.sequence,
      );
    } on InvalidInputSignature {
      return null;
    }

  }

  /// Complete the input by adding (or replacing) the [OutPoint].
  ///
  /// A signature is not invalidated if ANYPREVOUT or ANYPREVOUTANYSCRIPT is
  /// used.
  TaprootSingleScriptSigInput addPrevOut(
    OutPoint prevOut,
  ) => TaprootSingleScriptSigInput._(
    prevOut: prevOut,
    leaf: leaf,
    controlBlock: witness.last,
    insig: (insig != null && insig!.hashType.requiresApo) ? insig : null,
    sequence: sequence,
  );

  /// Add a preprepared input signature.
  TaprootSingleScriptSigInput addSignature(
    SchnorrInputSignature insig,
  ) => TaprootSingleScriptSigInput._(
    prevOut: prevOut,
    leaf: leaf,
    controlBlock: witness.last,
    insig: insig,
    sequence: sequence,
  );

  /// Sign the input for the tapscript key.
  TaprootSingleScriptSigInput sign({
    required TaprootScriptSignDetails details,
    required ECPrivateKey key,
  }) {

    if (!leaf.isApo && details.hashType.requiresApo) {
      throw CannotSignInput(
        "Cannot sign with ${details.hashType} for non-APO key",
      );
    }

    return addSignature(
      createInputSignature(key: key, details: details.addLeafHash(leaf.hash)),
    );

  }

  @override
  bool get complete => witness.length == 3 && !prevOut.isNothing;

}
