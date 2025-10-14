part of "library.dart";

class InvalidMuSigPartialSig implements Exception {}

/// The partial signature from a participant that needs to be shared.
class MuSigPartialSig {

  final OpaqueMuSigPartialSig _underlying;
  final Uint8List bytes;

  MuSigPartialSig._(this._underlying, this.bytes);
  MuSigPartialSig._fromUnderlying(this._underlying)
    : bytes = secp256k1.muSigSerialisePartialSig(_underlying);

  /// Creates the partial signature from the [bytes]. If the [bytes] are
  /// invalid, [InvalidMuSigPartialSig] will be thrown.
  factory MuSigPartialSig.fromBytes(Uint8List bytes) {
    try {
      return MuSigPartialSig._(secp256k1.muSigParsePartialSig(bytes), bytes);
    } on Secp256k1Exception {
      throw InvalidMuSigPartialSig();
    }
  }

}
