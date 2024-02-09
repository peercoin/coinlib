import 'dart:convert';
import 'dart:typed_data';
import 'package:coinlib/src/address.dart';
import 'package:coinlib/src/common/bytes.dart';
import 'package:coinlib/src/common/serial.dart';
import 'ec_private_key.dart';
import 'hash.dart';
import 'ec_public_key.dart';
import 'ecdsa_recoverable_signature.dart';

class MagicHash with Writable {

  final String message;
  final String prefix;
  MagicHash(this.message, this.prefix);

  static void _writeUtf8(Writer writer, String msg)
    => writer.writeVarSlice(utf8.encode(msg));

  @override
  void write(Writer writer) {
    _writeUtf8(writer, prefix);
    _writeUtf8(writer, message);
  }

  Uint8List get hash => sha256DoubleHash(toBytes());

}

/// Encapsulates a signature for messages that are encoded to base-64. The
/// base-64 representation can be obtained via [toString()].
class MessageSignature {

  final ECDSARecoverableSignature signature;

  static Uint8List magicHash(String message, String prefix)
    => MagicHash(message, prefix).hash;

  MessageSignature.fromBase64(String str)
    : signature = ECDSARecoverableSignature.fromCompact(base64.decode(str));

  MessageSignature.sign({
    required ECPrivateKey key,
    required String message,
    required String prefix,
  }) : signature = ECDSARecoverableSignature.sign(
    key, magicHash(message, prefix),
  );

  ECPublicKey? recover(String message, String prefix)
    => signature.recover(magicHash(message, prefix));

  bool verifyPublicKey({
    required ECPublicKey pubkey,
    required String message,
    required String prefix,
  }) => recover(message, prefix) == pubkey;

  bool verifyAddress({
    required Address address,
    required String message,
    required String prefix,
  }) {

    late Uint8List pkHash;
    if (address is P2PKHAddress) {
      pkHash = address.hash;
    } else if (address is P2WPKHAddress) {
      pkHash = address.data;
    } else {
      return false;
    }

    final pk = recover(message, prefix);
    return pk != null && bytesEqual(hash160(pk.data), pkHash);

  }

  @override
  String toString() => base64.encode(signature.compact);

}
