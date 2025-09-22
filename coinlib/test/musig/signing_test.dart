import 'dart:typed_data';

import 'package:coinlib/coinlib.dart';
import 'package:coinlib/src/musig/signing.dart';
import 'package:test/test.dart';
import '../vectors/keys.dart';

void main() {

  group("MuSigStatefulSigningSession", () {

    setUpAll(loadCoinlib);

    test("creates unique public nonces", () {

      final keys = getMuSigKeys();
      final ourKey = keys.pubKeys.first;
      Uint8List getNonce() => MuSigStatefulSigningSession(
        keys: keys,
        ourPublicKey: ourKey,
      ).ourPublicNonce;

      expect(getNonce(), isNot(getNonce()));

    });

  });

}
