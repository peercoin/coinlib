import 'package:coinlib/coinlib.dart';
import 'package:test/test.dart';
import '../vectors/keys.dart';
import '../vectors/tx.dart';

CETOutputs getOuts(List<String> coins) => CETOutputs(
  [
    for (final coinAmt in coins) Output.fromScriptBytes(
      CoinUnit.coin.toSats(coinAmt),
      exampleOutput.scriptPubKey,
    ),
  ],
  Network.mainnet,
);

final exampleLocktime = MedianTimeLocktime(DateTime(2026));

final exampleTerms = DLCTerms(
  participants: [
    getPubKey(0),
    getPubKey(1, false),
  ],
  fundAmounts: {
    // Can be different from participants
    getPubKey(0): CoinUnit.coin.toSats("2"),
    getPubKey(2, false): CoinUnit.coin.toSats("4"),
  },
  outcomes: {
    getPubKey(3): getOuts(["1", "5"]),
    getPubKey(4, false): getOuts(["6"]),
  },
  refundLocktime: exampleLocktime,
  network: Network.mainnet,
);

void main() {

  void expectInvalid(void Function() f) => expect(
    f, throwsA(isA<InvalidDLCTerms>()),
  );

  setUpAll(loadCoinlib);

  group("CETOutputs", () {

    test(
      "gives totalValue",
      () => expect(getOuts(["1", "5"]).totalValue, CoinUnit.coin.toSats("6")),
    );

    test(
      "outputs cannot be empty",
      () => expectInvalid(() => getOuts([])),
    );

    test(
      "outputs must reach minOutput",
      () => expectInvalid(() => getOuts(["0.009999"])),
    );

  });

  group("DLCTerms", () {

    test("immutable fields", () {
      expect(
        () => exampleTerms.participants.first = examplePubkey,
        throwsA(anything),
      );
      expect(
        () => exampleTerms.fundAmounts[examplePubkey] = BigInt.zero,
        throwsA(anything),
      );
      expect(
        () => exampleTerms.outcomes[examplePubkey] = getOuts(["5"]),
        throwsA(anything),
      );
    });

    test("outcomes and funded amounts must match", () => expectInvalid(
      () => DLCTerms(
        participants: exampleTerms.participants,
        fundAmounts: { getPubKey(0): CoinUnit.coin.toSats("1") },
        outcomes: exampleTerms.outcomes,
        refundLocktime: exampleLocktime,
        network: Network.mainnet,
      ),
    ),);

    test("funded amounts must be at least minOutput", () => expectInvalid(
      () => DLCTerms(
        participants: exampleTerms.participants,
        fundAmounts: {
          getPubKey(0): CoinUnit.coin.toSats("5.990001"),
          getPubKey(1): CoinUnit.coin.toSats("0.009999"),
        },
        outcomes: exampleTerms.outcomes,
        refundLocktime: exampleLocktime,
        network: Network.mainnet,
      ),
    ),);

    test("can read and write", () {

      final readTerms = DLCTerms.fromBytes(
        exampleTerms.toBytes(), Network.mainnet,
      );

      void expectContainsTwo<T>(Iterable<T> it, T a, T b) {
        final li = it.toList();
        expect(li, hasLength(2));
        expect(li, containsAll([a, b]));
      }

      void expectTwoKeys(
        Iterable<ECPublicKey> keys, int a, int b,
      ) => expectContainsTwo(
        keys, getPubKey(a), getPubKey(b),
      );

      expectTwoKeys(readTerms.participants, 0, 1);

      expectTwoKeys(readTerms.fundAmounts.keys, 0, 2);
      expectContainsTwo(
        readTerms.fundAmounts.values.map((bi) => bi.toInt()),
        2000000,
        4000000,
      );

      expectTwoKeys(readTerms.outcomes.keys, 3, 4);

      void expectOuts(int i, List<int> coins) {
        final outs = readTerms.outcomes[getPubKey(i)]!;
        expect(outs.totalValue.toInt(), 6000000);
        expect(outs.outputs.map((out) => out.value.toInt() / 1000000), coins);
      }
      expectOuts(3, [1, 5]);
      expectOuts(4, [6]);

      expect(readTerms.refundLocktime.value, 1767225600);
      expect(readTerms.toHex(), exampleTerms.toHex());

    });

    test("bad version", () {
      final bytes = exampleTerms.toBytes();
      bytes[0] = 0xff;
      expectInvalid(() => DLCTerms.fromBytes(bytes, Network.mainnet));
    });

  });

}
