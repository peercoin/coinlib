import 'dart:typed_data';
import 'package:coinlib/src/secp256k1/secp256k1.dart';
import 'package:coinlib/src/common/bytes.dart';
import 'package:coinlib/src/common/hex.dart';

class InvalidPublicKey implements Exception {}

/// Represents an ECC public key on the secp256k1 curve that has an associated
/// private key
class ECPublicKey {

  /// Either 33 compressed or 65 uncompressed bytes
  final Uint8List _data;

  /// Constructs a public key from a 33-byte compressed or 65-byte uncompressed
  /// representation. [InvalidPublicKey] will be thrown if the public key is
  /// invalid or in the wrong format.
  ECPublicKey(Uint8List data) : _data = Uint8List.fromList(data) {
    if (data.length != 33 && data.length != 65) {
      throw InvalidPublicKey();
    }
    if (!secp256k1.pubKeyVerify(data)) throw InvalidPublicKey();
  }

  /// Constructs a public key from HEX encoded data that must represent a
  /// 33-byte compressed key, or 65-byte uncompressed key
  ECPublicKey.fromHex(String hex) : this(hexToBytes(hex));

  /// Constructs a public key from a 32-byte X coordinate where the Y coordinate
  /// is made even.
  ECPublicKey.fromXOnly(Uint8List xcoord) : this(
    Uint8List.fromList([2, ...checkBytes(xcoord, 32, name: "xcoord")]),
  );
  ECPublicKey.fromXOnlyHex(String hex) : this.fromXOnly(hexToBytes(hex));

  /// Tweaks the public key with a scalar multiplied by the generator point. In
  /// the instance a new key cannot be created (practically impossible for
  /// random 32-bit scalars), then null will be returned.
  ECPublicKey? tweak(Uint8List scalar) {
    checkBytes(scalar, 32, name: "Scalar");
    final newKey = secp256k1.pubKeyTweak(_data, scalar, compressed);
    return newKey == null ? null : ECPublicKey(newKey);
  }

  String get hex => bytesToHex(_data);
  bool get compressed => _data.length == 33;
  Uint8List get data => Uint8List.fromList(_data);

  /// Obtains the X coordinate of the public key which is used for Schnorr
  /// signatures. Schnorr signatures force an even Y coordinate. Public and
  /// private keys are converted to use even Y coordinates as necessary allowing
  /// any existing keys to work.
  Uint8List get x => _data.sublist(1, 33);

  /// A hex string of the x-coordinate
  String get xhex => bytesToHex(x);

  /// Obtains a new key that uses the same X coordinate but uses an even Y
  /// coordinate.
  ECPublicKey get xonly => ECPublicKey.fromXOnly(x);

  /// True if the Y-coordinate is even as required for Schnorr signatures. If
  /// the Y-coorindate is not even, then the odd equivilent can be obtained via
  /// [xonly].
  bool get yIsEven
    // Compressed even type
    => _data[0] == 2
    // Uncompressed even type
    || _data[0] == 6
    // Uncompressed and check for even
    || (_data[0] == 4 && (_data.last & 1 == 0));

  @override
  bool operator ==(Object other)
    => (other is ECPublicKey) && bytesEqual(_data, other._data);

  @override
  int get hashCode => _data[1] | _data[2] << 8 | _data[3] << 16 | _data[4] << 24;

}
