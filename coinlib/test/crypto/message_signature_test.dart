import 'package:coinlib/coinlib.dart';
import 'package:test/test.dart';
import '../vectors/keys.dart';

final privKey = WIF.fromString(
  "UBGjv7kuxKmN1JHLJxQypz9jE7mYkKTZ9U6C1p1N2nEWbPZLiEkT",
  version: Network.mainnet.wifPrefix,
).privkey;
final addrs = [
  P2PKHAddress.fromPublicKey(
    privKey.pubkey, version: Network.mainnet.p2pkhPrefix,
  ),
  P2WPKHAddress.fromPublicKey(
    privKey.pubkey, hrp: Network.mainnet.bech32Hrp,
  ),
];
final msgSigs = [
  [
    "Hello, this is a message",
    "H4UaAiTB5aNpPiwHpH1Qp7th5NxBQeLoNdk0qzqqVHmQN1f+2yMyH4eX/9Iq2gkXSN1GTnflJpZQcxqOkUtuYJc=",
  ],
  [
    "The recid for this message is 1",
    "IIXsSzUwny1RGeKNBzp9UBqlNxXisKJd5WpkrsPBVrblPETGvL8ESy4L5WpYZibQdSH04cL088zT0JMc4KAgvVY=",
  ],
];

final prefix = Network.mainnet.messagePrefix;

void main() {
  group("MessageSignature", () {

    setUpAll(loadCoinlib);

    test("can sign messages", () {
      for (final vec in msgSigs) {
        final msgSig = MessageSignature.sign(
          key: privKey,
          message: vec[0],
          prefix: prefix,
        );
        expect(msgSig.toString(), vec[1]);
      }
    });

    test("verifies against public key and address", () {
      for (final vec in msgSigs) {
        final msgSig = MessageSignature.fromBase64(vec[1]);
        expect(
          msgSig.verifyPublicKey(
            pubkey: privKey.pubkey,
            message: vec[0],
            prefix: prefix,
          ),
          true,
        );
        for (final addr in addrs) {
          expect(
            msgSig.verifyAddress(
              address: addr,
              message: vec[0],
              prefix: prefix,
            ),
            true,
          );
        }
      }
    });

    test("fails against wrong public key or address", () {
      final msgSig = MessageSignature.fromBase64(msgSigs[0][1]);
      expect(
        msgSig.verifyPublicKey(
          pubkey: keyPairVectors[0].publicObj,
          message: msgSigs[0][0],
          prefix: prefix,
        ),
        false,
      );
      expect(
        msgSig.verifyAddress(
          address: Address.fromString(
            "P8bB9yPr3vVByqfmM5KXftyGckAtAdu6f8",
            Network.mainnet,
          ),
          message: msgSigs[0][0],
          prefix: prefix,
        ),
        false,
      );
    });

  });

}
