import 'dart:typed_data';
import 'package:coinlib/coinlib.dart';
import 'package:test/test.dart';
import '../vectors/hd_keys.dart';

void forEachHDVector(void Function(HDVector? parent, HDVector vec) f) {
  for (final path in hdVectors) {
    HDVector? parent;
    for (final key in path) {
      f(parent, key);
      parent = key;
    }
  }
}

void expectPriv(HDKey key) => expect(key, isA<HDPrivateKey>());
void expectPub(HDKey key) => expect(key, isA<HDPublicKey>());

void main() {

  group("HDKey", () {

    setUpAll(loadCoinlib);

    test("base58 decode/encode", () {
      forEachHDVector((parent, vec) {

        final priv = HDKey.decode(vec.privEncoded);
        final pub = HDKey.decode(vec.pubEncoded);

        expectPriv(priv);
        expectPub(pub);
        expect(priv.parentFingerprint, parent == null ? 0 : parent.fingerprint);
        expect(pub.parentFingerprint, parent == null ? 0 : parent.fingerprint);
        vec.expectHDKey(priv);
        vec.expectHDKey(pub);

        // Decodes when version specified
        expectPriv(HDKey.decode(vec.privEncoded, privVersion: privPrefix));
        expectPriv(
          HDKey.decode(
            vec.privEncoded,
            privVersion: privPrefix,
            pubVersion: pubPrefix,
          ),
        );
        expectPub(HDKey.decode(vec.pubEncoded, pubVersion: pubPrefix));
        expectPub(
          HDKey.decode(
            vec.pubEncoded,
            privVersion: privPrefix,
            pubVersion: pubPrefix,
          ),
        );

        // Decodes for specific class, with and without version
        expectPriv(HDPrivateKey.decode(vec.privEncoded, privPrefix));
        expectPub(HDPublicKey.decode(vec.pubEncoded, pubPrefix));
        expectPriv(HDPrivateKey.decode(vec.privEncoded));
        expectPub(HDPublicKey.decode(vec.pubEncoded));

      });
    });

    test("invalid checksum", () {
      expect(
        () => HDKey.decode(
          "xprvQQQQQQQQQQQQQQQQCviVfJSKyQ1mDYahRjijr5idH2WwLsEd4Hsb2Tyh8RfQMuPh7f7RtyzTtdrbdqqsunu5Mm3wDvUAKRHSC34sJ7in334",
        ),
        throwsA(isA<InvalidBase58Checksum>()),
      );
    });

    test("wrong base58 version", () {
      expect(
        () => HDKey.decode(
          "Ltpv73XYpw28ZyVe2zEVyiFnxUZxoKLGQNdZ8NxUi1WcqjNmMBgtLbh3KimGSnPHCoLv1RmvxHs4dnKmo1oXQ8dXuDu8uroxrbVxZPA1gXboYvx",
          privVersion: privPrefix,
        ),
        throwsA(isA<InvalidHDKeyVersion>()),
      );
      // Private key, but swap versions around so it doesn't match
      expect(
        () => HDKey.decode(
          masterVector.privEncoded,
          privVersion: pubPrefix,
          pubVersion: privPrefix,
        ),
        throwsA(isA<InvalidHDKeyVersion>()),
      );
    });

    test("wrong key type", () {
      expect(
        () => HDPrivateKey.decode(masterVector.pubEncoded),
        throwsA(isA<InvalidHDKey>()),
      );
      expect(
        () => HDPublicKey.decode(masterVector.privEncoded),
        throwsA(isA<InvalidHDKey>()),
      );
    });

    test("invalid key", () {
      for (final invalid in [
        // Too short
        "DeaWiRvhTUWHmRFa65QcRFoZqVNmvXCnyi7cod8wKuH6s3dLhoawqehRCwzNEK1fVrh3ojSNBkvrBj6GRe5UGW5qpMwtda7wfu3xHzJHBs1gum",
        // Invalid parent fingerprint
        "xprv9tnJFvAXAXPfPnMTKfwpwnkty7MzJwELVgp4NTBquaKXy4RndyfJJCJJf7zNaVpBpzrwVRutZNLRCVLEcZHcvuCNG3zGbGBcZn57FbNnmSP",
        // Invalid key type
        "xpub661MyMwAqRbcFtXgS5sYJABqqG9YLmC4Q1Rdap9gSE8NqtwybGhePY2gZ45ycVBsADt89FVXeDkYqbSeZmpjjnJETkyyiMwXokWPisrtUjm",
        // Invalid index
        "xprv9s21ZrQYdgnodnKW4Drm1Qg7poU6Gf2WUDsjPxvYiK7iLBMrsjbnF1wsZZQgmXNeMSG3s7jmHk1b3JrzhG5w8mwXGxqFxfrweico7k8DtxR",
        // Invalid private key
        "xprv9s21ZrQH143K3QTDL4LXw2F7HEK3wJUD2nW2nRk4stbPy6cq3jPPqjiChkg5hntwdZH6QYdrGVYWUCS2Xv6FCMHoYQZYQDohv67LnGTwiNd",
        "xprv9s21ZrQH143K24Mfq5zL5MhWK9hUhhGbd45hLXo2Pq2oqzMMo63oStZzF93Y5wvzdUayhgkkFoicQZcP3y52uPPxFnfoLZB21Teqt1VvEHx",
        "xprv9s21ZrQH143K24Mfq5zL5MhWK9hUhhGbd45hLXo2Pq2oqzMMo63oStZzFAzHGBP2UuGCqWLTAPLcMtD5SDKr24z3aiUvKr9bJpdrcLg1y3G",
        // Invalid public key
        "xpub661MyMwAqRbcFtXgS5sYJABqqG9YLmC4Q1Rdap9gSE8NqtwybGhePY2gYymDsxxRe3WWeZQ7TadaLSdKUffezzczTCpB8j3JP96UwE2n6w1",
        "xpub661MyMwAqRbcEYS8w7XLSVeEsBXy79zSzH1J8vCdxAZningWLdN3zgtU6Q5JXayek4PRsn35jii4veMimro1xefsM58PgBMrvdYre8QyULY",
        // 0 depth with non-zero parent
        "xprv9s2SPatNQ9Vc6GTbVMFPFo7jsaZySyzk7L8n2uqKXJen3KUmvQNTuLh3fhZMBoG3G4ZW1N2kZuHEPY53qmbZzCHshoQnNf4GvELZfqTUrcv",
        "xpub661no6RGEX3uJkY4bNnPcw4URcQTrSibUZ4NqJEw5eBkv7ovTwgiT91XX27VbEXGENhYRCf7hyEbWrR3FewATdCEebj6znwMfQkhRYHRLpJ",
        // 0 depth with non-zero index
        "xprv9s21ZrQH4r4TsiLvyLXqM9P7k1K3EYhA1kkD6xuquB5i39AU8KF42acDyL3qsDbU9NmZn6MsGSUYZEsuoePmjzsB3eFKSUEh3Gu1N3cqVUN",
        "xpub661MyMwAuDcm6CRQ5N4qiHKrJ39Xe1R1NyfouMKTTWcguwVcfrZJaNvhpebzGerh7gucBvzEQWRugZDuDXjNDRmXzSZe4c7mnTK97pTvGS8",
      ]) {
        expect(() => HDKey.decode(invalid), throwsA(isA<InvalidHDKey>()));
      }
    });

    test("invalid private key prefix", () {
      for (final invalid in [
        // = 1
        "xprv9s21ZrQH143K24Mfq5zL5MhWK9hUhhGbd45hLXo2Pq2oqzMMo63oStZzFAzHGBP2UuGCqWLTAPLcMtD9y5gkZ6Eq3Rjuahrv17fEQ3Qen6J",
        // = 2
        "xprv9s21ZrQH143K3QTDL4LXw2F7HEK3wJUD2nW2nRk4stbPy6cq3jPPqjiChpPRGqDq67fQn845uW2EzPrHBebomT92ThKrnz7q3Hv3BChaDfV",
      ]) {
        expect(
          () => HDPrivateKey.decode(invalid, privPrefix),
          throwsA(isA<InvalidHDKey>()),
        );
      }
    });

    test("invalid public key prefix = 0", () {
      expect(
        () => HDPublicKey.decode(
          "xpub661MyMwAqRbcFtXgS5sYJABqqG9YLmC4Q1Rdap9gSE8NqtwybGhePY2gYuwrp1sUuNvcWssWinxvnKBXjMkAhmeKHtsepMoxxSjGXnxxT83",
          pubPrefix,
        ),
        throwsA(isA<InvalidHDKey>()),
      );
    });

    test("fromSeed()", () {
      for (final path in hdVectors) {
        final vec = path[0];
        vec.expectHDKey(HDPrivateKey.fromSeed(hexToBytes(vec.seedHex!)));
      }
    });

    test("fromSeed() invalid seed size", () {
      for (final size in [15, 65]) {
        expect(() => HDPrivateKey.fromSeed(Uint8List(size)), throwsArgumentError);
      }
    });

    test("derive()", () {
      forEachHDVector((parent, vec) {
        if (parent != null) {

          final derivedPriv = HDPrivateKey.decode(parent.privEncoded).derive(vec.index);
          expectPriv(derivedPriv);
          vec.expectHDPrivateKey(derivedPriv);

          if (!vec.hardened) {
            final derivedPub = HDKey.decode(parent.pubEncoded).derive(vec.index);
            expectPub(derivedPub);
            vec.expectHDKey(derivedPub);
          }

        }
      });
    });

    test("deriveHardened()", () {
      forEachHDVector((parent, vec) {
        if (parent != null && vec.hardened) {
          final derivedHardened = HDKey.decode(parent.privEncoded)
            .deriveHardened(vec.index - 0x80000000);
          expectPriv(derivedHardened);
          vec.expectHDPrivateKey(derivedHardened);
        }
      });
    });

    test("derivePath()", () {

      final derived = masterHDKey.derivePath("m/0'/1/2'/2/1000000000");
      expectPriv(derived);
      hdVectors[0][5].expectHDPrivateKey(derived);

      final pubDerived = HDPublicKey.decode(hdVectors[0][3].pubEncoded, pubPrefix)
        .derivePath("2/1000000000");
      expectPub(pubDerived);
      hdVectors[0][5].expectHDKey(pubDerived);

      final pubMasterDerived =
        HDPublicKey.decode(hdVectors[1][0].pubEncoded, pubPrefix).derivePath("m/0");
      expectPub(pubMasterDerived);
      hdVectors[1][1].expectHDKey(pubMasterDerived);

    });

    test("invalid paths", () {
      for (final invalid in [
        "/",
        "m/m/123",
        "a/0/1/2",
        "m/0/  1  /2",
        "m/0/1.5/2",
        "m/0''",
        "m/0//",
        // Over max index
        "m/2147483648",
      ]) {
        expect(() => masterHDKey.derivePath(invalid), throwsArgumentError);
      }
    });

    test("derive m/ not from master", () {
      expect(
        () => HDKey.decode(hdVectors[0][1].privEncoded).derivePath("m/0"),
        throwsArgumentError,
      );
    });

    test("invalid derive() index", () {
      for (final invalid in [-1, 4294967296]) {
        expect(() => masterHDKey.derive(invalid), throwsArgumentError);
      }
    });

    test("invalid deriveHardened() index", () {
      for (final invalid in [-1, 2147483648]) {
        expect(() => masterHDKey.deriveHardened(invalid), throwsArgumentError);
      }
    });

    test("fails to derive hardened for public key", () {
      expect(
        () => masterHDKey.hdPublicKey.deriveHardened(0),
        throwsArgumentError,
      );
      expect(
        () => masterHDKey.hdPublicKey.derive(0x80000000),
        throwsArgumentError,
      );
      expect(
        () => masterHDKey.hdPublicKey.derivePath("m/0'"),
        throwsArgumentError,
      );
    });

    test("fromKeyAndChainCode()", () {
      for (final paths in hdVectors) {
        // For all master keys
        final vec = paths[0];
        final key = HDPrivateKey.fromKeyAndChainCode(
          ECPrivateKey.fromHex(vec.privHex), hexToBytes(vec.chaincodeHex),
        );
        vec.expectHDKey(key);
      }
    });

    test("fromKeyAndChainCode() chaincode must be 32 bytes", () {
      for (final invalid in [31, 33]) {
        expect(
          () => HDPrivateKey.fromKeyAndChainCode(
            masterHDKey.privateKey, Uint8List(invalid),
          ),
          throwsArgumentError,
        );
      }
    });

    test("encode() version must be uint32", () {
      for (final invalid in [-1, 0x0100000000]) {
        expect(() => masterHDKey.encode(invalid), throwsArgumentError);
      }
    });

    test(".chaincode is copied and cannot be mutated", () {
      final cc = Uint8List(32);
      final hdKey = HDPrivateKey.fromKeyAndChainCode(
        ECPrivateKey.fromHex(masterVector.privHex), cc,
      );
      hdKey.chaincode[0] = 0xff;
      cc[1] = 0xff;
      expect(hdKey.chaincode, Uint8List(32));
    });

  });

}
