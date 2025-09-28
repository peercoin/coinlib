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
  /// and public nonces have been obtained, the signing session can be prepared
  /// with [prepare].
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

  /// Prepares the MuSig signing session with details required to produce
  /// partial signatures. This can only be done once.
  ///
  /// [otherNonces] must map the public key of all other participants with their
  /// shared public nonces.
  ///
  /// [hash] must be the 32-byte hash to be signed.
  ///
  /// An optional [adaptor] point can be provided to produce an adaptor
  /// signature.
  void prepare({
    required KeyToNonceMap otherNonces,
    required Uint8List hash,
    ECPublicKey? adaptor,
  }) {

    checkBytes(hash, 32);

    // Ensure we haven't already aggregated the nonces
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

  }

}
