import 'dart:typed_data';
import 'package:coinlib/coinlib.dart';
import 'package:coinlib/src/common/hex.dart';
import 'package:test/test.dart';
import '../vectors/keys.dart';
import '../vectors/signatures.dart';
import '../vectors/inputs.dart';

void main() {

  group("P2WPKHInput", () {

    setUpAll(loadCoinlib);

    final der = validDerSigs[0];
    final pkBytes = hexToBytes(pubkeyVec);

    getWitness(bool hasSig) => [
      if (hasSig) Uint8List.fromList([
        ...hexToBytes(der),
        InputSignature.sigHashSingle,
      ]),
      hexToBytes(pubkeyVec),
    ];

    test("valid p2wpkh inputs inc. addSignature", () {

      final pk = ECPublicKey(pkBytes);
      final insig = InputSignature(
        ECDSASignature.fromDerHex(der),
        InputSignature.sigHashSingle,
      );

      final rawBytes = Uint8List.fromList([
        ...prevOutHash,
        0xef, 0xbe, 0xed, 0xfe,
        0,
        0xed, 0xfe, 0xef, 0xbe,
      ]);

      expectP2WPKHInput(P2WPKHInput input, bool hasSig) {

        expectInput(input);

        expect(input.publicKey.hex, pubkeyVec);
        expect(input.complete, hasSig);
        expect(input.insig, hasSig ? isNotNull : null);
        expect(input.scriptSig.ops.isEmpty, true);

        if (hasSig) {
          expect(bytesToHex(input.insig!.signature.der), validDerSigs[0]);
          expect(input.insig!.hashType, InputSignature.sigHashSingle);
        }

        expect(input.witness, getWitness(hasSig));
        expect(input.size, rawBytes.length);
        expect(input.toBytes(), rawBytes);

      }

      final noSig = P2WPKHInput(
        prevOut: prevOut,
        sequence: sequence,
        publicKey: pk,
      );

      final withSig = P2WPKHInput(
        prevOut: prevOut,
        sequence: sequence,
        publicKey: pk,
        insig: insig,
      );

      expectP2WPKHInput(noSig, false);
      expectP2WPKHInput(withSig, true);
      expectP2WPKHInput(noSig.addSignature(insig), true);

      expectMatched(bool hasSig) {
        final matched = Input.match(
          RawInput.fromReader(BytesReader(rawBytes)),
          getWitness(hasSig),
        );
        expect(matched, isA<P2WPKHInput>());
        expectP2WPKHInput(matched as P2WPKHInput, hasSig);
      }

      expectMatched(false);
      expectMatched(true);

    });

    test("doesn't match non p2wpkh inputs", () {

      expectNoMatch(String asm, List<Uint8List> witness) => expect(
        P2WPKHInput.match(
          RawInput(
            prevOut: prevOut,
            scriptSig: Script.fromAsm(asm),
            sequence: 0,
          ),
          witness,
        ),
        null,
      );

      expectNoMatch("0", getWitness(true));
      expectNoMatch("", []);
      expectNoMatch("", [hexToBytes(der)]);
      expectNoMatch("", [...getWitness(true), Uint8List(33)]);
      expectNoMatch("", [...getWitness(true), pkBytes]);
      expectNoMatch("", [...getWitness(false), pkBytes]);
      expectNoMatch("", [hexToBytes(der), ...getWitness(true)]);
      expectNoMatch("", [pkBytes.sublist(32)]);
      expectNoMatch("", [hexToBytes(invalidPubKeys[0])]);
      expectNoMatch("", [hexToBytes(invalidSignatures[0]), pkBytes]);

    });

  });

}
