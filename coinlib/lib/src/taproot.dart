import 'dart:typed_data';
import 'package:coinlib/src/crypto/ec_private_key.dart';
import 'package:coinlib/src/crypto/ec_public_key.dart';
import 'package:coinlib/src/crypto/hash.dart';

/// This class encapsulates the construction of Taproot tweaked keys given an
/// internal key
class Taproot {

  final ECPublicKey internalKey;

  static final tweakHash = getTaggedHasher("TapTweak");

  /// Takes the [internalKey] to construct the tweaked key. The internal key
  /// will be forced to use an even Y coordinate and may not equal the
  /// passed [internalKey].
  Taproot({ required ECPublicKey internalKey })
    : internalKey = internalKey.xonly;

  /// Takes a private key and tweaks it for key-path spending
  ECPrivateKey tweakPrivateKey(ECPrivateKey key)
    => key.xonly.tweak(tweakScalar)!;

  Uint8List? _tweakScalarCache;
  /// The scalar to tweak the internal key
  Uint8List get tweakScalar => _tweakScalarCache ??= tweakHash(internalKey.x);

  ECPublicKey? _tweakedKeyCache;
  /// Obtains the tweaked public key for use in a Taproot program
  ECPublicKey get tweakedKey => _tweakedKeyCache ??= internalKey.tweak(
    tweakScalar,
  )!; // Assert not-null. Failure should be practically impossible.

}
