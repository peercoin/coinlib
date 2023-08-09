import 'dart:typed_data';
import 'package:coinlib/src/common/hex.dart';

class Base58Vector {
  final Uint8List data;
  final String encoded;
  Base58Vector({ required String hex, required this.encoded })
    : data = hexToBytes(hex);
}

final base58ValidVectors = [
  // Null bitcoin address
  Base58Vector(
    hex: "000000000000000000000000000000000000000000",
    encoded: "1111111111111111111114oLvT2",
  ),
  Base58Vector(
    hex: "ffffffffffffffffffffffffffffffffffffffffff",
    encoded: "2n1XR4oJkmBdJMxhBGQGb96gQ88xUyGML1i",
  ),
  Base58Vector(
    hex: "",
    encoded: "3QJmnh",
  ),
  // zero private key WIF with compression
  Base58Vector(
    hex: "80000000000000000000000000000000000000000000000000000000000000000001",
    encoded: "KwDiBf89QgGbjEhKnhXJuH7LrciVrZi3qYjgd9M7rFU73Nd2Mcv1",
  ),
];

final base58InvalidVectors = [
  // Has invalid 0 character
  "11111111111111111111140LvT2",
  // No whitespace allowed
  " 2n1XR4oJkmBdJMxhBGQGb96gQ88xUyGML1i",
  "2n1XR4oJkmBdJMxhB GQGb96gQ88xUyGML1i",
  "2n1XR4oJkmBdJMxhBGQGb96gQ88xUyGML1i ",
  "3QJm",
  "",
  "x",
];

final base58InvalidChecksumVectors = [
  "1111111111111111111114oLvT1",
  "1111111111111111111114oLvT",
  "1111111111111111111113oLvT2",
  "3QJmn",
];

