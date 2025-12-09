import 'package:coinlib/coinlib.dart';
import 'package:test/test.dart';
import '../vectors/keys.dart';

final exampleLocktime = MedianTimeLocktime(DateTime(2026));
final exampleOutcomeLocktime = MedianTimeLocktime(DateTime(2025, 12));

Output getFundOutputWithValue(int pk, BigInt value) => Output.fromProgram(
  value,
  P2TR.fromTweakedKey(getPubKey(pk)),
);

Output getFundOutput(int pk, String coin) => getFundOutputWithValue(
  pk, CoinUnit.coin.toSats(coin),
);

CETOutcome getOutcome(List<String> coins, [ Locktime? locktime ]) => CETOutcome(
  outputs: [for (final coinAmt in coins) getFundOutput(0, coinAmt)],
  locktime: locktime ?? exampleOutcomeLocktime,
);

final exampleTerms = DLCTerms(
  participants: {
    getPubKey(0),
    getPubKey(1, false),
  },
  fundAmounts: {
    // Can be different from participants
    getPubKey(0): getFundOutput(0, "2"),
    getPubKey(2, false): getFundOutput(2, "4"),
  },
  outcomes: {
    getPubKey(3): getOutcome(["1", "5"]),
    getPubKey(4, false): getOutcome(["6"]),
  },
  refundLocktime: exampleLocktime,
  network: Network.mainnet,
);

DLCTerms getTerms({
  Set<ECPublicKey>? participants,
  Map<ECPublicKey, Output>? fundAmounts,
  Map<ECPublicKey, CETOutcome>? outcomes,
  Locktime? locktime,
}) => DLCTerms(
  participants: participants ?? exampleTerms.participants,
  fundAmounts: fundAmounts ?? exampleTerms.fundAmounts,
  outcomes: outcomes ?? exampleTerms.outcomes,
  refundLocktime: locktime ?? exampleLocktime,
  network: Network.mainnet,
);

void expectInvalidTerms(void Function() f) => expect(
  f, throwsA(isA<InvalidDLCTerms>()),
);
