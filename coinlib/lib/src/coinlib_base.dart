import 'package:coinlib/src/bindings/secp256k1.dart';
export 'package:coinlib/src/crypto/ec_private_key.dart';
export 'package:coinlib/src/crypto/ec_public_key.dart';
export 'package:coinlib/src/crypto/random.dart';
export 'package:coinlib/src/encode/base58.dart';

Future<void> loadCoinlib() => secp256k1.load();
