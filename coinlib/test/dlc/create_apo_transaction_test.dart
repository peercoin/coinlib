import 'package:coinlib/coinlib.dart';
import 'package:coinlib/src/common/bigints.dart';
import 'package:test/test.dart';
import '../vectors/keys.dart';
import 'helpers.dart';

final apoInput = TaprootSingleScriptSigInput.anyPrevOut(
  taproot: Taproot(
    internalKey: getPubKey(0),
    mast: TapLeafChecksig.apoInternal,
  ),
  leaf: TapLeafChecksig.apoInternal,
);

void main() {

  setUpAll(loadCoinlib);

  group("createUnsignedApoTransaction()", () {

    Transaction withOutputs(
      List<Output> outputs,
    ) => reduceOutputValuesIntoApoTransaction(
      apoInput: apoInput,
      outputs: outputs,
      locktime: exampleLocktime,
      network: Network.mainnet,
    );

    void expectOutputChange(
      List<String> startingCoins,
      List<String> endingCoins,
    ) {

      final tx = withOutputs(
        startingCoins.map((coin) => getFundOutput(0, coin)).toList(),
      );

      expect(tx.locktime, exampleLocktime);

      final startingValues = startingCoins.map(
        (coin) => CoinUnit.coin.toSats(coin),
      ).toList();
      final endingValues = endingCoins.map(
        (coin) => CoinUnit.coin.toSats(coin),
      ).toList();

      final startTotal = addBigInts(startingValues);
      final endTotal = addBigInts(endingValues);
      final expectFee = startTotal-endTotal;

      expect(
        tx.fee(Network.mainnet.feePerKb, Network.mainnet.minFee),
        expectFee,
      );

      expect(tx.outputs.map((out) => out.value), endingValues);

    }

    test(
      "outputs cannot be empty",
      () => expect(() => withOutputs([]), throwsArgumentError),
    );

    test("simple shared reduction of fee", () {

      // Reduction of single output
      expectOutputChange(["1"], ["0.998"]);

      // Barely enough
      expectOutputChange(["0.012"], ["0.01"]);

      // Shared across 7
      expectOutputChange(
        ["2", "6", "5", "4", "7", "1", "3"],
        [
          // Remainder of fee taken from first 2
          "1.999345", "5.999345", "4.999346", "3.999346", "6.999346",
          "0.999346", "2.999346",
        ],
      );

    });

    test("dust removed with excess shared", () {

      // One dust output removed
      expectOutputChange(
        ["1", "0.01", "2"],
        ["1.003785", "2.003785"],
      );

      // One dust output removed with remainder of excess added to first outputs
      expectOutputChange(
        ["2", "0.010002", "1", "3"],
        ["2.002381", "1.002381", "3.002380"],
      );

      // Only one needs to be removed
      expectOutputChange(
        ["0.01", "1", "2", "0.01"],
        ["1.002380", "2.002380", "0.012380"],
      );

      // Only one removed which is exact
      expectOutputChange(
        [
          "0.01017", "1", "2", "0.01017", "3", "4", "5", "0.01017", "6", "7",
          "0.01017", "0.01017", "1", "2", "0.01017", "3", "4", "5", "0.01017",
          "6", "7",
        ],
        [
          "1", "2", "0.01017", "3", "4", "5", "0.01017", "6", "7", "0.01017",
          "0.01017", "1", "2", "0.01017", "3", "4", "5", "0.01017", "6", "7",
        ],
      );

      // Two removed as not enough.
      expectOutputChange(
        [
          "0.01", "1", "2", "0.01", "3", "4", "5", "0.01", "6", "7", "0.01",
          "0.01", "1", "2", "0.01", "3", "4", "5", "0.01", "6", "7",
        ],
        [
          "1.000540", "2.000540", "3.000540", "4.000540", "5.000540", "0.010540",
          "6.000540", "7.000540", "0.010540", "0.010540", "1.000540", "2.000540",
          "0.010540", "3.000540", "4.000540", "5.000540", "0.010540", "6.000540",
          "7.000540",
        ],
      );

    });

    test("dust removed with further reduction required", () {

      expectOutputChange(
        [
          "0.01", "1", "2", "8", "3", "4", "5", "9", "6", "7", "1",
          "1", "1", "2", "2", "3", "4", "5", "8", "6", "7",
        ],
        [
          "0.999991", "1.999991", "7.999991", "2.999991", "3.999991",
          "4.999991", "8.999991", "5.999991", "6.999991", "0.999991",
          "0.999992", "0.999992", "1.999992", "1.999992", "2.999992",
          "3.999992", "4.999992", "7.999992", "5.999992", "6.999992",
        ],
      );

    });

    test("insufficient funds", () => expect(
      () => withOutputs([getFundOutput(0, "0.011999")]),
      throwsA(isA<InsufficientFunds>()),
    ),);

  });

}
