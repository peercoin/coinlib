import 'dart:typed_data';
import 'package:coinlib/src/common/serial.dart';
import 'package:coinlib/src/crypto/hash.dart';
import 'package:coinlib/src/scripts/script.dart';
import 'package:coinlib/src/tx/transaction.dart';
import 'precomputed_signature_hashes.dart';
import 'sighash_type.dart';
import 'signature_hasher.dart';

/// Produces signature hashes for non-taproot witness inputs
final class WitnessSignatureHasher with Writable implements SignatureHasher {

  static final hashZero = Uint8List(32);

  final Transaction tx;
  final TransactionSignatureHashes hashes;
  final int inputN;
  final Script scriptCode;
  final BigInt value;
  final SigHashType hashType;

  /// Produces the hash of an input signature for a non-taproot witness input
  /// at [inputN]. The [scriptCode] of the redeem script is necessary and the
  /// [value] of the previous output is required.
  /// [hashType] controls what data is included in the signature.
  WitnessSignatureHasher({
    required this.tx,
    required this.inputN,
    required this.scriptCode,
    required this.value,
    required this.hashType,
  }) : hashes = TransactionSignatureHashes(tx) {
    SignatureHasher.checkInputN(tx, inputN);
    SignatureHasher.checkSchnorrDisallowed(hashType);
  }

  @override
  void write(Writer writer) {

    final thisIn = tx.inputs[inputN];

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
    thisIn.prevOut.write(writer);
    writer.writeVarSlice(scriptCode.compiled);
    writer.writeUInt64(value);
    writer.writeUInt32(thisIn.sequence);
    writer.writeSlice(hashOutputs);
    writer.writeUInt32(tx.locktime);
    writer.writeUInt32(hashType.value);

  }

  @override
  Uint8List get hash => sha256DoubleHash(toBytes());

}
