import 'secp256k1_web.dart' if (dart.library.io) 'secp256k1_io.dart';
export 'secp256k1_web.dart' if (dart.library.io) 'secp256k1_io.dart'
  show MuSigCache;

final secp256k1 = Secp256k1();
