import 'package:coinlib/coinlib.dart';
import 'package:test/test.dart';
import '../vectors/keys.dart';

void main() {

  group("ECCompressedPublicKey", () {

    setUpAll(loadCoinlib);

    test("requires 33 bytes", () {

      for (final failing in [
        // Too small
        pubkeyVec.substring(0, 32*2),
        // Too large
        longPubkeyVec,
        "${pubkeyVec}ff",
      ]) {
        expect(
          () => ECCompressedPublicKey.fromHex(failing),
          throwsA(isA<InvalidPublicKey>()),
        );
      }

    });

    test("accepts compressed types", () {
      for (final vec in validPubKeys) {
        if (!vec.compressed) continue;
        final pk = ECCompressedPublicKey.fromHex(vec.hex);
        expect(pk.hex, vec.hex);
        expect(pk.compressed, true);
        expect(pk.yIsEven, vec.evenY);
      }
    });

    test(".fromXOnly", () => expect(
        ECCompressedPublicKey.fromXOnlyHex(xOnlyPubkeyVec).hex,
        "02$xOnlyPubkeyVec",
    ),);

    test(".fromPubkey", () {

      void expectCompressedKey(String pubkey, String compressed) => expect(
        ECCompressedPublicKey.fromPubkey(ECPublicKey.fromHex(pubkey)).hex,
        compressed,
      );

      expectCompressedKey(longPubkeyVec, pubkeyVec);
      expectCompressedKey(pubkeyVec, pubkeyVec);
      expectCompressedKey(
        "06ef164284e2c3abc32b310eb62904af0d49196c51087bdf4038998f8818787c882433ae83422904f48ad36dcf351ac9a37e6b00e57cf40b469b650ec850640efe",
        "02ef164284e2c3abc32b310eb62904af0d49196c51087bdf4038998f8818787c88",
      );
      expectCompressedKey(
        "07576168b540f6f80e4d2a325f8cbd420ceb170ff42cd07e96bffc5e6a4a4ea04b1208f618306fd629cd2972cea45aa81ae7b24a64bf2e86704d7a63d82fd97a8f",
        "03576168b540f6f80e4d2a325f8cbd420ceb170ff42cd07e96bffc5e6a4a4ea04b",
      );

    });

  });

}
