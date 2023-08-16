import 'package:coinlib/src/crypto/ec_public_key.dart';
import 'package:coinlib/src/tx/input_signature.dart';

/// A mixin for Public Key Hash input types, providing the [ECPublicKey] and
/// [InputSignature] required in these inputs.
abstract mixin class PKHInput {
  ECPublicKey get publicKey;
  InputSignature? get insig;
  PKHInput addSignature(InputSignature insig);
  bool get complete => insig != null;
}
