import 'dart:typed_data';
import 'package:coinlib/src/common/bytes.dart';
import 'package:coinlib/src/crypto/hash.dart';
import 'package:coinlib/src/scripts/program.dart';
import 'package:coinlib/src/scripts/programs/p2witness.dart';
import 'package:coinlib/src/scripts/script.dart';

/// Pay-to-Witness-Script-Hash program taking a 32-byte script hash for a redeem
/// script whereby the redeem script and other push data is to be provided as
/// witness data.
class P2WSH extends P2Witness {

  /// Construct using an output script, not to be confused with the redeem
  /// script. For that use [fromRedeemScript].
  P2WSH.fromScript(Script script) : super.fromScript(script) {
    if (data.length != 32 || version != 0) throw NoProgramMatch();
  }

  P2WSH.decompile(Uint8List compiled)
    : this.fromScript(Script.decompile(compiled));

  P2WSH.fromAsm(String asm) : this.fromScript(Script.fromAsm(asm));

  P2WSH.fromHash(Uint8List scriptHash)
    : super.fromData(0, checkBytes(scriptHash, 32, name: "Script hash"));

  P2WSH.fromRedeemScript(Script redeemScript)
    : this.fromHash(sha256Hash(redeemScript.compiled));

  Uint8List get scriptHash => data;

}
