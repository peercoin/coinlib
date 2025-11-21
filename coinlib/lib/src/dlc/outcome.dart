import 'package:coinlib/src/common/bigints.dart';
import 'package:coinlib/src/common/serial.dart';
import 'package:coinlib/src/network.dart';
import 'package:coinlib/src/tx/locktime.dart';
import 'package:coinlib/src/tx/output.dart';
import 'terms.dart';
import 'errors.dart';

/// A CET will pay to the [outputs] with the value of each output evenly reduced
/// to cover the transaction fee.
class CETOutcome with Writable {

  /// The outputs to be included in the CET of this outcome. The values must
  /// add up to the amounts being funded by the participants in
  /// [DLCTerms.fundAmounts].
  ///
  /// The [Output.value] for each output will have an equal share of the
  /// transaction fee removed when the transaction is constructed. When doing
  /// this, if any of the outputs fall below the dust amount, they will be
  /// removed first.
  final List<Output> outputs;

  /// The locktime to use for this CET. It should be no later than when the
  /// oracle is expected to reveal the discrete log and must be the same type as
  /// (block height or median timestamp) and before the Refund Transaction
  /// locktime.
  ///
  /// How long before the RF is not decided by this library but it should be
  /// sufficient time to broadcast and include the CET in a block before the RF
  /// becomes available.
  final Locktime locktime;

  /// Requires that the output values are at least [Network.minOutput] or
  /// [InvalidDLCTerms] may be thrown.
  CETOutcome({
    required this.outputs,
    required this.locktime,
    required Network network,
  }) {
    if (outputs.isEmpty) {
      throw InvalidDLCTerms.noOutputs();
    }
    if (outputs.any((out) => out.value.compareTo(network.minOutput) < 0)) {
      throw InvalidDLCTerms.smallOutput(network.minOutput);
    }
  }

  CETOutcome.fromReader(BytesReader reader, Network network) : this(
    outputs: reader.readListWithFunc(() => Output.fromReader(reader)),
    locktime: reader.readLocktime(),
    network: network,
  );

  BigInt get totalValue => addBigInts(outputs.map((out) => out.value));

  @override
  void write(Writer writer) {
    writer.writeWritableVector(outputs);
    writer.writeLocktime(locktime);
  }

}
