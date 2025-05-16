import 'dart:typed_data';

import 'package:coinlib/coinlib.dart';
import 'package:test/test.dart';
import '../vectors/keys.dart';
import '../vectors/tx.dart';

class CoinSelectionVector {
  final List<int> inputValues;
  final List<int> outputValues;
  final int expFee, expSignedSize;
  final bool expEnoughFunds, expChangeless;
  CoinSelectionVector({
    required this.inputValues,
    required this.outputValues,
    required this.expFee,
    required this.expSignedSize,
    required this.expEnoughFunds,
    required this.expChangeless,
  });

  int get inputValue => inputValues.fold(0, (a,b) => a+b);
  int get outputValue => outputValues.fold(0, (a,b) => a+b);
  int get expChangeValue => inputValue - outputValue - expFee;

}

final coin = 1000000;
final feePerKb = BigInt.from(10000);
final minFee = BigInt.from(1000);
final minChange = BigInt.from(100000);

final vectors = [
  // No inputs
  CoinSelectionVector(
    inputValues: [],
    outputValues: [coin],
    expFee: minFee.toInt(),
    expSignedSize: 78,
    expEnoughFunds: false,
    expChangeless: false,
  ),
  // Covers outputs but not fee
  CoinSelectionVector(
    inputValues: [coin],
    outputValues: [coin],
    expFee: 2250,
    expSignedSize: 225,
    expEnoughFunds: false,
    expChangeless: false,
  ),
  // Exact amount
  CoinSelectionVector(
    inputValues: [coin+1910],
    outputValues: [coin],
    expFee: 1910,
    expSignedSize: 191,
    expEnoughFunds: true,
    expChangeless: true,
  ),
  // Just under exact amount
  CoinSelectionVector(
    inputValues: [coin+1910-1],
    outputValues: [coin],
    expFee: 2250,
    expSignedSize: 225,
    expEnoughFunds: false,
    expChangeless: false,
  ),
  // Reach minimum change
  CoinSelectionVector(
    inputValues: [coin+2250+minChange.toInt()],
    outputValues: [coin],
    expFee: 2250,
    expSignedSize: 225,
    expEnoughFunds: true,
    expChangeless: false,
  ),
  // Just under minimum change
  CoinSelectionVector(
    inputValues: [coin+2250+minChange.toInt()-1],
    outputValues: [coin],
    expFee: 2250+minChange.toInt()-1,
    expSignedSize: 191,
    expEnoughFunds: true,
    expChangeless: true,
  ),
  // Change = 1 coin
  CoinSelectionVector(
    inputValues: [coin+2250+coin],
    outputValues: [coin],
    expFee: 2250,
    expSignedSize: 225,
    expEnoughFunds: true,
    expChangeless: false,
  ),
  // Multi input and outputs
  CoinSelectionVector(
    inputValues: [coin, coin*2, coin*3, coin+7340],
    outputValues: [coin, coin*2, coin*3],
    expFee: 7340,
    expSignedSize: 734,
    expEnoughFunds: true,
    expChangeless: false,
  ),
];

final privKey = keyPairVectors.first.privateObj;
final pubKey = keyPairVectors.first.publicObj;

void main() {

  group("CoinSelection()", () {

    late P2PKHInput input;
    late P2PKH changeProgram;
    setUpAll(() async {
      await loadCoinlib();
      input = P2PKHInput(prevOut: examplePrevOut, publicKey: pubKey);
      changeProgram = P2PKH.fromPublicKey(examplePubkey);
    });

    InputCandidate candidateForValue(int value) => InputCandidate(
      input: input, value: BigInt.from(value),
    );

    Output outputForValue(int value) => Output.fromProgram(
      BigInt.from(value), exampleOutput.program!,
    );

    test("gives correct calculated fields", () {
      // Assume feePerKb of 10000, min fee of 1000, min change of 100000

      for (final vector in vectors) {

        final selection = CoinSelection(
          selected: vector.inputValues.map(candidateForValue),
          recipients: vector.outputValues.map(outputForValue),
          changeProgram: changeProgram,
          feePerKb: feePerKb,
          minFee: minFee,
          minChange: minChange,
        );

        expect(selection.fee.toInt(), vector.expFee);
        expect(selection.changeValue.toInt(), vector.expChangeValue);
        expect(selection.signedSize.toInt(), vector.expSignedSize);
        expect(selection.enoughFunds, vector.expEnoughFunds);
        expect(selection.changeless, vector.expChangeless);
        expect(selection.tooLarge, false);
        expect(selection.ready, vector.expEnoughFunds);

        if (vector.expEnoughFunds) {

          var tx = selection.transaction;
          for (int i = 0; i < vector.inputValues.length; i++) {
            tx = tx.signLegacy(inputN: i, key: privKey);
          }

          expect(
            tx.outputs.any(
              (output) => output.program!.script.asm == changeProgram.script.asm
              && output.value.toInt() == vector.expChangeValue,
            ),
            !vector.expChangeless,
          );
          expect(tx.complete, true);
          expect(tx.size, lessThanOrEqualTo(selection.signedSize));
          expect(
            tx.outputs.fold(0, (i, output) => i + output.value.toInt()),
            vector.outputValue + vector.expChangeValue,
          );
          expect(tx.version, Transaction.currentVersion);
          expect(tx.locktime, 0);

        } else {
          expect(
            () => selection.transaction,
            throwsA(isA<InsufficientFunds>()),
          );
        }

      }

    });

    test("passes version and locktime", () {

      final selection = CoinSelection(
        version: 1234,
        locktime: 54,
        selected: [candidateForValue(coin)],
        recipients: [outputForValue(10000)],
        changeProgram: changeProgram,
        feePerKb: feePerKb,
        minFee: minFee,
        minChange: minChange,
      );

      final tx = selection.transaction;
      expect(tx.version, 1234);
      expect(tx.locktime, 54);

    });

    test(
      "requires signedSize for inputs",
      () => expect(
        () => CoinSelection(
          selected: [
            candidateForValue(coin),
            InputCandidate(
              input: RawInput(prevOut: examplePrevOut, scriptSig: Uint8List(0)),
              value: BigInt.from(coin),
            ),
          ],
          recipients: [exampleOutput],
          changeProgram: changeProgram,
          feePerKb: feePerKb,
          minFee: minFee,
          minChange: minChange,
        ),
        throwsArgumentError,
      ),
    );

    test("fields are immutable", () {

      final selected = [candidateForValue(coin)];
      final recipients = [outputForValue(coin)];

      final selection = CoinSelection(
        selected: selected,
        recipients: recipients,
        changeProgram: changeProgram,
        feePerKb: feePerKb,
        minFee: minFee,
        minChange: minChange,
      );

      selected.add(candidateForValue(coin*2));
      recipients.add(outputForValue(coin*2));

      expect(
        () => selection.selected.add(candidateForValue(coin*3)),
        throwsUnsupportedError,
      );
      expect(
        () => selection.recipients.add(outputForValue(coin*3)),
        throwsUnsupportedError,
      );

      expect(selection.selected.length, 1);
      expect(selection.recipients.length, 1);

    });

    test("gives tooLarge when signedSize is over 1MB", () {

      final selection = CoinSelection(
        selected: List.filled(6803, candidateForValue(coin)),
        recipients: [exampleOutput],
        changeProgram: changeProgram,
        feePerKb: feePerKb,
        minFee: minFee,
        minChange: minChange,
      );

      expect(selection.tooLarge, true);
      expect(selection.ready, false);
      expect(() => selection.transaction, throwsA(isA<TransactionTooLarge>()));

    });

    void expectSelectedValues(CoinSelection selection, List<int> values) {
      expect(
        selection.selected.map((candidate) => candidate.value.toInt()),
        unorderedEquals(values),
      );
      expect(selection.version, 1234);
      expect(selection.locktime, 0xabcd1234);
    }

    final candidates = [coin*4, coin, coin*3, coin, coin*2];

    test(".inOrderUntilEnough()", () {

      void expectInOrder(List<int> selected, int outValue) {
        final selection = CoinSelection.inOrderUntilEnough(
          version: 1234,
          candidates: candidates.map((value) => candidateForValue(value)),
          recipients: [outputForValue(outValue)],
          changeProgram: changeProgram,
          feePerKb: feePerKb, minFee: minFee, minChange: minChange,
          locktime: 0xabcd1234,
        );
        expectSelectedValues(selection, selected);
      }

      // Single input required
      expectInOrder(candidates.sublist(0, 1), coin*3);
      // Covers with first three, even if only two needed
      expectInOrder(candidates.sublist(0, 3), coin*5);
      // Need all
      expectInOrder(candidates, coin*10);
      // Select all even though not enough
      expectInOrder(candidates, coin*12);

    });

    test(".random", () {

      CoinSelection getRandom(int outValue) => CoinSelection.random(
        version: 1234,
        candidates: candidates.map((value) => candidateForValue(value)),
        recipients: [outputForValue(outValue)],
        changeProgram: changeProgram,
        feePerKb: feePerKb, minFee: minFee, minChange: minChange,
        locktime: 0xabcd1234,
      );

      // Only need one
      {
        final selected = getRandom(coin~/2).selected;
        expect(selected.length, 1);
        expect(selected[0].value.toInt(), isIn(candidates));
      }
      // Need multiple
      {
        final selection = getRandom(coin*2);
        expect(selection.selected.length, lessThanOrEqualTo(3));
        expect(selection.inputValue.toInt(), greaterThan(coin*2));
      }
      // Need all
      expectSelectedValues(getRandom(coin*10), candidates);
      // Select all even though not enough
      expectSelectedValues(getRandom(coin*12), candidates);

    });

    test(".largestFirst()", () {

      void expectLargestFirst(List<int> selected, int outValue) {
        final selection = CoinSelection.largestFirst(
          version: 1234,
          candidates: candidates.map((value) => candidateForValue(value)),
          recipients: [outputForValue(outValue)],
          changeProgram: changeProgram,
          feePerKb: feePerKb, minFee: minFee, minChange: minChange,
          locktime: 0xabcd1234,
        );
        expectSelectedValues(selection, selected);
      }

      // Can cover with single largest
      expectLargestFirst([coin*4], coin*3);
      // Can cover with two
      expectLargestFirst([coin*4, coin*3], coin*4);
      // Need all
      expectLargestFirst(candidates, coin*10);
      // Select all, though they aren't enough
      expectLargestFirst(candidates, coin*12);

    });

    test(".optimal()", () {

      CoinSelection getOptimal(List<int> candidates, int outValue)
        => CoinSelection.optimal(
          version: 1234,
          candidates: candidates.map((value) => candidateForValue(value)),
          recipients: [outputForValue(outValue)],
          changeProgram: changeProgram,
          feePerKb: feePerKb, minFee: minFee, minChange: minChange,
          locktime: 0xabcd1234,
        );

      // Defaults to random where possible
      {
        final selected = getOptimal(candidates, coin~/2).selected;
        expect(selected.length, 1);
        expect(selected[0].value.toInt(), isIn(candidates));
      }

      // Fallback to largestFirst where needed
      // Create a long list of small inputs that would lead to a too large
      // transaction with only a few larger inputs able to satisfy the transaction.
      // Create lots of inputs to reduce probability of randomly selecting
      // larger inputs.
      {
        final selection = getOptimal(
          [
            ...List.filled(1000, coin*100),
            ...List.filled(100000, coin),
          ], coin*100000,
        );
        expect(selection.tooLarge, false);
        expect(selection.enoughFunds, true);
        expect(selection.version, 1234);
        expect(selection.locktime, 0xabcd1234);
        expect(
          selection.selected.where(
            (candidate) => candidate.value.toInt() == coin*100,
          ).length,
          isNonZero,
        );
      }

    });

    test("works for taproot inputs", () {

      // Input 1 = Script with known default sighash type
      // Input 2 = Script with unknown default sighash type
      // Input 3 = Script with none sighash type
      // Input 4 = Key with known default sighash type
      // Input 5 = Key with unknown default sighash type
      // Input 6 = Key with none sighash type

      final tapleaf = TapLeafChecksig(pubKey);
      final taproot = Taproot(internalKey: pubKey, mast: tapleaf);
      final program = P2TR.fromTaproot(taproot);
      final inAmt = CoinUnit.coin.toSats("1");

      final selection = CoinSelection(
        selected: List.generate(
          6,
          // First three are script-path
          (i) => InputCandidate(
            input:
              i < 3
              ? TaprootSingleScriptSigInput(
                prevOut:  examplePrevOut,
                taproot: taproot,
                leaf: tapleaf,
              )
              : TaprootKeyInput(prevOut: examplePrevOut),
            value: inAmt,
            // First and 4th known as a default sig hash
            defaultSigHash: i % 3 == 0,
          ),
        ),
        recipients: [outputForValue(5000000)],
        changeProgram: program,
        feePerKb: feePerKb, minFee: minFee, minChange: minChange,
      );

      final prevOuts = List.generate(
        6,
        (_) => Output.fromProgram(inAmt, program),
      );
      final tweaked = taproot.tweakPrivateKey(privKey);

      // First two in each 3-set default
      SigHashType iToHashType(int i) => i % 3 != 2
        ? SigHashType.schnorrDefault()
        : SigHashType.none();

      var tx = selection.transaction;

      for (int i = 0; i < 3; i++) {
        tx = tx.signTaprootSingleScriptSig(
          inputN: i,
          key: tweaked,
          prevOuts: prevOuts,
          hashType: iToHashType(i),
        );
      }

      for (int i = 3; i < 6; i++) {
        tx = tx.signTaproot(
          inputN: i,
          key: tweaked,
          prevOuts: prevOuts,
          hashType: iToHashType(i),
        );
      }

      // Expected signed size is two bytes higher due to 2nd and 5th inputs not
      // having defaultSigHash set to true
      expect(selection.signedSize, 942);
      expect(tx.size, 940);
      expect(selection.fee, BigInt.from(9420));

    });

  });

}
