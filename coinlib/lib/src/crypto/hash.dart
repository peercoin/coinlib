import 'dart:typed_data';

import 'package:crypto/crypto.dart';

Uint8List sha256d(Uint8List msg) {
  return Uint8List.fromList(sha256.convert(sha256.convert(msg).bytes).bytes);
}
