import 'dart:typed_data';
import 'package:coinlib/src/tx/inputs/input.dart';
import 'package:coinlib/src/tx/sign_details.dart';
import 'package:coinlib/src/tx/transaction.dart';
import 'sighash_type.dart';

abstract class SignatureHasher {
  Uint8List get hash;
  SignDetails get details;
  Transaction get tx => details.tx;
  int get inputN => details.inputN;
  SigHashType get hashType => details.hashType;
  Input get thisInput => tx.inputs[inputN];
}
