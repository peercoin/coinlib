import 'package:coinlib/coinlib.dart';
import 'package:test/test.dart';
import '../vectors/keys.dart';
import 'helpers.dart';

void main() {

  group("DLCReady", () {

    late DLCReady dlc;

    setUpAll(() async {

      await loadCoinlib();

      final builders = List.generate(
        2,
        (i) => DLCStatefulBuilder(
          terms: exampleTerms,
          ourPublicKey: getPubKey(i),
        ),
      );

      final pkg2s = List.generate(
        2,
        (i) => builders[i].partOne(
          packages: {
            for (int j = 0; j < 2; j++)
              if (j != i) getPubKey(j): builders[j].publicPackageOne,
          },
          privKey: getPrivKey(i),
        ),
      );

      dlc = builders.first.partTwo({ getPubKey(1): pkg2s.last });

    });

    test(
      "cets is immutable",
      () => expect(
        () => dlc.cets.remove(exampleTerms.outcomes.keys.first),
        throwsA(anything),
      ),
    );

    test("can read and write", () {

      final readDlc = DLCReady.fromBytes(dlc.toBytes());
      expect(readDlc.refundTransaction.toHex(), dlc.refundTransaction.toHex());

      for (
        final f in <Writable Function(CETReady)>[
          (cet) => cet.tx,
          (cet) => cet.adaptorSig,
        ]
      ) {
        Iterable<String> cetsToHex(DLCReady dlc)
          => dlc.cets.values.map((cet) => f(cet).toHex());
        expect(cetsToHex(readDlc), unorderedMatches(cetsToHex(dlc)));
      }
    });

  });

}
