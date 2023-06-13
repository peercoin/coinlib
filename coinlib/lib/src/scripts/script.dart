import 'dart:typed_data';
import 'package:coinlib/src/common/serial.dart';
import 'operations.dart';

class Script {

  // A read only list of the script operations
  final List<ScriptOp> ops;
  Uint8List? _compiledCache;
  String? _asmCache;

  /// Constructs a script from the operations without constructing a sub-class
  /// script that matches the operations.
  Script.raw(List<ScriptOp> ops) : ops = List<ScriptOp>.unmodifiable(ops);

  /// Takes a list of script operations ([ops]) and constructs a matching
  /// subclass if one exists, or a basic [Script] class if there is no match.
  factory Script.match(List<ScriptOp> ops) {
    // TODO: Add script types
    return Script.raw(ops);
  }

  /// Decompiles the script and may return a sub-class representing the script
  /// type. May return [OutOfData] if the script has an invalid pushdata.
  /// If [requireMinimal] is true, the script push push data minimally or
  /// [PushDataNotMinimal] will be thrown.
  factory Script.decompile(Uint8List script, { bool requireMinimal = false }) {

    final List<ScriptOp> ops = [];
    final reader = BytesReader(script);

    // Read all the operations into the list
    while (!reader.atEnd) {
      ops.add(ScriptOp.fromReader(reader, requireMinimal: requireMinimal));
    }

    return Script.match(ops);

  }

  /// Constructs a script from the given script assembly string ([asm]). May
  /// return a matching sub-class for the given script.
  factory Script.fromASM(String asm) => Script.match(
    asm.split(" ").map((s) => ScriptOp.fromAsm(s)).toList(),
  );

  /// Returns the copied compiled bytes for the script.
  Uint8List get compiled => Uint8List.fromList(
    _compiledCache ??= Uint8List.fromList(
      ops.fold(<int>[], (prev, op) => prev + op.compiled),
    ),
  );

  /// Returns the ASM string representation of the script. All data and integers
  /// are provided in hex format.
  String get asm => _asmCache ??= ops.map((op) => op.asm).join(" ");

}
