part of "library.dart";

sealed class MuSigResult {}

/// A MuSig result with a completed [signature].
class MuSigResultComplete extends MuSigResult {
  final SchnorrSignature signature;
  MuSigResultComplete._(this.signature);
}

/// A MuSig result with an [adaptorSignature] that requires decrypting with the
/// adaptor discrete-log scalar.
class MuSigResultAdaptor extends MuSigResult {
  final SchnorrAdaptorSignature adaptorSignature;
  MuSigResultAdaptor._(this.adaptorSignature);
}
