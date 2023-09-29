import 'dart:typed_data';
import 'package:coinlib/src/crypto/ecdsa_signature.dart';
import 'sighash/sighash_type.dart';

class InvalidInputSignature implements Exception {}

/// Encapsulates an ECDSA [signature] and [hashType] for inclusion in an
/// [Input].
class InputSignature {

  final ECDSASignature signature;
  final SigHashType hashType;

  InputSignature(this.signature, [this.hashType = const SigHashType.all()]);

  factory InputSignature.fromBytes(Uint8List bytes) {

    if (bytes.isEmpty) throw InvalidInputSignature();

    late ECDSASignature sig;
    try {
      sig = ECDSASignature.fromDer(bytes.sublist(0, bytes.length-1));
    } on InvalidECDSASignature {
      throw InvalidInputSignature();
    }

    final hashType = bytes.last;
    if (!SigHashType.validValue(hashType)) throw InvalidInputSignature();

    return InputSignature(sig, SigHashType.fromValue(hashType));

  }

  Uint8List get bytes => Uint8List.fromList([...signature.der, hashType.value]);

}
