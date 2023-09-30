import 'dart:typed_data';
import 'package:coinlib/src/common/serial.dart';
import 'package:coinlib/src/crypto/hash.dart';
import 'package:coinlib/src/tx/transaction.dart';

/// Provides cached hashes for a transaction object for the purposes of creating
/// signature hashes
class PrecomputedSignatureHashes {

  final PrecomputeHasher prevouts;
  final PrecomputeHasher sequences;
  final PrecomputeHasher outputs;

  PrecomputedSignatureHashes(Transaction tx)
    : prevouts = PrecomputeHasher.prevouts(tx),
    sequences = PrecomputeHasher.sequences(tx),
    outputs = PrecomputeHasher.outputs(tx);

}

class PrecomputeHasher with Writable {

  final void Function(Writer writer, Transaction tx) txWrite;
  final Transaction tx;

  static void _writePrevouts(Writer writer, Transaction tx) {
    for (final input in tx.inputs) {
      input.prevOut.write(writer);
    }
  }

  static void _writeSequences(Writer writer, Transaction tx) {
    for (final input in tx.inputs) {
      writer.writeUInt32(input.sequence);
    }
  }

  static void _writeOutputs(Writer writer, Transaction tx) {
    for (final output in tx.outputs) {
      output.write(writer);
    }
  }

  PrecomputeHasher.prevouts(this.tx) : txWrite = _writePrevouts;
  PrecomputeHasher.sequences(this.tx) : txWrite = _writeSequences;
  PrecomputeHasher.outputs(this.tx) : txWrite = _writeOutputs;

  @override
  void write(Writer writer) => txWrite(writer, tx);

  Uint8List? _singleHashCache;
  Uint8List? _doubleHashCache;
  Uint8List get singleHash => _singleHashCache ??= sha256Hash(toBytes());
  Uint8List get doubleHash => _doubleHashCache ??= sha256Hash(singleHash);

}
