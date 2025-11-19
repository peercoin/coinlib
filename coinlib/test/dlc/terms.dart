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
  participants: {
    getPubKey(0),
    getPubKey(1, false),
  },
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

DLCTerms getTerms({
  Set<ECPublicKey>? participants,
  Map<ECPublicKey, BigInt>? fundAmounts,
  Map<ECPublicKey, CETOutputs>? outcomes,
  Locktime? locktime,
}) => DLCTerms(
  participants: participants ?? exampleTerms.participants,
  fundAmounts: fundAmounts ?? exampleTerms.fundAmounts,
  outcomes: outcomes ?? exampleTerms.outcomes,
  refundLocktime: locktime ?? exampleLocktime,
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
        () => exampleTerms.participants.add(examplePubkey),
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
      () => getTerms(
        fundAmounts: { getPubKey(0): CoinUnit.coin.toSats("1") },
      ),
    ),);

    test("funded amounts must be at least minOutput", () => expectInvalid(
      () => getTerms(
        fundAmounts: {
          getPubKey(0): CoinUnit.coin.toSats("5.990001"),
          getPubKey(1): CoinUnit.coin.toSats("0.009999"),
        },
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

    test("coerces keys into xonly", () {

      final odd = ECPublicKey.fromHex(
        "0379be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798",
      );

      expect(odd.yIsEven, false);

      final terms = getTerms(
        participants: { odd },
        fundAmounts: { odd: CoinUnit.coin.toSats("1") },
        outcomes: { odd: getOuts(["1"]) },
      );

      expect(terms.participants.first.yIsEven, true);
      expect(terms.fundAmounts.keys.first.yIsEven, true);
      expect(terms.outcomes.keys.first.yIsEven, true);

    });

    test("bad ordering of serialised keys", () {
      final bytes = exampleTerms.toBytes();
      // Swap first and second public keys
      final first = bytes.sublist(3, 35);
      bytes.setRange(3, 35, bytes, 35);
      bytes.setAll(35, first);
      expectInvalid(() => DLCTerms.fromBytes(bytes, Network.mainnet));
    });

    test("different musig for different data", () {

      final musig1 = exampleTerms.musig;
      final musig2 = getTerms(
        locktime: MedianTimeLocktime(DateTime(2030)),
      ).musig;

      /// Same set of participant keys
      for (final musig in [musig1, musig2]) {
        expect(musig.pubKeys, hasLength(2));
        expect(musig.pubKeys, containsAll(exampleTerms.participants));
      }

      // Different tweaked key
      expect(musig1.aggregate, isNot(musig2.aggregate));

    });

  });

}
