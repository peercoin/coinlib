import 'package:coinlib/src/common/checks.dart';
import 'package:coinlib/src/tx/transaction.dart';

/// Represents the sequence field of an input. Inputs should generally use
/// [enforceLocktime] to ensure that any given locktime will function correctly.
/// This is also the default behaviour of the Peercoin client.
///
/// To set BIP68 relative locktimes, use [InputSequence.fromValue]. There is no
/// high-level abstraction for this yet.
class InputSequence {

  final int value;

  const InputSequence._(this.value);

  /// The usual sequence value that requires the [Transaction.locktime] to be
  /// enforced.
  static const enforceLocktime = InputSequence._(0xfffffffe);

  /// An input which does not enforce the [Transaction.locktime]. If all inputs
  /// have this sequence, the transaction locktime will be ignored.
  static const finalWithoutLocktime = InputSequence._(0xffffffff);

  /// Set a specific value for the sequence.
  InputSequence.fromValue(this.value) {
    checkUint32(value, "this.value");
  }

  /// True if this input requires enforcement of the [Transaction.locktime].
  bool get locktimeIsEnforced => value < finalWithoutLocktime.value;

  @override
  String toString() => value.toString();

  @override
  bool operator ==(Object other)
    => (other is InputSequence) && value == other.value;

  @override
  int get hashCode => value;

}
