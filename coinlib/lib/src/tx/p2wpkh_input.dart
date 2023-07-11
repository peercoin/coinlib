import 'dart:typed_data';
import 'package:coinlib/src/crypto/ec_public_key.dart';
import 'package:coinlib/src/tx/input.dart';
import 'package:coinlib/src/tx/input_signature.dart';
import 'package:coinlib/src/tx/outpoint.dart';
import 'raw_input.dart';
import 'witness_input.dart';

/// An input for a Pay-to-Witness-Public-Key-Hash output ([P2WPKH]). This
/// contains the public key that should match the hash in the associated output.
/// It is either signed or unsigned and the [addSignature] method can be used to
/// add a signature. Signature and public key data is stored in the witness
/// data.
class P2WPKHInput extends WitnessInput {

  final ECPublicKey publicKey;
  final InputSignature? insig;

  P2WPKHInput({
    required OutPoint prevOut,
    required this.publicKey,
    this.insig,
    int sequence = Input.sequenceFinal,
  }) : super(
    prevOut: prevOut,
    sequence: sequence,
    witness: [
      if (insig != null) insig.bytes,
      publicKey.data,
    ],
  );

  /// Checks if the [raw] input and [witness] data match the expected format for
  /// a P2WPKHInput, with or without a signature. If it does it returns a
  /// [P2WPKHInput] for the input or else it returns null.
  static P2WPKHInput? match(RawInput raw, List<Uint8List> witness) {

    if (raw.scriptSig.ops.isNotEmpty) return null;
    if (witness.isEmpty || witness.length > 2) return null;

    try {

      final insig = witness.length == 2
        ? InputSignature.fromBytes(witness[0])
        : null;
      final publicKey = ECPublicKey(witness.last);

      return P2WPKHInput(
        prevOut: raw.prevOut,
        sequence: raw.sequence,
        publicKey: publicKey,
        insig: insig,
      );

    } on InvalidInputSignature {
      return null;
    } on InvalidPublicKey {
      return null;
    }

  }

  /// Returns a new [P2WPKHInput] with the [InputSignature] added. Any existing
  /// signature is replaced.
  P2WPKHInput addSignature(InputSignature insig) => P2WPKHInput(
    prevOut: prevOut,
    publicKey: publicKey,
    insig: insig,
    sequence: sequence,
  );

  @override
  bool get complete => insig != null;

}
