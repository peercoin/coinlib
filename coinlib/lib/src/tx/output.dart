import 'dart:typed_data';

import 'package:coinlib/src/address.dart';
import 'package:coinlib/src/common/checks.dart';
import 'package:coinlib/src/common/serial.dart';
import 'package:coinlib/src/scripts/program.dart';
import 'package:coinlib/src/scripts/script.dart';
import 'package:coinlib/src/tx/sighash/sighash_type.dart';

/// A transaction output that carries a [value] and [program] specifying how the
/// value can be spent.
class Output._(
  final BigInt value,
  Uint8List scriptPubKey,
  final Program? program,
) with Writable {
  /// Max 64-bit integer
  static final maxValue = (BigInt.from(1) << 64) - BigInt.one;

  final Uint8List _scriptPubKey = Uint8List.fromList(scriptPubKey);
  this {
    checkUint64(value, "this.value");
  }

  new fromProgram(BigInt value, Program program)
    : this._(
        value,
        program.script.compiled,
        program,
      );

  factory fromScriptBytes(BigInt value, Uint8List scriptPubKey) {
    late Program? program;
    try {
      program = Program.decompile(scriptPubKey);
    } on Exception {
      program = null;
    }

    return Output._(value, scriptPubKey, program);
  }

  new fromAddress(BigInt value, Address address)
    : this.fromProgram(value, address.program);

  /// The output used for blanking outputs when using [SigHashType.single].
  new blank() : this.fromProgram(maxValue, RawProgram(Script([])));

  factory fromReader(BytesReader reader) => Output.fromScriptBytes(
    reader.readUInt64(),
    reader.readVarSlice(),
  );

  @override
  void write(Writer writer) {
    writer.writeUInt64(value);
    writer.writeVarSlice(_scriptPubKey);
  }

  Uint8List get scriptPubKey => Uint8List.fromList(_scriptPubKey);
}
