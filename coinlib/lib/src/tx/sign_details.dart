import 'dart:typed_data';

import 'package:coinlib/src/scripts/program.dart';
import 'package:coinlib/src/scripts/script.dart';

import 'output.dart';
import 'sighash/sighash_type.dart';
import 'transaction.dart';

/// Sign details that are shared for all types of signature
abstract base class SignDetails({
  /// The transaction to sign
  required final Transaction tx,

  /// The input index to sign
  required final int inputN,

  /// The signature hash type
  required final SigHashType hashType,
}) {
  this {
    if (inputN < 0 || inputN >= tx.inputs.length) {
      throw ArgumentError.value(inputN, "inputN", "outside range of inputs");
    }

    if (!hashType.none && tx.outputs.isEmpty) {
      throw CannotSignInput("Cannot sign input without any outputs");
    }
  }
}

abstract base class LegacyOrWitnessSignDetails({
  required super.tx,
  required super.inputN,
  required super.hashType,
}) extends SignDetails {
  this : super() {
    if (!hashType.supportsLegacy) {
      throw CannotSignInput(
        "$hashType is not supported for legacy signature hashes",
      );
    }
  }
}

abstract base class LegacyOrWitnessSignDetailsWithScript({
  required super.tx,
  required super.inputN,
  required super.hashType,

  /// The redeem script for the input being signed
  required final Script scriptCode,
}) extends LegacyOrWitnessSignDetails {
  this : super();
}

/// Details for signing a legacy transaction input
final class LegacySignDetails({
  required super.tx,
  required super.inputN,
  super.hashType = const SigHashType.all(),
}) extends LegacyOrWitnessSignDetails {
  /// By default, SIGHASH_ALL will be used
  this : super();

  LegacySignDetailsWithScript addScript(Script script) =>
      LegacySignDetailsWithScript(
        tx: tx,
        inputN: inputN,
        hashType: hashType,
        scriptCode: script,
      );
}

/// Details for signing a legacy transaction input with the redeem script
final class LegacySignDetailsWithScript({
  required super.tx,
  required super.inputN,
  required super.scriptCode,
  super.hashType = const SigHashType.all(),
}) extends LegacyOrWitnessSignDetailsWithScript {
  /// By default, SIGHASH_ALL will be used
  this : super();
}

/// Details for signing a legacy witness transaction input
final class LegacyWitnessSignDetails({
  required super.tx,
  required super.inputN,

  /// The value of the previous output
  required final BigInt value,
  super.hashType = const SigHashType.all(),
}) extends LegacyOrWitnessSignDetails {
  /// By default, SIGHASH_ALL will be used
  this : super();

  LegacyWitnessSignDetailsWithScript addScript(Script script) =>
      LegacyWitnessSignDetailsWithScript(
        tx: tx,
        inputN: inputN,
        value: value,
        scriptCode: script,
        hashType: hashType,
      );
}

/// Details for signing a legacy witness transaction input with the redeem
/// script
final class LegacyWitnessSignDetailsWithScript({
  required super.tx,
  required super.inputN,

  /// The value of the previous output
  required final BigInt value,
  required super.scriptCode,
  super.hashType = const SigHashType.all(),
}) extends LegacyOrWitnessSignDetailsWithScript {
  /// By default, SIGHASH_ALL will be used
  this : super();
}

/// Details for signing a Taproot transaction input. Use [TaprootKeySignDetails]
/// or [TaprootScriptSignDetails].
base class TaprootSignDetails({
  required super.tx,
  required super.inputN,

  /// Details of previous outputs. This should carry only the previous output of
  /// the input to sign when using ANYONECANPAY or ANYPREVOUT. This should be
  /// empty for ANYPREVOUTANYSCRIPT.
  required final List<Output> prevOuts,

  /// If a tapscript is being signed for instead of a key-path.
  required final bool isScript,
  super.hashType = const SigHashType.schnorrDefault(),

  /// The leafhash to sign, null for key-spends or ANYPREVOUTANYSCRIPT.
  final Uint8List? leafHash,

  /// The last executed CODESEPARATOR position in the script
  final int codeSeperatorPos = 0xFFFFFFFF,
}) extends SignDetails {
  /// The [hashType] controls what data is included. If ommitted it will be
  /// treated as SIGHASH_DEFAULT which includes the same data as SIGHASH_ALL but
  /// produces distinct signatures.
  ///
  /// [prevOuts] must contain all previous outputs if the input option is
  /// [InputSigHashOption.all] which is the default. If ANYONECANPAY
  /// ([InputSigHashOption.anyOneCanPay]) or ANYPREVOUT
  /// ([InputSigHashOption.anyPrevOut]) is used, only a single output for the
  /// input being signed must be provided. If ANYPREVOUTANYSCRIPT
  /// ([InputSigHashOption.anyPrevOutAnyScript]) is used, this must be empty.
  this : super() {
    if (hashType.single && inputN >= tx.outputs.length) {
      throw CannotSignInput("No corresponing output for SIGHASH_SINGLE");
    }

    final expPrevOutLen = switch (hashType.inputs) {
      InputSigHashOption.all => tx.inputs.length,
      InputSigHashOption.anyOneCanPay || InputSigHashOption.anyPrevOut => 1,
      InputSigHashOption.anyPrevOutAnyScript => 0,
    };

    if (prevOuts.length != expPrevOutLen) {
      throw CannotSignInput(
        "prevOut length should be $expPrevOutLen for $hashType",
      );
    }
  }
}

/// Details for a Taproot key-spend
final class TaprootKeySignDetails({
  required super.tx,
  required super.inputN,
  required super.prevOuts,
  super.hashType,
}) extends TaprootSignDetails {
  /// See [TaprootSignDetails()].
  this : super(isScript: false) {
    if (hashType.requiresApo) {
      throw CannotSignInput("Cannot use APO for key-spend");
    }
  }

  Program? get program => switch (hashType.inputs) {
    InputSigHashOption.all => prevOuts[inputN].program,
    InputSigHashOption.anyOneCanPay => prevOuts.first.program,
    _ => null,
  };
}

/// Details for a Taproot script-spend
final class TaprootScriptSignDetails({
  required super.tx,
  required super.inputN,
  required super.prevOuts,
  super.codeSeperatorPos,
  super.leafHash,
  super.hashType,
}) extends TaprootSignDetails {
  /// See [TaprootSignDetails()].
  ///
  /// The [leafHash] has to be provided before a hash can be produced unless
  /// ANYPREVOUTANYSCRIPT is used.
  ///
  /// [codeSeperatorPos] can be provided with the position of the last executed
  /// CODESEPARATOR unless none have been executed in the script.
  this : super(isScript: true);

  /// Add the [leafHash] required before signing can be done unless using
  /// ANYPREVOUTANYSCRIPT
  TaprootScriptSignDetails addLeafHash(Uint8List leafHash) =>
      TaprootScriptSignDetails(
        tx: tx,
        inputN: inputN,
        prevOuts: prevOuts,
        leafHash: leafHash,
        codeSeperatorPos: codeSeperatorPos,
        hashType: hashType,
      );
}
