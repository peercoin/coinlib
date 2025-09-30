part of "library.dart";

/// Maps the public key of a participant to their public nonce
typedef KeyToNonceMap = Map<ECPublicKey, MuSigPublicNonce>;

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

/// A MuSig signing session state to be used for one signing session only.
///
/// This class is stateful unlike most of the classes in the library. This is to
/// prevent re-use of earlier parts of the signing session, ensuring signing
/// nonces are used no more than once.
class MuSigStatefulSigningSession {

  /// The keys being used for MuSig2
  final MuSigPublicKeys keys;
  /// The public key of the signer
  final ECPublicKey ourPublicKey;
  /// The public signing nonce that must be shared with all other signers
  late final MuSigPublicNonce ourPublicNonce;

  late final OpaqueMuSigSecretNonce _ourSecretNonce;

  OpaqueMuSigSession? _underlyingSession;
  KeyToNonceMap? _otherNonces;

  /// Starts a signing session with the MuSig [keys] and specifying the public
  /// key for the signer with [ourPublicKey].
  ///
  /// [ourPublicNonce] needs to be shared with other signers. Once all details
  /// and public nonces have been obtained, [sign] can be called to create a
  /// partial signature.
  MuSigStatefulSigningSession({
    required this.keys,
    required this.ourPublicKey,
  }) {

    if (!keys.pubKeys.contains(ourPublicKey)) {
      throw ArgumentError.value(
        ourPublicKey,
        "ourPublicKey",
        "not in MuSig public keys",
      );
    }

    final (secret, public) = secp256k1.muSigGenerateNonce(ourPublicKey.data);
    _ourSecretNonce = secret;
    ourPublicNonce = MuSigPublicNonce._fromUnderlying(public);

  }

  /// Produces a partial signature with the required details. This can only be
  /// done once or a [StateError] will be thrown.
  ///
  /// [otherNonces] must map the public key of all other participants with their
  /// shared public nonces.
  ///
  /// [hash] must be the 32-byte hash to be signed.
  ///
  /// The [privKey] must be paired with [ourPublicKey].
  ///
  /// An optional [adaptor] point can be provided to produce an adaptor
  /// signature.
  MuSigPartialSig sign({
    required KeyToNonceMap otherNonces,
    required Uint8List hash,
    required ECPrivateKey privKey,
    ECPublicKey? adaptor,
  }) {

    checkBytes(hash, 32);

    // Check private key matches the participant's public key
    if (privKey.pubkey != ourPublicKey) {
      throw ArgumentError.value(
        privKey,
        "privKey",
        "doesn't match outPublicKey",
      );
    }

    // Ensure we haven't already produced a partial signature
    if (_underlyingSession != null) {
      throw StateError("Already prepared signing session");
    }

    // Check the number of nonces and existance of keys
    final otherKeys = keys.pubKeys.where((key) => key != ourPublicKey).toSet();
    if (
      !otherNonces.keys.toSet().containsAll(otherKeys)
      || otherKeys.length != otherNonces.length
    ) {
      throw ArgumentError.value(
        otherNonces,
        "otherNonces",
        "do not contain all participant keys",
      );
    }

    // Aggregate
    _underlyingSession = secp256k1.muSigCreateSigningSession(
      keys._aggCache,
      {
        ourPublicNonce._underlying,
        ...otherNonces.values.map((nonce) => nonce._underlying).toSet(),
      },
      hash,
      adaptor?.data,
    );
    _otherNonces = otherNonces;

    // Produce partial signature
    return MuSigPartialSig._fromUnderlying(
      secp256k1.muSigPartialSign(
        _ourSecretNonce, privKey.data, keys._aggCache, _underlyingSession!,
      ),
    );

  }

}
