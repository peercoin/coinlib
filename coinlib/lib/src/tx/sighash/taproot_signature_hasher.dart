import 'dart:typed_data';
import 'package:coinlib/src/common/serial.dart';
import 'package:coinlib/src/crypto/hash.dart';
import 'package:coinlib/src/tx/sign_details.dart';
import 'package:coinlib/src/tx/transaction.dart';
import 'precomputed_signature_hashes.dart';
import 'signature_hasher.dart';

/// Produces signature hashes for taproot inputs
final class TaprootSignatureHasher extends SignatureHasher with Writable {

  static final tapSigHash = getTaggedHasher("TapSighash");

  @override
  final TaprootSignDetails details;
  final TransactionSignatureHashes txHashes;
  final PrevOutSignatureHashes? prevOutHashes;

  /// Produces the hash for a Taproot input signature.
  TaprootSignatureHasher(this.details)
  : txHashes = TransactionSignatureHashes(details.tx),
  prevOutHashes = details.hashType.allInputs
      ? PrevOutSignatureHashes(details.prevOuts)
      : null {
    if (
      details.isScript
      && details.leafHash == null
      && !hashType.anyPrevOutAnyScript
    ) {
      throw CannotSignInput("Missing leaf hash for tapscript sign details");
    }
  }

  @override
  void write(Writer writer) {

    final leafHash = details.leafHash;
    final extFlag = details.isScript ? 1 : 0;

    writer.writeUInt8(0); // "Epoch"
    writer.writeUInt8(hashType.value);

    // Total transaction data
    writer.writeUInt32(tx.version);
    writer.writeUInt32(tx.locktime);

    if (hashType.allInputs) {
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

    if (hashType.allInputs) {
      writer.writeUInt32(inputN);
    } else {

      // ANYONECANPAY commits to the prevout point
      if (hashType.anyOneCanPay) {
        thisInput.prevOut.write(writer);
      }

      // Commit to the output value and script unless ANYPREVOUTANYSCRIPT
      if (!hashType.anyPrevOutAnyScript) {
        details.prevOuts.first.write(writer);
      }

      // Always include sequence
      writer.writeUInt32(thisInput.sequence);

    }

    // Data specific to matched output
    if (hashType.single) {
      writer.writeSlice(
        PrecomputeHasher.singleOutput(tx.outputs[inputN]).singleHash,
      );
    }

    // Data specific to the tapscript
    if (details.isScript) {
      if (!hashType.anyPrevOutAnyScript) {
        writer.writeSlice(leafHash!);
      }
      final keyVersion = hashType.requiresApo ? 1 : 0;
      writer.writeUInt8(keyVersion);
      writer.writeUInt32(details.codeSeperatorPos);
    }

  }

  @override
  Uint8List get hash => tapSigHash(toBytes());

}
