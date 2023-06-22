import 'dart:typed_data';
import 'package:coinlib/src/crypto/ec_public_key.dart';
import 'package:coinlib/src/scripts/operations.dart';
import 'package:coinlib/src/scripts/program.dart';
import 'package:coinlib/src/scripts/script.dart';

class MultisigProgram implements Program {

  static int maxPubkeys = 20;
  static ScriptOp checkmultisig = ScriptOpCode.fromName("CHECKMULTISIG");

  @override
  final Script script;
  late final int threshold;
  late final List<ECPublicKey> pubkeys;

  MultisigProgram.fromScript(this.script) {

    // Must have threshold, 1-20 public keys, pubkey number and CHECKMULTISIG
    if (script.length < 4 || script.length > maxPubkeys+3) {
      throw NoProgramMatch();
    }

    if (!script.ops.last.match(checkmultisig)) throw NoProgramMatch();

    final pknum = script[script.length-2].number;
    if (
      pknum == null || pknum < 1 || pknum > maxPubkeys
      || script.length != pknum+3
    ) throw NoProgramMatch();

    final firstNum = script[0].number;
    if (firstNum == null) throw NoProgramMatch();
    threshold = firstNum;

    // Threshold must be within 1-pknum
    if (threshold < 1 || threshold > pknum) throw NoProgramMatch();

    // Check all public keys are push data and extract data
    final potentialPubkeys = script.ops.sublist(1, script.length-2);
    if (
      potentialPubkeys.any(
        (op) => op is! ScriptPushData
        || (op.data.length != 33 && op.data.length != 65),
      )
    ) throw NoProgramMatch();

    try {
      pubkeys = potentialPubkeys.map(
        (op) => ECPublicKey((op as ScriptPushData).data),
      ).toList();
    } on InvalidPublicKey {
      throw NoProgramMatch();
    }

  }

  MultisigProgram.decompile(Uint8List compiled)
    : this.fromScript(Script.decompile(compiled));

  MultisigProgram.fromAsm(String asm) : this.fromScript(Script.fromAsm(asm));

  MultisigProgram(this.threshold, Iterable<ECPublicKey> pubkeys)
    : pubkeys = pubkeys.toList(),
    script = Script([
      ScriptOp.fromNumber(threshold),
      ...pubkeys.map((pk) => ScriptPushData(pk.data)),
      ScriptOp.fromNumber(pubkeys.length),
      checkmultisig,
    ]) {

      if (pubkeys.isEmpty || pubkeys.length > maxPubkeys) {
        throw ArgumentError.value(
          pubkeys, "pubkeys", "must have length between 1 and $maxPubkeys",
        );
      }

      if (threshold < 1 || threshold > pubkeys.length) {
        throw ArgumentError.value(
          threshold, "threshold",
          "must have length between 1 and the number of public keys",
        );
      }

    }

}
