import 'dart:typed_data';

import '../../../coinlib.dart';

class MwebScriptOp implements ScriptOp {
  final Uint8List data;

  MwebScriptOp(this.data);

  @override
  String get asm => throw UnimplementedError();

  @override
  Uint8List get compiled => data;

  @override
  ECDSAInputSignature? get ecdsaSig => null;

  @override
  bool match(ScriptOp other) {
    throw UnimplementedError();
  }

  @override
  int? get number => null;

  @override
  ECPublicKey? get publicKey => null;

  @override
  SchnorrInputSignature? get schnorrSig => null;
}
