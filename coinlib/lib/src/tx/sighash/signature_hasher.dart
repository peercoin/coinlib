import 'dart:typed_data';
import 'package:coinlib/src/tx/transaction.dart';

abstract interface class SignatureHasher {

  static checkInputN(Transaction tx, int inputN) {
    if (inputN < 0 || inputN >= tx.inputs.length) {
      throw RangeError.index(inputN, tx.inputs, "inputN");
    }
  }

  Uint8List get hash;

}
