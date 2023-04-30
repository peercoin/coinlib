import 'dart:typed_data';
import 'package:coinlib/src/common/hex.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:pointycastle/digests/ripemd160.dart';

// Using the crypto and pointycastle packages for now, but could migrate to
// native platform-specific implementations later for enhanced efficiency
_singleSha256(Uint8List msg)
  => Uint8List.fromList(crypto.sha256.convert(msg).bytes);
_ripemd160(Uint8List msg) => RIPEMD160Digest().process(msg);

_copyCheckBytes(Uint8List bytes, int length) {
  if (bytes.length != length) {
    throw ArgumentError("Hash should be $length bytes", "bytes");
  }
  return Uint8List.fromList(bytes);
}

/// Encapsulates a 32-byte hash
class Hash256 {

  final Uint8List bytes;

  Hash256.fromHashBytes(Uint8List bytes)
    : bytes = _copyCheckBytes(bytes, 32);
  Hash256.fromHashHex(String hex) : this.fromHashBytes(hexToBytes(hex));

}

/// Encapsulates a 20-byte hash
class Hash160 {

  final Uint8List bytes;

  Hash160.fromHashBytes(Uint8List bytes)
    : bytes = _copyCheckBytes(bytes, 20);
  Hash160.fromHashHex(String hex) : this.fromHashBytes(hexToBytes(hex));

}

Hash256 sha256Hash(Uint8List msg) => Hash256.fromHashBytes(_singleSha256(msg));
Hash256 sha256DoubleHash(Uint8List msg) => Hash256.fromHashBytes(
  _singleSha256(_singleSha256(msg)),
);
Hash160 hash160(Uint8List msg) => Hash160.fromHashBytes(
  _ripemd160(_singleSha256(msg)),
);
