import 'dart:typed_data';
import 'package:coinlib/src/crypto/ec_private_key.dart';
import 'package:coinlib/src/taproot/leaves.dart';
import 'package:coinlib/src/taproot/taproot.dart';
import 'package:coinlib/src/tx/outpoint.dart';
import 'package:coinlib/src/tx/sign_details.dart';
import 'package:coinlib/src/tx/transaction.dart';
import 'input_signature.dart';
import 'raw_input.dart';
import 'sequence.dart';
import 'taproot_input.dart';
import 'taproot_script_input.dart';

/// An input that provides a single signature to satisfy a tapscript [leaf].
class TaprootSingleScriptSigInput extends TaprootInput {

  final TapLeafChecksig leaf;
  final SchnorrInputSignature? insig;

  @override
  final int signedSize;

  TaprootSingleScriptSigInput._({
    required this.leaf,
    required Uint8List controlBlock,
    required super.sequence,
    OutPoint? prevOut,
    bool defaultSigHash = false,
    this.insig,
  }) :
    // 41 bytes for legacy input data plus 3 bytes for witness varints
    // 64 to 65 witness signature bytes
    signedSize = 44
      + (
        insig == null
        ? (defaultSigHash ? 64 : 65)
        : insig.bytes.length
      )
      + leaf.script.compiled.length
      + controlBlock.length,
    super(
      prevOut: prevOut ?? OutPoint.nothing,
      witness: [
        if (insig != null) insig.bytes,
        leaf.script.compiled,
        controlBlock,
      ],
    );

  /// Constructs an input with all the information for signing with any sighash
  /// type.
  ///
  /// Set [defaultSigHash] to true if it is known that the default sighash type
  /// is being used which allows one less byte to be used for Taproot
  /// signatures and for the [signedSize] to be set correctly.
  TaprootSingleScriptSigInput({
    required OutPoint prevOut,
    required Taproot taproot,
    required TapLeafChecksig leaf,
    bool defaultSigHash = false,
    SchnorrInputSignature? insig,
    InputSequence sequence = InputSequence.enforceLocktime,
  }) : this._(
    prevOut: prevOut,
    controlBlock: taproot.controlBlockForLeaf(leaf),
    leaf: leaf,
    insig: insig,
    defaultSigHash: defaultSigHash,
    sequence: sequence,
  );

  /// Create an APO input specifying a [Taproot] and [TapLeaf] that can be
  /// signed using ANYPREVOUT or ANYPREVOUTANYSCRIPT.
  TaprootSingleScriptSigInput.anyPrevOut({
    required Taproot taproot,
    required TapLeafChecksig leaf,
    SchnorrInputSignature? insig,
    InputSequence sequence = InputSequence.enforceLocktime,
  }) : this._(
    leaf: leaf,
    controlBlock: taproot.controlBlockForLeaf(leaf),
    insig: insig,
    defaultSigHash: false,
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
