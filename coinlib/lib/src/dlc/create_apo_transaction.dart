import 'package:coinlib/src/network.dart';
import 'package:coinlib/src/tx/coin_selection.dart';
import 'package:coinlib/src/tx/inputs/taproot_single_script_sig_input.dart';
import 'package:coinlib/src/tx/locktime.dart';
import 'package:coinlib/src/tx/output.dart';
import 'package:coinlib/src/tx/transaction.dart';
import 'package:collection/collection.dart';

/// For outputs [outputs] of a CET or RT, this reduces the output amounts to
/// cover the required transaction fee and returns a unsigned [Transaction] with
/// the appropriate amounts.
///
/// Output amounts are reduced evenly by the fee. It is assumed that the value
/// of the inputted [outputs] equals the input value. Any amounts that would
/// fall below the [Network.minOutput] will be removed.
///
/// The [locktime] and [apoInput] is given to the returned [Transaction].
///
/// Can throw [InsufficientFunds] if the input amount is insufficient to allow
/// at least one output.
Transaction reduceOutputValuesIntoApoTransaction({
  required TaprootSingleScriptSigInput apoInput,
  required List<Output> outputs,
  required Locktime locktime,
  required Network network,
}) {

  if (outputs.isEmpty) {
    throw ArgumentError.value(outputs, "outputs", "should not be empty");
  }

  // Accumulate the removed dust which is is to be subtracted from the fee
  var dustRemoved = BigInt.zero;

  // Could be done in a more functional way but the loop is not too complicated.
  // Each iteration mutates the outputs and dustRemoved with a removed dust
  // output. The function returns inside the loop when no more dust is removed.
  while (true) {

    if (outputs.isEmpty) throw InsufficientFunds();

    // Create transaction without fee
    final feeless = Transaction(inputs: [apoInput], outputs: outputs);

    // Calculates the difference between the output amount and what needs to be
    // reduced to meet the fee. If negative then the outputs can share amounts
    // from the removed dust.
    final differenceToFee
      = feeless.fee(network.feePerKb, network.minFee)!
      - dustRemoved;

    // The remainder will be taken from the first outputs making this slightly
    // unfair but only by no more than a satoshi
    final outLen = BigInt.from(outputs.length);
    final splitDiff = differenceToFee ~/ outLen;

    // Get the absolute remainder to determine how many outputs to apply it to
    // and then determine the sign for adding or subtracting.
    final remainderCount = differenceToFee.remainder(outLen).abs();
    final remainderToSubtract
      = differenceToFee.isNegative ? -BigInt.one : BigInt.one;

    // Adjust output amounts by sharing difference to fee
    final candidateOutputs = outputs.mapIndexed(
      (i, output) => Output.fromScriptBytes(
        output.value
        - splitDiff
        - (BigInt.from(i) < remainderCount ? remainderToSubtract : BigInt.zero),
        output.scriptPubKey,
      ),
    ).toList();

    // Determine if there is dust to remove, removing the smallest dust first
    // Further optimisation could be done to remove the least number of outputs
    // requied whilst still favouring the smaller dust outputs but such
    // complexity is not worthwhile for such small outputs.

    final smallest = candidateOutputs.reduce(
      (a, b) => a.value < b.value ? a : b,
    ).value;

    if (smallest < network.minOutput) {
      // Dust found

      // Determine the first dust index
      final i = candidateOutputs.indexWhere((out) => out.value == smallest);
      assert(i != -1);

      // Remove the dust from the input outputs and try again
      dustRemoved += outputs[i].value;
      outputs.removeAt(i);

    } else {
      // No dust. Use candidate outputs and create transaction
      return Transaction(
        inputs: [apoInput],
        outputs: candidateOutputs,
        locktime: locktime,
      );

    }

  }

}
