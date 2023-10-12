import 'dart:typed_data';
import 'package:coinlib/src/crypto/ecdsa_signature.dart';
import 'package:coinlib/src/tx/sighash/sighash_type.dart';

class InvalidInputSignature implements Exception {}

/// The base for input signatures that carry a [hashType].
abstract interface class InputSignature {
  SigHashType get hashType;
  Uint8List get bytes;
}

/// Encapsulates an ECDSA [signature] and [hashType] for inclusion in an
/// [Input].
class ECDSAInputSignature implements InputSignature {

  final ECDSASignature signature;
  @override
  final SigHashType hashType;

  ECDSAInputSignature(this.signature, [this.hashType = const SigHashType.all()]);

  factory ECDSAInputSignature.fromBytes(Uint8List bytes) {

    if (bytes.isEmpty) throw InvalidInputSignature();

    late ECDSASignature sig;
    try {
      sig = ECDSASignature.fromDer(bytes.sublist(0, bytes.length-1));
    } on InvalidECDSASignature {
      throw InvalidInputSignature();
    }

    final hashType = bytes.last;
    if (!SigHashType.validValue(hashType)) throw InvalidInputSignature();

    return ECDSAInputSignature(sig, SigHashType.fromValue(hashType));

  }

  @override
  Uint8List get bytes => Uint8List.fromList([...signature.der, hashType.value]);

}
