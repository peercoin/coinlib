import 'package:coinlib/coinlib.dart';
import 'package:test/test.dart';

void main() {

  group("SigHashType", () {

    test("valid values", () {

      expectValid(
        SigHashType obj, int value, bool all, bool none, bool single,
        bool anyOneCanPay,
      ) {

        expect(SigHashType.validValue(value), true);

        final objs = [obj, SigHashType.fromValue(value)];

        expect(objs[0], objs[1]);

        for (final o in objs) {
          expect(o.all, all);
          expect(o.none, none);
          expect(o.single, single);
          expect(o.anyOneCanPay, anyOneCanPay);
        }

      }

      expectValid(SigHashType.all(), 1, true, false, false, false);
      expectValid(
        SigHashType.all(anyOneCanPay: true), 0x81, true, false, false, true,
      );
      expectValid(SigHashType.none(), 2, false, true, false, false);
      expectValid(
        SigHashType.none(anyOneCanPay: true), 0x82, false, true, false, true,
      );
      expectValid(SigHashType.single(), 3, false, false, true, false);
      expectValid(
        SigHashType.single(anyOneCanPay: true), 0x83, false, false, true, true,
      );

    });

    test("invalid values", () {
      for (final invalid in [0, 4, 0x80, 0x84, 0x11, 0xc1, 0x181]) {
        expect(SigHashType.validValue(invalid), false);
        expect(() => SigHashType.checkValue(invalid), throwsArgumentError);
        expect(() => SigHashType.fromValue(invalid), throwsArgumentError);
      }
    });

  });

}
