import 'dart:typed_data';
import 'package:coinlib/coinlib.dart';
import 'package:test/test.dart';
import '../../vectors/inputs.dart';
import '../../vectors/taproot.dart';

// Placed in global for lazy initialisation after loadCoinlib
final taprootVec = taprootVectors[3];
final leaf = taprootVec.object.leaves[0];
final script = leaf.script;
final controlBlock = taprootVec.object.controlBlockForLeaf(leaf);
final witness = [script.compiled, controlBlock];
final stack = [hexToBytes("0102030405"), hexToBytes("01020304")];

void main() {

  group("TaprootScriptInput", () {

    setUpAll(loadCoinlib);

    test("valid script-path taproot inputs", () {

      expectTaprootScriptInput(TaprootScriptInput input, bool withStack) {

        expectInput(input);

        expect(input.complete, true);
        expect(input.scriptSig.isEmpty, true);
        expect(input.script!.length, 0);

        expect(input.tapscript.asm, script.asm);
        expect(input.controlBlock, controlBlock);

        expect(input.witness, [if (withStack) ...stack, ...witness]);
        expect(input.size, rawWitnessInputBytes.length);
        expect(input.toBytes(), rawWitnessInputBytes);

      }

      for (final withStack in [false, true]) {
        expectTaprootScriptInput(
          TaprootScriptInput(
            prevOut: prevOut,
            controlBlock: controlBlock,
            tapscript: script,
            sequence: sequence,
            stack: withStack ? stack : null,
          ),
          withStack,
        );
        expectTaprootScriptInput(
          TaprootScriptInput.fromTaprootLeaf(
            prevOut: prevOut,
            taproot: taprootVec.object,
            leaf: leaf,
            sequence: sequence,
            stack: withStack ? stack : null,
          ),
          withStack,
        );
        expectTaprootScriptInput(
          Input.match(
            rawWitnessInput,
            [if (withStack) ...stack, ...witness],
          ) as TaprootScriptInput,
          withStack,
        );
      }

    });

    test("control blocks up-to 128 hashes accepted", () {
      expect(
        TaprootScriptInput(
          prevOut: prevOut,
          controlBlock: Uint8List.fromList(
            [...controlBlock, ...Uint8List(32*128)],
          ),
          tapscript: script,
        ),
        isA<TaprootScriptInput>(),
      );
    });

    test("doesn't match non script-spend inputs", () {

      expectNoMatch(String asm, List<Uint8List> witness) => expect(
        TaprootScriptInput.match(
          RawInput(
            prevOut: prevOut,
            scriptSig: Script.fromAsm(asm).compiled,
            sequence: 0,
          ),
          witness,
        ),
        null,
      );

      expectNoMatch("0", witness);
      // Requires script
      expectNoMatch("", witness.skip(1).toList());
      // Not allowing annex
      expectNoMatch("", [...witness, hexToBytes("5001020304")]);
      // Control block must be correct size
      expectNoMatch("", [script.compiled, hexToBytes("c1")]);
      expectNoMatch("", [script.compiled, Uint8List(0)]);
      expectNoMatch(
        "",
        [
          script.compiled,
          controlBlock.sublist(0, controlBlock.length-1),
        ],
      );
      expectNoMatch(
        "",
        [
          script.compiled,
          Uint8List.fromList([...controlBlock.take(33), ...Uint8List(32*129)]),
        ],
      );
      // Control block must have valid tapscript version.
      expectNoMatch(
        "",
        [
          script.compiled,
          Uint8List.fromList([0xc2, ...controlBlock.sublist(1)]),
        ],
      );
      // Script must be valid and minimal
      expectNoMatch("", [hexToBytes("0201"), controlBlock]);
      expectNoMatch("", [hexToBytes("0101"), controlBlock]);
    });

  });

}
