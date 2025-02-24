import 'dart:typed_data';
import 'package:coinlib/src/common/bytes.dart';
import 'package:coinlib/src/crypto/ec_public_key.dart';
import 'package:coinlib/src/scripts/program.dart';
import 'package:coinlib/src/scripts/programs/p2witness.dart';
import 'package:coinlib/src/scripts/script.dart';
import 'package:coinlib/src/taproot/taproot.dart';

/// Pay-to-Taproot program taking a 32-byte Taproot tweaked key.
class P2TR extends P2Witness {

  /// Construct using an output script.
  P2TR.fromScript(super.script) : super.fromScript() {
    if (data.length != 32 || version != 1) throw NoProgramMatch();
  }

  P2TR.decompile(Uint8List compiled)
    : this.fromScript(Script.decompile(compiled));

  P2TR.fromAsm(String asm) : this.fromScript(Script.fromAsm(asm));

  /// Creates a P2TR program with the 32-byte X-only tweaked public key.
  P2TR.fromTweakedKeyX(Uint8List tweakedKeyX)
    : super.fromData(1, checkBytes(tweakedKeyX, 32));

  /// Creates a P2TR program with a given [tweakedKey].
  P2TR.fromTweakedKey(ECPublicKey tweakedKey) : super.fromData(1, tweakedKey.x);

  /// Creates a P2TR program from a [Taproot] object.
  P2TR.fromTaproot(Taproot taproot) : this.fromTweakedKey(taproot.tweakedKey);

  ECPublicKey get tweakedKey => ECPublicKey.fromXOnly(data);

}
