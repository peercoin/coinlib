import 'dart:typed_data';
import 'package:coinlib/src/crypto/ecdsa_signature.dart';
import 'package:coinlib/src/crypto/schnorr_signature.dart';
import 'package:coinlib/src/tx/sighash/sighash_type.dart';
import 'input.dart';

class InvalidInputSignature implements Exception {}

SigHashType _hashTypeFromValueWithCheck(int value) {
  if (value == 0 || !SigHashType.validValue(value)) {
    throw InvalidInputSignature();
  }
  return SigHashType.fromValue(value);
}

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

  ECDSAInputSignature(
    this.signature,
    [this.hashType = const SigHashType.all(),]
  ) {
    if (!hashType.supportsLegacy) throw InvalidInputSignature();
  }

  factory ECDSAInputSignature.fromBytes(Uint8List bytes) {

    if (bytes.isEmpty) throw InvalidInputSignature();

    late ECDSASignature sig;
    try {
      sig = ECDSASignature.fromDer(bytes.sublist(0, bytes.length-1));
    } on InvalidECDSASignature {
      throw InvalidInputSignature();
    }

    return ECDSAInputSignature(sig, _hashTypeFromValueWithCheck(bytes.last));

  }

  @override
  Uint8List get bytes => Uint8List.fromList([...signature.der, hashType.value]);

}

/// Encapsulates a Schnorr [signature] and [hashType] for inclusion in a Taproot
/// input.
class SchnorrInputSignature implements InputSignature {

  final SchnorrSignature signature;
  @override
  final SigHashType hashType;

  SchnorrInputSignature(
    this.signature,
    [this.hashType = const SigHashType.schnorrDefault(),]
  );

  factory SchnorrInputSignature.fromBytes(Uint8List bytes) {

    if (bytes.length != 64 && bytes.length != 65) throw InvalidInputSignature();

    return SchnorrInputSignature(
      SchnorrSignature(bytes.sublist(0, 64)),
      bytes.length == 65
        ? _hashTypeFromValueWithCheck(bytes.last)
        : SigHashType.schnorrDefault(),
    );

  }

  @override
  Uint8List get bytes => Uint8List.fromList(
    [
      ...signature.data,
      if (!hashType.schnorrDefault) hashType.value,
    ]
  );

}
