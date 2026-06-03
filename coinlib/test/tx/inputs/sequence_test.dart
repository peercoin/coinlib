import 'package:coinlib/coinlib.dart';
import 'package:test/test.dart';

void main() {

  group("InputSequence", () {

    test("requires uint32 sequence", () {
      for (final n in [-1, 0x100000000]) {
        expect(
          () => InputSequence.fromValue(n),
          throwsArgumentError,
        );
      }
    });

    test(".locktimeIsEnforced", () {
      expect(InputSequence.enforceLocktime.locktimeIsEnforced, true);
      expect(InputSequence.finalWithoutLocktime.locktimeIsEnforced, false);
    });

    test("comparison works", () {
      expect(
        InputSequence.enforceLocktime,
        InputSequence.fromValue(0xfffffffe),
      );
      expect(
        InputSequence.enforceLocktime,
        isNot(InputSequence.finalWithoutLocktime),
      );
    });

  });

}
