import 'dart:math';
import 'dart:typed_data';

const int _sizeByte = 256;

/// Generates random bytes using a CSPRNG
/// Tested with the ent command
Uint8List generateRandomBytes(int size) {
  final rng = Random.secure();
  final bytes = Uint8List(size);
  for (var i = 0; i < size; i++) {
    bytes[i] = rng.nextInt(_sizeByte);
  }
  return bytes;
}

