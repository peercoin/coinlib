import 'dart:typed_data';
import 'package:coinlib/src/common/bytes.dart';
import 'package:coinlib/src/crypto/ec_public_key.dart';
import 'package:coinlib/src/crypto/hash.dart';
import 'package:coinlib/src/scripts/operations.dart';
import 'package:coinlib/src/scripts/program.dart';
import 'package:coinlib/src/scripts/script.dart';

/// Pay-to-Public-Key-Hash program taking a 20-byte public key hash that can
/// satisfy this script with a signature.
class P2PKH implements Program {

  static final template = Script.fromAsm(
    "OP_DUP OP_HASH160 <20-bytes> OP_EQUALVERIFY OP_CHECKSIG",
  );

  @override
  final Script script;
  late final Uint8List _pkHash;

  P2PKH.fromScript(this.script) {
    if (!template.match(script)) throw NoProgramMatch();
    _pkHash = (script[2] as ScriptPushData).data;
  }

  P2PKH.decompile(Uint8List compiled)
    : this.fromScript(Script.decompile(compiled));

  P2PKH.fromAsm(String asm) : this.fromScript(Script.fromAsm(asm));

  P2PKH.fromHash(Uint8List pkHash)
    : _pkHash = copyCheckBytes(pkHash, 20), script = template.fill([pkHash]);

  P2PKH.fromPublicKey(ECPublicKey pk) : this.fromHash(hash160(pk.data));

  Uint8List get pkHash => Uint8List.fromList(_pkHash);

}
