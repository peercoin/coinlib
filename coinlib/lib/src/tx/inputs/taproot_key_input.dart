import 'dart:typed_data';
import 'package:coinlib/src/crypto/ec_private_key.dart';
import 'package:coinlib/src/scripts/programs/p2tr.dart';
import 'package:coinlib/src/taproot/taproot.dart';
import 'package:coinlib/src/tx/inputs/taproot_input.dart';
import 'package:coinlib/src/tx/sign_details.dart';
import 'package:coinlib/src/tx/transaction.dart';
import 'input.dart';
import 'input_signature.dart';
import 'raw_input.dart';

/// A [TaprootInput] which spends using the key-path
class TaprootKeyInput extends TaprootInput {

  final SchnorrInputSignature? insig;

  @override
  // 41 bytes for legacy input data
  // 64 witness signature bytes
  // 1 potential sighash byte
  // 2 bytes for witness varints
  final int signedSize = 41 + 64 + 1 + 2;

  @override
  // Minus the sighash byte
  int get defaultSignedSize => signedSize - 1;

  TaprootKeyInput({
    required super.prevOut,
    this.insig,
    super.sequence = Input.sequenceFinal,
  }) : super(witness: [insig != null ? insig.bytes : Uint8List(0)]);

  /// Checks if the [raw] input and [witness] data match the expected format for
  /// a [TaprootKeyInput], with a signature. If it does it returns a
  /// [TaprootKeyInput] for the input or else it returns null.
  static TaprootKeyInput? match(RawInput raw, List<Uint8List> witness) {

    if (raw.scriptSig.isNotEmpty) return null;
    if (witness.length != 1) return null;

    try {
      final sig = witness.first;
      return TaprootKeyInput(
        prevOut: raw.prevOut,
        insig: sig.isEmpty ? null : SchnorrInputSignature.fromBytes(witness[0]),
        sequence: raw.sequence,
      );
    } on InvalidInputSignature {
      return null;
    }

  }

  /// Return a signed Taproot input using tweaked private key for the key-path
  /// spend. The [key] should be tweaked by [Taproot.tweakScalar].
  TaprootKeyInput sign({
    required TaprootKeySignDetails details,
    required ECPrivateKey key,
  }) {

    // Check key corresponds to matching prevOut
    final program = details.program;
    if (program is! P2TR || key.pubkey.xonly != program.tweakedKey) {
      throw CannotSignInput(
        "Key cannot sign for Taproot input's tweaked key",
      );
    }

    return addSignature(createInputSignature(key: key, details: details));

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
