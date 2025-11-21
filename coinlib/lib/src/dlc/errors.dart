class InvalidDLCTerms implements Exception {

  final String message;

  InvalidDLCTerms(this.message);
  InvalidDLCTerms.badOutcomeMatch()
    : this("Contains outcome output amounts not matching the funded amount");
  InvalidDLCTerms.badVersion(int v)
    : this("Version $v isn't allowed. Only v1 is supported.");
  InvalidDLCTerms.noOutputs() : this("CETOutcome have no outputs");
  InvalidDLCTerms.smallOutput(BigInt min)
    : this("Contains output value less than min of $min");
  InvalidDLCTerms.smallFunding(BigInt min)
    : this("Contains funding value less than min of $min");
  InvalidDLCTerms.notOrdered()
    : this("The input bytes contain out-of-order keys");
  InvalidDLCTerms.cetLocktimeAfterRf()
    : this("A CET locktime is not before the RF locktime");

}
