import 'dart:typed_data';
import 'package:coinlib/src/common/serial.dart';
import 'package:coinlib/src/scripts/script.dart';
import 'package:coinlib/src/tx/input_signature.dart';
import 'outpoint.dart';
import 'p2pkh_input.dart';
import 'p2sh_multisig_input.dart';
import 'raw_input.dart';
import 'witness_input.dart';

/// The base class for all inputs, providing the [match] factory constructor to
/// determine the appropriate subclass from a [RawInput]
abstract class Input with Writable {

  static const sequenceFinal = 0xffffffff;

  OutPoint get prevOut;
  Uint8List get scriptSig;
  int get sequence;

  /// True when the input is fully signed and ready for broadcast
  bool get complete;

  Input();

  /// Given a [RawInput] and witness data, the specific [Input] subclass is
  /// returned. If there is no witness data for the input, the [witness] can be
  /// excluded or provided as an empty list.
  factory Input.match(RawInput raw, [List<Uint8List> witness = const[]])
    => P2PKHInput.match(raw)
    ?? P2SHMultisigInput.match(raw)
    ?? WitnessInput.match(raw, witness)
    ?? raw;

  /// Removes signatures that the [predicate] returns false for. This is used to
  /// remove invalidated signatures.
  Input filterSignatures(bool Function(InputSignature insig) predicate);

  /// The script from the [scriptSig] bytes or null if the bytes do not
  /// represent a valid script.
  Script? get script {
    try {
      return Script.decompile(scriptSig);
    } on Exception {
      return null;
    }
  }

}
