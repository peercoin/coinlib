part of "library.dart";

/// Maps the public key of a participant to their public nonce
typedef KeyToNonceMap = Map<ECPublicKey, MuSigPublicNonce>;

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
  bool _isAdaptor = false;
  KeyToNonceMap? _otherNonces;
  OpaqueMuSigPartialSig? _ourPartialSig;
  final Map<ECPublicKey, OpaqueMuSigPartialSig> _partialSigs = {};

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
    _isAdaptor = adaptor != null;

    // Produce partial signature
    _ourPartialSig = secp256k1.muSigPartialSign(
      _ourSecretNonce, privKey.data, keys._aggCache, _underlyingSession!,
    );
    return MuSigPartialSig._fromUnderlying(_ourPartialSig!);

  }

  /// Adds the partial signature ([partialSig]) of a participant with the
  /// [participantKey] if it is valid.
  ///
  /// Will return true if the partial signature is valid or false if it isn't.
  ///
  /// This must be called after [sign] or else [StateError] will be thrown.
  ///
  /// A valid [partialSig] cannot be sent for a [participantKey] more than once
  /// or [StateError] will be thrown.
  bool addPartialSignature({
    required MuSigPartialSig partialSig,
    required ECPublicKey participantKey,
  }) {

    if (_underlyingSession == null) {
      throw StateError("Need to call sign first");
    }

    if (havePartialSignature(participantKey)) {
      throw StateError(
        "Already contains a valid partial signature from $participantKey",
      );
    }

    final pubNonce = _otherNonces![participantKey];

    if (pubNonce == null) {
      throw ArgumentError.value(
        participantKey,
        "participantKey",
        "is not a public key of a participant",
      );
    }

    final valid = secp256k1.muSigPartialSignatureVerify(
      partialSig._underlying,
      pubNonce._underlying,
      participantKey.data,
      keys._aggCache,
      _underlyingSession!,
    );

    if (valid) {
      _partialSigs[participantKey] = partialSig._underlying;
    }

    return valid;

  }

  /// Returns true if a valid partial signature was processed with
  /// [addPartialSignature] for the [participantKey].
  bool havePartialSignature(ECPublicKey participantKey) =>
    _partialSigs.containsKey(participantKey);

  MuSigResult finish() {

    if (_underlyingSession == null) {
      throw StateError("Need to call sign before finishing");
    }

    final actualSigs = _partialSigs.length;
    final reqSigs = keys.pubKeys.length - 1;
    if (actualSigs != reqSigs) {
      throw StateError(
        "Need $reqSigs partial signatures. Only have $actualSigs",
      );
    }

    final sig = SchnorrSignature(
      secp256k1.muSigSignatureAggregate(
        { _ourPartialSig!, ..._partialSigs.values },
        _underlyingSession!,
      ),
    );

    return _isAdaptor
      ? MuSigResultAdaptor._(
        SchnorrAdaptorSignature(
          sig,
          secp256k1.muSigNonceParity(_underlyingSession!),
        ),
      )
      : MuSigResultComplete._(sig);

  }

}
