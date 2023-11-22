import 'dart:typed_data';
import 'input.dart';
import 'raw_input.dart';
import 'p2wpkh_input.dart';
import 'taproot_key_input.dart';
import 'taproot_script_input.dart';

/// The base-class for all witness inputs
class WitnessInput extends RawInput {

  final List<Uint8List> witness;

  WitnessInput({
    required super.prevOut,
    required List<Uint8List> witness,
    super.sequence = Input.sequenceFinal,
  }) : witness = List.unmodifiable(witness), super(scriptSig: Uint8List(0));

  /// Matches a [raw] input with witness data to a corresponding [WitnessInput]
  /// or specialised sub-class object. If this is not a witness input, null is
  /// returned.
  static WitnessInput? match(RawInput raw, List<Uint8List> witness)
    => raw.scriptSig.isEmpty && witness.isNotEmpty
      ? (
        // Is a witness input, so match with the specific input type
        P2WPKHInput.match(raw, witness)
        ?? TaprootKeyInput.match(raw, witness)
        ?? TaprootScriptInput.match(raw, witness)
        ?? WitnessInput(
          prevOut: raw.prevOut,
          witness: witness,
          sequence: raw.sequence,
        )
      )
      : null;

}
