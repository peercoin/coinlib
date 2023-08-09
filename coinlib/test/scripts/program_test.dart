import 'package:coinlib/coinlib.dart';
import 'package:test/test.dart';

void main() {
  group("Program", () {

    test("Returns a RawProgram when notings matches", () {
      final raw = Program.fromAsm("0 OP_DUP");
      expect(raw, isA<RawProgram>());
      expect(raw.script.asm, "0 OP_DUP");
    });

    test("decompile() requireMinimal", () {
      final compiled = hexToBytes("0101");
      expect(
        () => Program.decompile(compiled),
        throwsA(isA<PushDataNotMinimal>()),
      );
      final prog = Program.decompile(compiled, requireMinimal: false);
      expect(prog, isA<RawProgram>());
      expect(prog.script.length, 1);
      expect(prog.script.ops[0].number, 1);
      expect(prog.script.asm, "01");
    });

  });
}
