import 'dart:typed_data';
import 'package:coinlib/src/common/serial.dart';
import 'package:coinlib/src/crypto/hash.dart';
import 'package:coinlib/src/tx/output.dart';
import 'package:coinlib/src/tx/transaction.dart';

typedef OutputList = List<Output>;

/// Provides cached hashes for a transaction object for the purposes of creating
/// signature hashes
class TransactionSignatureHashes {

  final PrecomputeHasher prevouts;
  final PrecomputeHasher sequences;
  final PrecomputeHasher outputs;

  TransactionSignatureHashes(Transaction tx)
    : prevouts = PrecomputeHasher.prevouts(tx),
    sequences = PrecomputeHasher.sequences(tx),
    outputs = PrecomputeHasher.outputs(tx);

}

/// Provides cached hashes for the previous output data used for Taproot
/// signatures.
class PrevOutSignatureHashes {

  final PrecomputeHasher amounts;
  final PrecomputeHasher scripts;

  PrevOutSignatureHashes(OutputList prevOuts)
    : amounts = PrecomputeHasher.inAmounts(prevOuts),
    scripts = PrecomputeHasher.prevScripts(prevOuts);

}

class PrecomputeHasher<T extends Object> with Writable {

  final void Function(Writer writer, T obj) _write;
  final T _obj;

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

  static void _writeAmounts(Writer writer, OutputList prevOuts) {
    for (final output in prevOuts) {
      writer.writeUInt64(output.value);
    }
  }

  static void _writePrevScripts(Writer writer, OutputList prevOuts) {
    for (final output in prevOuts) {
      writer.writeVarSlice(output.scriptPubKey);
    }
  }

  static void _singleOutput(Writer writer, Output output)
    => output.write(writer);

  PrecomputeHasher._(this._obj, this._write);

  static PrecomputeHasher<Transaction> prevouts(Transaction tx)
    => PrecomputeHasher._(tx, _writePrevouts);
  static PrecomputeHasher<Transaction> sequences(Transaction tx)
    => PrecomputeHasher._(tx, _writeSequences);
  static PrecomputeHasher<Transaction> outputs(Transaction tx)
    => PrecomputeHasher._(tx, _writeOutputs);

  static PrecomputeHasher<OutputList> inAmounts(OutputList prevOuts)
    => PrecomputeHasher._(prevOuts, _writeAmounts);
  static PrecomputeHasher<OutputList> prevScripts(OutputList prevOuts)
    => PrecomputeHasher._(prevOuts, _writePrevScripts);

  static PrecomputeHasher<Output> singleOutput(Output output)
    => PrecomputeHasher._(output, _singleOutput);

  @override
  void write(Writer writer) => _write(writer, _obj);

  Uint8List? _singleHashCache;
  Uint8List? _doubleHashCache;
  Uint8List get singleHash => _singleHashCache ??= sha256Hash(toBytes());
  Uint8List get doubleHash => _doubleHashCache ??= sha256Hash(singleHash);

}
