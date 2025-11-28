import 'package:coinlib/src/common/bigints.dart';
import 'package:coinlib/src/crypto/random.dart';
import 'package:coinlib/src/scripts/program.dart';
import 'package:collection/collection.dart';
import 'inputs/input.dart';
import 'locktime.dart';
import 'output.dart';
import 'transaction.dart';

class InsufficientFunds implements Exception {}

/// A candidate input to spend a UTXO with the UTXO value
class InputCandidate {

  /// Input that can spend the UTXO
  final Input input;
  /// Value of UTXO to be spent
  final BigInt value;

  /// Provides an [input] alongside the [value] being spent that may be
  /// selected.
  InputCandidate({
    required this.input,
    required this.value,
  });

}

/// Represents a selection of inputs to fund a transaction. If the inputs
/// provide sufficient value to cover the ouputs and fee for a transaction that
/// isn't too large, [ready] shall be true and it is possible to obtain a
/// signable [transaction].
class CoinSelection {

  final int version;
  final List<InputCandidate> selected;
  final List<Output> recipients;
  final Program changeProgram;
  final BigInt feePerKb;
  final BigInt minFee;
  final BigInt minChange;
  final Locktime locktime;

  /// The total value of selected inputs
  late final BigInt inputValue;
  /// The total value of all recipient outputs
  late final BigInt recipientValue;
  /// The value of the change output. This is 0 for a changeless transaction or
  /// negative if there aren't enough funds.
  late final BigInt changeValue;
  /// The maximum size of the transaction after being fully signed
  late int signedSize;

  /// Selects all the inputs from [selected] to send to the [recipients] outputs
  /// and provide change to the [changeProgram]. The [feePerKb] specifies the
  /// required fee in sats per KB with a minimum fee specified with
  /// [minFee]. The [minChange] is the minimum allowed change.
  ///
  /// Will throw [ArgumentError] if a [selected] input does not have a
  /// calculable size.
  CoinSelection({
    this.version = Transaction.currentVersion,
    required Iterable<InputCandidate> selected,
    required Iterable<Output> recipients,
    required this.changeProgram,
    required this.feePerKb,
    required this.minFee,
    required this.minChange,
    this.locktime = Locktime.zero,
  }) : selected = List.unmodifiable(selected),
    recipients = List.unmodifiable(recipients) {

    if (selected.any((candidate) => candidate.input.signedSize == null)) {
      throw ArgumentError("Cannot select inputs without known max signed size");
    }

    // Get input and recipient values
    inputValue = addBigInts(selected.map((candidate) => candidate.value));
    recipientValue = addBigInts(recipients.map((output) => output.value));
    final inputExcess = inputValue - recipientValue;

    final inputs = selected.map((candidate) => candidate.input).toList();
    final isWitness = Transaction.inputsHaveWitness(inputs);
    final outputProgram = Output.fromProgram(BigInt.zero, changeProgram);

    int getSize(bool withChange) => Transaction.calculateSignedSize(
      inputs: inputs,
      outputs: [...recipients, if (withChange) outputProgram ],
      isWitness: isWitness,
    )!; // Assert null as all inputs will have signedSize as tested above

    BigInt getFeeExcess(int size)
      => inputExcess - Transaction.calculateFee(size, feePerKb, minFee);

    // Try to create change tranasction first
    final sizeWithChange = getSize(true);
    final change = getFeeExcess(sizeWithChange);

    // Transaction with change is successful if the change is above the minimum
    if (change.compareTo(minChange) >= 0) {
      signedSize = sizeWithChange;
      changeValue = change;
      return;
    }

    // Else target the transaction without the change output
    signedSize = getSize(false);
    final feeExcess = getFeeExcess(signedSize);

    // Clamp the change value to no more than 0 as it is a changeless
    // transaction.
    // If the excess is negative, it is a shortfall.
    changeValue = feeExcess.isNegative ? feeExcess : BigInt.zero;

  }

  /// A useful default coin selection algorithm.
  /// Currently this will first select candidates at random until the required
  /// input amount is reached. If the resulting transaction is too large or not
  /// enough funds have been reached it will fall back to adding the largest
  /// input values first.
  factory CoinSelection.optimal({
    int version = Transaction.currentVersion,
    required Iterable<InputCandidate> candidates,
    required Iterable<Output> recipients,
    required Program changeProgram,
    required BigInt feePerKb,
    required BigInt minFee,
    required BigInt minChange,
    Locktime locktime = Locktime.zero,
  }) {

    final randomSelection = CoinSelection.random(
      version: version,
      candidates: candidates,
      recipients: recipients,
      changeProgram: changeProgram,
      feePerKb: feePerKb,
      minFee: minFee,
      minChange: minChange,
      locktime: locktime,
    );

    return randomSelection.tooLarge || !randomSelection.enoughFunds
      ? CoinSelection.largestFirst(
        version: version,
        candidates: candidates,
        recipients: recipients,
        changeProgram: changeProgram,
        feePerKb: feePerKb,
        minFee: minFee,
        minChange: minChange,
        locktime: locktime,
      )
      : randomSelection;

  }

  /// A simple selection algorithm that selects inputs from the [candidates]
  /// in the order that they are given until the required amount has been
  /// reached. If there are not enough coins, all shall be selected and
  /// [enoughFunds] shall be false.
  ///
  /// If [randomise] is set to true, the order of inputs shall be randomised
  /// after being selected. This is useful for candidates that are not already
  /// randomised as it may avoid giving clues to the algorithm being used.
  ///
  /// The algorithm will only take upto 6800 candidates by default to avoid
  /// taking too long and due to size limitations. This can be changed with
  /// [maxCandidates].
  factory CoinSelection.inOrderUntilEnough({
    int version = Transaction.currentVersion,
    required Iterable<InputCandidate> candidates,
    required Iterable<Output> recipients,
    required Program changeProgram,
    required BigInt feePerKb,
    required BigInt minFee,
    required BigInt minChange,
    Locktime locktime = Locktime.zero,
    bool randomise = false,
    int maxCandidates = 6800,
  }) {

    CoinSelection trySelection(Iterable<InputCandidate> selected)
      => CoinSelection(
        version: version,
        selected: selected,
        recipients: recipients,
        changeProgram: changeProgram,
        feePerKb: feePerKb,
        minFee: minFee,
        minChange: minChange,
        locktime: locktime,
      );

    if (candidates.isEmpty) return trySelection([]);

    // Restrict number of candidates due to size limitation and for efficiency
    final list = candidates.take(maxCandidates).toList();

    // Use binary search to find the required amount
    CoinSelection search(int left, int right, CoinSelection? cacheRight) {

      if (left == right) {
        return cacheRight ?? trySelection(list.take(left));
      }

      final middle = (left + right) ~/ 2;
      final middleSelection = trySelection(list.take(middle));

      return middleSelection.enoughFunds
        ? search(left, middle, middleSelection)
        : search(middle+1, right, cacheRight);

    }

    final selection = search(1, list.length, null);

    return randomise
      ? trySelection(selection.selected.toList()..shuffle())
      : selection;

  }

  /// A simple selection algorithm that selects inputs randomly from the
  /// [candidates] until the required amount has been reached.
  factory CoinSelection.random({
    int version = Transaction.currentVersion,
    required Iterable<InputCandidate> candidates,
    required Iterable<Output> recipients,
    required Program changeProgram,
    required BigInt feePerKb,
    required BigInt minFee,
    required BigInt minChange,
    Locktime locktime = Locktime.zero,
  }) => CoinSelection.inOrderUntilEnough(
    version: version,
    candidates: candidates.toList()..shuffle(),
    recipients: recipients,
    changeProgram: changeProgram,
    feePerKb: feePerKb,
    minFee: minFee,
    minChange: minChange,
    locktime: locktime,
  );

  /// A simple selection algorithm that selects inputs from the [candidates]
  /// starting from the largest value until the required amount has been
  /// reached. The order of the selected inputs are randomised.
  factory CoinSelection.largestFirst({
    int version = Transaction.currentVersion,
    required Iterable<InputCandidate> candidates,
    required Iterable<Output> recipients,
    required Program changeProgram,
    required BigInt feePerKb,
    required BigInt minFee,
    required BigInt minChange,
    Locktime locktime = Locktime.zero,
  }) => CoinSelection.inOrderUntilEnough(
    version: version,
    candidates: candidates.toList().sorted(
      (a, b) => b.value.compareTo(a.value),
    ),
    recipients: recipients,
    changeProgram: changeProgram,
    feePerKb: feePerKb,
    minFee: minFee,
    minChange: minChange,
    randomise: true,
    locktime: locktime,
  );

  /// Obtains the transaction with selected inputs and outputs including any
  /// change at a random location, ready to be signed. Throws
  /// [InsufficientFunds] if there is not enough input value to meet the output
  /// value and fee, or [TransactionTooLarge] if the resulting signed
  /// transaction would be too large.
  Transaction get transaction {

    if (!enoughFunds) throw InsufficientFunds();
    if (tooLarge) throw TransactionTooLarge();

    return Transaction(
      version: version,
      inputs: selected.map((candidate) => candidate.input),
      outputs: changeless
        ? recipients
        : insertRandom(
          recipients,
          Output.fromProgram(changeValue, changeProgram),
        ),
      locktime: locktime,
      skipSizeCheck: true,
    );

  }

  /// True when the input value covers the outputs and fee
  bool get enoughFunds => !changeValue.isNegative;
  /// True when the change output is omitted
  bool get changeless => changeValue.compareTo(BigInt.zero) == 0;
  /// True if the resulting fully signed transaction will be too large
  bool get tooLarge => signedSize > Transaction.maxSize;
  /// True if a signable solution has been found
  bool get ready => enoughFunds && !tooLarge;
  /// The fee to be paid by the transaction
  BigInt get fee => inputValue - recipientValue - changeValue;

}
