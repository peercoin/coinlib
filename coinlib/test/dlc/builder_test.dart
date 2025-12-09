import 'package:coinlib/coinlib.dart';
import 'package:test/test.dart';
import '../vectors/keys.dart';
import 'helpers.dart';

void main() {

  setUpAll(loadCoinlib);

  group("DLCStatefulBuilder", () {

    test("ourPublicKey not in terms", () => expect(
      () => DLCStatefulBuilder(
        terms: exampleTerms,
        ourPublicKey: getPubKey(2),
      ),
      throwsArgumentError,
    ),);

    group(".partOne()", () {

      List<DLCStatefulBuilder> getBuildersForOutcomes(int n) {
        final terms = getTerms(
          participants: Iterable.generate(3, (i) => getPubKey(i)).toSet(),
          outcomes: Map.fromEntries(
            Iterable.generate(
              n,
              (i) => MapEntry(getPubKey(i), getOutcome(["6"])),
            ),
          ),
          fundAmounts: {
            getPubKey(1): getFundOutput(4, "2"),
            getPubKey(2): getFundOutput(5, "3.99"),
            // Dust will be removed from refund to cover fee
            getPubKey(3): getFundOutput(6, "0.01"),
          },
        );
        return List.generate(
          3,
          (i) => DLCStatefulBuilder(terms: terms, ourPublicKey: getPubKey(i)),
        );
      }

      late List<DLCStatefulBuilder> buildersFor2CETs;
      late List<DLCStatefulBuilder> buildersFor3CETs;
      late List<DLCStatefulBuilder> buildersFor4CETs;

      setUp(() {
        buildersFor2CETs = getBuildersForOutcomes(2);
        buildersFor3CETs = getBuildersForOutcomes(3);
        buildersFor4CETs = getBuildersForOutcomes(4);
      });

      Map<ECPublicKey, PublicPackageOne> getPackageOnes(
        List<DLCStatefulBuilder> builders,
        List<int> which,
      ) => {
        for (final i in which) getPubKey(i): builders[i].publicPackageOne,
      };

      test("invalid packages", () {

        // Duplicated logic as for package twos
        for (final packages in [
          // Shouldn't contain own key
          getPackageOnes(buildersFor2CETs, [0, 1]),
          // Too few
          getPackageOnes(buildersFor2CETs, [1]),
          getPackageOnes(buildersFor2CETs, []),
          // Key that shouldn't exist
          {
            ...getPackageOnes(buildersFor2CETs, [1, 2]),
            getPubKey(3): buildersFor2CETs.first.publicPackageOne,
          }
        ]) {
          expect(
            () => buildersFor2CETs.first.partOne(
              packages: packages,
              privKey: getPrivKey(0),
            ),
            throwsArgumentError,
          );
        }

      });

      test("invalid private key", () => expect(
        () => buildersFor2CETs.first.partOne(
          packages: getPackageOnes(buildersFor2CETs, [1, 2]),
          privKey: getPrivKey(1),
        ),
        throwsArgumentError,
      ),);

      test("misbehaviour due to wrong CETs", () {
        for (final builders in [buildersFor2CETs, buildersFor4CETs]) {
          expect(
            () => buildersFor3CETs.first.partOne(
              packages: getPackageOnes(builders, [1, 2]),
              privKey: getPrivKey(0),
            ),
            throwsA(isA<DLCParticipantMisbehaviour>()),
          );
        }
      });

      test("PublicPackageOne can be read and written", () {
        final pkgBytes = buildersFor4CETs.first.publicPackageOne.toBytes();
        expect(pkgBytes, PublicPackageOne.fromBytes(pkgBytes).toBytes());
      });

      test("cannot do partOne twice", () {
        void doPartOne() => buildersFor2CETs.first.partOne(
          packages: getPackageOnes(buildersFor2CETs, [1, 2]),
          privKey: getPrivKey(0),
        );
        doPartOne();
        expect(doPartOne, throwsStateError);
      });

      group(".partTwo()", () {

        late List<PublicPackageTwo> packageTwosFor2CETs, packageTwosFor4CETs;

        List<PublicPackageTwo> createPackageTwos(
          List<DLCStatefulBuilder> builders,
        ) => List.generate(
          3,
          (i) => builders[i].partOne(
            packages: getPackageOnes(
              builders,
              [for (int j = 0; j < 3; j++) if (j != i) j],
            ).map(
              (key, pkg) => MapEntry(
                key,
                PublicPackageOne.fromBytes(pkg.toBytes()),
              ),
            ),
            privKey: getPrivKey(i),
          ),
        );

        setUp(() {
          // Run partOne for all builders using serialised packages
          packageTwosFor2CETs = createPackageTwos(buildersFor2CETs);
          packageTwosFor4CETs = createPackageTwos(buildersFor4CETs);
        });

        Map<ECPublicKey, PublicPackageTwo> getPackageTwos(
          List<PublicPackageTwo> packages,
          List<int> which,
        ) => {
          for (final i in which) getPubKey(i): packages[i],
        };

        test("invalid packages", () {

          // Duplicated logic as for package ones
          for (final packages in [
            // Shouldn't contain own key
            getPackageTwos(packageTwosFor2CETs, [0, 1]),
            // Too few
            getPackageTwos(packageTwosFor2CETs, [1]),
            getPackageTwos(packageTwosFor2CETs, []),
            // Key that shouldn't exist
            {
              ...getPackageTwos(packageTwosFor2CETs, [1, 2]),
              getPubKey(3): packageTwosFor2CETs.first,
            }
          ]) {
            expect(
              () => buildersFor2CETs.first.partTwo(packages),
              throwsArgumentError,
            );
          }

        });

        test("misbehaviour due to wrong CETs", () {
          // Same logic as for partOne
          for (final packages in [packageTwosFor2CETs, packageTwosFor4CETs]) {
            expect(
              () => buildersFor3CETs.first.partTwo(
                getPackageTwos(packages, [1, 2]),
              ),
              throwsA(isA<DLCParticipantMisbehaviour>()),
            );
          }
        });

        test("misbehaviour due to invalid partial sig", () {
          // Use packages from a different session that will have invalid
          // partial sigs for the original builders
          final altPkgTwos = createPackageTwos(getBuildersForOutcomes(2));
          expect(
            () => buildersFor2CETs.first.partTwo(
              getPackageTwos(altPkgTwos, [1, 2]),
            ),
            throwsA(isA<DLCParticipantMisbehaviour>()),
          );
        });

        test("PublicPackageTwo can be read and written", () {
          final pkgBytes = packageTwosFor2CETs.first.toBytes();
          expect(pkgBytes, PublicPackageTwo.fromBytes(pkgBytes).toBytes());
        });

        test("success", () {

          final dlc = buildersFor2CETs.first.partTwo(
            getPackageTwos(packageTwosFor2CETs, [1, 2])
            // Ensure serialisation of package 2s works
            .map(
              (key, package) => MapEntry(
                key,
                PublicPackageTwo.fromBytes(package.toBytes()),
              ),
            ),
          );

          Matcher txMatcher(
            Locktime locktime,
            Iterable<Output> expOuts,
          ) => isA<Transaction>()
            // Incomplete due to missing previous output
            .having((tx) => tx.complete, ".complete", false)
            .having((tx) => tx.locktime.value, ".locktime", locktime.value)
            .having(
              (tx) => tx.outputs.map((out) => out.toHex()),
              ".outputs",
              allOf(
                containsAll(expOuts.map((out) => out.toHex())),
                hasLength(expOuts.length),
              ),
            );

          BigInt getFee(Transaction tx) => tx.fee(
            Network.mainnet.feePerKb,
            Network.mainnet.minFee,
          )!;

          expect(dlc.terms.toBytes(), buildersFor2CETs.first.terms.toBytes());
          expect(dlc.cets, hasLength(2));
          expect(
            dlc.cets.values.map((cet) => cet.tx),
            everyElement(
              txMatcher(
                exampleOutcomeLocktime,
                [
                  getFundOutputWithValue(
                    0, BigInt.from(6000000) - getFee(dlc.cets.values.first.tx),
                  ),
                ],
              ),
            ),
          );

          // Refunds to funding amounts, removing the dust

          final sharedDust = (
            CoinUnit.coin.toSats("0.01") - getFee(dlc.refundTransaction)
          ) ~/ BigInt.from(2);

          expect(
            dlc.refundTransaction,
            txMatcher(
              dlc.terms.refundLocktime,
              [
                getFundOutputWithValue(
                  4, CoinUnit.coin.toSats("2") + sharedDust,
                ),
                getFundOutputWithValue(
                  5, CoinUnit.coin.toSats("3.99") + sharedDust,
                ),
              ],
            ),
          );

        });

        test("cannot do partTwo twice", () {
          void doPartTwo() => buildersFor2CETs.first.partTwo(
            getPackageTwos(packageTwosFor2CETs, [1, 2]),
          );
          doPartTwo();
          expect(doPartTwo, throwsStateError);
        });

      });

    });

  });

}
