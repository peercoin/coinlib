import 'dart:typed_data';
import 'package:coinlib/src/common/bytes.dart';
import 'package:coinlib/src/common/hex.dart';
import 'package:coinlib/src/common/serial.dart';
import 'package:coinlib/src/crypto/ec_public_key.dart';
import 'package:coinlib/src/crypto/hash.dart';
import 'package:coinlib/src/musig/library.dart';
import 'package:coinlib/src/network.dart';
import 'package:coinlib/src/tx/locktime.dart';
import 'package:coinlib/src/tx/output.dart';
import 'package:coinlib/src/tx/transaction.dart';
import 'package:collection/collection.dart';

class InvalidDLCTerms implements Exception {

  final String message;

  InvalidDLCTerms(this.message);
  InvalidDLCTerms.badOutcomeMatch()
    : this("Contains outcome output amounts not matching the funded amount");
  InvalidDLCTerms.badVersion(int v)
    : this("Version $v isn't allowed. Only v1 is supported.");
  InvalidDLCTerms.noOutputs() : this("CETOutputs have no outputs");
  InvalidDLCTerms.smallOutput(BigInt min)
    : this("Contains output value less than min of $min");
  InvalidDLCTerms.smallFunding(BigInt min)
    : this("Contains funding value less than min of $min");
  InvalidDLCTerms.notOrdered()
    : this("The input bytes contain out-of-order keys");

}

BigInt _addBigInts(Iterable<BigInt> ints) => ints.fold(
  BigInt.zero, (a, b) => a+b,
);

Map<ECPublicKey, T> _xOnlyUnmodifiableMap<T>(Map<ECPublicKey, T> map)
  => Map.unmodifiable(map.map((key, v) => MapEntry(key.xonly, v)));

Map<ECPublicKey, T> _readPubKeyMap<T>(
  BytesReader reader,
  T Function() readValue,
) => Map.fromEntries(
  Iterable.generate(
    reader.readVarInt().toInt(),
    (_) => MapEntry(
      ECPublicKey.fromXOnly(reader.readSlice(32)),
      readValue(),
    ),
  ),
);

void _writeOrderedPubkeyMap<T>(
  Writer writer,
  Map<ECPublicKey, T> map,
  void Function(T) writeValue,
) {

  writer.writeVarInt(BigInt.from(map.length));

  final orderedEntries = map.entries
    .map((entry) => MapEntry(entry.key.x, entry.value))
    .sortedByCompare((entry) => entry.key, compareBytes);

  for (final entry in orderedEntries) {
    writer.writeSlice(entry.key);
    writeValue(entry.value);
  }

}

/// A CET will pay to the [outputs] with the value of each output evenly reduced
/// to cover the transaction fee.
class CETOutputs {

  /// The outputs to be included in the CET of this outcome. The values must
  /// add up to the amounts being funded by the participants in
  /// [DLCTerms.fundAmounts].
  ///
  /// The [Output.value] for each output will have an equal share of the
  /// transaction fee removed when the transaction is constructed. When doing
  /// this, if any of the outputs fall below the dust amount, they will be
  /// removed first.
  final List<Output> outputs;

  /// Requires that the output values are at least [Network.minOutput] or
  /// [InvalidDLCTerms] may be thrown.
  CETOutputs(this.outputs, Network network) {
    if (outputs.isEmpty) {
      throw InvalidDLCTerms.noOutputs();
    }
    if (outputs.any((out) => out.value.compareTo(network.minOutput) < 0)) {
      throw InvalidDLCTerms.smallOutput(network.minOutput);
    }
  }

  BigInt get totalValue => _addBigInts(outputs.map((out) => out.value));

}

/// Specifies the terms of a DLC contract to be agreed upon by all
/// [participants].
///
/// DLCs use CETs signed with adaptor signatures to be completed using an
/// oracle. CETs do not have a refund mechanism as they can only be broadcast
/// when the oracle reveals the associated scalar.
///
/// Funding transactions are only created after all CETs and a Refund
/// Transaction have been created. APO is used to allow creation of the CETs and
/// the Refund Transaction before the Funding Transaction.
class DLCTerms with Writable {

  /// The version of the protocol is currently 1
  static final int version = 1;

  /// A set of participants that must sign all CETs and RTs for the DLCs.
  final Set<ECPublicKey> participants;

  /// How much each participant is expected to fund the DLC. A public key may
  /// refer to a funder outside of [participants] if they are not expected to
  /// sign.
  ///
  /// Note that these participants will also be expected to pay an equal
  /// contribution to the Funding Transaction fee in excess of these amounts.
  final Map<ECPublicKey, BigInt> fundAmounts;

  /// Maps oracle adaptor points to [CETOutputs] that contain the output
  /// information to include in Contract Execution Transactions.
  ///
  /// The points can be arbitrarily announced by the oracle in association with
  /// each outcome.
  ///
  /// Alternatively, as proposed in the original DLC designs, a point can be
  /// the S point of an oracle signature where `S = R + eP`, and where `R` is a
  /// pre-disclosed nonce point, `P` is the oracle public key and `e` is the
  /// commitment of the nonce and message representing the outcome. This allows
  /// computation of multiple adaptor points for multiple outcome messages given
  /// the R and P points. coinlib doesn't provide an abstraction for
  /// constructing adaptor points via signatures this way.
  final Map<ECPublicKey, CETOutputs> outcomes;

  /// The [Transaction.locktime] to be used in the Refund Transaction where
  /// participants may regain access to funds.
  ///
  /// Ought to be in the future to give enough time for the oracle event and
  /// broadcast of a CET, but this is not checked.
  final Locktime refundLocktime;

  /// All [ECPublicKey]s will be coerced into x-only public keys. May throw
  /// [InvalidDLCTerms].
  DLCTerms({
    required Set<ECPublicKey> participants,
    required Map<ECPublicKey, BigInt> fundAmounts,
    required Map<ECPublicKey, CETOutputs> outcomes,
    required this.refundLocktime,
    required Network network,
  }) :
    participants = Set.unmodifiable(participants.map((key) => key.xonly)),
    fundAmounts = _xOnlyUnmodifiableMap(fundAmounts),
    outcomes = _xOnlyUnmodifiableMap(outcomes) {

    // There should not be any funding amount for a participant which is under
    // the minimum output
    if (fundAmounts.values.any((val) => val.compareTo(network.minOutput) < 0)) {
      throw InvalidDLCTerms.smallFunding(network.minOutput);
    }

    // The outcome output amounts must add up to the total funded amount
    final totalToFund = _addBigInts(fundAmounts.values);
    if (
      outcomes.values.any(
        (outcome) => outcome.totalValue.compareTo(totalToFund) != 0,
      )
    ) {
      throw InvalidDLCTerms.badOutcomeMatch();
    }

  }

  /// There are no size limits, so the caller may wish to enforce a reasonable
  /// size for the serialised data. Public keys will always be serialised and
  /// read as compressed keys.
  ///
  /// May throw [InvalidDLCTerms].
  factory DLCTerms.fromReader(BytesReader reader, Network network) {

    if (reader.readUInt16() != version) {
      throw InvalidDLCTerms.badVersion(version);
    }

    final terms = DLCTerms(
      participants: Iterable.generate(
        reader.readVarInt().toInt(),
        (_) => ECPublicKey.fromXOnly(reader.readSlice(32)),
      ).toSet(),
      fundAmounts: _readPubKeyMap(reader, () => reader.readVarInt()),
      outcomes: _readPubKeyMap(
        reader,
        () => CETOutputs(
          reader.readListWithFunc(() => Output.fromReader(reader)),
          network,
        ),
      ),
      refundLocktime: reader.readLocktime(),
      network: network,
    );

    // Check public keys were ordered correctly
    // This is not the optimal way to do this but is simple
    final inBytes = reader.bytes.buffer.asUint8List();
    if (compareBytes(inBytes, terms.toBytes()) != 0) {
      throw InvalidDLCTerms.notOrdered();
    }

    return terms;

  }

  factory DLCTerms.fromBytes(Uint8List bytes, Network network)
    => DLCTerms.fromReader(BytesReader(bytes), network);

  factory DLCTerms.fromHex(String hex, Network network)
    => DLCTerms.fromBytes(hexToBytes(hex), network);

  @override
  void write(Writer writer) {

    writer.writeUInt16(version);

    // Sort the public keys ensuring the written set is always the same
    writer.writeVarInt(BigInt.from(participants.length));
    for (final key in participants.map((key) => key.x).sorted(compareBytes)) {
      writer.writeSlice(key);
    }

    _writeOrderedPubkeyMap(
      writer,
      fundAmounts,
      (amt) => writer.writeVarInt(amt),
    );

    _writeOrderedPubkeyMap(
      writer,
      outcomes,
      (outputs) => writer.writeWritableVector(outputs.outputs),
    );

    writer.writeLocktime(refundLocktime);

  }

  // Use a tagged hasher to avoid potential conflicts that could lead to key
  // reuse
  static final _dlcKeyTweakHash = getTaggedHasher("CoinlibDLCKeyTweak");
  Uint8List? _tweakHashCache;

  /// Obtains the tweaked MuSig2 aggregate key for this DLC. The key is
  /// aggregated from the [participants] and then tweaked from the [DLCTerms]
  /// data to prevent key-reuse across multiple DLCs in the event that
  /// participants re-use their individual keys.
  MuSigPublicKeys get musig => MuSigPublicKeys(participants).tweak(
    _tweakHashCache ??= _dlcKeyTweakHash(toBytes()),
  );

}
