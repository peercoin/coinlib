import 'dart:typed_data';

import 'package:coinlib/coinlib.dart';
import 'package:test/test.dart';

void main() {

  sizeTest<T>(int n, T Function(Uint8List) f) => test("must be $n bytes", () {
    for (final b in [Uint8List(n-1), Uint8List(n+1)]) {
      expect(() => f(b), throwsA(isA<ArgumentError>()));
    }
    expect(f(Uint8List(n)), isA<T>());
  });

  group("Bytes32", () => sizeTest(32, (b) => Bytes32.fromList(b)));
  group("Bytes20", () => sizeTest(20, (b) => Bytes20.fromList(b)));

}
