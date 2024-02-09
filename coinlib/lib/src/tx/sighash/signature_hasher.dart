import 'dart:typed_data';
import 'package:coinlib/src/tx/sighash/sighash_type.dart';
import 'package:coinlib/src/tx/transaction.dart';

abstract interface class SignatureHasher {

  static void checkInputN(Transaction tx, int inputN) {
    if (inputN < 0 || inputN >= tx.inputs.length) {
      throw RangeError.index(inputN, tx.inputs, "inputN");
    }
  }

  static void checkSchnorrDisallowed(SigHashType type) {
    if (type.schnorrDefault) {
      throw ArgumentError(
        "Cannot create signature hash for legacy input using default Schnorr"
        "hash type",
      );
    }
  }

  Uint8List get hash;

}
