import 'dart:typed_data';
import 'package:coinlib/src/crypto/ecdsa_signature.dart';

/// Encapsulates an ECDSA [signature] and [hashType] for inclusion in an
/// [Input].
class InputSignature {

  static int sigHashAll = 1;
  static int sigHashNone = 2;
  static int sigHashSingle = 2;
  static int sigHashAnyoneCanPay = 0x80;

  final ECDSASignature signature;
  final int hashType;

  InputSignature(this.signature, this.hashType) {
    final hashTypeMod = hashType & ~sigHashAnyoneCanPay;
    if (hashTypeMod < sigHashAll || hashTypeMod > sigHashSingle) {
      throw ArgumentError.value(
        hashType, "this.hashType", "not a valid hash type",
      );
    }
  }

  InputSignature.fromBytes(Uint8List bytes) : this(
    ECDSASignature.fromDer(bytes.sublist(0, bytes.length-1)),
    bytes.last,
  );

  Uint8List get bytes => Uint8List.fromList([...signature.der, hashType]);

}
