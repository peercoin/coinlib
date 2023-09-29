/// Encapsulates the signature hash type to be used for an input signature.
/// Signatures may sign different output and inputs to allow for transaction
/// modifications. To sign an entire transaction the [all] constructor should be
/// used.
class SigHashType {

  /// Value to sign all outputs
  static const allValue = 1;
  /// Value to sign no outputs
  static const noneValue = 2;
  /// Value to sign the output at the same index as the input
  static const singleValue = 3;
  /// Flag that can be combined with other hash type values to only sign the
  /// input containing the signature
  static const anyOneCanPayFlag = 0x80;

  /// The single byte representation of the sighash type. Use [all], [none],
  /// [single] and [anyonecanpay] to extract details of the type.
  final int value;

  /// Returns true if the sighash type value is valid
  static bool validValue(int value) {
    final valueMod = value & ~anyOneCanPayFlag;
    return valueMod >= allValue && valueMod <= singleValue;
  }

  /// Checks if the sighash value is valid and returns an [ArgumentError] if
  /// not.
  static checkValue(int value) {
    if (!validValue(value)) {
      throw ArgumentError.value(value, "value", "not a valid hash type");
    }
  }

  /// Constructs from the byte representation of the sighash type.
  SigHashType.fromValue(this.value) {
    checkValue(value);
  }

  /// Sign all of the outputs. If [anyOneCanPay] is true, then only the input
  /// containing the signature will be signed.
  /// If [anyOneCanPay] is false and a Taproot input is being signed, this will
  /// be treated as "SIGHASH_DEFAULT".
  const SigHashType.all({ bool anyOneCanPay = false })
    : value = allValue | (anyOneCanPay ? anyOneCanPayFlag : 0);

  /// Sign no outputs. If [anyOneCanPay] is true, then only the input containing
  /// the signature will be signed.
  const SigHashType.none({ bool anyOneCanPay = false })
    : value = noneValue | (anyOneCanPay ? anyOneCanPayFlag : 0);

  /// Sign the output at the same index as the input. If [anyOneCanPay] is true,
  /// then only the input containing the signature will be signed.
  const SigHashType.single({ bool anyOneCanPay = false })
    : value = singleValue | (anyOneCanPay ? anyOneCanPayFlag : 0);

  /// All outputs shall be signed
  bool get all => (value & ~anyOneCanPayFlag) == allValue;
  /// No outputs shall be signed
  bool get none => (value & ~anyOneCanPayFlag) == noneValue;
  /// Only the output with the same index as the input shall be signed
  bool get single => (value & ~anyOneCanPayFlag) == singleValue;
  /// Only the input receiving the signature shall be signed
  bool get anyOneCanPay => (value & anyOneCanPayFlag) != 0;

  @override
  bool operator==(Object other) => other is SigHashType && value == other.value;

  @override
  int get hashCode => value;


}
