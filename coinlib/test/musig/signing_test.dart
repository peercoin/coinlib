import 'dart:typed_data';
import 'package:coinlib/coinlib.dart';
import 'package:test/test.dart';
import '../vectors/keys.dart';

final hash = Uint8List(32);

void main() {

  late final List<MuSigPrivate> privs;
  late final ECPublicKey aggregate;

  setUpAll(() async {
    await loadCoinlib();
    privs = List.generate(3, (i) => getMuSigPrivate(i));
    aggregate = privs.first.public.aggregate;
  });

  MuSigStatefulSigningSession getSession(int i) => MuSigStatefulSigningSession(
    keys: privs[i].public,
    ourPublicKey: privs[i].privateKey.pubkey,
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
      expect(bytes, MuSigPublicNonce.fromBytes(bytes).bytes);
    });

  });

  group("MuSigPartialSig", () {

    test("invalid public signature", () => expect(
      () => MuSigPartialSig.fromBytes(
        Uint8List.fromList(List.filled(32, 0xff)),
      ),
      throwsA(isA<InvalidMuSigPartialSig>()),
    ),);

    test("can read/write partial signatures", () {
      final bytes = Uint8List(32)..last = 1;
      final bytes2 = MuSigPartialSig.fromBytes(bytes).bytes;
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
        keys: privs.first.public,
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

      late List<MuSigPartialSig> partialSigs;

      bool addPartialSig(int who, int from, [ int? keyI ])
        => sessions[who].addPartialSignature(
          partialSig: partialSigs[from],
          participantKey: getPubKey(keyI ?? from),
        );

      void addAllPartialSigs() {
        for (int who = 0; who < 3; who++) {
          for (int from = 0; from < 3; from++) {
            if (who != from) {
              addPartialSig(who, from);
            }
          }
        }
      }

      void expectIdenticalValidSigs(Iterable<SchnorrSignature> sigs) {
        expect(
          sigs.map((sig) => sig.verify(aggregate, hash)),
          everyElement(true),
        );
        expect(
          sigs.map((sig) => bytesToHex(sig.data)).toSet(),
          hasLength(1),
        );
      }

      test("sign failure", () {

        void expectInvalid(
          KeyToNonceMap otherNonces,
          [
            int hashLen = 32,
            int key = 0,
          ]
        ) => expect(
          () => sessions.first.sign(
            otherNonces: otherNonces,
            hash: Uint8List(hashLen),
            privKey: privs[key].privateKey,
          ),
          throwsArgumentError,
        );

        // Wrong key
        expectInvalid(otherNoncesMaps.first, 32, 1);

        // Bad hash size
        for (final i in [31, 33]) {
          expectInvalid(otherNoncesMaps.first, i);
        }

        // Too few nonces
        expectInvalid({ getPubKey(1): sessions[1].ourPublicNonce });

        // Wrong nonces
        expectInvalid(otherNoncesMaps.last);

      });

      test("cannot add partial sig before sign", () => expect(
        () => sessions.first.addPartialSignature(
          partialSig: MuSigPartialSig.fromBytes(Uint8List(32)..last = 1),
          participantKey: getPubKey(1),
        ),
        throwsStateError,
      ),);

      void expectCannotFinish() => expect(
        () => sessions.first.finish(),
        throwsStateError,
      );

      test("cannot finish before sign", expectCannotFinish);

      group("given partial signatures", () {

        setUp(() {
          partialSigs = List.generate(
            3,
            (i) => sessions[i].sign(
              otherNonces: otherNoncesMaps[i],
              hash: hash,
              privKey: privs[i].privateKey,
            ),
          );
        });

        test("cannot sign twice", () => expect(
          () => sessions.first.sign(
            otherNonces: otherNoncesMaps.first,
            hash: hash,
            privKey: privs.first.privateKey,
          ),
          throwsStateError,
        ),);

        test("cannot add own partial sig", () => expect(
          () => addPartialSig(0, 0),
          throwsArgumentError,
        ),);

        test("invalid partial sig", () => expect(
          addPartialSig(0, 0, 1),
          false,
        ),);

        test("can add partial sigs", () {

          void expectHave(int i, bool have)
            => expect(sessions.first.havePartialSignature(getPubKey(i)), have);

          for (int i = 1; i < 3; i++) {
            expectHave(i, false);
            expect(addPartialSig(0, i), true);
            expectHave(i, true);
          }

        });

        test("cannot finish before all partial sigs", () {
          expectCannotFinish();
          addPartialSig(0, 1);
          expectCannotFinish();
        });

        group("given added all partial sigs", () {

          setUp(() => addAllPartialSigs());

          test("cannot add partial sig more than once", () => expect(
            () => addPartialSig(0, 1),
            throwsStateError,
          ),);

          test("finish gives identical and valid signatures", () {

            final sigs = sessions.map(
              (session) => (session.finish() as MuSigResultComplete).signature,
            ).toList();

            expectIdenticalValidSigs(sigs);

          });

        });

      });

      test("can sign with adaptor", () {

        final adaptorScalar = getPrivKey(0);
        partialSigs = List.generate(
          3,
          (i) => sessions[i].sign(
            otherNonces: otherNoncesMaps[i],
            hash: hash,
            privKey: privs[i].privateKey,
            adaptor: adaptorScalar.pubkey,
          ),
        );
        addAllPartialSigs();

        final adaptorSigs = sessions.map(
          (session) => (
            session.finish() as MuSigResultAdaptor
          ).adaptorSignature,
        ).toList();

        expect(
          adaptorSigs.map((sig) => sig.preSig.verify(aggregate, hash)),
          everyElement(false),
        );

        final completeSigs = adaptorSigs.map((sig) => sig.adapt(adaptorScalar));

        expectIdenticalValidSigs(completeSigs);

        expect(
          adaptorSigs.map((sig) => sig.extract(completeSigs.first).pubkey),
          everyElement(adaptorScalar.pubkey),
        );

      });

    });

  });

}
