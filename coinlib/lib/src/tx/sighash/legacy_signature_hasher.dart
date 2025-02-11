import 'dart:typed_data';
import 'package:coinlib/src/common/serial.dart';
import 'package:coinlib/src/crypto/hash.dart';
import 'package:coinlib/src/scripts/operations.dart';
import 'package:coinlib/src/scripts/script.dart';
import 'package:coinlib/src/tx/inputs/raw_input.dart';
import 'package:coinlib/src/tx/output.dart';
import 'package:coinlib/src/tx/sign_details.dart';
import 'package:coinlib/src/tx/transaction.dart';
import 'signature_hasher.dart';

/// Produces signature hashes for legacy non-witness inputs.
final class LegacySignatureHasher extends SignatureHasher {

  static final ScriptOp _codeseperator = ScriptOpCode.fromName("CODESEPARATOR");
  static final _hashOne = Uint8List(32)..last = 1;

  @override
  final LegacySignDetailsWithScript details;

  /// Produces the hash of an input signature for a non-witness input.
  LegacySignatureHasher(this.details);

  @override
  Uint8List get hash {

    // Remove OP_CODESEPERATOR from the script code
    final correctedScriptSig = Script(
      details.scriptCode.ops.where((op) => !op.match(_codeseperator)),
    ).compiled;

    // If there is no matching output for SIGHASH_SINGLE, then return all null
    // bytes apart from the last byte that should be 1
    if (hashType.single && inputN >= tx.outputs.length) return _hashOne;

    // Create modified transaction for obtaining a signature hash

    final modifiedInputs = (
      hashType.anyOneCanPay ? [thisInput] : tx.inputs
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

    final modifiedOutputs = hashType.all ? tx.outputs : (
      hashType.none ? <Output>[] : [
        // Single output
        // Include blank outputs upto output index
        ...Iterable.generate(inputN, (i) => Output.blank()),
        tx.outputs[inputN],
      ]
    );

    final modifiedTx = Transaction(
      version: tx.version,
      inputs: modifiedInputs,
      outputs: modifiedOutputs,
      locktime: tx.locktime,
    );

    // Add sighash type onto the end
    final bytes = Uint8List(modifiedTx.size + 4);
    final writer = BytesWriter(bytes);
    modifiedTx.write(writer);
    writer.writeUInt32(hashType.value);

    // Use sha256d for signature hash
    return sha256DoubleHash(bytes);

  }

}
