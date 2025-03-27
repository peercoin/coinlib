import 'dart:typed_data';
import 'package:coinlib/src/secp256k1/secp256k1.dart';
import 'package:coinlib/src/common/bytes.dart';
import 'package:coinlib/src/common/hex.dart';
import 'ec_private_key.dart';
import 'ec_public_key.dart';

class InvalidSchnorrSignature extends Error {}

class SchnorrSignature {

  static const length = 64;

  final Uint8List _data;

  /// Takes a 64-byte serialized Schnorr signature as [data] that contains
  /// 32-byte r and s values. The r and s values are not checked for validity.
  /// If they are invalid then [verify] will always fail.
  SchnorrSignature(Uint8List data)
    : _data = copyCheckBytes(data, length, name: "Schnorr signature");

  /// Takes a HEX encoded 64-byte schnorr signature.
  SchnorrSignature.fromHex(String hex) : this(hexToBytes(hex));

  /// Construct a signature from an R point and s scalar.
  SchnorrSignature.fromRS(ECPublicKey r, ECPrivateKey s)
    : this(Uint8List.fromList(r.x + s.data));

  /// Creates a signature using a private key ([privkey]) for a given 32-byte
  /// [hash]. The signature will be generated deterministically and shall be the
  /// same for a given hash and key.
  /// [InvalidSchnorrSignature] is thrown if the resulting signature is invalid.
  /// This shouldn't happen unless there is a computation error.
  factory SchnorrSignature.sign(ECPrivateKey privkey, Uint8List hash) {
    checkBytes(hash, 32);

    final sig = SchnorrSignature(secp256k1.schnorrSign(hash, privkey.data));

    // Verify signature to protect against computation errors. Cosmic rays etc.
    if (!sig.verify(privkey.pubkey, hash)) throw InvalidSchnorrSignature();

    return sig;

  }

  /// Takes a 32-byte message [hash] and [publickey] and returns true if the
  /// signature is valid for the public key and hash.
  bool verify(ECPublicKey publickey, Uint8List hash)
    => secp256k1.schnorrVerify(_data, checkBytes(hash, 32), publickey.x);

  /// The serialized 32 byte r and s values of a schnorr signature
  Uint8List get data => Uint8List.fromList(_data);

  /// The R point of the Schnorr signature, given by the x coordinate.
  /// The x-coordinate can be obtained by [ECPublicKey.x()].
  ECPublicKey get r => ECPublicKey.fromXOnly(_data.sublist(0, 32));

  /// The s scalar of the Schnorr signature
  ECPrivateKey get s => ECPrivateKey(_data.sublist(32, 64));

}
