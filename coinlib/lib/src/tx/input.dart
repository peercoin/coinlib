import 'dart:typed_data';
import 'package:coinlib/src/common/serial.dart';
import 'package:coinlib/src/scripts/script.dart';
import 'package:coinlib/src/tx/outpoint.dart';
import 'package:coinlib/src/tx/p2pkh_input.dart';
import 'raw_input.dart';

/// The base class for all inputs, providing the [match] factory constructor to
/// determine the appropriate subclass from a [RawInput]
abstract class Input with Writable {

  OutPoint get prevOut;
  Script get scriptSig;
  int get sequence;

  /// True when the input is fully signed and ready for broadcast
  bool get complete;

  Input();

  /// Given a [RawInput] and witness data, the specific [Input] subclass is
  /// returned. If there is no witness data for the input, the [witness] can be
  /// excluded or provided as an empty list.
  factory Input.match(RawInput raw, [List<Uint8List> witness = const[]])
    => P2PKHInput.match(raw) ?? raw;

}
