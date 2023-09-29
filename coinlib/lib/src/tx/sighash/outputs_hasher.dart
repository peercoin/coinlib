import 'package:coinlib/src/common/serial.dart';
import 'package:coinlib/src/tx/transaction.dart';
import 'precompute_hasher.dart';

final class OutputsHasher extends PrecomputeHasher {

  final Transaction tx;
  OutputsHasher(this.tx);

  @override
  void write(Writer writer) {
    for (final output in tx.outputs) {
      output.write(writer);
    }
  }

}
