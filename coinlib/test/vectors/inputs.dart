import 'dart:typed_data';
import 'package:coinlib/coinlib.dart';
import 'package:test/test.dart';

final prevOutHash = Uint8List(32);
final prevOutN = 0xfeedbeef;
final prevOut = OutPoint(prevOutHash, prevOutN);
final sequence = 0xbeeffeed;

expectInput(Input input) {
  expect(input.prevOut.hash, prevOutHash);
  expect(input.prevOut.n, prevOutN);
  expect(input.sequence, sequence);
}
