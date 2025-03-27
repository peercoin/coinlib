import 'dart:typed_data';
import 'package:coinlib/coinlib.dart';
import 'package:test/test.dart';
import '../vectors/signatures.dart';

void main() {

  group("SchnorrSignature", () {

    setUpAll(loadCoinlib);

    final validHex = validSignatures[0];

    test("requires 64-bytes", () {

      for (final failing in [validHex.substring(2), "${validHex}00"]) {
        expect(
          () => SchnorrSignature.fromHex(failing),
          throwsArgumentError,
        );
      }

    });

    test(".data is copied cannot be mutated", () {
      final data = hexToBytes(validHex);
      final sig = SchnorrSignature(data);
      sig.data[0] = 0xff;
      data[1] = 0xff;
      expect(bytesToHex(sig.data), validSignatures[0]);
    });

    test(".r and .s give point and scalar", () {
      final data = hexToBytes(validHex);
      final sig = SchnorrSignature(data);
      final r = sig.r;
      final s = sig.s;
      expect(SchnorrSignature.fromRS(r, s).data, sig.data);
    });

    test(".sign()", () {

      void expectValid(ECPrivateKey privkey, Uint8List hash, String expSig) {
        final sig = SchnorrSignature.sign(privkey, hash);
        expect(bytesToHex(sig.data), expSig);
        expect(sig.verify(privkey.pubkey, hash), true);
      }

      // First BIP0340 test vector

      expectValid(
        ECPrivateKey.fromHex(
          "0000000000000000000000000000000000000000000000000000000000000003",
        ),
        Uint8List(32),
        "e907831f80848d1069a5371b402410364bdf1c5f8307b0084c55f1ce2dca821525f66a4a85ea8b71e482a74f382d2ce5ebeee8fdb2172f477df4900d310536c0",
      );

      // Private key leading to odd-Y public key, tested using python reference
      // implementation

      expectValid(
        ECPrivateKey.fromHex(
          "1000000000000000000000000000000000000000000000000000000000000000",
        ),
        Uint8List.fromList(List.filled(32, 0xff)),
        "84a54df8662c0458c075fabc1f12cbbd1da75d88b57931066ccbf817f0278e39cb343d41b9f6bbcba221c61aee421f9c15028d936a978de7ef6b83b4c58b857b",
      );

    });

    test(".verify() success", () {
      final sig = SchnorrSignature.fromHex(
        "00000000000000000000003b78ce563f89a0ed9414f5aa28ad0d96d6795f9c6376afb1548af603b3eb45c9f8207dee1060cb71c04e80f593060b07d28308d7f4",
      );
      final pubkey = ECPublicKey.fromXOnlyHex(
        "d69c3509bb99e412e68b0fe8544e72837dfa30746d8be2aa65975f29d22dc7b9",
      );
      final hash = hexToBytes(
        "4df3c3f68fcc83b27e9d42c90431a72499f17875c81a599b566c9889b9696703",
      );
      expect(sig.verify(pubkey, hash), true);
    });

    test(".verify() failure", () {

      final hash = hexToBytes(
        "243f6a8885a308d313198a2e03707344a4093822299f31d0082efa98ec4e6c89",
      );

      void expectFail(String pk, String sig) {
        expect(
          SchnorrSignature.fromHex(sig)
          .verify(ECPublicKey.fromXOnlyHex(pk), hash),
          false,
        );
      }

      final reusedPk
        = "dff1d77f2a671c5f36183726db2341be58feae1da2deced843240f7b502ba659";

      expectFail(
        reusedPk,
        "fff97bd5755eeea420453a14355235d382f6472f8568a18b2f057a14602975563cc27944640ac607cd107ae10923d9ef7a73c643e166be5ebeafa34b1ac553e2",
      );

      expectFail(
        reusedPk,
        "1fa62e331edbc21c394792d2ab1100a7b432b013df3f6ff4f99fcb33e0e1515f28890b3edb6e7189b630448b515ce4f8622a954cfe545735aaea5134fccdb2bd",
      );

      expectFail(
        reusedPk,
        "6cff5c3ba86c69ea4b7376f31a9bcb4f74c1976089b2d9963da2e5543e177769961764b3aa9b2ffcb6ef947b6887a226e8d7c93e00c5ed0c1834ff0d0c2e6da6",
      );

      expectFail(
        reusedPk,
        "0000000000000000000000000000000000000000000000000000000000000000123dda8328af9c23a94c1feecfd123ba4fb73476f0d594dcb65c6425bd186051",
      );

      expectFail(
        reusedPk,
        "00000000000000000000000000000000000000000000000000000000000000017615fbaf5ae28864013c099742deadb4dba87f11ac6754f93780d5a1837cf197",
      );

      expectFail(
        reusedPk,
        "4a298dacae57395a15d0795ddbfd1dcb564da82b0f269bc70a74f8220429ba1d69e89b4c5564d00349106b8497785dd7d1d713a8ae82b32fa79d5f7fc407d39b",
      );

      expectFail(
        reusedPk,
        "fffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2f69e89b4c5564d00349106b8497785dd7d1d713a8ae82b32fa79d5f7fc407d39b",
      );

      expectFail(
        reusedPk,
        "6cff5c3ba86c69ea4b7376f31a9bcb4f74c1976089b2d9963da2e5543e177769fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141",
      );

    });

  });

}
