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

  ECPublicKey? _tweakedKeyCache;
  /// Obtains the tweaked key for use in a Taproot program
  ECPublicKey get tweakedKey => _tweakedKeyCache ??= internalKey.tweak(
    tweakHash(internalKey.x),
  )!; // Assert not-null. Failure should be practically impossible.

}
