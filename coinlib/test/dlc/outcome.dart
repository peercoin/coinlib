import 'package:coinlib/coinlib.dart';
import 'package:test/test.dart';
import 'helpers.dart';

void main() {

  setUpAll(loadCoinlib);

  group("CETOutputs", () {

    test(
      "gives totalValue",
      () => expect(getOutcome(["1", "5"]).totalValue, CoinUnit.coin.toSats("6")),
    );

    test(
      "outputs cannot be empty",
      () => expectInvalidTerms(() => getOutcome([])),
    );

    test(
      "outputs must reach minOutput",
      () => expectInvalidTerms(() => getOutcome(["0.009999"])),
    );

  });

}
