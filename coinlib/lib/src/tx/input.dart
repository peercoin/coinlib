import 'dart:typed_data';
import 'raw_input.dart';

/// The base-class for all inputs, providing the [match] factory constructor to
/// determine the appropriate subclass.
abstract class Input {

  /// Given a [RawInput] and witness data, the specific [Input] subclass is
  /// returned. If there is no witness data for the input, the [witness] can be
  /// excluded or provided as an empty list.
  factory Input.match(RawInput raw, [List<Uint8List> witness = const[]]) => raw;

  /// True when the input is fully signed and ready for broadcast
  bool get complete;

}
