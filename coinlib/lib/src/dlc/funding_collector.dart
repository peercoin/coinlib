part of "library.dart";

/// Collects the inputs and change outputs for each participant for the
/// construction of a Funding Transaction.
///
/// This can only be created through a [DLCReady] object to remind consumers of
/// the library to create DLCs in the correct order as the Refund Transaction
/// and Contract Execution Transactions must first be created through a
/// [DLCStatefulBuilder].
class DLCFundingCollector {

  final DLCTerms terms;
  final Map<ECPublicKey, DLCParticipantFundingCommitment> fundingCommitments;

  DLCFundingCollector._(this.terms) : fundingCommitments = {};

  // TODO: Create funding transaction without inputs and change, determine total
  // contribution requirements for each participant.
  // TODO: Allow adding DLCParticipantFundingCommitment and verify contribution
  // meets requirement including fee

}
