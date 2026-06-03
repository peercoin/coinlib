import 'dart:typed_data';
import 'package:coinlib/coinlib.dart';
import 'package:test/test.dart';

final prevOutHash = Uint8List(32);
final prevOutN = 0xfeedbeef;
final prevOut = OutPoint(prevOutHash, prevOutN);

final rawWitnessInputBytes = Uint8List.fromList([
  ...prevOutHash,
  0xef, 0xbe, 0xed, 0xfe,
  0,
  0xfe, 0xff, 0xff, 0xff,
]);
final rawWitnessInput = RawInput.fromReader(BytesReader(rawWitnessInputBytes));

void expectInput(
  Input input, [
    InputSequence sequence = InputSequence.enforceLocktime,
  ]
) {
  expect(input.prevOut.hash, prevOutHash);
  expect(input.prevOut.n, prevOutN);
  expect(input.sequence, sequence);
}
