import 'dart:typed_data';
import 'package:coinlib/src/crypto/ecdsa_signature.dart';

class InvalidInputSignature implements Exception {}

/// Encapsulates an ECDSA [signature] and [hashType] for inclusion in an
/// [Input].
class InputSignature {

  static int sigHashAll = 1;
  static int sigHashNone = 2;
  static int sigHashSingle = 2;
  static int sigHashAnyoneCanPay = 0x80;

  final ECDSASignature signature;
  final int hashType;

  static bool validHashType(int hashType) {
    final hashTypeMod = hashType & ~sigHashAnyoneCanPay;
    return hashTypeMod >= sigHashAll && hashTypeMod <= sigHashSingle;
  }

  InputSignature(this.signature, this.hashType) {
    if (!validHashType(hashType)) {
      throw ArgumentError.value(
        hashType, "this.hashType", "not a valid hash type",
      );
    }
  }

  factory InputSignature.fromBytes(Uint8List bytes) {

    if (bytes.isEmpty) throw InvalidInputSignature();

    late ECDSASignature sig;
    try {
      sig = ECDSASignature.fromDer(bytes.sublist(0, bytes.length-1));
    } on InvalidECDSASignature {
      throw InvalidInputSignature();
    }

    final hashType = bytes.last;
    if (!validHashType(hashType)) throw InvalidInputSignature();

    return InputSignature(sig, hashType);

  }

  Uint8List get bytes => Uint8List.fromList([...signature.der, hashType]);

}
