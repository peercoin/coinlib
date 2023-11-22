import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart' as crypto;
import 'package:pointycastle/digests/ripemd160.dart';

// Using the crypto and pointycastle packages for now, but could migrate to
// native platform-specific implementations later for enhanced efficiency
Uint8List _singleSha256(Uint8List msg)
  => Uint8List.fromList(crypto.sha256.convert(msg).bytes);
Uint8List _ripemd160(Uint8List msg) => RIPEMD160Digest().process(msg);

Uint8List sha256Hash(Uint8List msg) => _singleSha256(msg);
Uint8List sha256DoubleHash(Uint8List msg) => _singleSha256(_singleSha256(msg));
Uint8List hash160(Uint8List msg) => _ripemd160(_singleSha256(msg));
Uint8List hmacSha512(Uint8List key, Uint8List msg) => Uint8List.fromList(
  crypto.Hmac(crypto.sha512, key).convert(msg).bytes,
);

Uint8List Function(Uint8List msg) getTaggedHasher(String tag) {
  final hashedTag = sha256Hash(utf8.encode(tag));
  return (Uint8List msg) => sha256Hash(
    Uint8List.fromList([...hashedTag, ...hashedTag, ...msg]),
  );
}
