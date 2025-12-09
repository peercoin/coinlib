import 'package:coinlib/src/crypto/ec_public_key.dart';
import 'package:coinlib/src/crypto/schnorr_adaptor_signature.dart';
import 'package:coinlib/src/tx/transaction.dart';
import 'terms.dart';

class CETReady {

  final Transaction tx;
  final SchnorrAdaptorSignature adaptorSig;

  CETReady(this.tx, this.adaptorSig);

}

class DLCReady {

  final DLCTerms terms;
  final Transaction refundTransaction;
  // TODO: Make immutable
  final Map<ECPublicKey, CETReady> cets;

  DLCReady({
    required this.terms,
    required this.refundTransaction,
    required this.cets,
  });

}
