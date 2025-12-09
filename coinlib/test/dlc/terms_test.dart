import 'package:coinlib/coinlib.dart';
import 'package:test/test.dart';
import '../vectors/keys.dart';
import '../vectors/tx.dart';
import 'helpers.dart';

void main() {

  void expectInvalid(void Function() f) => expect(
    f, throwsA(isA<InvalidDLCTerms>()),
  );

  setUpAll(loadCoinlib);

  group("DLCTerms", () {

    test("immutable fields", () {
      expect(
        () => exampleTerms.participants.add(examplePubkey),
        throwsA(anything),
      );
      expect(
        () => exampleTerms.fundAmounts[examplePubkey] = getFundOutput(0, "3"),
        throwsA(anything),
      );
      expect(
        () => exampleTerms.outcomes[examplePubkey] = getOutcome(["5"]),
        throwsA(anything),
      );
    });

    test("outcomes and funded amounts must match", () => expectInvalid(
      () => getTerms(
        fundAmounts: { getPubKey(0): getFundOutput(0, "1") },
      ),
    ),);

    test("funded amounts must be at least minOutput", () => expectInvalid(
      () => getTerms(
        fundAmounts: {
          getPubKey(0): getFundOutput(0, "5.990001"),
          getPubKey(1): getFundOutput(1, "0.009999"),
        },
      ),
    ),);

    test("outcome amounts must be at least minOutput", () => expectInvalid(
      () => getTerms(
        outcomes: {
          getPubKey(3): getOutcome(["5.990001", "0.009999"]),
        },
      ),
    ),);

    test(
      "outcome locktime must be before the refund locktime",
      () => expectInvalidTerms(
        () => getTerms(
          outcomes: {
            getPubKey(0): getOutcome(["6"], exampleLocktime),
          },
        ),
      ),
    );

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
        readTerms.fundAmounts.values.map((out) => out.value.toInt()),
        2000000,
        4000000,
      );

      expectTwoKeys(readTerms.outcomes.keys, 3, 4);

      void expectOuts(int i, List<int> coins) {
        final outs = readTerms.outcomes[getPubKey(i)]!;
        expect(outs.totalValue.toInt(), 6000000);
        expect(outs.outputs.map((out) => out.value.toInt() / 1000000), coins);
        expect(outs.locktime.value, exampleOutcomeLocktime.value);
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
        fundAmounts: { odd: getFundOutput(0, "1") },
        outcomes: { odd: getOutcome(["1"]) },
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
