import 'package:coinlib/src/common/checks.dart';
import 'inputs/sequence.dart';

/// A locktime restricts when a transaction can be mined.
///
/// Either it is restricted to block heights that are equal or later than a
/// given block height. For this use [BlockHeightLocktime].
///
/// Or it is restricted to where the median timestamp of the last 11 blocks is
/// equal or later than a given timestamp. For this use [MedianTimeLocktime].
///
/// This restriction is ignored if all the transaction inputs are final with a
/// [InputSequence.finalWithoutLocktime] sequence.
sealed class Locktime {

  static final int _timeThreshold = 500000000;

  static const zero = BlockHeightLocktime._noCheck(0);

  final int value;

  const Locktime._noCheck(this.value);

  Locktime._(this.value) {
    checkUint32(value);
  }

  /// Creates a [BlockHeightLocktime] or [MedianTimeLocktime] from the raw
  /// value.
  factory Locktime(int value) {
    if (value < _timeThreshold) return BlockHeightLocktime(value);
    return MedianTimeLocktime._(value);
  }

  /// Given the [medianTime] of the previous 11 blocks and the current
  /// [blockHeight], returns true if the locktime is reached and the transaction
  /// is unlocked.
  bool isUnlocked(DateTime medianTime, int blockHeight)
    => this is BlockHeightLocktime
    ? value <= blockHeight
    : (this as MedianTimeLocktime).time.compareTo(medianTime) <= 0;

  /// True if this [Locktime] is the same type as the [other] locktime and comes
  /// before it.
  bool isDefinitelyBefore(Locktime other)
    => value < other.value && runtimeType == other.runtimeType;

}

class BlockHeightLocktime extends Locktime {

  const BlockHeightLocktime._noCheck(super.height) : super._noCheck();

  /// Restricts the transaction to block heights greater or equal to [height].
  ///
  /// The [height] be less than 500000000.
  BlockHeightLocktime(int height) : super._(height) {
    if (height >= Locktime._timeThreshold) {
      throw ArgumentError.value(
        height, "height", "must be less than ${Locktime._timeThreshold}",
      );
    }
  }

}

class MedianTimeLocktime extends Locktime {

  MedianTimeLocktime._(int value) : super._(value) {
    if (value < Locktime._timeThreshold) {
      throw ArgumentError.value(
        value, "value", "must be more or equal to ${Locktime._timeThreshold}",
      );
    }
  }

  /// Restricts the transaction to blocks where the median timestamp of the
  /// previous 11 blocks is greater than or equal to [time].
  ///
  /// Must be between "1985-11-05 00:53:20" and "2106-02-07 06:28:15".
  MedianTimeLocktime(
    DateTime time,
  ) : this._(time.millisecondsSinceEpoch ~/ 1000);

  DateTime get time => DateTime.fromMillisecondsSinceEpoch(value*1000);

}
