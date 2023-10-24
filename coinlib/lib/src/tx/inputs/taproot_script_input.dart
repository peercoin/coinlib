import 'dart:typed_data';
import 'package:coinlib/src/common/serial.dart';
import 'package:coinlib/src/scripts/operations.dart';
import 'package:coinlib/src/scripts/script.dart';
import 'package:coinlib/src/taproot.dart';
import 'package:coinlib/src/tx/inputs/taproot_input.dart';
import 'package:coinlib/src/tx/outpoint.dart';
import 'input.dart';
import 'raw_input.dart';

/// A [TaprootInput] which spends using the script-path for 0xc0 version
/// Tapscripts. There is no signing logic and sign() is not implemented.
/// Subclasses should handle signing. [createInputSignature] can be used to
/// create signatures for insertion as necessary.
class TaprootScriptInput extends TaprootInput {

  /// The tapscript embedded in the witness data, not to be confused with the
  /// empty [script].
  final Script tapscript;

  TaprootScriptInput({
    required OutPoint prevOut,
    required Uint8List controlBlock,
    required this.tapscript,
    List<Uint8List>? stack,
    int sequence = Input.sequenceFinal,
  }) : super(
    prevOut: prevOut,
    sequence: sequence,
    witness: [if (stack != null) ...stack, tapscript.compiled, controlBlock],
  );

  TaprootScriptInput.fromTaprootLeaf({
    required OutPoint prevOut,
    required Taproot taproot,
    required TapLeaf leaf,
    List<Uint8List>? stack,
    int sequence = Input.sequenceFinal,
  }) : this(
    prevOut: prevOut,
    controlBlock: taproot.controlBlockForLeaf(leaf),
    tapscript: leaf.script,
    stack: stack,
    sequence: sequence,
  );

  /// Checks if the [raw] input and [witness] data match the expected format for
  /// a [TaprootScriptInput] with the control block and script. If it matches
  /// this returns a [TaprootScriptInput] for the input or else it returns null.
  /// The script must be valid with minimal push data. The control block must be
  /// the correct size and contain the correct 0xc0 tapscript version but the
  /// internal key and parity bit is not validated.
  static TaprootScriptInput? match(RawInput raw, List<Uint8List> witness) {

    if (raw.scriptSig.isNotEmpty) return null;
    if (witness.length < 2) return null;

    final controlBlock = witness.last;
    final lengthAfterKey = controlBlock.length - 33;

    if (
      controlBlock.length < 33
      || lengthAfterKey % 32 != 0
      || lengthAfterKey / 32 > 128
      || controlBlock[0] & 0xfe != TapLeaf.tapscriptVersion
    ) {
      return null;
    }

    try {

      return TaprootScriptInput(
        prevOut: raw.prevOut,
        controlBlock: controlBlock,
        tapscript: Script.decompile(witness[witness.length-2]),
        stack: witness.sublist(0, witness.length-2),
        sequence: raw.sequence,
      );

    } on OutOfData {
      return null;
    } on PushDataNotMinimal {
      return null;
    }

  }

  Uint8List get controlBlock => witness.last;

}
