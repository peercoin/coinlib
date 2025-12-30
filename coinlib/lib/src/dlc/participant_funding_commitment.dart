part of "library.dart";

/// The proposed inputs and change for a DLC funding participant. Their net
/// contribution must reach their amount in [DLCTerms.fundAmounts] plus a share
/// of the fee that includes the fee specific to their inputs and change input
/// and a fraction of all other transaction data.
/// TODO: The required commitment should probably be determined by
/// [DLCFundingCollector] and this docstring updated accordingly.
class DLCParticipantFundingCommitment {

  /// The change output to include in the outputs
  final Output change;
  /// The inputs provided by the participant. The [InputCandidate] contains the
  /// input value but this must be validated against the actual output value to
  /// be correct.
  final List<InputCandidate> inputs;

  DLCParticipantFundingCommitment({
    required this.change,
    required this.inputs,
  });

  // TODO: Add coin selector to meet required contribution and fee, making this
  // easier for consumers of the library to fund their contribution.

  /// Amount contributed after subtracting change from inputs
  BigInt get netAmount
    => addBigInts(inputs.map((input) => input.value)) - change.value;

}
