import 'package:coinlib/src/crypto/ec_private_key.dart';
import 'package:coinlib/src/crypto/ec_public_key.dart';
import 'package:coinlib/src/scripts/programs/p2pkh.dart';
import 'package:coinlib/src/scripts/script.dart';
import 'package:coinlib/src/tx/transaction.dart';
import 'input_signature.dart';

/// A mixin for Public Key Hash input types, providing the [ECPublicKey] and
/// [InputSignature] required in these inputs.
abstract mixin class PKHInput {

  ECPublicKey get publicKey;
  InputSignature? get insig;
  PKHInput addSignature(InputSignature insig);
  bool get complete => insig != null;
  Script get scriptCode => P2PKH.fromPublicKey(publicKey).script;

  ECPrivateKey checkKey(ECPrivateKey key) {
    if (key.pubkey != publicKey) {
      throw CannotSignInput("Incorrect key for input");
    }
    return key;
  }

}
