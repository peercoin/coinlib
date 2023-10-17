import 'dart:typed_data';
import 'package:coinlib/coinlib.dart';
import 'package:test/test.dart';
import '../../vectors/inputs.dart';
import '../../vectors/keys.dart';
import '../../vectors/signatures.dart';

void main() {

  group("P2SHMultisigInput", () {

    late List<ECPublicKey> pks;
    late List<ECDSAInputSignature> insigs;
    late MultisigProgram multisig;

    setUpAll(() async {

      await loadCoinlib();

      pks = validPubKeys
        .getRange(0, 4)
        .map((vec) => ECPublicKey.fromHex(vec.hex))
        .toList();

      insigs = validDerSigs
        .getRange(0, 4)
        .map((der) => ECDSAInputSignature(ECDSASignature.fromDerHex(der)))
        .toList();

      multisig = MultisigProgram(3, pks);

    });

    scriptForNumSigs(int numSigs) => Script([
      ScriptOp.fromNumber(0),
      ...insigs.sublist(0, numSigs).map((sig) => ScriptPushData(sig.bytes)),
      ScriptPushData(multisig.script.compiled),
    ]);

    bytesForNumSigs(int numSigs) {

      final scriptSig = scriptForNumSigs(numSigs).compiled;
      final measure = MeasureWriter()..writeVarSlice(scriptSig);
      final withVarInt = Uint8List(measure.size);

      BytesWriter(withVarInt).writeVarSlice(scriptSig);

      return Uint8List.fromList([
        ...prevOutHash,
        0xef, 0xbe, 0xed, 0xfe,
        ...withVarInt,
        0xed, 0xfe, 0xef, 0xbe,
      ]);

    }

    expectP2SHMultisigInput(P2SHMultisigInput input, int numSigs) {

      expectInput(input);

      expect(input.program.script.match(multisig.script), true);
      expect(input.program.threshold, 3);

      expect(input.complete, numSigs == 3);
      final expScript = scriptForNumSigs(numSigs);
      expect(input.script.match(expScript), true);
      expect(input.scriptSig, expScript.compiled);

      expect(
        input.sigs.map((sig) => sig.bytes),
        insigs.getRange(0, numSigs).map((sig) => sig.bytes),
      );

      final bytes = bytesForNumSigs(numSigs);
      expect(input.size, bytes.length);
      expect(input.toBytes(), bytes);

    }

    test("valid with varying sigs", () {

      for (int i = 0; i < 4; i++) {

        expectP2SHMultisigInput(
          P2SHMultisigInput(
            prevOut: prevOut,
            sequence: sequence,
            program: multisig,
            sigs: insigs.sublist(0, i),
          ),
          i,
        );

        final matched = Input.match(
          RawInput.fromReader(
            BytesReader(bytesForNumSigs(i)),
          ),
        );
        expect(matched, isA<P2SHMultisigInput>());
        expect(matched, isNotNull);
        expectP2SHMultisigInput(matched as P2SHMultisigInput, i);

      }

    });

    test("too many passed sigs", () {
      expect(
        () => P2SHMultisigInput(
          prevOut: prevOut,
          sequence: sequence,
          program: multisig,
          sigs: insigs.sublist(0, 4),
        ),
        throwsArgumentError,
      );
    });

    test(".sigs cannot be mutated", () {

      final input = P2SHMultisigInput(
        prevOut: prevOut,
        sequence: sequence,
        program: multisig,
        sigs: insigs.sublist(0, 1),
      );

      expect(() => input.sigs[0] = insigs[1], throwsA(anything));
      expect(input.sigs[0].bytes, insigs[0].bytes);

    });

    test("doesn't match non p2sh-multisig inputs", () {

      final redeemAsm = bytesToHex(multisig.script.compiled);
      final sigAsm = bytesToHex(insigs[0].bytes);

      for (final asm in [
        "",
        "0",
        "0 0",
        scriptForNumSigs(4).asm,
        "0 $sigAsm $redeemAsm OP_DUP",
        "0 0 $sigAsm $redeemAsm",
        "0 0 $redeemAsm",
        "0 $sigAsm 0100$redeemAsm",
        "0 $sigAsm",
        "$sigAsm $redeemAsm",
        "0 ${invalidDerSigs[0]}02 $redeemAsm",
      ]) {
        expect(
          P2SHMultisigInput.match(
            RawInput(
              prevOut: prevOut,
              scriptSig: Script.fromAsm(asm).compiled,
              sequence: 0,
            ),
          ),
          null,
        );
      }

    });

    test("insertSignature", () {
      // Insert signatures out of order and ensure they are ordered

      Uint8List getSigHash(SigHashType type) => Uint8List.fromList([
        ...List.filled(31, 0), type.value,
      ]);

      final keys = List.generate(4, (i) => ECPrivateKey.generate());

      final sigs = List.generate(
        4,
        (i) {
          final hashType = SigHashType.fromValue(i % 3 + 1);
          return ECDSAInputSignature(
            ECDSASignature.sign(keys[i], getSigHash(hashType)),
            hashType,
          );
        }
      );

      var input = P2SHMultisigInput(
        prevOut: prevOut,
        program: MultisigProgram(3, keys.map((priv) => priv.pubkey)),
      );

      expectInsertion(int index, List<int> expIndices) {

        input = input.insertSignature(
          sigs[index], keys[index].pubkey, getSigHash,
        );

        expect(
          input.sigs.map((sig) => sig.signature.compact).toList(),
          expIndices.map((i) => sigs[i].signature.compact),
        );

      }

      // Adds 3 and 1 twice which still goes through
      expectInsertion(1, [1]);
      expectInsertion(3, [1, 3]);
      expectInsertion(3, [1, 3]);
      expectInsertion(0, [0, 1, 3]);
      expectInsertion(1, [0, 1, 3]);

      // Adding more signatures than necessary trims from end
      expectInsertion(2, [0, 1, 2]);

    });

    test("filterSignatures", () {

      final input = P2SHMultisigInput(
        prevOut: prevOut,
        program: multisig,
        sigs: insigs.sublist(0, 3),
      );

      int i = 0;
      final filtered = input.filterSignatures((insig) => i++ & 1 == 1);

      expect(filtered.sigs.length, 1);
      expect(bytesToHex(filtered.sigs.first.signature.der), validDerSigs[1]);

    });

  });

}
