import 'dart:typed_data';
import 'package:coinlib/src/common/hex.dart';
import 'package:coinlib/src/crypto/ec_public_key.dart';
import 'package:coinlib/src/crypto/hash.dart';
import 'package:coinlib/src/network_params.dart';
import 'package:coinlib/src/encode/base58.dart';
import 'package:coinlib/src/encode/bech32.dart';

class InvalidAddress implements Exception {}
class InvalidAddressNetwork implements Exception {}

/// Base class for all addresses. Encoded addresses for sub-classes are provided
/// via the [toString()] method.
abstract class Address {

  /// Decodes an address string ([encoded]) and returns the sub-class object for
  /// the type of address. Throws [InvalidAddress], [InvalidAddressNetwork],
  /// [InvalidBech32Checksum] or [InvalidBase58Checksum] if there is an error
  /// with the address. The address must match the [network] provided.
  factory Address.fromString(String encoded, NetworkParams network) {
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

}

/// Base class for all addresses that use base58: [P2PKHAddress] and
/// [P2SHAddress].
abstract class Base58Address implements Address {

  /// The 160bit public key or redeemScript hash for the base58 address
  final Hash160 hash;
  /// The network and address type version of the address
  final int version;
  String? _encodedCache;

  Base58Address._(this.hash, this.version) {
    if (version < 0 || version > 255) {
      throw ArgumentError("base58 version must be within 0-255", "this.version");
    }
  }

  factory Base58Address.fromString(String encoded, NetworkParams network) {

    final data = base58Decode(encoded);
    if (data.length != 21) throw InvalidAddress();

    final version = data.first;
    final payload = data.sublist(1);

    late Base58Address addr;
    if (version == network.p2pkhPrefix) {
      addr = P2PKHAddress.fromHash(Hash160.fromHashBytes(payload), version: version);
    } else if (version == network.p2shPrefix) {
      addr = P2SHAddress.fromHash(Hash160.fromHashBytes(payload), version: version);
    } else {
      throw InvalidAddressNetwork();
    }

    addr._encodedCache = encoded;
    return addr;

  }

  @override
  toString() => _encodedCache ??= base58Encode(
    Uint8List.fromList([version, ...hash.bytes]),
  );

}

class P2PKHAddress extends Base58Address {

  /// Takes a [hash] directly for a P2PKH address
  P2PKHAddress.fromHash(Hash160 hash, { required int version })
    : super._(hash, version);

  /// Constructs a P2PKH address from a given [pubkey].
  P2PKHAddress.fromPublicKey(ECPublicKey pubkey, { required int version })
    : this.fromHash(hash160(pubkey.data), version: version);

}

class P2SHAddress extends Base58Address {
  /// Constructs a P2SH address from the redeemScript [hash].
  P2SHAddress.fromHash(Hash160 hash, { required int version })
    : super._(hash, version);
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
  /// The witness program encoded in the address
  final Uint8List program;
  String? _encodedCache;

  Bech32Address._(this.version, this.program, this.hrp) {

    if (version < 0 || version > 16) {
      throw ArgumentError("bech32 version must be 0-16", "this.version");
    }
    if (program.length < 2 || program.length > maxWitnessProgramLength) {
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
      = (program.length*8+4)/5
      // Seperator and version
      + 2
      + hrp.length
      + Bech32.checksumLength;

    if (encodedLength > Bech32.maxLength) {
      throw ArgumentError("Bech32Address arguments exceed allowable size");
    }

  }

  factory Bech32Address.fromString(String encoded, NetworkParams network) {

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

    final program = convertBits(bech32.words.sublist(1), 5, 8, false);
    if (program == null) throw InvalidAddress();

    final bytes = Uint8List.fromList(program);

    late Bech32Address addr;

    if (version == 0) {
      // Version 0 signals P2WPKH or P2WSH
      if (program.length == 20) {
        addr = P2WPKHAddress.fromHash(
          Hash160.fromHashBytes(bytes), hrp: bech32.hrp,
        );
      } else if (program.length == 32) {
        addr = P2WSHAddress.fromHash(
          Hash256.fromHashBytes(bytes), hrp: bech32.hrp,
        );
      } else {
        throw InvalidAddress();
      }
    } else if (version <= 16) {
      // Treat other versions as unknown. Will add version 1 taproot later
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
      version, ...convertBits(program, 8, 5, true)!,
    ]),
    type: version == 0 ? Bech32Type.bech32 : Bech32Type.bech32m,
  ).encode();

}

class P2WPKHAddress extends Bech32Address {

  /// Constructs a P2WPKH address directly from the [hash]
  P2WPKHAddress.fromHash(Hash160 hash, { required String hrp })
    : super._(0, hash.bytes, hrp);

  /// Constructs a P2WPKH address from a [pubkey]
  P2WPKHAddress.fromPublicKey(ECPublicKey pubkey, { required String hrp })
    : this.fromHash(hash160(pubkey.data), hrp: hrp);

  /// Obtains the 160bit hash of the public key
  Hash160 get hash => Hash160.fromHashBytes(program);

}

class P2WSHAddress extends Bech32Address {

  /// Constructs a P2WSH address from the script [hash]
  P2WSHAddress.fromHash(Hash256 hash, { required String hrp })
    : super._(0, hash.bytes, hrp);

  /// Obtains the hash for the script
  Hash256 get hash => Hash256.fromHashBytes(program);

}

/// This address type is for all bech32 addresses that do not match known
/// witness versions. Currently this includes taproot until it is fully
/// specified.
class UnknownWitnessAddress extends Bech32Address {

  /// Constructs a bech32 witness address from the [program], witness [version]
  /// and [hrp]
  UnknownWitnessAddress(
    Uint8List program, { required int version, required String hrp, }
  ) : super._(version, program, hrp);

  /// Constructs a bech32 witness address with the program provided as a [hex]
  /// string.
  UnknownWitnessAddress.fromHex(
    String hex, { required int version, required String hrp, }
  ) : super._(version, hexToBytes(hex), hrp);

}
