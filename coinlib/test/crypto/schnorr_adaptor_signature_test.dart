import 'dart:typed_data';
import 'package:coinlib/coinlib.dart';
import 'package:test/test.dart';
import '../vectors/keys.dart';
import '../vectors/signatures.dart';

final goodSig = SchnorrSignature.fromHex(validSchnorrSig);
final goodAdaptorSig = SchnorrAdaptorSignature(goodSig, false);

void main() {

  group("SchnorrAdaptorSignature", () {

    setUpAll(loadCoinlib);

    test("cannot extract where both signatures are the same", () => expect(
      () => goodAdaptorSig.extract(goodSig),
      throwsA(isA<InvalidPrivateKey>()),
    ),);

    test("cannot adapt or extract using malformed signatures", () {

      final badSig = SchnorrSignature(
        Uint8List.fromList(List.filled(64, 0xff)),
      );
      final badAdaptorSig = SchnorrAdaptorSignature(badSig, false);

      final throwsInvalidSig = throwsA(isA<InvalidSchnorrSignature>());

      expect(() => badAdaptorSig.adapt(getPrivKey(0)), throwsInvalidSig);
      expect(() => badAdaptorSig.extract(goodSig), throwsInvalidSig);
      expect(() => goodAdaptorSig.extract(badSig), throwsInvalidSig);

    });

  });

}
