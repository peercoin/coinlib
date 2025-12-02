import 'package:coinlib/coinlib.dart';
import 'package:test/test.dart';
import '../vectors/tx.dart';

final exampleLocktime = MedianTimeLocktime(DateTime(2026));
final exampleOutcomeLocktime = MedianTimeLocktime(DateTime(2025, 12));

CETOutcome getOutcome(List<String> coins, [ Locktime? locktime ]) => CETOutcome(
  outputs: [
    for (final coinAmt in coins) Output.fromScriptBytes(
      CoinUnit.coin.toSats(coinAmt),
      exampleOutput.scriptPubKey,
    ),
  ],
  locktime: locktime ?? exampleOutcomeLocktime,
);

void expectInvalidTerms(void Function() f) => expect(
  f, throwsA(isA<InvalidDLCTerms>()),
);
