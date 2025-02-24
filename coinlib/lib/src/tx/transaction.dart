import 'dart:typed_data';
import 'package:coinlib/src/common/checks.dart';
import 'package:coinlib/src/common/hex.dart';
import 'package:coinlib/src/common/serial.dart';
import 'package:coinlib/src/crypto/ec_private_key.dart';
import 'package:coinlib/src/crypto/hash.dart';
import 'package:coinlib/src/tx/inputs/taproot_key_input.dart';
import 'package:coinlib/src/tx/inputs/taproot_single_script_sig_input.dart';
import 'inputs/input.dart';
import 'inputs/input_signature.dart';
import 'inputs/legacy_input.dart';
import 'inputs/legacy_witness_input.dart';
import 'inputs/raw_input.dart';
import 'inputs/witness_input.dart';
import 'sighash/sighash_type.dart';
import 'output.dart';
import 'sign_details.dart';

class TransactionTooLarge implements Exception {}
class InvalidTransaction implements Exception {}
class CannotSignInput implements Exception {
  final String message;
  CannotSignInput(this.message);
  @override
  String toString() => "CannotSignInput: $message";
}

/// Allows construction and signing of Peercoin transactions including those
/// with witness data.
class Transaction with Writable {

  static const currentVersion = 3;
  static const maxSize = 1000000;

  static const minInputSize = 41;
  static const minOutputSize = 9;
  static const minOtherSize = 10;

  static const maxInputs
    = (maxSize - minOtherSize - minOutputSize) ~/ minInputSize;
  static const maxOutputs
    = (maxSize - minOtherSize - minInputSize) ~/ minOutputSize;

  final int version;
  final List<Input> inputs;
  final List<Output> outputs;
  final int locktime;

  /// Constructs a transaction with the given [inputs] and [outputs].
  /// [TransactionTooLarge] will be thrown if the resulting transction exceeds
  /// [maxSize] (1MB).
  Transaction({
    this.version = currentVersion,
    required Iterable<Input> inputs,
    required Iterable<Output> outputs,
    this.locktime = 0,
  })
  : inputs = List.unmodifiable(inputs),
  outputs = List.unmodifiable(outputs)
  {
    checkInt32(version);
    checkUint32(locktime);
    if (size > maxSize) throw TransactionTooLarge();
  }

  static int _readAndCheckVarInt(BytesReader reader, int max) {
    final n = reader.readVarInt();
    if (n > BigInt.from(max)) throw TransactionTooLarge();
    return n.toInt();
  }

  static Transaction? _tryRead(BytesReader reader, bool witness) {

    final version = reader.readInt32();

    if (witness) {
      // Check for witness data
      final marker = reader.readUInt8();
      final flag = reader.readUInt8();
      if (marker != 0 || flag != 1) return null;
    }

    final rawInputs = List.generate(
      _readAndCheckVarInt(reader, maxInputs),
      (i) => RawInput.fromReader(reader),
    );

    final outputs = List.generate(
      _readAndCheckVarInt(reader, maxOutputs),
      (i) => Output.fromReader(reader),
    );

    // Match the raw inputs with witness data if this is a witness transaction
    final inputs = rawInputs.map(
      (raw) => Input.match(raw, witness ? reader.readVector() : []),
    // Create list now to ensure we read the witness data before the locktime
    ).toList();

    final locktime = reader.readUInt32();

    return Transaction(
      version: version,
      inputs: inputs,
      outputs: outputs,
      locktime: locktime,
    );

  }

  /// Reads a transaction from a [BytesReader], which may throw
  /// [TransactionTooLarge] or [InvalidTransaction] if the data doesn't
  /// represent a complete transaction within [maxSize] (1MB).
  /// If [expectWitness] is true, the transaction is assumed to be a witness
  /// transaction. If it is false, the transction is assumed to be a legacy
  /// non-witness transaction.
  /// If [expectWitness] is omitted or null, then this method will determine the
  /// correct transaction type from the data, starting with a witness type.
  factory Transaction.fromReader(BytesReader reader, { bool? expectWitness }) {

    bool tooLarge = false;
    final start = reader.offset;

    Transaction? tryReadAndSetTooLarge(bool witness) {
      try {
        return _tryRead(reader, witness);
      } on TransactionTooLarge {
        tooLarge = true;
      } on Exception catch(_) {}
      return null;
    }

    if (expectWitness != false) { // Includes null condition
      final witnessTx = tryReadAndSetTooLarge(true);
      if (witnessTx != null) return witnessTx;
    }

    // Reset offset of reader
    reader.offset = start;

    if (expectWitness != true) { // Includes null condition
      final legacyTx = tryReadAndSetTooLarge(false);
      if (legacyTx != null) return legacyTx;
    }

    throw tooLarge ? TransactionTooLarge() : InvalidTransaction();

  }

  /// Constructs a transaction from serialised bytes. See [fromReader()].
  factory Transaction.fromBytes(Uint8List bytes, { bool? expectWitness })
    => Transaction.fromReader(BytesReader(bytes), expectWitness: expectWitness);

  /// Constructs a transaction from the serialised data encoded as hex. See
  /// [fromReader()].
  factory Transaction.fromHex(String hex, { bool? expectWitness })
    => Transaction.fromBytes(hexToBytes(hex), expectWitness: expectWitness);

  @override
  void write(Writer writer) {

    writer.writeInt32(version);

    if (isWitness) {
      writer.writeUInt8(0); // Marker
      writer.writeUInt8(1); // Flag
    }

    writer.writeVarInt(BigInt.from(inputs.length));
    for (final input in inputs) {
      input.write(writer);
    }

    writer.writeVarInt(BigInt.from(outputs.length));
    for (final output in outputs) {
      output.write(writer);
    }

    if (isWitness) {
      for (final input in inputs) {
        writer.writeVector(input is WitnessInput ? input.witness : []);
      }
    }

    writer.writeUInt32(locktime);

  }

  Transaction _newInputs(List<Input> newInputs) => Transaction(
    version: version,
    inputs: newInputs,
    outputs: outputs,
    locktime: locktime,
  );

  T _requireInputOfType<T>(int inputN) {
    if (inputN < 0 || inputN >= inputs.length) {
      throw RangeError.range(inputN, 0, inputs.length-1, "inputN");
    }
    final input = inputs[inputN];
    if (input is! T) throw CannotSignInput("Input to sign is not a $T");
    return input as T;
  }

  Transaction _replaceNewlySigned(int n, Input input) => _newInputs(
    [...inputs.take(n), input, ...inputs.skip(n+1)],
  );

  /// Sign a [LegacyInput] at [inputN] with the [key]. The signature hash is
  /// SIGHASH_ALL by default but can be changed via [hashType].
  Transaction signLegacy({
    required int inputN,
    required ECPrivateKey key,
    SigHashType hashType = const SigHashType.all(),
  }) => _replaceNewlySigned(
    inputN,
    _requireInputOfType<LegacyInput>(inputN).sign(
      details: LegacySignDetails(tx: this, inputN: inputN, hashType: hashType),
      key: key,
    ),
  );

  /// Sign a [LegacyWitnessInput] at [inputN] with the [key]. Must contain the
  /// [value] being spent. The signature hash is SIGHASH_ALL by default but can
  /// be changed via [hashType].
  Transaction signLegacyWitness({
    required int inputN,
    required ECPrivateKey key,
    required BigInt value,
    SigHashType hashType = const SigHashType.all(),
  }) => _replaceNewlySigned(
    inputN,
    _requireInputOfType<LegacyWitnessInput>(inputN).sign(
      details: LegacyWitnessSignDetails(
        tx: this,
        inputN: inputN,
        value: value,
        hashType: hashType,
      ),
      key: key,
    ),
  );

  /// Sign a [TaprootKeyInput] at [inputN] with the tweaked [key].
  ///
  /// If all inputs are included, all previous outputs must be provided to
  /// [prevOuts]. If ANYONECANPAY is used, only the output of the input should
  /// be included in [prevOuts].
  ///
  /// The signature hash is SIGHASH_DEFAULT by default but can be changed via
  /// [hashType].
  Transaction signTaproot({
    required int inputN,
    required ECPrivateKey key,
    required List<Output> prevOuts,
    SigHashType hashType = const SigHashType.schnorrDefault(),
  }) => _replaceNewlySigned(
    inputN,
    _requireInputOfType<TaprootKeyInput>(inputN).sign(
      details: TaprootKeySignDetails(
        tx: this,
        inputN: inputN,
        prevOuts: prevOuts,
        hashType: hashType,
      ),
      key: key,
    ),
  );

  /// Sign a [TaprootSingleScriptSigInput] at [inputN] with the [key].
  ///
  /// If all inputs are included, all previous outputs must be provided to
  /// [prevOuts]. If ANYONECANPAY or ANYPREVOUT is used, only the output of the
  /// input must be included in [prevOuts]. If ANYPREVOUTANYSCRIPT is used,
  /// [prevOuts] must be empty.
  ///
  /// The signature hash is SIGHASH_DEFAULT by default but can be changed via
  /// [hashType].
  Transaction signTaprootSingleScriptSig({
    required int inputN,
    required ECPrivateKey key,
    required List<Output> prevOuts,
    SigHashType hashType = const SigHashType.schnorrDefault(),
  }) => _replaceNewlySigned(
    inputN,
    _requireInputOfType<TaprootSingleScriptSigInput>(inputN).sign(
      details: TaprootScriptSignDetails(
        tx: this,
        inputN: inputN,
        prevOuts: prevOuts,
        hashType: hashType,
      ),
      key: key,
    ),
  );

  /// Replaces the input at [n] with the new [input] and invalidates other
  /// input signatures that have standard sighash types accordingly. This is
  /// useful for signing or otherwise updating inputs that cannot be signed with
  /// the [signLegacy], [signLegacyWitness] or [signTaproot] methods.
  Transaction replaceInput(Input input, int n) {

    final oldInput = inputs[n];

    if (input == oldInput) return this;

    final newPrevOut = input.prevOut != oldInput.prevOut;
    final newSequence = input.sequence != oldInput.sequence;

    final filtered = inputs.map(
      (input) => input.filterSignatures(
        (insig)
          // Allow ANYONECANPAY, ANYPREVOUT or ANYPREVOUTANYSCRIPT
          => insig.hashType.inputs != InputSigHashOption.all
          // Allow signature if previous output hasn't changed and the sequence
          // has not changed for taproot inputs or when using SIGHASH_ALL.
          || !(
            newPrevOut || (
              newSequence
              && (insig.hashType.all || insig is SchnorrInputSignature)
            )
          ),
      ),
    ).toList();

    return _newInputs([...filtered.take(n), input, ...filtered.skip(n+1)]);

  }

  /// Returns a new [Transaction] with the [input] added to the end of the input
  /// list.
  Transaction addInput(Input input) => Transaction(
    version: version,
    inputs: [
      // Only keep ANYONECANPAY, ANYPREVOUT and ANYPREVOUTANYSCRIPT signatures
      // when adding a new input
      ...inputs.map(
        (input) => input.filterSignatures(
          (insig) => insig.hashType.inputs != InputSigHashOption.all,
        ),
      ),
      input,
    ],
    outputs: outputs,
    locktime: locktime,
  );

  /// Returns a new [Transaction] with the [output] added to the end of the
  /// output list.
  Transaction addOutput(Output output) {

    final modifiedInputs = inputs.asMap().map(
      (i, input) => MapEntry(
        i, input.filterSignatures(
          (insig)
          // Allow signatures that sign no outpus
          => insig.hashType.none
          // Allow signatures that sign a single output which isn't the one
          // being added
          || (insig.hashType.single && i != outputs.length),
        ),
      ),
    ).values;

    return Transaction(
      version: version,
      inputs: modifiedInputs,
      outputs: [...outputs, output],
      locktime: locktime,
    );

  }

  Transaction? _legacyCache;
  /// Returns a non-witness variant of this transaction. Any witness inputs are
  /// replaced with their raw equivalents without witness data. If the
  /// transaction is already non-witness, then it shall be returned as-is.
  Transaction get legacy => isWitness
    ? _legacyCache ??= Transaction(
      version: version,
      inputs: inputs.map(
        // Raw inputs remove all witness data and are serialized as legacy
        // inputs. Don't waste creating a new object for non-witness inputs.
        (input) => input is WitnessInput
          ? RawInput(
            prevOut: input.prevOut,
            scriptSig: input.scriptSig,
            sequence: input.sequence,
          )
          : input,
      ),
      outputs: outputs,
      locktime: locktime,
    )
    : this;

  Uint8List? _hashCache;
  /// The serialized tx data hashed with sha256d
  Uint8List get hash => _hashCache ??= sha256DoubleHash(toBytes());

  Uint8List? _legacyHashCache;
  /// The serialized tx data without witness data hashed with sha256d
  Uint8List get legacyHash => _legacyHashCache ??= legacy.hash;

  /// Get the reversed hash as hex which is usual for Peercoin transactions
  /// This provides the witness txid. See [legacyHash] for the legacy type of
  /// hash.
  String get hashHex => bytesToHex(Uint8List.fromList(hash.reversed.toList()));

  /// Gets the legacy reversed hash as hex without witness data.
  String get txid
    => bytesToHex(Uint8List.fromList(legacyHash.reversed.toList()));

  /// If the transaction has any witness inputs.
  bool get isWitness => inputs.any((input) => input is WitnessInput);

  bool get isCoinBase
    => inputs.length == 1
    && inputs.first.prevOut.coinbase
    && outputs.isNotEmpty;

  bool get isCoinStake
    => inputs.isNotEmpty
    && !inputs.first.prevOut.coinbase
    && outputs.length >= 2
    && outputs.first.value == BigInt.zero
    && outputs.first.scriptPubKey.isEmpty;

  /// Returns true when all of the inputs are fully signed with at least one
  /// input and one output. There is no guarentee that the transaction is valid
  /// on the blockchain.
  bool get complete
    => inputs.isNotEmpty && outputs.isNotEmpty
    && inputs.every((input) => input.complete);

}
