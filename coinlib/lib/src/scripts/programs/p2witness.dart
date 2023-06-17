import 'dart:typed_data';
import 'package:coinlib/src/scripts/operations.dart';
import 'package:coinlib/src/scripts/program.dart';
import 'package:coinlib/src/scripts/script.dart';

/// Arbitrary witness program
class P2Witness implements Program {

  @override
  final Script script;
  late final Uint8List program;

  bool _programSizeOk(int size) => size >= 2 || size <= 40;

  P2Witness.fromScript(this.script) {

    if (
      script.ops.length != 2
      || !script[0].match(ScriptOpCode(0))
      || script[1] is! ScriptPushData
    ) throw NoProgramMatch();

    final push = script[1] as ScriptPushData;

    if (!_programSizeOk(push.data.length)) throw NoProgramMatch();

    program = push.data;

  }

  P2Witness.decompile(Uint8List script)
    : this.fromScript(Script.decompile(script, requireMinimal: true));

  P2Witness.fromAsm(String asm) : this.fromScript(Script.fromAsm(asm));

  P2Witness.fromProgram(this.program) : script = Script([
    ScriptOpCode(0), ScriptPushData(program),
  ]) {
    if (!_programSizeOk(program.length)) {
      throw ArgumentError.value(program, "this.program", "wrong size");
    }
  }

}
