part of "library.dart";

class InvalidMuSigPublicNonce implements Exception {}

/// The public nonce of a participant for a single signing session only.
class MuSigPublicNonce {

  final OpaqueMuSigPublicNonce _underlying;
  /// The serialised bytes that can be shared with other signers
  final Uint8List bytes;

  MuSigPublicNonce._(this._underlying, this.bytes);
  MuSigPublicNonce._fromUnderlying(this._underlying)
    : bytes = secp256k1.muSigSerialisePublicNonce(_underlying);

  /// Creates the public nonce from the [bytes]. If the [bytes] are invalid,
  /// [InvalidMuSigPublicNonce] will be thrown.
  factory MuSigPublicNonce.fromBytes(Uint8List bytes) {
    try {
      return MuSigPublicNonce._(secp256k1.muSigParsePublicNonce(bytes), bytes);
    } on Secp256k1Exception {
      throw InvalidMuSigPublicNonce();
    }
  }

}
