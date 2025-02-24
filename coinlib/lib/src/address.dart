import 'dart:typed_data';
import 'package:coinlib/src/common/bytes.dart';
import 'package:coinlib/src/common/hex.dart';
import 'package:coinlib/src/crypto/ec_public_key.dart';
import 'package:coinlib/src/crypto/hash.dart';
import 'package:coinlib/src/network.dart';
import 'package:coinlib/src/encode/base58.dart';
import 'package:coinlib/src/encode/bech32.dart';
import 'package:coinlib/src/scripts/program.dart';
import 'package:coinlib/src/scripts/programs/p2pkh.dart';
import 'package:coinlib/src/scripts/programs/p2sh.dart';
import 'package:coinlib/src/scripts/programs/p2tr.dart';
import 'package:coinlib/src/scripts/programs/p2witness.dart';
import 'package:coinlib/src/scripts/programs/p2wpkh.dart';
import 'package:coinlib/src/scripts/programs/p2wsh.dart';
import 'package:coinlib/src/scripts/script.dart';
import 'package:coinlib/src/taproot/taproot.dart';

class InvalidAddress implements Exception {}
class InvalidAddressNetwork implements Exception {}

/// Base class for all addresses. Encoded addresses for sub-classes are provided
/// via the [toString()] method.
abstract class Address {

  /// Decodes an address string ([encoded]) and returns the sub-class object for
  /// the type of address. Throws [InvalidAddress], [InvalidAddressNetwork],
  /// [InvalidBech32Checksum] or [InvalidBase58Checksum] if there is an error
  /// with the address. The address must match the [network] provided.
  factory Address.fromString(String encoded, Network network) {
    // Try base58
    try {
      return Base58Address.fromString(encoded, network);
    } on Exception catch(e) {
      // If not base58, then try bech32
      try {
        return Bech32Address.fromString(encoded, network);
      } on InvalidBech32 {
        // Not valid bech32
        // If it is not a valid base58 string either, throw InvalidAddress.
        // Otherwise rethrow error from base58 which could have been due to the
        // wrong network or checksum
        if (e is InvalidBase58) {
          throw InvalidAddress();
        }
        throw e;
      }
    }
  }

  Program get program;

}

/// Base class for all addresses that use base58: [P2PKHAddress] and
/// [P2SHAddress].
abstract class Base58Address implements Address {

  /// The 160bit public key or redeemScript hash for the base58 address
  final Uint8List _hash;
  /// The network and address type version of the address
  final int version;
  String? _encodedCache;

  Base58Address._(Uint8List hash, this.version) : _hash = hash {
    if (version < 0 || version > 255) {
      throw ArgumentError("base58 version must be within 0-255", "this.version");
    }
  }

  factory Base58Address.fromString(String encoded, Network network) {

    final data = base58Decode(encoded);
    if (data.length != 21) throw InvalidAddress();

    final version = data.first;
    final payload = data.sublist(1);

    late Base58Address addr;
    if (version == network.p2pkhPrefix) {
      addr = P2PKHAddress.fromHash(payload, version: version);
    } else if (version == network.p2shPrefix) {
      addr = P2SHAddress.fromHash(payload, version: version);
    } else {
      throw InvalidAddressNetwork();
    }

    addr._encodedCache = encoded;
    return addr;

  }

  @override
  toString() => _encodedCache ??= base58Encode(
    Uint8List.fromList([version, ..._hash]),
  );

  Uint8List get hash => Uint8List.fromList(_hash);

}

class P2PKHAddress extends Base58Address {

  /// Takes a [hash] directly for a P2PKH address
  P2PKHAddress.fromHash(Uint8List hash, { required int version })
    : super._(copyCheckBytes(hash, 20), version);

  /// Constructs a P2PKH address from a given [pubkey].
  P2PKHAddress.fromPublicKey(ECPublicKey pubkey, { required int version })
    : this.fromHash(hash160(pubkey.data), version: version);

  @override
  P2PKH get program => P2PKH.fromHash(hash);

}

class P2SHAddress extends Base58Address {

  /// Constructs a P2SH address from the redeemScript [hash].
  P2SHAddress.fromHash(Uint8List hash, { required int version })
    : super._(copyCheckBytes(hash, 20), version);

  /// Constructs a P2SH address for a redeemScript
  P2SHAddress.fromRedeemScript(Script script, { required int version })
    : super._(hash160(script.compiled), version);

  @override
  P2SH get program => P2SH.fromHash(hash);

}

/// Base class for addresses that use bech32: [P2WPKHAddress] and
/// [P2WSHAddress]. Unknown witness programs are encoded via
/// [UnknownWitnessAddress].
abstract class Bech32Address implements Address {

  static const maxWitnessProgramLength = 40;

  /// The human readable part of the address used to specify the network
  final String hrp;
  /// The program version of the address
  final int version;
  final Uint8List _data;
  String? _encodedCache;

  Bech32Address._(this.version, this._data, this.hrp) {

    if (version < 0 || version > 16) {
      throw ArgumentError("bech32 version must be 0-16", "this.version");
    }
    if (_data.length < 2 || _data.length > maxWitnessProgramLength) {
      throw ArgumentError(
        "witness programs must be 2-$maxWitnessProgramLength in length",
        "this.program",
      );
    }
    if (!hrpValid(hrp)) {
      throw ArgumentError("Invalid hrp: $hrp", "this.hrp");
    }

    final encodedLength
      // Encoded program length
      = (_data.length*8+4)/5
      // Seperator and version
      + 2
      + hrp.length
      + Bech32.checksumLength;

    if (encodedLength > Bech32.maxLength) {
      throw ArgumentError("Bech32Address arguments exceed allowable size");
    }

  }

  factory Bech32Address.fromString(String encoded, Network network) {

    final bech32 = Bech32.decode(encoded);

    if (bech32.words.isEmpty) throw InvalidAddress();
    if (bech32.hrp != network.bech32Hrp) throw InvalidAddressNetwork();

    final version = bech32.words[0];

    // Must use bech32m starting with version 1
    if (
      (version == 0 && bech32.type != Bech32Type.bech32)
      || (version != 0 && bech32.type != Bech32Type.bech32m)
    ) {
      throw InvalidAddress();
    }

    final data = convertBits(bech32.words.sublist(1), 5, 8, false);
    if (data == null) throw InvalidAddress();

    final bytes = Uint8List.fromList(data);

    late Bech32Address addr;

    if (version == 0) {
      // Version 0 signals P2WPKH or P2WSH
      if (bytes.length == 20) {
        addr = P2WPKHAddress.fromHash(bytes, hrp: bech32.hrp);
      } else if (bytes.length == 32) {
        addr = P2WSHAddress.fromHash(bytes, hrp: bech32.hrp);
      } else {
        throw InvalidAddress();
      }
    } else if (version == 1) {
      // Version 1 is Taproot
      if (bytes.length == 32) {
        addr = P2TRAddress.fromTweakedKeyX(bytes, hrp: bech32.hrp);
      } else {
        throw InvalidAddress();
      }
    } else if (version <= 16) {
      // Treat other versions as unknown.
      if (bytes.length < 2 || bytes.length > maxWitnessProgramLength) {
        throw InvalidAddress();
      }
      addr = UnknownWitnessAddress(bytes, hrp: bech32.hrp, version: version);
    } else {
      throw InvalidAddress();
    }

    addr._encodedCache = encoded;
    return addr;

  }

  @override
  toString() => _encodedCache ??= Bech32(
    hrp: hrp,
    words: List<int>.from([
      version, ...convertBits(_data, 8, 5, true)!,
    ]),
    type: version == 0 ? Bech32Type.bech32 : Bech32Type.bech32m,
  ).encode();

  /// The "witness program" data encoded in the address
  Uint8List get data => Uint8List.fromList(_data);

}

class P2WPKHAddress extends Bech32Address {

  /// Constructs a P2WPKH address directly from the [hash]
  P2WPKHAddress.fromHash(Uint8List hash, { required String hrp })
    : super._(0, copyCheckBytes(hash, 20), hrp);

  /// Constructs a P2WPKH address from a [pubkey]
  P2WPKHAddress.fromPublicKey(ECPublicKey pubkey, { required String hrp })
    : this.fromHash(hash160(pubkey.data), hrp: hrp);

  @override
  P2WPKH get program => P2WPKH.fromHash(_data);

}

class P2WSHAddress extends Bech32Address {

  /// Constructs a P2WSH address from the script [hash]
  P2WSHAddress.fromHash(Uint8List hash, { required String hrp })
    : super._(0, copyCheckBytes(hash, 32), hrp);

  /// Constructs a P2WSH address for a witnessScript
  P2WSHAddress.fromWitnessScript(Script script, { required String hrp })
    : super._(0, sha256Hash(script.compiled), hrp);

  @override
  P2WSH get program => P2WSH.fromHash(_data);

}

class P2TRAddress extends Bech32Address {

  P2TRAddress.fromTweakedKeyX(Uint8List tweakedKeyX, { required String hrp })
    : super._(1, copyCheckBytes(tweakedKeyX, 32), hrp);

  P2TRAddress.fromTweakedKey(ECPublicKey tweakedKey, { required String hrp })
    : super._(1, tweakedKey.x, hrp);

  P2TRAddress.fromTaproot(Taproot taproot, { required String hrp })
    : super._(1, taproot.tweakedKey.x, hrp);

  @override
  P2TR get program => P2TR.fromTweakedKeyX(_data);

}

/// This address type is for all bech32 addresses that do not match known
/// witness versions.
class UnknownWitnessAddress extends Bech32Address {

  /// Constructs a bech32 witness address from the "witness program" [data],
  /// witness [version] and [hrp]
  UnknownWitnessAddress(
    Uint8List data, { required int version, required String hrp, }
  ) : super._(version, data, hrp);

  /// Constructs a bech32 witness address with the "witness program" [data]
  /// provided as a [hex] string.
  UnknownWitnessAddress.fromHex(
    String hex, { required int version, required String hrp, }
  ) : super._(version, hexToBytes(hex), hrp);

  @override
  P2Witness get program => P2Witness.fromData(version, _data);

}
