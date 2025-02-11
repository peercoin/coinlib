import 'dart:typed_data';
import 'package:coinlib/src/common/serial.dart';
import 'package:coinlib/src/crypto/hash.dart';
import 'package:coinlib/src/tx/sign_details.dart';
import 'precomputed_signature_hashes.dart';
import 'signature_hasher.dart';

/// Produces signature hashes for non-taproot witness inputs
final class WitnessSignatureHasher extends SignatureHasher with Writable {

  static final hashZero = Uint8List(32);

  @override
  final LegacyWitnessSignDetailsWithScript details;
  final TransactionSignatureHashes hashes;

  /// Produces the hash of an input signature for a non-taproot witness input.
  WitnessSignatureHasher(this.details)
    : hashes = TransactionSignatureHashes(details.tx);

  @override
  void write(Writer writer) {

    final hashPrevouts = !hashType.anyOneCanPay
      ? hashes.prevouts.doubleHash
      : hashZero;

    final hashSequences
      = !hashType.anyOneCanPay && !hashType.single && !hashType.none
      ? hashes.sequences.doubleHash
      : hashZero;

    final hashOutputs = !hashType.single && !hashType.none
      ? hashes.outputs.doubleHash
      : hashType.single && inputN < tx.outputs.length
        ? sha256DoubleHash(tx.outputs[inputN].toBytes())
        : hashZero;

    writer.writeUInt32(tx.version);
    writer.writeSlice(hashPrevouts);
    writer.writeSlice(hashSequences);
    thisInput.prevOut.write(writer);
    writer.writeVarSlice(details.scriptCode.compiled);
    writer.writeUInt64(details.value);
    writer.writeUInt32(thisInput.sequence);
    writer.writeSlice(hashOutputs);
    writer.writeUInt32(tx.locktime);
    writer.writeUInt32(hashType.value);

  }

  @override
  Uint8List get hash => sha256DoubleHash(toBytes());

}
