import 'package:coinlib/src/common/serial.dart';
import 'package:coinlib/src/scripts/script.dart';
import 'input.dart';
import 'outpoint.dart';

/// A transaction input without any associated witness data that acts as the
/// base for all other inputs as all inputs include a outpoint, script and
/// sequence number.
class RawInput with Writable implements Input {

  final OutPoint prevOut;
  final Script scriptSig;
  final int sequence;

  RawInput({
    required this.prevOut,
    required this.scriptSig,
    required this.sequence,
  });

  RawInput.fromReader(BytesReader reader)
    : prevOut = OutPoint.fromReader(reader),
    scriptSig = Script.decompile(reader.readVarSlice()),
    sequence = reader.readInt32();

  @override
  void write(Writer writer) {
    prevOut.write(writer);
    writer.writeVarSlice(scriptSig.compiled);
    writer.writeUInt32(sequence);
  }

  /// Always true as a simple [RawInput] is assumed to be fully signed as there
  /// is no way to determine if it is or not.
  @override
  bool get complete => true;

}
