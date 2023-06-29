import 'dart:typed_data';
import 'package:coinlib/coinlib.dart';
import 'package:coinlib/src/common/hex.dart';
import 'package:test/test.dart';
import '../vectors/signatures.dart';

void main() {

  group("InputSignature", () {

    setUpAll(loadCoinlib);

    test("valid input signature", () {

      final der = hexToBytes(validDerSigs[0]);
      final hashType = InputSignature.sigHashAll
        | InputSignature.sigHashAnyoneCanPay;

      final bytes = Uint8List.fromList([...der, hashType]);

      expectSig(InputSignature sig) {
        expect(sig.bytes, bytes);
        expect(sig.hashType, hashType);
        expect(sig.signature.der, der);
      }

      expectSig(InputSignature(ECDSASignature.fromDer(der), hashType));
      expectSig(InputSignature.fromBytes(bytes));

    });

    test("invalid sighash", () {
      final sig = ECDSASignature.fromDerHex(validDerSigs[0]);
      for (final hashType in [-1, 0, 0x80, 0x84, 4]) {
        expect(() => InputSignature(sig, hashType), throwsArgumentError);
      }
    });

  });

}
