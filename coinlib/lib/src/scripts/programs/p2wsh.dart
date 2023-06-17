import 'dart:typed_data';
import 'package:coinlib/src/crypto/hash.dart';
import 'package:coinlib/src/scripts/operations.dart';
import 'package:coinlib/src/scripts/program.dart';
import 'package:coinlib/src/scripts/script.dart';

/// Pay-to-Witness-Script-Hash program taking a 32-byte script hash for a redeem
/// script whereby the redeem script and other push data is to be provided as
/// witness data.
class P2WSH implements Program {

  static Script template = Script.fromAsm("0 <32-bytes>");

  @override
  final Script script;
  late final Uint8List scriptHash;

  /// Construct using an output script, not to be confused with the redeem
  /// script. For that use [fromRedeemScript].
  P2WSH.fromScript(this.script) {
    if (!template.match(script)) throw NoProgramMatch();
    scriptHash = (script[1] as ScriptPushData).data;
  }

  P2WSH.decompile(Uint8List script)
    : this.fromScript(Script.decompile(script, requireMinimal: true));

  P2WSH.fromAsm(String asm) : this.fromScript(Script.fromAsm(asm));

  P2WSH.fromHash(this.scriptHash) : script = template.fill([scriptHash]);

  P2WSH.fromRedeemScript(Script redeemScript)
    : this.fromHash(sha256Hash(redeemScript.compiled));

}
