import 'dart:typed_data';
import 'package:coinlib/src/scripts/script.dart';
import 'outpoint.dart';
import 'raw_input.dart';
import 'p2wpkh_input.dart';

/// The base-class for all witness inputs
class WitnessInput extends RawInput {

  final List<Uint8List> witness;

  WitnessInput({
    required OutPoint prevOut,
    required int sequence,
    required this.witness,
  }) : super(
    prevOut: prevOut,
    scriptSig: Script([]),
    sequence: sequence,
  );

  /// Matches a [raw] input with witness data to a corresponding [WitnessInput]
  /// or specialised sub-class object. If this is not a witness input, null is
  /// returned.
  static WitnessInput? match(RawInput raw, List<Uint8List> witness)
    => raw.scriptSig.ops.isEmpty && witness.isNotEmpty
      ? (
        // Is a witness input, so match with the specific input type
        P2WPKHInput.match(raw, witness)
        ?? WitnessInput(
          prevOut: raw.prevOut,
          sequence: raw.sequence,
          witness: witness,
        )
      )
      : null;

}
