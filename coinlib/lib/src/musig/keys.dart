part of "library.dart";

/// Takes the public keys ([pubKeys]) for MuSig2 and provides the [aggregate]
/// public key. This will automatically order the keys and provide a consistent
/// aggregate key.
class MuSigPublicKeys {

  final Set<ECPublicKey> pubKeys;
  late final ECPublicKey aggregate;

  late final OpaqueMuSigCache _aggCache;

  MuSigPublicKeys._(this.pubKeys, this.aggregate, this._aggCache);

  factory MuSigPublicKeys(Set<ECPublicKey> pubKeys) {

    if (pubKeys.isEmpty) {
      throw ArgumentError.value(pubKeys, "pubKeys", "should not be empty");
    }

    final (bytes, cache) = secp256k1.muSigAgggregate(
      pubKeys.map((pk) => pk.data).toList(),
    );

    return MuSigPublicKeys._(pubKeys, ECPublicKey.fromXOnly(bytes), cache);

  }

  /// Tweaks as an x-only aggregate public key
  MuSigPublicKeys tweak(Uint8List scalar) {
    checkScalar(scalar);
    final (keyBytes, cache) = secp256k1.muSigTweakXOnly(
      _aggCache, scalar,
    );
    return MuSigPublicKeys._(pubKeys, ECPublicKey(keyBytes).xonly, cache);
  }

}

/// The private MuSig2 information for a participant
class MuSigPrivate {

  final ECPrivateKey privateKey;
  final MuSigPublicKeys public;

  MuSigPrivate._(this.privateKey, this.public);

  MuSigPrivate(this.privateKey, Set<ECPublicKey> otherKeys)
    : public = MuSigPublicKeys({ privateKey.pubkey, ...otherKeys });

  MuSigPrivate tweak(Uint8List scalar) => MuSigPrivate._(
    privateKey, public.tweak(scalar),
  );

}
