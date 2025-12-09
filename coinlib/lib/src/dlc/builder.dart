import 'dart:typed_data';
import 'package:coinlib/src/common/hex.dart';
import 'package:coinlib/src/common/serial.dart';
import 'package:coinlib/src/crypto/ec_private_key.dart';
import 'package:coinlib/src/crypto/ec_public_key.dart';
import 'package:coinlib/src/dlc/create_apo_transaction.dart';
import 'package:coinlib/src/musig/library.dart';
import 'package:coinlib/src/taproot/leaves.dart';
import 'package:coinlib/src/tx/coin_selection.dart';
import 'package:coinlib/src/tx/inputs/input_signature.dart';
import 'package:coinlib/src/tx/inputs/taproot_single_script_sig_input.dart';
import 'package:coinlib/src/tx/locktime.dart';
import 'package:coinlib/src/tx/output.dart';
import 'package:coinlib/src/tx/sighash/sighash_type.dart';
import 'package:coinlib/src/tx/sighash/taproot_signature_hasher.dart';
import 'package:coinlib/src/tx/sign_details.dart';
import 'package:coinlib/src/tx/transaction.dart';
import 'ready.dart';
import 'terms.dart';

final apoSigHashType = SigHashType.all(inputs: InputSigHashOption.anyPrevOut);

class _MuSigTxState {

  final Transaction unsignedTx;
  final MuSigStatefulSigningSession muSigSession;

  _MuSigTxState(this.unsignedTx, this.muSigSession);

  MuSigPartialSig sign(
    KeyToNonceMap otherNonces,
    Output fundingOutput,
    ECPrivateKey privKey,
    ECPublicKey? adaptor,
  ) {

    final apoInput = unsignedTx.inputs.first as TaprootSingleScriptSigInput;

    final hash = TaprootSignatureHasher(
      TaprootScriptSignDetails(
        tx: unsignedTx,
        inputN: 0,
        prevOuts: [ fundingOutput ],
        leafHash: apoInput.leaf.hash,
        hashType: apoSigHashType,
      ),
    ).hash;

    return muSigSession.sign(
      otherNonces: otherNonces,
      hash: hash,
      privKey: privKey,
      adaptor: adaptor,
    );

  }

  MuSigResult complete(Iterable<(ECPublicKey, MuSigPartialSig)> partialSigs) {

    for (final (key, sig) in partialSigs) {
      if (
        !muSigSession.addPartialSignature(partialSig: sig, participantKey: key)
      ) {
        throw DLCParticipantMisbehaviour(key);
      }
    }

    return muSigSession.finish();

  }

}

class _CETState {
  final ECPublicKey orcalePoint;
  final _MuSigTxState muSigTx;
  _CETState(this.orcalePoint, this.muSigTx);
}

class DLCParticipantMisbehaviour implements Exception {
  final ECPublicKey participant;
  DLCParticipantMisbehaviour(this.participant);
  @override
  String toString() => "Participant with key ${participant.hex} misbehaved";
}

abstract class _PublicPackage<T> with Writable {

  final T _refund;
  final Map<ECPublicKey, T> _cets;

  _PublicPackage(this._refund, this._cets);
  _PublicPackage.fromReader(
    BytesReader reader,
    T Function(Uint8List) fromBytes,
  ) : this(
    fromBytes(reader.readVarSlice()),
    reader.readXPubKeyMap(() => fromBytes(reader.readVarSlice())),
  );

  Uint8List bytesOf(T obj);

  @override
  void write(Writer writer) {
    writer.writeVarSlice(bytesOf(_refund));
    writer.writeOrderedXPubkeyMap(
      _cets,
      (obj) => writer.writeVarSlice(bytesOf(obj)),
    );
  }

}

class PublicPackageOne extends _PublicPackage<MuSigPublicNonce> {

  PublicPackageOne._(super._refund, super._cets);

  PublicPackageOne.fromReader(BytesReader reader)
    : super.fromReader(reader, (bytes) => MuSigPublicNonce.fromBytes(bytes));

  PublicPackageOne.fromBytes(Uint8List bytes)
    : this.fromReader(BytesReader(bytes));

  PublicPackageOne.fromHex(String hex) : this.fromBytes(hexToBytes(hex));

  @override
  Uint8List bytesOf(MuSigPublicNonce nonce) => nonce.bytes;

}

class PublicPackageTwo extends _PublicPackage<MuSigPartialSig> {

  PublicPackageTwo._(super._refund, super._cets);

  PublicPackageTwo.fromReader(BytesReader reader)
    : super.fromReader(reader, (bytes) => MuSigPartialSig.fromBytes(bytes));

  PublicPackageTwo.fromBytes(Uint8List bytes)
    : this.fromReader(BytesReader(bytes));

  PublicPackageTwo.fromHex(String hex) : this.fromBytes(hexToBytes(hex));

  @override
  Uint8List bytesOf(MuSigPartialSig sig) => sig.bytes;

}

/// Handles the state for constructing the transactions for a DLC
class DLCStatefulBuilder {

  final DLCTerms terms;
  /// The first package to share to all other participants when building the
  /// DLC. This contains the MuSig nonces for all the CETs and RT.
  late final PublicPackageOne publicPackageOne;

  late final _MuSigTxState _refundTx;
  late final List<_CETState> _cets;

  /// Uses the given [terms] and the public key ([ourPublicKey]) of a
  /// participant to sign the transactions. If [ourPublicKey] is not in the
  /// [DLCTerms.participants] [ArgumentError] will be thrown.
  ///
  /// If [InsufficientFunds] is thrown, then the [DLCTerms] are not capable of
  /// creating CET or RT transactions that can cover the required fee.
  DLCStatefulBuilder({
    required this.terms,
    required ECPublicKey ourPublicKey,
  }) {

    if (!terms.participants.contains(ourPublicKey)) {
      throw ArgumentError("ourPublicKey must be in DLCTerms.participants");
    }

    final network = terms.network;

    final apoInput = TaprootSingleScriptSigInput.anyPrevOut(
      taproot: terms.taproot,
      leaf: TapLeafChecksig.apoInternal,
    );

    _MuSigTxState createApoTxState(
      List<Output> outputs,
      Locktime locktime,
    ) => _MuSigTxState(
      reduceOutputValuesIntoApoTransaction(
        apoInput: apoInput,
        outputs: outputs,
        locktime: locktime,
        network: network,
      ),
      MuSigStatefulSigningSession(
        keys: terms.musig,
        ourPublicKey: ourPublicKey,
      ),
    );

    _refundTx = createApoTxState(
      terms.fundAmounts.values.toList(),
      terms.refundLocktime,
    );

    _cets = terms.outcomes.entries.map(
      (entry) => _CETState(
        entry.key,
        createApoTxState(entry.value.outputs, entry.value.locktime),
      ),
    ).toList();

    publicPackageOne = PublicPackageOne._(
      _refundTx.muSigSession.ourPublicNonce,
      {
        for (final cet in _cets)
          cet.orcalePoint: cet.muSigTx.muSigSession.ourPublicNonce,
      },
    );

  }

  void _verifyAllPackages<T>(Map<ECPublicKey, _PublicPackage<T>> packages) {

    final others = terms.participants.difference({
      _refundTx.muSigSession.ourPublicKey,
    });

    if (
      others.length != packages.length
      || !others.containsAll(packages.keys)
    ) {
      throw ArgumentError(
        "Packages doesn't contain all and only other participants",
      );
    }

    // Packages should contain data for every CET (outcome)
    for (final MapEntry(key: key, value: package) in packages.entries) {
      if (
        package._cets.length != terms.outcomes.length
        || !package._cets.keys.toSet().containsAll(terms.outcomes.keys)
      ) {
        throw DLCParticipantMisbehaviour(key);
      }
    }

  }

  /// Takes a map of all other [DLCTerms.participants] to all
  /// [PublicPackageOne]s and the participant's private key to process the first
  /// interactive signing stage for the DLC.
  ///
  /// Will throw [DLCParticipantMisbehaviour] if a nonce is missing from a
  /// participant's [PublicPackageOne].
  ///
  /// Will throw [ArgumentError] if [packages] doesn't include only and all
  /// other participants.
  PublicPackageTwo partOne({
    required Map<ECPublicKey, PublicPackageOne> packages,
    required ECPrivateKey privKey,
  }) {

    _verifyAllPackages(packages);

    final fundingOutput = terms.fundingOutput;

    final refundPartialSig = _refundTx.sign(
      packages.map((key, package) => MapEntry(key, package._refund)),
      fundingOutput,
      privKey,
      null,
    );

    final cetPartialSigs = {
      for (final cet in _cets)
        cet.orcalePoint: cet.muSigTx.sign(
          packages.map(
            (key, package) => MapEntry(key, package._cets[cet.orcalePoint]!),
          ),
          fundingOutput,
          privKey,
          cet.orcalePoint,
        ),
    };

    return PublicPackageTwo._(refundPartialSig, cetPartialSigs);

  }

  /// Takes a map of all other [DLCTerms.participants] to all
  /// [PublicPackageTwo]s and completes the MuSig2 signing process for the
  /// refund transaction (RT) and all CETs.
  ///
  /// The retured [DLCReady] is available for funding to activate the DLC on the
  /// blockchain. All CETs and the RT are available once the DLC is funded and
  /// the appropriate oracle discrete-logs and/or locktimes are reached.
  ///
  /// Will throw [DLCParticipantMisbehaviour] if a partial signature is missing
  /// from a participant's [PublicPackageOne].
  ///
  /// Will throw [ArgumentError] if [packages] doesn't include only and all
  /// other participants.
  DLCReady partTwo(Map<ECPublicKey, PublicPackageTwo> packages) {

    _verifyAllPackages(packages);

    final refundSig = (
      _refundTx.complete(
        packages.entries.map((entry) => (entry.key, entry.value._refund)),
      ) as MuSigResultComplete
    ).signature;

    final signedRefundTx = _refundTx.unsignedTx.replaceInput(
      (_refundTx.unsignedTx.inputs.first as TaprootSingleScriptSigInput)
      .addSignature(SchnorrInputSignature(refundSig, apoSigHashType)),
      0,
    );

    return DLCReady(
      terms: terms,
      refundTransaction: signedRefundTx,
      cets: {
        for (final cet in _cets)
          cet.orcalePoint: CETReady(
            cet.muSigTx.unsignedTx,
            (
              cet.muSigTx.complete(
                packages.entries.map(
                  (entry) => (entry.key, entry.value._cets[cet.orcalePoint]!),
                ),
              ) as MuSigResultAdaptor
            ).adaptorSignature,
          ),
      },
    );

  }

}
