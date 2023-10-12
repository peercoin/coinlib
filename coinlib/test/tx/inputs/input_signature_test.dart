import 'dart:typed_data';
import 'package:coinlib/coinlib.dart';
import 'package:test/test.dart';
import '../../vectors/signatures.dart';

void main() {

  group("ECDSAInputSignature", () {

    setUpAll(loadCoinlib);

    test("valid input signature", () {

      final der = hexToBytes(validDerSigs[0]);
      final hashType = SigHashType.all(anyOneCanPay: true);

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
        [...hexToBytes(validDerSigs[0]), 0],
        [...hexToBytes(invalidDerSigs[0]), 1],
      ]) {
        expect(
          () => ECDSAInputSignature.fromBytes(Uint8List.fromList(list)),
          throwsA(isA<InvalidInputSignature>()),
        );
      }
    });

  });

}
