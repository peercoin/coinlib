import 'dart:typed_data';
import 'package:coinlib/src/crypto/ec_private_key.dart';
import 'package:coinlib/src/crypto/schnorr_signature.dart';
import 'package:coinlib/src/tx/output.dart';
import 'package:coinlib/src/tx/sighash/sighash_type.dart';
import 'package:coinlib/src/tx/sighash/taproot_signature_hasher.dart';
import 'package:coinlib/src/tx/transaction.dart';
import 'input.dart';
import 'input_signature.dart';
import 'witness_input.dart';

/// Represents v1 Taproot program inputs
abstract class TaprootInput extends WitnessInput {

  TaprootInput({
    required super.prevOut,
    required super.witness,
    super.sequence = Input.sequenceFinal,
  });

  /// Signs the input given the [tx], input number ([inputN]), private [key] and
  /// [prevOuts] using the specifified [hashType]. Should throw
  /// [CannotSignInput] if the key cannot sign the input. Implemented by
  /// specific subclasses.
  TaprootInput sign({
    required Transaction tx,
    required int inputN,
    required ECPrivateKey key,
    required List<Output> prevOuts,
    SigHashType hashType = const SigHashType.all(),
  }) => throw CannotSignInput("Unimplemented sign() for {this.runtimeType}");

  /// Creates a signature for the input. Used by subclasses to implement
  /// signing.
  SchnorrInputSignature createInputSignature({
    required Transaction tx,
    required int inputN,
    required ECPrivateKey key,
    required List<Output> prevOuts,
    SigHashType hashType = const SigHashType.all(),
    Uint8List? leafHash,
    int codeSeperatorPos = 0xFFFFFFFF,
  }) => SchnorrInputSignature(
    SchnorrSignature.sign(
      key,
      TaprootSignatureHasher(
        tx: tx,
        inputN: inputN,
        prevOuts: prevOuts,
        hashType: hashType,
        leafHash: leafHash,
        codeSeperatorPos: codeSeperatorPos,
      ).hash,
    ),
    hashType,
  );

}
