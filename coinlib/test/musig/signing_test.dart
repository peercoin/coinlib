import 'dart:typed_data';
import 'package:coinlib/coinlib.dart';
import 'package:test/test.dart';
import '../vectors/keys.dart';

void main() {

  late final MuSigPublicKeys keys;

  setUpAll(() async {
    await loadCoinlib();
    keys = getMuSigKeys();
  });

  MuSigStatefulSigningSession getSession(int i) => MuSigStatefulSigningSession(
    keys: keys,
    ourPublicKey: getPubKey(i),
  );

  Uint8List getNonceBytes() => getSession(0).ourPublicNonce.bytes;

  group("MuSigPublicNonce", () {

    test("invalid public nonces", () {
      final bytes = getNonceBytes();
      for (final invalid in [
        [0xff, ...bytes.skip(1)],
        [...getNonceBytes(), 00],
      ]) {
        expect(
          () => MuSigPublicNonce.fromBytes(Uint8List.fromList(invalid)),
          throwsA(isA<InvalidMuSigPublicNonce>()),
        );
      }
    });

    test("can read/write public nonces", () {
      final bytes = getNonceBytes();
      final bytes2 = MuSigPublicNonce.fromBytes(bytes).bytes;
      expect(bytes, bytes2);
    });

  });

  group("MuSigStatefulSigningSession", () {

    test(
      "creates unique public nonces",
      () => expect(getNonceBytes(), isNot(getNonceBytes())),
    );

    test("ourPublicKey must be in keys", () => expect(
      () => MuSigStatefulSigningSession(
        keys: keys,
        ourPublicKey: getPubKey(3),
      ),
      throwsArgumentError,
    ),);

    group("given sessions", () {

      late List<MuSigStatefulSigningSession> sessions;
      late List<KeyToNonceMap> otherNoncesMaps;
      setUp(() {
        sessions = List.generate(3, (i) => getSession(i));
        otherNoncesMaps = List.generate(
          3,
          (i) => {
            for (int j = 0; j < 3; j++)
              if (j != i) getPubKey(j): sessions[j].ourPublicNonce,
          },
        );
      });

      test("prepare failure", () {

        void expectInvalid(
          KeyToNonceMap otherNonces,
          int hashLen,
        ) => expect(
          () => sessions.first.prepare(
            otherNonces: otherNonces,
            hash: Uint8List(hashLen),
          ),
          throwsArgumentError,
        );

        // Bad hash size
        for (final i in [31, 33]) {
          expectInvalid(otherNoncesMaps.first, i);
        }

        // Too few nonces
        expectInvalid(
          { getPubKey(1): sessions[1].ourPublicNonce },
          32,
        );

        // Wrong public key
        expectInvalid(otherNoncesMaps.last, 32);

      });

      group("given prepared", () {

        final hash = Uint8List(32);

        setUp(() {
          for (int i = 0; i < 3; i++) {
            sessions[i].prepare(otherNonces: otherNoncesMaps[i], hash: hash);
          }
        });

        test("cannot prepare twice", () => expect(
          () => sessions.first.prepare(
            otherNonces: otherNoncesMaps.first,
            hash: hash,
          ),
          throwsStateError,
        ),);

      });

      test("can sign with adaptor", () {
        // TODO
      });

    });

  });

}
