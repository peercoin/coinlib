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

void main() {

  group("CoinSelection()", () {

    late P2PKHInput input;
    late P2PKH changeProgram;
    setUpAll(() async {
      await loadCoinlib();
      input = P2PKHInput(
        prevOut: examplePrevOut,
        publicKey: keyPairVectors[0].publicObj,
      );
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
            tx = tx.sign(inputN: i, key: keyPairVectors[0].privateObj);
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

    void expectSelectedValues(CoinSelection selection, List<int> values) => expect(
      selection.selected.map((candidate) => candidate.value.toInt()),
      unorderedEquals(values),
    );

    test(".largestFirst()", () {

      final candidates = [coin*4, coin, coin*3, coin, coin*2];

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
        expect(selection.version, 1234);
        expect(selection.locktime, 0xabcd1234);
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

  });

}
