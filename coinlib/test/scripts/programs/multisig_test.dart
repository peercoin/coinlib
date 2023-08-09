import 'package:coinlib/coinlib.dart';
import 'package:test/test.dart';
import '../../vectors/keys.dart';

class MultisigVector {
  final String asm;
  final String? hex;
  final List<String>? pubkeys;
  final int? threshold;
  MultisigVector({ required this.asm, this.hex, this.pubkeys, this.threshold });
}

final correctVectors = [
  // 1-of-1 pointless but valid
  MultisigVector(
    asm: "01 $pubkeyVec 01 OP_CHECKMULTISIG",
    hex: "5121${pubkeyVec}51ae",
    pubkeys: [pubkeyVec],
    threshold: 1,
  ),
  // 1-of-2
  MultisigVector(
    asm: "01 $pubkeyVec $longPubkeyVec 02 OP_CHECKMULTISIG",
    hex: "5121${pubkeyVec}41${longPubkeyVec}52ae",
    pubkeys: [pubkeyVec, longPubkeyVec],
    threshold: 1,
  ),
  // 2-of-2
  MultisigVector(
    asm: "02 $pubkeyVec $longPubkeyVec 02 OP_CHECKMULTISIG",
    hex: "5221${pubkeyVec}41${longPubkeyVec}52ae",
    pubkeys: [pubkeyVec, longPubkeyVec],
    threshold: 2,
  ),
  // 20-of-20
  MultisigVector(
    asm: "14 ${List.filled(20, pubkeyVec).join(" ")} 14 OP_CHECKMULTISIG",
    hex: "0114${List.filled(20, "21$pubkeyVec").join("")}0114ae",
    pubkeys: List.filled(20, pubkeyVec),
    threshold: 20,
  ),
];

final invalidVectors = [
  // 0-of-1
  MultisigVector(asm: "0 $pubkeyVec 01 OP_CHECKMULTISIG"),
  // 2-of-1
  MultisigVector(asm: "02 $pubkeyVec 01 OP_CHECKMULTISIG"),
  // -1 threshold
  MultisigVector(asm: "-1 $pubkeyVec 01 OP_CHECKMULTISIG"),
  // 21 pks
  MultisigVector(
    asm: "14 ${List.filled(21, pubkeyVec).join(" ")} 15 OP_CHECKMULTISIG",
  ),
  // Public key length more than specified
  MultisigVector(asm: "01 $pubkeyVec $pubkeyVec 01 OP_CHECKMULTISIG"),
  // Public key length less than specified
  MultisigVector(asm: "01 $pubkeyVec 02 OP_CHECKMULTISIG"),
  // Extra data at begining
  MultisigVector(asm: "00 01 $pubkeyVec 01 OP_CHECKMULTISIG"),
  // Extra data at end
  MultisigVector(asm: "01 $pubkeyVec 01 OP_CHECKMULTISIG 00"),
  // Not numerical
  MultisigVector(asm: "OP_DUP $pubkeyVec 01 OP_CHECKMULTISIG"),
  MultisigVector(asm: "01 $pubkeyVec OP_DUP OP_CHECKMULTISIG"),
  // Wrong public key length
  MultisigVector(
    asm:
      "01 0279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f817"
      " 01 OP_CHECKMULTISIG",
  ),
  // Not push data for public key
  MultisigVector(asm: "01 01 01 OP_CHECKMULTISIG"),
  // Invalid public key data
  MultisigVector(asm: "01 ${invalidPubKeys[0]} 01 OP_CHECKMULTISIG"),
];

void main() {

  group("MultisigProgram", () {

    setUpAll(loadCoinlib);

    expectMultisig(MultisigVector vec, MultisigProgram multisig) {
      expect(multisig.pubkeys.map((pk) => pk.hex), vec.pubkeys);
      expect(multisig.threshold, vec.threshold);
      expect(bytesToHex(multisig.script.compiled), vec.hex);
    }

    test("correct vectors", () {

      for (final vec in correctVectors) {
        expectMultisig(vec, MultisigProgram.fromAsm(vec.asm));
        expectMultisig(vec, MultisigProgram.decompile(hexToBytes(vec.hex!)));
        expectMultisig(
          vec,
          MultisigProgram(
            vec.threshold!,
            vec.pubkeys!.map((s) => ECPublicKey.fromHex(s)),
          ),
        );
        final program = Program.fromAsm(vec.asm);
        expect(program, isA<MultisigProgram>());
        expectMultisig(vec, program as MultisigProgram);
      }

    });

    test("invalid vectors", () {
      for (final vec in invalidVectors) {
        expect(
          () => MultisigProgram.fromAsm(vec.asm),
          throwsA(isA<NoProgramMatch>()),
          reason: vec.asm,
        );
        expect(Program.fromAsm(vec.asm), isA<RawProgram>());
      }
    });

    test("push data not minimal", () {
      final compiled = hexToBytes("010121${pubkeyVec}51ae");
      expect(
        () => MultisigProgram.decompile(compiled),
        throwsA(isA<PushDataNotMinimal>()),
      );
      expect(
        () => Program.decompile(compiled),
        throwsA(isA<PushDataNotMinimal>()),
      );
      expectMultisig(
        correctVectors[0],
        Program.decompile(compiled, requireMinimal: false) as MultisigProgram,
      );
    });

    test("invalid arguments", () {

      final pk = ECPublicKey.fromHex(pubkeyVec);
      expect(() => MultisigProgram(1, []), throwsArgumentError);
      expect(
        () => MultisigProgram(1, List.filled(21, pk)), throwsArgumentError,
      );
      expect(() => MultisigProgram(0, [pk]), throwsArgumentError);
      expect(() => MultisigProgram(-1, [pk]), throwsArgumentError);
      expect(() => MultisigProgram(2, [pk]), throwsArgumentError);
      expect(
        () => MultisigProgram(21, List.filled(20, pk)),
        throwsArgumentError,
      );

    });

    test(".pubkeys cannot be mutated", () {
      final multisig = MultisigProgram.fromAsm(correctVectors[0].asm);
      expect(
        () => multisig.pubkeys[0] = ECPublicKey.fromHex(longPubkeyVec),
        throwsA(anything),
      );
      expect(multisig.pubkeys[0], ECPublicKey.fromHex(pubkeyVec));
    });

  });

}
