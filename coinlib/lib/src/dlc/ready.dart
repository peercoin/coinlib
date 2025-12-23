part of "library.dart";

class CETReady with Writable {

  final Transaction tx;
  final SchnorrAdaptorSignature adaptorSig;

  CETReady(this.tx, this.adaptorSig);
  CETReady.fromReader(BytesReader reader)
    : tx = Transaction.fromReader(reader),
      adaptorSig = SchnorrAdaptorSignature.fromReader(reader);
  CETReady.fromBytes(Uint8List bytes) : this.fromReader(BytesReader(bytes));

  @override
  void write(Writer writer) {
    tx.write(writer);
    adaptorSig.write(writer);
  }

}

/// Carries data for a DLC with fully signed [cets] and a [refundTransaction].
/// After this has been created, the DLC requires funding before it can be used.
class DLCReady with Writable {

  final Transaction refundTransaction;
  final Map<ECPublicKey, CETReady> cets;

  DLCReady({
    required this.refundTransaction,
    required Map<ECPublicKey, CETReady> cets,
  }) : cets = Map.unmodifiable(cets);
  DLCReady.fromReader(BytesReader reader)
    : refundTransaction = Transaction.fromReader(reader),
      cets = reader.readXPubKeyMap(() => CETReady.fromReader(reader));
  DLCReady.fromBytes(Uint8List bytes) : this.fromReader(BytesReader(bytes));

  @override
  void write(Writer writer) {
    refundTransaction.write(writer);
    writer.writeOrderedXPubkeyMap(cets, (cet) => cet.write(writer));
  }

}
