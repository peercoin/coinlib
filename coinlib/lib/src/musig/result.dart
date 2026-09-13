part of "library.dart";

sealed class MuSigResult;

/// A MuSig result with a completed [signature].
class MuSigResultComplete._(final SchnorrSignature signature)
    extends MuSigResult;

/// A MuSig result with an [adaptorSignature] that requires decrypting with the
/// adaptor discrete-log scalar.
class MuSigResultAdaptor._(final SchnorrAdaptorSignature adaptorSignature)
    extends MuSigResult;
