import 'package:coinlib/coinlib.dart';
import 'package:test/test.dart';

void main() {
  group("Program", () {
    test("Returns a RawProgram when notings matches", () {
      final raw = Program.fromAsm("0 OP_DUP");
      expect(raw, isA<RawProgram>());
      expect(raw.script.asm, "0 OP_DUP");
    });
  });
}
