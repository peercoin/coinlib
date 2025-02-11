import 'dart:typed_data';
import 'package:coinlib/src/crypto/ec_private_key.dart';
import 'package:coinlib/src/crypto/ec_public_key.dart';
import 'package:coinlib/src/scripts/programs/p2wpkh.dart';
import 'package:coinlib/src/tx/sign_details.dart';
import 'input.dart';
import 'input_signature.dart';
import 'pkh_input.dart';
import 'raw_input.dart';
import 'legacy_witness_input.dart';

/// An input for a Pay-to-Witness-Public-Key-Hash output ([P2WPKH]). This
/// contains the public key that should match the hash in the associated output.
/// It is either signed or unsigned. The [sign] method can be used to sign the
/// input with the corresponding [ECPrivateKey] or a signature can be added
/// without checks using [addSignature]. Signature and public key data is
/// stored in the witness data.
class P2WPKHInput extends LegacyWitnessInput with PKHInput {

  @override
  final ECPublicKey publicKey;
  @override
  final ECDSAInputSignature? insig;
  @override
  final int? signedSize = 147;

  P2WPKHInput({
    required super.prevOut,
    required this.publicKey,
    this.insig,
    super.sequence = Input.sequenceFinal,
  }) : super(
    witness: [
      if (insig != null) insig.bytes,
      publicKey.data,
    ],
  );

  /// Checks if the [raw] input and [witness] data match the expected format for
  /// a P2WPKHInput, with or without a signature. If it does it returns a
  /// [P2WPKHInput] for the input or else it returns null.
  static P2WPKHInput? match(RawInput raw, List<Uint8List> witness) {

    if (raw.scriptSig.isNotEmpty) return null;
    if (witness.isEmpty || witness.length > 2) return null;

    try {

      final insig = witness.length == 2
        ? ECDSAInputSignature.fromBytes(witness[0])
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

  @override
  LegacyWitnessInput sign({
    required LegacyWitnessSignDetails details,
    required ECPrivateKey key,
  }) => addSignature(
    createInputSignature(
      key: checkKey(key),
      details: details.addScript(scriptCode),
    ),
  );

  @override
  /// Returns a new [P2WPKHInput] with the [ECDSAInputSignature] added. Any
  /// existing signature is replaced.
  P2WPKHInput addSignature(ECDSAInputSignature insig) => P2WPKHInput(
    prevOut: prevOut,
    publicKey: publicKey,
    insig: insig,
    sequence: sequence,
  );

  @override
  P2WPKHInput filterSignatures(bool Function(InputSignature insig) predicate)
    => insig == null || predicate(insig!) ? this : P2WPKHInput(
      prevOut: prevOut,
      publicKey: publicKey,
      insig: null,
      sequence: sequence,
    );

}
