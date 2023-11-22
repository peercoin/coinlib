import 'dart:convert';
import 'dart:typed_data';
import 'package:coinlib/src/common/bytes.dart';
import 'package:coinlib/src/common/checks.dart';
import 'package:coinlib/src/crypto/ec_private_key.dart';
import 'package:coinlib/src/crypto/hash.dart';
import 'package:coinlib/src/encode/base58.dart';
import 'ec_public_key.dart';

class InvalidHDKey implements Exception {}
class InvalidHDKeyVersion implements Exception {}

abstract class HDKey {

  static const maxIndex = 0xffffffff;
  static const hardenBit = 0x80000000;
  static const encodedLength = 78;

  final Uint8List _chaincode;
  final int depth;
  final int index;
  final int parentFingerprint;

  HDKey._({
    required Uint8List chaincode,
    required this.depth,
    required this.index,
    required this.parentFingerprint,
  }) : _chaincode = Uint8List.fromList(chaincode);

  /// Decodes a base58 string into a [HDPrivateKey] or [HDPublicKey]. May throw
  /// [InvalidBase58], [InvalidBase58Checksum] or [InvalidHDKey].
  /// If [privVersion] or/and [pubVersion] is provided, it shall require that
  /// the version is equal to either one of these for a corresponsing private or
  /// public key or else it shall throw [InvalidHDKeyVersion].
  factory HDKey.decode(String b58, { int? privVersion, int? pubVersion }) {

    final data = base58Decode(b58);
    if (data.length != encodedLength) throw InvalidHDKey();

    final keyType = data[45];
    final isPriv = keyType == 0;
    if (!isPriv && keyType != 2 && keyType != 3) throw InvalidHDKey();

    ByteData bd = data.buffer.asByteData();

    if (privVersion != null || pubVersion != null) {
      // Check version if either expected version is provided. Otherwise ignore.
      final version = bd.getUint32(0);
      // If expected version is only public, then reject private and vice versa.
      if (privVersion == null && isPriv) throw InvalidHDKey();
      if (pubVersion == null && !isPriv) throw InvalidHDKey();
      // Ensure version matches
      if (isPriv && version != privVersion) throw InvalidHDKeyVersion();
      if (!isPriv && version != pubVersion) throw InvalidHDKeyVersion();
    }

    final depth = data[4];
    final parentFingerprint = bd.getUint32(5);
    if (depth == 0 && parentFingerprint != 0) throw InvalidHDKey();

    final index = bd.getUint32(9);
    if (depth == 0 && index != 0) throw InvalidHDKey();

    final chaincode = data.sublist(13, 45);

    try {

      return isPriv
        ? HDPrivateKey(
          privateKey: ECPrivateKey(data.sublist(46)),
          chaincode: chaincode,
          depth: depth,
          index: index,
          parentFingerprint: parentFingerprint,
        )
        : HDPublicKey(
          publicKey: ECPublicKey(data.sublist(45)),
          chaincode: chaincode,
          depth: depth,
          index: index,
          parentFingerprint: parentFingerprint,
        );

    } on Exception {
      // If the key provided is invalid, an exception will have been thrown.
      throw InvalidHDKey();
    }

  }

  Uint8List? _identifierCache;
  /// The identifier hash for this key
  Uint8List get identifier => _identifierCache ??= hash160(publicKey.data);
  /// The integer fingerprint of the identifier
  int get fingerprint => identifier.buffer.asByteData().getUint32(0);
  Uint8List get chaincode => Uint8List.fromList(_chaincode);

  /// Derives a key at [index] returning the same type of key: either public or
  /// private. The [index] can inlcude the [hardenBit] to specify that it is
  /// hardened.
  HDKey derive(int index) {

    if (index > HDKey.maxIndex || index < 0) {
      throw ArgumentError.value(
        index, "index", "Can only derive 32-bit indicies",
      );
    }

    final hardened = index >= hardenBit;

    Uint8List data = Uint8List(37);
    if (hardened) {
      if (privateKey == null) {
        throw ArgumentError("Unabled to derive hardened key from public key");
      }
      data[0] = 0x00;
      data.setRange(1, 33, privateKey!.data);
    } else {
      data.setRange(0, 33, publicKey.data);
    }
    data.buffer.asByteData().setUint32(33, index);

    final i = hmacSha512(_chaincode, data);
    final il = i.sublist(0, 32);
    final ir = i.sublist(32);

    if (privateKey != null) {
      final newKey = privateKey!.tweak(il);
      if (newKey == null) return derive(index+1);
      return HDPrivateKey(
        privateKey: newKey,
        chaincode: ir,
        depth: depth+1,
        index: index,
        parentFingerprint: fingerprint,
      );
    }

    // Public key
    final newKey = publicKey.tweak(il);
    if (newKey == null) return derive(index+1);
    return HDPublicKey(
      publicKey: newKey,
      chaincode: ir,
      depth: depth+1,
      index: index,
      parentFingerprint: fingerprint,
    );

  }

  /// Derives a hardened key at [index] which only applies to private keys. The
  /// [index] must not include the left-bit to specify that it is hardened.
  HDPrivateKey deriveHardened(int index) {
    if (index < 0 || index >= hardenBit) {
      throw ArgumentError.value(
        index, "index", "should be below hardered index",
      );
    }
    return derive(index + hardenBit) as HDPrivateKey;
  }

  /// Derives a child key in a [path] format akin to "m/15/3'/4" where the
  /// optional "m" specifies that this key is a master key and "'" specifies
  /// that an index is a hardened key.
  HDKey derivePath(String path) {

    final regex = RegExp(r"^(m\/)?(\d+'?\/)*\d+'?$");
    if (!regex.hasMatch(path)) throw ArgumentError("Expected BIP32 Path");

    List<String> splitPath = path.split("/");

    if (splitPath[0] == "m") {
      if (parentFingerprint != 0) {
        throw ArgumentError("Expected master, got child");
      }
      splitPath = splitPath.sublist(1);
    }

    return splitPath.fold(this, (HDKey prev, String indexStr) {
      if (indexStr.substring(indexStr.length - 1) == "'") {
        return prev.deriveHardened(
          int.parse(indexStr.substring(0, indexStr.length - 1)),
        );
      } else {
        final index = int.parse(indexStr);
        if (index >= hardenBit) {
          throw ArgumentError.value(path, "path", "out-of-range index");
        }
        return prev.derive(index);
      }
    });

  }

  /// Encodes the base58 representation of this key using the [version] prefix.
  String encode(int version) {

    checkUint32(version, "version");

    Uint8List data = Uint8List(encodedLength);
    ByteData bd = data.buffer.asByteData();
    bd.setUint32(0, version);
    bd.setUint8(4, depth);
    bd.setUint32(5, parentFingerprint);
    bd.setUint32(9, index);
    data.setRange(13, 45, _chaincode);

    if (privateKey != null) {
      bd.setUint8(45, 0);
      data.setAll(46, privateKey!.data);
    } else {
      data.setAll(45, publicKey.data);
    }

    return base58Encode(data);

  }

  ECPublicKey get publicKey;
  ECPrivateKey? get privateKey;

}

/// Represents a private key with a chain code that can derive BIP32 keys.
class HDPrivateKey extends HDKey {

  @override
  final ECPrivateKey privateKey;

  HDPrivateKey({
    required this.privateKey,
    required super.chaincode,
    required super.depth,
    required super.index,
    required super.parentFingerprint,
  }) : super._();

  /// Creates a master key from an existing private key and chain code.
  HDPrivateKey.fromKeyAndChainCode(this.privateKey, Uint8List chaincode)
    : super._(
    chaincode: chaincode,
    depth: 0,
    index: 0,
    parentFingerprint: 0,
  ) {
    checkBytes(chaincode, 32, name: "Chaincode");
  }

  /// Generates a master key from a 16-64 byte [seed]. The default BIP32 HMAC
  /// [key] can also be changed.
  factory HDPrivateKey.fromSeed(Uint8List seed, { String key = "Bitcoin seed" }) {

    if (seed.length < 16 || seed.length > 64) {
      throw ArgumentError("Seed should be between 16 and 64 bytes", "seed");
    }

    final hash = hmacSha512(utf8.encode("Bitcoin seed"), seed);
    return HDPrivateKey(
      privateKey: ECPrivateKey(hash.sublist(0, 32)),
      chaincode: hash.sublist(32),
      depth: 0, index: 0, parentFingerprint: 0,
    );

  }

  /// Creates a HD private key from a base58 encoded representation ([b58]). May
  /// throw [InvalidBase58], [InvalidBase58Checksum] or [InvalidHDKey].
  /// If [version] is provided a [InvalidHDKeyVersion] will be thrown if the
  /// version does not match.
  factory HDPrivateKey.decode(String b58, [int? version]) {
    final key = HDKey.decode(b58, privVersion: version);
    if (key is HDPrivateKey) return key;
    throw InvalidHDKey();
  }

  @override
  HDPrivateKey derive(int index) => super.derive(index) as HDPrivateKey;

  @override
  HDPrivateKey derivePath(String path) => super.derivePath(path) as HDPrivateKey;

  HDPublicKey get hdPublicKey => HDPublicKey(
    publicKey: publicKey,
    chaincode: chaincode,
    depth: depth,
    index: index,
    parentFingerprint: parentFingerprint,
  );

  @override
  ECPublicKey get publicKey => privateKey.pubkey;

}

class HDPublicKey extends HDKey {

  @override
  ECPrivateKey? privateKey;
  @override
  final ECPublicKey publicKey;

  HDPublicKey({
    required this.publicKey,
    required super.chaincode,
    required super.depth,
    required super.index,
    required super.parentFingerprint,
  }) : super._();

  /// Creates a HD public key from a base58 encoded representation ([b58]). May
  /// throw [InvalidBase58], [InvalidBase58Checksum] or [InvalidHDKey].
  /// If [version] is provided a [InvalidHDKeyVersion] will be thrown if the
  /// version does not match.
  factory HDPublicKey.decode(String b58, [int? version]) {
    final key = HDKey.decode(b58, pubVersion: version);
    if (key is HDPublicKey) return key;
    throw InvalidHDKey();
  }

}
