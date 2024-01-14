import 'package:coinlib/coinlib.dart';
import 'package:test/test.dart';

void main() {

  group("CoinUnit", () {

    void expectValidConversion(
      CoinUnit unit, String original, String sats, String result,
    ) {
      final actualSats = unit.toSats(original);
      expect(actualSats, BigInt.parse(sats));
      expect(unit.fromSats(actualSats), result);
    }

    void expectInvalid(CoinUnit unit, String str) => expect(
      () => unit.toSats(str), throwsA(isA<BadAmountString>()),
    );

    test("valid coin", () {

      void expectCoin(String original, String sats, String result)
        => expectValidConversion(CoinUnit.coin, original, sats, result);

      expectCoin("0", "0", "0");
      expectCoin("0.0", "0", "0");
      expectCoin("0.000000", "0", "0");
      expectCoin("000.000000", "0", "0");

      expectCoin("1", "1000000", "1");
      expectCoin("001", "1000000", "1");
      expectCoin("1.000000", "1000000", "1");

      expectCoin("1.123456", "1123456", "1.123456");
      expectCoin("1.123", "1123000", "1.123");
      expectCoin("1.123000", "1123000", "1.123");
      expectCoin("0.000001", "1", "0.000001");
      expectCoin("020.000001", "20000001", "20.000001");

    });

    test("valid sats", () {

      void expectSats(String original, String sats)
        => expectValidConversion(CoinUnit.sats, original, sats, sats);

      expectSats("0", "0");
      expectSats("000", "0");
      expectSats("1", "1");
      expectSats("00100", "100");
      expectSats("1234567890", "1234567890");
      expectSats("012345678090", "12345678090");

    });

    test("invalid coin", () {
      for (final invalid in [
        "0.", ".123456", ".", "0.1.2", " 1", "1 ", "1 000", "1,000", "0.1234567",
        "1.1234560", "0a", "0A", "A0", "1/2", "one", "-1", "-0",
      ]) {
        expectInvalid(CoinUnit.coin, invalid);
      }
    });

    test("invalid sats", () {
      for (final invalid in [
        "0.", ".123456", ".", "0.1", "0.1.2", " 1", "1 ", "1 000", "1,000",
        "0a", "0A", "A0",
      ]) {
        expectInvalid(CoinUnit.sats, invalid);
      }
    });

  });

}
