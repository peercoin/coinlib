import 'package:coinlib/coinlib.dart';
import 'package:test/test.dart';

void main() {

  group("SigHashType", () {

    test("valid values", () {

      void expectValid(
        int value,
        SigHashType obj,
        OutputSigHashOption outputs,
        InputSigHashOption inputs,
        String string,
        {
          required bool schnorrDefault,
          required bool supportsLegacy,
          required bool requiresApo,
        }
      ) {

        expect(SigHashType.validValue(value), true);
        final fromValue = SigHashType.fromValue(value);

        expect(obj, fromValue);

        for (final o in [obj, fromValue]) {
          expect(o.outputs, outputs);
          expect(o.inputs, inputs);
          expect(o.value, value);
          expect(o.schnorrDefault, schnorrDefault);
        }

      }

      void expectValidOpts(
        int value, OutputSigHashOption outputs, InputSigHashOption inputs,
        String string,
        {
          required bool supportsLegacy,
          required bool requiresApo,
        }
      ) => expectValid(
        value,
        SigHashType(outputs: outputs, inputs: inputs),
        outputs,
        inputs,
        string,
        schnorrDefault: false,
        supportsLegacy: supportsLegacy,
        requiresApo: requiresApo,
      );

      expectValid(
        0, SigHashType.schnorrDefault(),
        OutputSigHashOption.all,
        InputSigHashOption.all,
        "DEFAULT",
        schnorrDefault: true,
        supportsLegacy: false,
        requiresApo: false,
      );

      expectValid(
        1, SigHashType.all(),
        OutputSigHashOption.all,
        InputSigHashOption.all,
        "ALL",
        schnorrDefault: false,
        supportsLegacy: true,
        requiresApo: false,
      );

      expectValid(
        2, SigHashType.none(),
        OutputSigHashOption.none,
        InputSigHashOption.all,
        "NONE",
        schnorrDefault: false,
        supportsLegacy: true,
        requiresApo: false,
      );

      expectValid(
        0x43, SigHashType.single(inputs: InputSigHashOption.anyPrevOut),
        OutputSigHashOption.single,
        InputSigHashOption.anyPrevOut,
        "SINGLE|ANYPREVOUT",
        schnorrDefault: false,
        supportsLegacy: false,
        requiresApo: true,
      );

      expectValidOpts(
        1, OutputSigHashOption.all, InputSigHashOption.all,
        "ALL",
        supportsLegacy: true,
        requiresApo: false,
      );
      expectValidOpts(
        2, OutputSigHashOption.none, InputSigHashOption.all,
        "NONE",
        supportsLegacy: true,
        requiresApo: false,
      );
      expectValidOpts(
        3, OutputSigHashOption.single, InputSigHashOption.all,
        "SINGLE",
        supportsLegacy: true,
        requiresApo: false,
      );

      expectValidOpts(
        0x81, OutputSigHashOption.all, InputSigHashOption.anyOneCanPay,
        "ALL|ANYONECANPAY",
        supportsLegacy: true,
        requiresApo: false,
      );
      expectValidOpts(
        0x82, OutputSigHashOption.none, InputSigHashOption.anyOneCanPay,
        "NONE|ANYONECANPAY",
        supportsLegacy: true,
        requiresApo: false,
      );
      expectValidOpts(
        0x83, OutputSigHashOption.single, InputSigHashOption.anyOneCanPay,
        "SINGLE|ANYONECANPAY",
        supportsLegacy: true,
        requiresApo: false,
      );

      expectValidOpts(
        0x41, OutputSigHashOption.all, InputSigHashOption.anyPrevOut,
        "ALL|ANYPREVOUT",
        supportsLegacy: false,
        requiresApo: true,
      );
      expectValidOpts(
        0x42, OutputSigHashOption.none, InputSigHashOption.anyPrevOut,
        "NONE|ANYPREVOUT",
        supportsLegacy: false,
        requiresApo: true,
      );
      expectValidOpts(
        0x43, OutputSigHashOption.single, InputSigHashOption.anyPrevOut,
        "SINGLE|ANYPREVOUT",
        supportsLegacy: false,
        requiresApo: true,
      );

      expectValidOpts(
        0xc1, OutputSigHashOption.all, InputSigHashOption.anyPrevOutAnyScript,
        "ALL|ANYPREVOUTANYSCRIPT",
        supportsLegacy: false,
        requiresApo: true,
      );
      expectValidOpts(
        0xc2, OutputSigHashOption.none,
        InputSigHashOption.anyPrevOutAnyScript,
        "NONE|ANYPREVOUTANYSCRIPT",
        supportsLegacy: false,
        requiresApo: true,
      );
      expectValidOpts(
        0xc3, OutputSigHashOption.single,
        InputSigHashOption.anyPrevOutAnyScript,
        "SINGLE|ANYPREVOUTANYSCRIPT",
        supportsLegacy: false,
        requiresApo: true,
      );

    });

    test("invalid values", () {
      for (final invalid in [-1, 4, 0x80, 0x84, 0x11, 0x181]) {
        expect(SigHashType.validValue(invalid), false);
        expect(() => SigHashType.checkValue(invalid), throwsArgumentError);
        expect(() => SigHashType.fromValue(invalid), throwsArgumentError);
      }
    });

  });

}
