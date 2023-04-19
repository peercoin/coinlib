import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;

Uint8List sha256Hash(Uint8List msg) => Uint8List.fromList(
  crypto.sha256.convert(msg).bytes,
);

Uint8List sha256DoubleHash(Uint8List msg) => sha256Hash(sha256Hash(msg));
