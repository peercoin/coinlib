import 'package:coinlib/src/common/serial.dart';
import 'package:coinlib/src/tx/transaction.dart';
import 'precompute_hasher.dart';

final class PrevOutPointsHasher extends PrecomputeHasher {

  final Transaction tx;
  PrevOutPointsHasher(this.tx);

  @override
  void write(Writer writer) {
    for (final input in tx.inputs) {
      input.prevOut.write(writer);
    }
  }

}
