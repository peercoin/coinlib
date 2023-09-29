import 'dart:typed_data';
import 'package:coinlib/src/common/serial.dart';
import 'package:coinlib/src/crypto/hash.dart';
import 'package:coinlib/src/scripts/script.dart';
import 'package:coinlib/src/tx/sighash/sighash_type.dart';
import 'package:coinlib/src/tx/transaction.dart';
import 'outputs_hasher.dart';
import 'prevout_points_hasher.dart';
import 'sequence_hasher.dart';
import 'signature_hasher.dart';

/// Produces signature hashes for non-taproot witness inputs
final class WitnessSignatureHasher with Writable implements SignatureHasher {

  static final hashZero = Uint8List(32);

  final Transaction tx;
  final int inputN;
  final Script scriptCode;
  final BigInt value;
  final SigHashType hashType;

  // These may be cached in the future for faster signing of multiple inputs
  final Uint8List hashPrevouts;
  final Uint8List hashSequence;
  final Uint8List hashOutputs;

  /// Produces the hash for an input signature for a non-taproot witness input
  /// at [inputN]. The [scriptCode] of the redeem script is necessary and the
  /// [value] of the previous output is required.
  /// [hashType] controls what data is included in the signature.
  WitnessSignatureHasher({
    required this.tx,
    required this.inputN,
    required this.scriptCode,
    required this.value,
    required this.hashType,
  }) :
    hashPrevouts = !hashType.anyOneCanPay
      ? PrevOutPointsHasher(tx).doubleHash
      : hashZero,
    hashSequence = !hashType.anyOneCanPay && !hashType.single && !hashType.none
      ? SequenceHasher(tx).doubleHash
      : hashZero,
    hashOutputs = !hashType.single && !hashType.none
      ? OutputsHasher(tx).doubleHash
      : hashType.single && inputN < tx.outputs.length
        ? sha256DoubleHash(tx.outputs[inputN].toBytes())
        : hashZero
  {
    SignatureHasher.checkInputN(tx, inputN);
  }

  @override
  void write(Writer writer) {
    final thisIn = tx.inputs[inputN];
    writer.writeUInt32(tx.version);
    writer.writeSlice(hashPrevouts);
    writer.writeSlice(hashSequence);
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
