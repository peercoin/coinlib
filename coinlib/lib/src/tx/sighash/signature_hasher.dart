import 'dart:typed_data';
import 'package:coinlib/src/tx/transaction.dart';
import 'sighash_type.dart';

abstract interface class SignatureHasher {

  static void checkInputN(Transaction tx, int inputN) {
    if (inputN < 0 || inputN >= tx.inputs.length) {
      throw RangeError.index(inputN, tx.inputs, "inputN");
    }
  }

  static void checkLegacySigHashType(SigHashType type) {
    if (!type.supportsLegacy) {
      throw ArgumentError.value(
        type, "type",
        "hash type is not supported for legacy signature hashes",
      );
    }
  }

  Uint8List get hash;

}
