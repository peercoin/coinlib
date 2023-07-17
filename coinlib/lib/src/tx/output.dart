import 'package:coinlib/src/address.dart';
import 'package:coinlib/src/common/checks.dart';
import 'package:coinlib/src/common/serial.dart';
import 'package:coinlib/src/scripts/program.dart';
import 'package:coinlib/src/scripts/script.dart';

/// A transaction output that carries a [value] and [program] specifying how the
/// value can be spent.
class Output with Writable {

  /// Max 64-bit integer
  static BigInt maxValue = (BigInt.from(1) << 64) - BigInt.one;

  final BigInt value;
  final Program program;

  Output(this.value, this.program) {
    checkUint64(value, "this.value");
  }
  Output.fromAddress(BigInt value, Address address)
    : this(value, address.program);
  /// The output used for blanking outputs when using [SigHashType.single].
  Output.blank() : this(maxValue, RawProgram(Script([])));

  factory Output.fromReader(BytesReader reader) => Output(
    reader.readUInt64(),
    Program.decompile(reader.readVarSlice()),
  );

  @override
  void write(Writer writer) {
    writer.writeUInt64(value);
    writer.writeVarSlice(program.script.compiled);
  }

}
