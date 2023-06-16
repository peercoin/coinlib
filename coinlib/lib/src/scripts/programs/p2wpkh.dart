import 'dart:typed_data';
import 'package:coinlib/src/crypto/ec_public_key.dart';
import 'package:coinlib/src/crypto/hash.dart';
import 'package:coinlib/src/scripts/operations.dart';
import 'package:coinlib/src/scripts/program.dart';
import 'package:coinlib/src/scripts/script.dart';

/// Pay-to-Witness-Public-Key-Hash program taking a 20-byte public key hash that
/// can satisfy this script with a signature provided as witness data.
class P2WPKH implements Program {

  static Script template = Script.fromAsm("0 <20-bytes>");

  @override
  final Script script;
  late final Uint8List pkHash;

  P2WPKH.fromScript(this.script) {
    if (!template.match(script)) throw NoProgramMatch();
    pkHash = (script[1] as ScriptPushData).data;
  }

  P2WPKH.decompile(Uint8List script)
    : this.fromScript(Script.decompile(script, requireMinimal: true));

  P2WPKH.fromAsm(String asm) : this.fromScript(Script.fromAsm(asm));

  P2WPKH.fromHash(this.pkHash) : script = template.fill([pkHash]);

  P2WPKH.fromPublicKey(ECPublicKey pk) : this.fromHash(hash160(pk.data));

}
