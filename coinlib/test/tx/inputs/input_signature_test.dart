import 'dart:typed_data';
import 'package:coinlib/coinlib.dart';
import 'package:test/test.dart';
import '../../vectors/signatures.dart';

void main() {

  group("ECDSAInputSignature", () {

    setUpAll(loadCoinlib);

    final der = hexToBytes(validDerSigs[0]);

    test("valid input signature", () {

      final hashType = SigHashType.all(inputs: InputSigHashOption.anyOneCanPay);
      final bytes = Uint8List.fromList([...der, 0x81]);

      expectSig(ECDSAInputSignature sig) {
        expect(sig.bytes, bytes);
        expect(sig.hashType, hashType);
        expect(sig.signature.der, der);
      }

      expectSig(ECDSAInputSignature(ECDSASignature.fromDer(der), hashType));
      expectSig(ECDSAInputSignature.fromBytes(bytes));

    });

    test("invalid bytes", () {
      for (final list in <List<int>>[
        [],
        [1],
        der,
        [...der, 0],
        [
          ...der,
          SigHashType.all(inputs: InputSigHashOption.anyPrevOut).value,
        ],
        [...hexToBytes(invalidDerSigs[0]), 1],
      ]) {
        expect(
          () => ECDSAInputSignature.fromBytes(Uint8List.fromList(list)),
          throwsA(isA<InvalidInputSignature>()),
        );
      }
    });

  });

  group("SchnorrInputSignature", () {

    setUpAll(loadCoinlib);

    final sig = hexToBytes(validSchnorrSig);

    test("valid input signatures", () {

      expectSig(SigHashType hashType, Uint8List bytes) {
        final insig = SchnorrInputSignature.fromBytes(bytes);
        expect(insig.bytes, bytes);
        expect(insig.hashType, hashType);
        expect(insig.signature.data, sig);
      }

      expectSig(
        SigHashType.all(inputs: InputSigHashOption.anyOneCanPay),
        Uint8List.fromList([...sig, 0x81]),
      );
      expectSig(
        SigHashType.all(inputs: InputSigHashOption.anyPrevOut),
        Uint8List.fromList([...sig, 0x41]),
      );
      expectSig(SigHashType.all(), Uint8List.fromList([...sig, 1]));
      expectSig(SigHashType.schnorrDefault(), Uint8List.fromList([...sig]));

    });

    test(
      "SIGHASH_DEFAULT by default",
      () => expect(
        SchnorrInputSignature(SchnorrSignature(sig)).hashType,
        SigHashType.schnorrDefault(),
      ),
    );

    test("invalid bytes", () {
      for (final list in <List<int>>[
        [...sig, 0],
        [...sig, 1, 1],
        sig.sublist(0, 63),
      ]) {
        expect(
          () => SchnorrInputSignature.fromBytes(Uint8List.fromList(list)),
          throwsA(isA<InvalidInputSignature>()),
        );
      }
    });

  });

}
