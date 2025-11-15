import 'dart:typed_data';
import 'package:coinlib/src/common/hex.dart';
import 'package:coinlib/src/common/serial.dart';
import 'package:coinlib/src/crypto/ec_public_key.dart';
import 'package:coinlib/src/network.dart';
import 'package:coinlib/src/tx/locktime.dart';
import 'package:coinlib/src/tx/output.dart';
import 'package:coinlib/src/tx/transaction.dart';

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

}

BigInt addBigInts(Iterable<BigInt> ints) => ints.fold(
  BigInt.zero, (a, b) => a+b,
);

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

  BigInt get totalValue => addBigInts(outputs.map((out) => out.value));

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

  /// A list of participants that must sign all CETs and RTs for the DLCs.
  final List<ECPublicKey> participants;

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

  /// May throw [InvalidDLCTerms].
  DLCTerms({
    required List<ECPublicKey> participants,
    required Map<ECPublicKey, BigInt> fundAmounts,
    required Map<ECPublicKey, CETOutputs> outcomes,
    required this.refundLocktime,
    required Network network,
  }) :
    participants = List.unmodifiable(participants),
    fundAmounts = Map.unmodifiable(fundAmounts),
    outcomes = Map.unmodifiable(outcomes) {

    // There should not be any funding amount for a participant which is under
    // the minimum output
    if (fundAmounts.values.any((val) => val.compareTo(network.minOutput) < 0)) {
      throw InvalidDLCTerms.smallFunding(network.minOutput);
    }

    // The outcome output amounts must add up to the total funded amount
    final totalToFund = addBigInts(fundAmounts.values);
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

    return DLCTerms(
      participants: reader.readPubKeyVector(),
      fundAmounts: reader.readPubKeyMap(() => reader.readVarInt()),
      outcomes: reader.readPubKeyMap(
        () => CETOutputs(
          reader.readListWithFunc(() => Output.fromReader(reader)),
          network,
        ),
      ),
      refundLocktime: reader.readLocktime(),
      network: network,
    );

  }

  factory DLCTerms.fromBytes(Uint8List bytes, Network network)
    => DLCTerms.fromReader(BytesReader(bytes), network);

  factory DLCTerms.fromHex(String hex, Network network)
    => DLCTerms.fromBytes(hexToBytes(hex), network);

  @override
  /// The public keys will be written as compressed public keys
  void write(Writer writer) {
    writer.writeUInt16(version);
    writer.writePubKeyVector(participants);
    writer.writePubKeyMap(
      fundAmounts,
      (amount) => writer.writeVarInt(amount),
    );
    writer.writePubKeyMap(
      outcomes,
      (outputs) => writer.writeWritableVector(outputs.outputs),
    );
    writer.writeLocktime(refundLocktime);
  }

}
