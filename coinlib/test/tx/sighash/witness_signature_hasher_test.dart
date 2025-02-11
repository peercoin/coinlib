import 'package:coinlib/coinlib.dart';
import '../../vectors/tx.dart';
import 'signature_hasher_tester.dart';

void main() {

  signatureHasherTester(
    "WitnessSignatureHasher",
    (Transaction tx, int inputN, SigHashVector vec) => WitnessSignatureHasher(
      LegacyWitnessSignDetailsWithScript(
        tx: tx,
        inputN: inputN,
        scriptCode: Script.fromAsm(vec.scriptCodeAsm),
        value: witnessValue,
        hashType: vec.type,
      ),
    ).hash,
    (SigHashVector vec) => vec.witnessHash,
  );

}
