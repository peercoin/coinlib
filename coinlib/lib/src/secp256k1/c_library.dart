import 'package:native_toolchain_c/native_toolchain_c.dart';

/// Native build shared by the build and link hooks.
CLibrary secp256k1Library({Uri? sourceRoot}) => CLibrary(
  name: 'secp256k1',
  assetName: 'src/secp256k1/secp256k1.ffi.g.dart',
  sources: sourceRoot == null
      ? const []
      : [
          sourceRoot.resolve('src/secp256k1.c').toFilePath(),
          sourceRoot.resolve('src/precomputed_ecmult.c').toFilePath(),
          sourceRoot.resolve('src/precomputed_ecmult_gen.c').toFilePath(),
        ],
  includes: sourceRoot == null
      ? const []
      : [sourceRoot.resolve('include/').toFilePath()],
  frameworks: [],
  defines: {
    'COMB_BLOCKS': '43',
    'COMB_TEETH': '6',
    'ECMULT_WINDOW_SIZE': '15',
    'ENABLE_MODULE_ECDH': '1',
    'ENABLE_MODULE_EXTRAKEYS': '1',
    'ENABLE_MODULE_MUSIG': '1',
    'ENABLE_MODULE_RECOVERY': '1',
    'ENABLE_MODULE_SCHNORRSIG': '1',
    'SECP256K1_DLL_EXPORT': '1',
  },
  std: 'c90',
);
