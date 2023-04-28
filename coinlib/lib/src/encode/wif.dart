import 'dart:typed_data';
import 'package:coinlib/src/crypto/ec_private_key.dart';
import 'package:coinlib/src/encode/base58.dart';

class WifVersionMismatch implements Exception {}
class InvalidWif implements Exception {}

/// Encapsulates a [ECPrivateKey] and version that can be encoded or decoded in
/// the Wallet Import Format (WIF). [toString] can be used to obtain the encoded
/// WIF string.
class WIF {

  final ECPrivateKey privkey;
  final int version;

  String? _wifCache;

  WIF({ required this.privkey, required this.version });

  /// Decodes a [wif] string into the private key and version.
  /// [WifVersionMismatch] is thrown if the specified [version] does not match
  /// the WIF. [InvalidWif] is thrown if the base58 is valid but the data
  /// doesn't meet the correct format. If no [version] is specified, any version
  /// will be accepted. May throw [InvalidBase58] or [InvalidBase58Checksum]
  /// when decoding the WIF.
  factory WIF.fromString(String wif, { int? version }) {

    final data = base58Decode(wif);

    // Determine if the data meets the compressed or uncompressed formats
    final compressed = data.length == 34;
    if (!compressed && data.length != 33) throw InvalidWif();
    if (compressed && data.last != 1) throw InvalidWif();

    final decodedVersion = data.first;
    if (version != null && version != decodedVersion) {
      throw WifVersionMismatch();
    }

    final wifObj = WIF(
      privkey: ECPrivateKey(data.sublist(1, 33), compressed: compressed),
      version: decodedVersion,
    );
    wifObj._wifCache = wif;
    return wifObj;

  }

  /// Provides the base-58 encoded WIF string
  @override
  toString() => _wifCache ??= base58Encode(
    Uint8List.fromList([
      version, ...privkey.data, ...(privkey.compressed ? [1] : []),
    ]),
  );

}
