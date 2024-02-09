import 'dart:typed_data';
import 'package:coinlib/src/crypto/ec_private_key.dart';
import 'package:coinlib/src/scripts/programs/p2tr.dart';
import 'package:coinlib/src/taproot.dart';
import 'package:coinlib/src/tx/inputs/taproot_input.dart';
import 'package:coinlib/src/tx/output.dart';
import 'package:coinlib/src/tx/sighash/sighash_type.dart';
import 'package:coinlib/src/tx/transaction.dart';
import 'input.dart';
import 'input_signature.dart';
import 'raw_input.dart';

/// A [TaprootInput] which spends using the key-path
class TaprootKeyInput extends TaprootInput {

  final SchnorrInputSignature? insig;

  @override
  // 64-bit sig plus varint with default sighash type
  final int? signedSize = 41 + 65;

  TaprootKeyInput({
    required super.prevOut,
    this.insig,
    super.sequence = Input.sequenceFinal,
  }) : super(witness: [if (insig != null) insig.bytes]);

  /// Checks if the [raw] input and [witness] data match the expected format for
  /// a [TaprootKeyInput], with a signature. If it does it returns a
  /// [TaprootKeyInput] for the input or else it returns null.
  static TaprootKeyInput? match(RawInput raw, List<Uint8List> witness) {

    if (raw.scriptSig.isNotEmpty) return null;
    if (witness.length != 1) return null;

    try {
      return TaprootKeyInput(
        prevOut: raw.prevOut,
        insig: SchnorrInputSignature.fromBytes(witness[0]),
        sequence: raw.sequence,
      );
    } on InvalidInputSignature {
      return null;
    }

  }

  @override
  /// Return a signed Taproot input using tweaked private key for the key-path
  /// spend. The [key] should be tweaked by [Taproot.tweakScalar].
  TaprootKeyInput sign({
    required Transaction tx,
    required int inputN,
    required ECPrivateKey key,
    required List<Output> prevOuts,
    SigHashType hashType = const SigHashType.all(),
  }) {

    if (inputN >= prevOuts.length) {
      throw CannotSignInput(
        "Input is out of range of the previous outputs provided",
      );
    }

    // Check key corresponds to matching prevOut
    final program = prevOuts[inputN].program;
    if (program is! P2TR || key.pubkey.xonly != program.tweakedKey) {
      throw CannotSignInput(
        "Key cannot sign for Taproot input's tweaked key",
      );
    }

    return addSignature(
      createInputSignature(
        tx: tx,
        inputN: inputN,
        key: key,
        prevOuts: prevOuts,
        hashType: hashType,
      ),
    );

  }

  /// Returns a new [TaprootKeyInput] with the [SchnorrInputSignature] added.
  /// Any existing signature is replaced.
  TaprootKeyInput addSignature(SchnorrInputSignature insig) => TaprootKeyInput(
    prevOut: prevOut,
    insig: insig,
    sequence: sequence,
  );

  @override
  TaprootKeyInput filterSignatures(
    bool Function(InputSignature insig) predicate,
  ) => insig == null || predicate(insig!) ? this : TaprootKeyInput(
    prevOut: prevOut,
    insig: null,
    sequence: sequence,
  );

  @override
  bool get complete => insig != null;

}
