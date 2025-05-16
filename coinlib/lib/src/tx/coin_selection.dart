import 'package:coinlib/src/common/serial.dart';
import 'package:coinlib/src/crypto/random.dart';
import 'package:coinlib/src/scripts/program.dart';
import 'package:coinlib/src/tx/inputs/witness_input.dart';
import 'package:collection/collection.dart';
import 'inputs/input.dart';
import 'inputs/taproot_input.dart';
import 'output.dart';
import 'transaction.dart';

class InsufficientFunds implements Exception {}

/// A candidate input to spend a UTXO with the UTXO value
class InputCandidate {

  /// Input that can spend the UTXO
  final Input input;
  /// Value of UTXO to be spent
  final BigInt value;
  /// True if it is known that the default sighash type is being used which
  /// allows one less byte to be used for Taproot signatures.
  final bool defaultSigHash;

  /// Provides an [input] alongside the [value] being spent that may be
  /// selected.
  ///
  /// [defaultSigHash] can be set to true if it is known that a Taproot input
  /// will definitely be signed with SIGHASH_DEFAULT. The fee calculation will
  /// be incorrect if this is set for a non-default sighash type.
  InputCandidate({
    required this.input,
    required this.value,
    this.defaultSigHash = false,
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
  final int locktime;

  /// The total value of selected inputs
  late final BigInt inputValue;
  /// The total value of all recipient outputs
  late final BigInt recipientValue;
  /// The fee to be paid by the transaction
  late final BigInt fee;
  /// The value of the change output. This is 0 for a changeless transaction or
  /// negative if there aren't enough funds.
  late final BigInt changeValue;
  /// The maximum size of the transaction after being fully signed
  late final int signedSize;

  int _sizeGivenChange(int fixedSize, bool includeChange)
    => fixedSize
    + recipients.fold(0, (acc, output) => acc + output.size)
    + (includeChange ? Output.fromProgram(BigInt.zero, changeProgram).size : 0)
    + MeasureWriter.varIntSizeOfInt(
      recipients.length + (includeChange ? 1 : 0),
    ) as int;

  BigInt _feeForSize(int size) {
    final feeForSize = feePerKb * BigInt.from(size) ~/ BigInt.from(1000);
    return feeForSize.compareTo(minFee) > 0 ? feeForSize : minFee;
  }

  /// Selects all the inputs from [selected] to send to the [recipients] outputs
  /// and provide change to the [changeProgram]. The [feePerKb] specifies the
  /// required fee in sats per KB with a minimum fee specified with
  /// [minFee]. The [minChange] is the minimum allowed change.
  CoinSelection({
    this.version = Transaction.currentVersion,
    required Iterable<InputCandidate> selected,
    required Iterable<Output> recipients,
    required this.changeProgram,
    required this.feePerKb,
    required this.minFee,
    required this.minChange,
    this.locktime = 0,
  }) : selected = List.unmodifiable(selected),
    recipients = List.unmodifiable(recipients) {

    if (selected.any((candidate) => candidate.input.signedSize == null)) {
      throw ArgumentError("Cannot select inputs without known max signed size");
    }

    // Get input and recipient values
    inputValue = selected
      .fold(BigInt.zero, (acc, candidate) => acc + candidate.value);
    recipientValue = recipients
      .fold(BigInt.zero, (acc, output) => acc + output.value);

    final isWitness = selected.any(
      (candidate) => candidate.input is WitnessInput,
    );

    // Get unchanging size
    final int fixedSize
      // Version and locktime
      = 8
      // Add witness marker and flag
      + (isWitness ? 2 : 0)
      // Fully signed inputs
      + MeasureWriter.varIntSizeOfInt(selected.length)
      + selected.fold(
        0,
        (acc, candidate) {
          final input = candidate.input;
          final inputSize = input is TaprootInput && candidate.defaultSigHash
            ? input.defaultSignedSize
            : input.signedSize;
          return acc + inputSize!;
        }
      );

    // Determine size and fee with change
    final sizeWithChange = _sizeGivenChange(fixedSize, true);
    final feeWithChange = _feeForSize(sizeWithChange);
    final includedChangeValue = inputValue - recipientValue - feeWithChange;

    // If change is under the required minimum, remove the change output
    if (includedChangeValue.compareTo(minChange) < 0) {

      final changelessSize = _sizeGivenChange(fixedSize, false);
      final feeForSize = _feeForSize(changelessSize);
      final excess = inputValue - recipientValue - feeForSize;

      if (!excess.isNegative) {
        // Exceeded without change. Fee is the input value minus the recipient
        // value
        signedSize = changelessSize;
        fee = inputValue - recipientValue;
        changeValue = BigInt.zero;
        return;
      }
      // Else haven't met requirement

    }

    // Either haven't met requirement, or have met requirement with change so
    // provide details of change-containing transaction
    signedSize = sizeWithChange;
    fee = feeWithChange;
    changeValue = includedChangeValue;

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
    int locktime = 0,
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
  /// If [randomise] is set to true, the order of inputs shall be randomised
  /// after being selected. This is useful for candidates that are not already
  /// randomised as it may avoid giving clues to the algorithm being used.
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
    int locktime = 0,
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

    // Restrict number of candidates due to size limitation and for efficiency
    final list = candidates.take(maxCandidates).toList();

    CoinSelection selection = trySelection([]);
    for (int i = 0; i < list.length; i++) {
      selection = trySelection(list.take(i+1));
      if (selection.enoughFunds) break;
    }

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
    int locktime = 0,
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
    int locktime = 0,
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
      outputs: changeless ? recipients : insertRandom(
        recipients,
        Output.fromProgram(changeValue, changeProgram),
      ),
      locktime: locktime,
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

}
