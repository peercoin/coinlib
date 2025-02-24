import 'package:coinlib/coinlib.dart';
import 'package:test/test.dart';
import '../vectors/keys.dart';

final pubkey = keyPairVectors.first.publicObj;

void main() {

  group("TapLeafChecksig", () {

    setUpAll(loadCoinlib);

    test("valid keys", () {

      void expectLeaf(TapLeafChecksig leaf, String asm, bool isApo) {
        expect(leaf.script.asm, asm);
        expect(leaf.isApo, isApo);
      }

      expectLeaf(
        TapLeafChecksig.apoInternal,
        "01 OP_CHECKSIG",
        true,
      );

      expectLeaf(
        TapLeafChecksig(pubkey),
        "${bytesToHex(pubkey.x)} OP_CHECKSIG",
        false,
      );

      expectLeaf(
        TapLeafChecksig.apo(pubkey),
        "01${bytesToHex(pubkey.x)} OP_CHECKSIG",
        true,
      );

    });

    test(".match() valid", () {

      void expectMatch(String asm, bool isApo) {
        final leaf = TapLeafChecksig.match(Script.fromAsm(asm));
        expect(leaf, isNotNull);
        expect(leaf?.isApo, isApo);
        expect(leaf?.script.asm, asm);
      }

      expectMatch("01 OP_CHECKSIG", true);
      expectMatch("${bytesToHex(pubkey.x)} OP_CHECKSIG", false);
      expectMatch("01${bytesToHex(pubkey.x)} OP_CHECKSIG", true);

    });

    test(".match() invalid", () {

      for (final invalid in [
        "",
        "02 OP_CHECKSIG",
        "OP_CHECKSIG",
        "01 01 OP_CHECKSIG",
        "02${bytesToHex(pubkey.x)} OP_CHECKSIG",
        "${bytesToHex(pubkey.x.sublist(1))} OP_CHECKSIG",
        "0101${bytesToHex(pubkey.x)} OP_CHECKSIG",
        "fffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc30 OP_CHECKSIG",
      ]) {
        expect(TapLeafChecksig.match(Script.fromAsm(invalid)), isNull);
      }

    });

  });

}
