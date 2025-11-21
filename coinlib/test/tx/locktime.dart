import 'package:coinlib/coinlib.dart';
import 'package:test/test.dart';

void main() {

  final earliest = DateTime(1985, 11, 5, 0, 53, 20);
  final latest = DateTime(2106, 2, 7, 6, 28, 15);
  final second = Duration(seconds: 1);

  void expectHeightLockTime(Locktime locktime, int height) {
    locktime as BlockHeightLocktime;
    expect(locktime.value, height);
    expect(locktime.isUnlocked(DateTime.now(), height), true);
    expect(locktime.isUnlocked(DateTime.now(), height-1), false);
  }

  void expectMedianLockTime(Locktime locktime, DateTime time, int value) {

    locktime as MedianTimeLocktime;

    expect(locktime.value, value);
    expect(locktime.time, time);
    expect(locktime.isUnlocked(time, value-1), true);
    expect(locktime.isUnlocked(time.subtract(second), 0), false);

  }

  group("Locktime", () {

    test("can produce correct subclass for value", () {

      expectHeightLockTime(Locktime(0), 0);
      expectHeightLockTime(Locktime.zero, 0);
      expectHeightLockTime(Locktime(499999999), 499999999);

      expectMedianLockTime(Locktime(500000000), earliest, 500000000);
      expectMedianLockTime(Locktime(0xffffffff), latest, 0xffffffff);

    });

    test("invalid", () {
      for (final invalid in [-1, 0x100000000]) {
        expect(() => Locktime(invalid), throwsArgumentError);
      }
    });

  });

  group("BlockHeightLocktime", () {

    test("success", () {
      expectHeightLockTime(BlockHeightLocktime(0), 0);
      expectHeightLockTime(BlockHeightLocktime(499999999), 499999999);
    });

    test("invalid", () {
      for (final invalid in [-1, 500000000]) {
        expect(() => BlockHeightLocktime(invalid), throwsArgumentError);
      }
    });

  });

  group("MedianTimeLocktime", () {

    test("success", () {
      expectMedianLockTime(MedianTimeLocktime(earliest), earliest, 500000000);
      expectMedianLockTime(MedianTimeLocktime(latest), latest, 0xffffffff);
    });

    test("invalid", () {
      for (final invalid in [earliest.subtract(second), latest.add(second)]) {
        expect(() => MedianTimeLocktime(invalid), throwsArgumentError);
      }
    });

  });

  test(".isDefinitelyBefore", () {

    final lowTime = MedianTimeLocktime(earliest);
    final highTime = MedianTimeLocktime(earliest.add(second));
    final lowBlock = BlockHeightLocktime(1);
    final highBlock = BlockHeightLocktime(2);

    void expectBefores(Locktime locktime, bool time, bool block) {
      expect(locktime.isDefinitelyBefore(lowTime), false);
      expect(locktime.isDefinitelyBefore(highTime), time);
      expect(locktime.isDefinitelyBefore(lowBlock), false);
      expect(locktime.isDefinitelyBefore(highBlock), block);
    }

    expectBefores(lowTime, true, false);
    expectBefores(highTime, false, false);
    expectBefores(lowBlock, false, true);
    expectBefores(highBlock, false, false);

  });

}
