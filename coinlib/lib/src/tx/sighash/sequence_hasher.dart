import 'package:coinlib/src/common/serial.dart';
import 'package:coinlib/src/tx/transaction.dart';
import 'precompute_hasher.dart';

final class SequenceHasher extends PrecomputeHasher {

  final Transaction tx;
  SequenceHasher(this.tx);

  @override
  void write(Writer writer) {
    for (final input in tx.inputs) {
      writer.writeUInt32(input.sequence);
    }
  }

}
