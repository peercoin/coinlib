class InvalidOutputSigHashValue extends ArgumentError {
  InvalidOutputSigHashValue(int value)
    : super.value(value, "value", "not a valid output sighash value");
}

/// Signature hash options that control what outputs are included.
enum OutputSigHashOption {

  /// Sign all outputs
  all(1, "ALL"),
  /// Sign no outputs
  none(2, "NONE"),
  /// Sign the output at the same index as the input
  single(3, "SINGLE");

  final int value;
  final String string;
  const OutputSigHashOption(this.value, this.string);

  static const Map<int, OutputSigHashOption> _valuesToOption = {
    1: OutputSigHashOption.all,
    2: OutputSigHashOption.none,
    3: OutputSigHashOption.single,
  };

  /// Determines if the value specifies a valid output option, ignoring the
  /// input part.
  static bool validValue(int value)
    => _valuesToOption.containsKey(value & ~0xf0);

  /// Creates an option from the sighash value, ignoring the input part.
  factory OutputSigHashOption.fromValue(int value)
    => _valuesToOption[value & ~0xf0]
    ?? (throw InvalidOutputSigHashValue(value));

  @override
  String toString() => string;

}

class InvalidInputSigHashValue extends ArgumentError {
  InvalidInputSigHashValue(int value)
    : super.value(value, "value", "not a valid input sighash value");
}

/// Signature hash options that control what input data is included.
enum InputSigHashOption {

  /// Include all inputs
  all(0, ""),
  /// Sign only the current input
  anyOneCanPay(0x80, "|ANYONECANPAY"),
  /// Sign only the current input and do not include the output point, allowing
  /// the signature to be reused to reference other outputs with the same output
  /// script and amount.
  anyPrevOut(0x40, "|ANYPREVOUT"),
  /// Sign only the current input and do not include the output point, amount or
  /// script. This allows the signature to be reused for other outputs that
  /// require a signature with the same key but can have arbitrary amounts and
  /// scripts.
  anyPrevOutAnyScript(0xc0, "|ANYPREVOUTANYSCRIPT");

  final int value;
  final String string;
  const InputSigHashOption(this.value, this.string);

  static const Map<int, InputSigHashOption> _valuesToOption = {
    0: InputSigHashOption.all,
    0x80: InputSigHashOption.anyOneCanPay,
    0x40: InputSigHashOption.anyPrevOut,
    0xc0: InputSigHashOption.anyPrevOutAnyScript,
  };

  /// Determines if the value specifies a valid input option, ignoring the
  /// output part.
  static bool validValue(int value)
    => _valuesToOption.containsKey(value & ~0x0f);

  /// Creates an option from the sighash value, ignoring the output part.
  factory InputSigHashOption.fromValue(int value)
    => _valuesToOption[value & ~0x0f]
    ?? (throw InvalidInputSigHashValue(value));

  @override
  String toString() => string;

}

/// Encapsulates the signature hash type to be used for an input signature.
/// Signatures may sign different output and inputs to allow for transaction
/// modifications. To sign an entire transaction the [schnorrDefault()]
/// constructor should be used for Taproot transactions or the [all()]
/// constructor for other transactions.
class SigHashType {

  final OutputSigHashOption outputs;
  final InputSigHashOption inputs;
  /// If true, this is the default value for Schnorr signatures that uses the
  /// behaviour of [all()] (SIGHASH_ALL) but provides distinct signatures.
  final bool schnorrDefault;

  /// Returns true if the sighash type value is valid.
  static bool validValue(int value) => value == 0 || (
    OutputSigHashOption.validValue(value)
    && InputSigHashOption.validValue(value)
  );

  /// Checks if the sighash value is valid and returns an [ArgumentError] if
  /// not.
  static void checkValue(int value) {
    if (value == 0) return;
    OutputSigHashOption.fromValue(value);
    InputSigHashOption.fromValue(value);
  }

  /// Constructs from the byte representation of the sighash type.
  SigHashType.fromValue(int value)
  : outputs = value == 0
      // SIGHASH_ALL behaviour when default schnorr value of 0
      ? OutputSigHashOption.all
      : OutputSigHashOption.fromValue(value),
    inputs = InputSigHashOption.fromValue(value),
    schnorrDefault = value == 0 {
      checkValue(value);
    }

  /// [outputs] must specify if ALL, SINGLE, or NONE is to be used.
  /// [inputs] may restrict inputs to sign to ANYONECANPAY, ANYPREVOUT
  /// or ANYPREVOUTANYSCRIPT.
  const SigHashType({
    required this.outputs,
    required this.inputs,
  }) : schnorrDefault = false;

  /// Functions like [all()] with the same options but produces distinct
  /// signatures and is only acceptable for Taproot Schnorr signatures.
  const SigHashType.schnorrDefault()
    : outputs = OutputSigHashOption.all,
    inputs = InputSigHashOption.all,
    schnorrDefault = true;

  /// Signs all outputs as ALL which is used for typical transactions.
  /// May include restriction on [inputs] to be signed.
  const SigHashType.all({
    InputSigHashOption inputs = InputSigHashOption.all,
  }) : this(outputs: OutputSigHashOption.all, inputs: inputs);

  /// Signs no outputs as NONE.
  /// May include restriction on [inputs] to be signed.
  const SigHashType.none({
    InputSigHashOption inputs = InputSigHashOption.all,
  }) : this(outputs: OutputSigHashOption.none, inputs: inputs);

  /// Signs a single output at the same index as the input as SINGLE.
  /// May include restriction on [inputs] to be signed.
  const SigHashType.single({
    InputSigHashOption inputs = InputSigHashOption.all,
  }) : this(outputs: OutputSigHashOption.single, inputs: inputs);

  /// The single byte representation of the sighash type.
  int get value => schnorrDefault ? 0 : (outputs.value | inputs.value);

  @override
  bool operator==(Object other) => other is SigHashType && value == other.value;

  @override
  int get hashCode => value;

  /// All outputs shall be signed
  bool get all => outputs == OutputSigHashOption.all;
  /// No outputs shall be signed
  bool get none => outputs == OutputSigHashOption.none;
  /// Only the output with the same index as the input shall be signed
  bool get single => outputs == OutputSigHashOption.single;

  /// All inputs shall be signed
  bool get allInputs => inputs == InputSigHashOption.all;
  /// Only the input receiving the signature shall be signed
  bool get anyOneCanPay => inputs == InputSigHashOption.anyOneCanPay;
  /// Only the input receiving the signature shall be signed without the output
  /// point.
  bool get anyPrevOut => inputs == InputSigHashOption.anyPrevOut;
  /// Only the input receiving the signature shall be signed without the output
  /// point, amount or output script.
  bool get anyPrevOutAnyScript => inputs == InputSigHashOption.anyPrevOutAnyScript;

  /// True if the sighash type is supported for legacy transactions outside of
  /// Taproot
  bool get supportsLegacy => !schnorrDefault && !requiresApo;

  /// True if the sighash type is only valid for APO keys
  bool get requiresApo => anyPrevOut || anyPrevOutAnyScript;

  @override
  String toString() => schnorrDefault ? "DEFAULT" : "$outputs$inputs";

}
