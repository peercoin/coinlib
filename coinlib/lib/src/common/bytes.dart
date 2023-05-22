import 'dart:typed_data';
import 'package:collection/collection.dart';

/// Throws an [ArgumentError] if the [bytes] are not of the required [length]
/// and returns the [bytes].
Uint8List checkBytes(Uint8List bytes, int length) {
  if (bytes.length != length) {
    throw ArgumentError("Bytes should have length of $length", "bytes");
  }
  return bytes;
}

/// Throws an [ArgumentError] if the [bytes] are not of the required [length]
/// and returns a copy of the [bytes].
Uint8List copyCheckBytes(Uint8List bytes, int length) => Uint8List.fromList(
  checkBytes(bytes, length),
);

/// Determines if two objects are equal lists
bool bytesEqual(Object? a, Object? b)
  => (a is Uint8List) && (b is Uint8List) && ListEquality().equals(a, b);
