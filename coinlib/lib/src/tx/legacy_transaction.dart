import 'dart:typed_data';
import 'package:coinlib/src/common/checks.dart';
import 'package:coinlib/src/common/hex.dart';
import 'package:coinlib/src/common/serial.dart';
import 'package:coinlib/src/crypto/ec_private_key.dart';
import 'package:coinlib/src/crypto/ec_public_key.dart';
import 'package:coinlib/src/crypto/ecdsa_signature.dart';
import 'package:coinlib/src/crypto/hash.dart';
import 'package:coinlib/src/scripts/operations.dart';
import 'package:coinlib/src/scripts/programs/p2pkh.dart';
import 'package:coinlib/src/scripts/script.dart';
import 'p2pkh_input.dart';
import 'p2sh_multisig_input.dart';
import 'sighash_type.dart';
import 'input.dart';
import 'input_signature.dart';
import 'output.dart';
import 'raw_input.dart';

class TransactionTooLarge with Exception {}
class CannotSignInput with Exception {
  final String message;
  CannotSignInput(this.message);
  @override
  String toString() => "CannotSignInput: $message";
}

/// A legacy transaction does not include or consider witness data. Use
/// [WitnessTransaction] to sign and build transactions with witness inputs.
class LegacyTransaction with Writable {

  static const int currentVersion = 3;
  static const int maxSize = 1000000;

  static const int minInputSize = 41;
  static const int minOutputSize = 9;
  static const int minOtherSize = 10;

  static const int maxInputs
    = (maxSize - minOtherSize - minOutputSize) ~/ minInputSize;
  static const int maxOutputs
    = (maxSize - minOtherSize - minInputSize) ~/ minOutputSize;

  final int version;
  final List<Input> inputs;
  final List<Output> outputs;
  final int locktime;

  /// Constructs a transaction with the given [inputs] and [outputs].
  /// [TransactionTooLarge] will be thrown if the resulting transction exceeds
  /// [maxSize (1MB).
  LegacyTransaction({
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

  /// Reads a transaction from a [BytesReader], which may throw
  /// [TransactionTooLarge] or [OutOfData] if the data doesn't represent a
  /// complete transaction within [maxSize] (1MB).
  factory LegacyTransaction.fromReader(BytesReader reader) {

    final version = reader.readInt32();

    final inputs = List.generate(
      _readAndCheckVarInt(reader, maxInputs),
      (i) => Input.match(RawInput.fromReader(reader)),
    );

    final outputs = List.generate(
      _readAndCheckVarInt(reader, maxOutputs),
      (i) => Output.fromReader(reader),
    );

    final locktime = reader.readUInt32();

    return LegacyTransaction(
      version: version,
      inputs: inputs,
      outputs: outputs,
      locktime: locktime,
    );

  }

  /// Constructs a transaction from serialised bytes. See [fromReader].
  factory LegacyTransaction.fromBytes(Uint8List bytes)
    => LegacyTransaction.fromReader(BytesReader(bytes));

  /// Constructs a transaction from the serialised data encoded as hex. See
  /// [fromReader].
  factory LegacyTransaction.fromHex(String hex)
    => LegacyTransaction.fromBytes(hexToBytes(hex));

  @override
  void write(Writer writer) {
    writer.writeInt32(version);
    writer.writeVarInt(BigInt.from(inputs.length));
    for (final input in inputs) {
      input.write(writer);
    }
    writer.writeVarInt(BigInt.from(outputs.length));
    for (final output in outputs) {
      output.write(writer);
    }
    writer.writeUInt32(locktime);
  }

  static final ScriptOp _codeseperator = ScriptOpCode.fromName("CODESEPARATOR");

  /// Obtains the hash for an input signature for the input at [inputN]. The
  /// [prevOutScript] from the previous output is necessary. [hashType] controls
  /// what data is included in the signature.
  Uint8List signatureHash(int inputN, Script prevOutScript, SigHashType hashType) {

    if (inputN < 0 || inputN >= inputs.length) {
      throw ArgumentError.value(
        inputN, "inputN", "not within input range 0-${inputs.length-1}",
      );
    }

    // Remove OP_CODESEPERATOR from previous output script
    final correctedScriptSig = Script(
      prevOutScript.ops.where((op) => !op.match(_codeseperator)),
    ).compiled;

    // If there is no matching output for SIGHASH_SINGLE, then return all null
    // bytes apart from the last byte that should be 1
    if (hashType.single && inputN >= outputs.length) {
      return Uint8List(32)..last = 1;
    }

    // Create modified transaction for obtaining a signature hash

    final modifiedInputs = (
      hashType.anyOneCanPay ? [inputs[inputN]] : inputs
    ).asMap().map(
      (index, input) {
        final isThisInput = hashType.anyOneCanPay || index == inputN;
        return MapEntry(
          index,
          RawInput(
            prevOut: input.prevOut,
            // Use the corrected previous output script for the input being signed
            // and blank scripts for all the others
            scriptSig: isThisInput ? correctedScriptSig : Uint8List(0),
            // Make sequence 0 for other inputs unless using SIGHASH_ALL
            sequence: isThisInput || hashType.all ? input.sequence : 0,
          ),
        );
      }
    ).values;

    final modifiedOutputs = hashType.all ? outputs : (
      hashType.none ? <Output>[] : [
        // Single output
        // Include blank outputs upto output index
        ...Iterable.generate(inputN, (i) => Output.blank()),
        outputs[inputN],
      ]
    );

    final modifiedTx = LegacyTransaction(
      version: version,
      inputs: modifiedInputs,
      outputs: modifiedOutputs,
      locktime: locktime,
    );

    // Add sighash type onto the end
    final bytes = Uint8List(modifiedTx.size + 4);
    final writer = BytesWriter(bytes);
    modifiedTx.write(writer);
    writer.writeUInt32(hashType.value);

    // Use sha256d for signature hash
    return sha256DoubleHash(bytes);

  }

  /// Sign the input at [inputN] with the [key] and [hashType] and return a new
  /// [LegacyTransaction] with the signed input. The input must be a signable
  /// P2PKH or P2SH multisig input or [CannotSignInput] will be thrown.
  LegacyTransaction sign({
    required int inputN,
    required ECPrivateKey key,
    hashType = const SigHashType.all(),
  }) {

    if (inputN >= inputs.length) {
      throw ArgumentError.value(inputN, "inputN", "outside range of inputs");
    }

    if (!hashType.none && outputs.isEmpty) {
      throw CannotSignInput("Cannot sign input without any outputs");
    }

    final input = inputs[inputN];

    // Get data for input
    late List<ECPublicKey> pubkeys;
    late Script prevOutScript;

    if (input is P2PKHInput) {
      pubkeys = [input.publicKey];
      prevOutScript = P2PKH.fromPublicKey(input.publicKey).script;
    } else if (input is P2SHMultisigInput) {
      pubkeys = input.program.pubkeys;
      // For P2SH it is the redeem script
      prevOutScript = input.program.script;
    } else {
      throw CannotSignInput("${input.runtimeType} not a signable input");
    }

    if (!pubkeys.contains(key.pubkey)) {
      throw CannotSignInput("Public key not part of input");
    }

    // Create signature
    final signHash = signatureHash(inputN, prevOutScript, hashType);
    final insig = InputSignature(ECDSASignature.sign(key, signHash), hashType);

    // Get input with new signature
    late Input newInput;
    if (input is P2PKHInput) {
      newInput = input.addSignature(insig);
    } else if (input is P2SHMultisigInput) {
      // Add signature in the correct order
      newInput = input.insertSignature(
        insig,
        key.pubkey,
        (hashType) => signatureHash(inputN, prevOutScript, hashType),
      );
    }

    // Replace input in input list
    final newInputs = inputs.asMap().map(
      (index, input) => MapEntry(
        index, index == inputN ? newInput : input,
      ),
    ).values;

    return LegacyTransaction(
      version: version,
      inputs: newInputs,
      outputs: outputs,
      locktime: locktime,
    );

  }

  /// Returns a new [LegacyTransaction] with the [input] added to the end of the
  /// input list.
  LegacyTransaction addInput(Input input) {

    // For existing inputs, remove any signatures without ANYONECANPAY
    final modifiedInputs = inputs.map(
      (input) => input.filterSignatures((insig) => insig.hashType.anyOneCanPay),
    );

    // Add new input to end of inputs of new transaction
    return LegacyTransaction(
      version: version,
      inputs: [...modifiedInputs, input],
      outputs: outputs,
      locktime: locktime,
    );

  }

  /// Returns a new [LegacyTransaction] with the [output] added to the end of the
  /// output list.
  LegacyTransaction addOutput(Output output) {

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

    return LegacyTransaction(
      version: version,
      inputs: modifiedInputs,
      outputs: [...outputs, output],
      locktime: locktime,
    );

  }

  Uint8List? _hashCache;
  Uint8List get hash => _hashCache ??= sha256DoubleHash(toBytes());
  /// Get the reversed hash as hex which is usual for Peercoin transactions
  String get hashHex => bytesToHex(Uint8List.fromList(hash.reversed.toList()));
  /// Alias for [hashHex]. This is the tx hash reversed in hex format.
  String get txid => hashHex;

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
