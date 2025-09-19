import 'package:coinlib/src/crypto/ec_private_key.dart';
import 'package:coinlib/src/crypto/ec_public_key.dart';
import 'package:coinlib/src/secp256k1/secp256k1.dart';

/// Takes the public keys ([pubKeys]) for MuSig2 and provides the [aggregate]
/// public key. This will automatically order the keys and provide a consistent
/// aggregate key.
class MuSigPublicKeys {

  final Set<ECPublicKey> pubKeys;
  late final ECPublicKey aggregate;

  late final MuSigCache _aggCache;

  MuSigPublicKeys(this.pubKeys) {

    if (pubKeys.isEmpty) {
      throw ArgumentError.value(pubKeys, "pubKeys", "should not be empty");
    }

    final (bytes, cache) = secp256k1.muSigAgggregate(
      pubKeys.map((pk) => pk.data).toList(),
    );
    aggregate = ECPublicKey.fromXOnly(bytes);
    _aggCache = cache;

  }

}

/// The private MuSig2 information for a participant
class MuSigPrivate {

  final ECPrivateKey privateKey;
  final MuSigPublicKeys public;

  MuSigPrivate(this.privateKey, Set<ECPublicKey> otherKeys)
    : public = MuSigPublicKeys({ privateKey.pubkey, ...otherKeys });

}
