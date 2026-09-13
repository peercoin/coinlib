import 'dart:typed_data';

import 'package:coinlib/src/common/hex.dart';

import 'ec_public_key.dart';

/// Represents an [ECPublicKey] that must be in a compressed format, or else a
/// [InvalidPublicKey] will be thrown.
class ECCompressedPublicKey extends ECPublicKey {
  new(super.data) {
    if (data.length != 33) throw InvalidPublicKey();
  }
  new fromHex(String hex) : this(hexToBytes(hex));
  new fromXOnly(super.xcoord) : super.fromXOnly();
  new fromXOnlyHex(super.hex) : super.fromXOnlyHex();
  new fromPubkey(ECPublicKey key)
    : this(
        key.compressed
            ? key.data
            : Uint8List.fromList([key.yIsEven ? 2 : 3, ...key.x]),
      );

  @override
  ECCompressedPublicKey? tweak(Uint8List scalar) {
    final tweaked = super.tweak(scalar);
    return tweaked == null ? null : ECCompressedPublicKey.fromPubkey(tweaked);
  }

  @override
  ECCompressedPublicKey get xonly => ECCompressedPublicKey.fromXOnly(x);
}
