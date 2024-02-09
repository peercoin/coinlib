import 'dart:typed_data';
import 'package:coinlib/src/crypto/ec_public_key.dart';
import 'package:coinlib/src/crypto/random.dart';

/// A "nothing up my sleeve" [ECPublicKey] that is created from a point with no
/// known private key and tweaked with a scalar value named [rTweak]. The key is
/// reproduceable from this scalar using [fromRTweak()]. Any of
/// these keys have no known associted private key. Sharing the [rTweak] allows
/// others to verify this. These keys can be used as Taproot internal keys where
/// no key-path spending is desired.
class NUMSPublicKey extends ECPublicKey {

  /// To prove that this point does not have an associated private key, the
  /// x-coordinate is the sha256 hash of the uncompressed secp256k1 generator
  /// point bytes. This can be reproduced and verified using the script
  /// bin/generate_nums_point.dart.
  static final numsPoint = ECPublicKey.fromXOnlyHex(
    "50929b74c1a04954b78b4b6035e97a5e078a5a0f28ec96d547bfee9ace803ac0",
  );

  final Uint8List _rTweak;

  NUMSPublicKey._(Uint8List rTweak, super.data)
    : _rTweak = Uint8List.fromList(rTweak), super();

  /// Constructs a NUMS key from a given [rTweak].
  /// Throws [ArgumentError] if [rTweak] cannot produce a valid public key.
  factory NUMSPublicKey.fromRTweak(Uint8List rTweak) {
    final tweaked = numsPoint.tweak(rTweak);
    if (tweaked == null) {
      throw ArgumentError.value(rTweak, "rTweak", "gives invalid tweaked key");
    }
    return NUMSPublicKey._(rTweak, tweaked.data);
  }

  /// Generates a new NUMS key with a random [rTweak].
  factory NUMSPublicKey.generate()
    => NUMSPublicKey.fromRTweak(generateRandomBytes(32));

  /// The scalar tweak for this key which may be shared for verification.
  Uint8List get rTweak => Uint8List.fromList(_rTweak);

}
