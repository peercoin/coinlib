import 'secp256k1_web.dart' if (dart.library.io) 'secp256k1_io.dart';
export 'secp256k1_web.dart' if (dart.library.io) 'secp256k1_io.dart'
  show OpaqueMuSigCache, OpaqueMuSigSecretNonce, OpaqueMuSigPublicNonce,
  OpaqueMuSigSession, OpaqueMuSigPartialSig;
export 'secp256k1_base.dart' show Secp256k1Exception;

final secp256k1 = Secp256k1();
