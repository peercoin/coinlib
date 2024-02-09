import 'dart:typed_data';
import 'package:coinlib/src/common/serial.dart';
import 'package:coinlib/src/crypto/hash.dart';
import 'package:coinlib/src/tx/output.dart';
import 'package:coinlib/src/tx/sighash/sighash_type.dart';
import 'package:coinlib/src/tx/transaction.dart';
import 'precomputed_signature_hashes.dart';
import 'signature_hasher.dart';

/// Produces signature hashes for taproot inputs
final class TaprootSignatureHasher with Writable implements SignatureHasher {

  static final tapSigHash = getTaggedHasher("TapSighash");

  final Transaction tx;
  final TransactionSignatureHashes txHashes;
  final PrevOutSignatureHashes? prevOutHashes;
  final int inputN;
  final List<Output> prevOuts;
  final SigHashType hashType;
  final Uint8List? leafHash;
  final int codeSeperatorPos;

  /// Produces the hash for a Taproot input signature at [inputN].
  /// Unless [SigHashType.anyOneCanPay] is true, [prevOuts] must contain the
  /// full list of previous outputs being spent.
  /// The [hashType] controls what data is included. If ommitted it will be
  /// treated as SIGHASH_DEFAULT which includes the same data as SIGHASH_ALL but
  /// produces distinct signatures.
  /// If an input is being signed for a tapscript, the [leafHash] must be
  /// provided. [codeSeperatorPos] must be provided with the position of the
  /// last executed CODESEPARATOR unless none have been executed in the script
  TaprootSignatureHasher({
    required this.tx,
    required this.inputN,
    required this.prevOuts,
    required this.hashType,
    this.leafHash,
    this.codeSeperatorPos = 0xFFFFFFFF,
  }) : txHashes = TransactionSignatureHashes(tx),
  prevOutHashes = PrevOutSignatureHashes(prevOuts) {

    SignatureHasher.checkInputN(tx, inputN);

    if (hashType.single && inputN >= tx.outputs.length) {
      throw ArgumentError.value(
        inputN, "inputN", "has no corresponing output for SIGHASH_SINGLE",
      );
    }

    if (prevOuts.length != tx.inputs.length) {
      throw ArgumentError.value(
        prevOuts.length, "prevOuts.length", "must be same length as inputs",
      );
    }

  }

  @override
  void write(Writer writer) {

    final extFlag = leafHash == null ? 0 : 1;

    writer.writeUInt8(0); // "Epoch"
    writer.writeUInt8(hashType.value);

    // Total transaction data
    writer.writeUInt32(tx.version);
    writer.writeUInt32(tx.locktime);

    if (!hashType.anyOneCanPay) {
      writer.writeSlice(txHashes.prevouts.singleHash);
      writer.writeSlice(prevOutHashes!.amounts.singleHash);
      writer.writeSlice(prevOutHashes!.scripts.singleHash);
      writer.writeSlice(txHashes.sequences.singleHash);
    }

    if (hashType.all) {
      writer.writeSlice(txHashes.outputs.singleHash);
    }

    // Data specific to spending input
    writer.writeUInt8(extFlag << 1);

    if (hashType.anyOneCanPay) {
      tx.inputs[inputN].prevOut.write(writer);
      prevOuts[inputN].write(writer);
      writer.writeUInt32(tx.inputs[inputN].sequence);
    } else {
      writer.writeUInt32(inputN);
    }

    // Data specific to matched output
    if (hashType.single) {
      writer.writeSlice(
        PrecomputeHasher.singleOutput(tx.outputs[inputN]).singleHash,
      );
    }

    // Data specific to the script
    if (leafHash != null) {
      writer.writeSlice(leafHash!);
      writer.writeUInt8(0); // Key version = 0
      writer.writeUInt32(codeSeperatorPos);
    }

  }

  @override
  Uint8List get hash => tapSigHash(toBytes());

}
