import 'dart:typed_data';
import 'package:coinlib/src/common/bytes.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:pointycastle/digests/ripemd160.dart';

// Using the crypto and pointycastle packages for now, but could migrate to
// native platform-specific implementations later for enhanced efficiency
_singleSha256(Uint8List msg)
  => Uint8List.fromList(crypto.sha256.convert(msg).bytes);
_ripemd160(Uint8List msg) => RIPEMD160Digest().process(msg);

Bytes32 sha256Hash(Uint8List msg) => Bytes32.fromList(_singleSha256(msg));
Bytes32 sha256DoubleHash(Uint8List msg) => Bytes32.fromList(
  _singleSha256(_singleSha256(msg)),
);
Bytes20 hash160(Uint8List msg) => Bytes20.fromList(
  _ripemd160(_singleSha256(msg)),
);
