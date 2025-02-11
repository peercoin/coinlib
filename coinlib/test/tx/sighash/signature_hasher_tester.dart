import 'dart:typed_data';
import 'package:coinlib/coinlib.dart';
import 'package:test/test.dart';
import '../../vectors/tx.dart';

/// Used for legacy and legacy-segwit hashers
void signatureHasherTester(
  String name,
  Uint8List Function(Transaction tx, int inputN, SigHashVector vec) hasher,
  String Function(SigHashVector vec) hashFromVec,
) => group(name, () {

  late Transaction tx;
  setUpAll(() async {
    await loadCoinlib();
    tx = Transaction.fromHex(sigHashTxHex);
  });

  test("produces correct signature hash", () {
    for (final vec in sighashVectors) {
      expect(bytesToHex(hasher(tx, vec.inputN, vec)), hashFromVec(vec));
    }
  });

  test("input out of range", () {
    expect(() => hasher(tx, 2, sighashVectors[0]), throwsArgumentError);
  });

  test("doesn't allow DEFAULT or ANYPREVOUT", () {
    for (final type in [
      SigHashType.schnorrDefault(),
      SigHashType(
        outputs: OutputSigHashOption.all,
        inputs: InputSigHashOption.anyPrevOut,
      ),
      SigHashType(
        outputs: OutputSigHashOption.all,
        inputs: InputSigHashOption.anyPrevOutAnyScript,
      ),
    ]) {
      expect(
        () => hasher(
          tx, 0,
          SigHashVector(
            inputN: 0,
            scriptCodeAsm: "",
            type: type,
            hash: "",
            witnessHash: "",
          ),
        ),
        throwsA(isA<CannotSignInput>()),
      );
    }
  });

});
