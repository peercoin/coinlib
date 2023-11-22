import 'dart:typed_data';
import 'package:coinlib/src/common/bytes.dart';
import 'package:coinlib/src/crypto/ec_public_key.dart';
import 'package:coinlib/src/crypto/hash.dart';
import 'package:coinlib/src/scripts/program.dart';
import 'package:coinlib/src/scripts/programs/p2witness.dart';
import 'package:coinlib/src/scripts/script.dart';

/// Pay-to-Witness-Public-Key-Hash program taking a 20-byte public key hash that
/// can satisfy this script with a signature provided as witness data.
class P2WPKH extends P2Witness {

  P2WPKH.fromScript(super.script) : super.fromScript() {
    if (data.length != 20 || version != 0) throw NoProgramMatch();
  }

  P2WPKH.decompile(Uint8List compiled)
    : this.fromScript(Script.decompile(compiled));

  P2WPKH.fromAsm(String asm) : this.fromScript(Script.fromAsm(asm));

  P2WPKH.fromHash(Uint8List pkHash)
    : super.fromData(0, checkBytes(pkHash, 20, name: "PK hash"));

  P2WPKH.fromPublicKey(ECPublicKey pk) : this.fromHash(hash160(pk.data));

  Uint8List get pkHash => data;

}
