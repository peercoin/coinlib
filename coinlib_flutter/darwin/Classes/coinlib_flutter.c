// Relative import to be able to reuse the C sources.
#include "../build/secp256k1/src/secp256k1.c"
#include "../build/secp256k1/src/precompute_ecmult_gen.c"
#include "../build/secp256k1/src/precomputed_ecmult_gen.c"
#include "../build/secp256k1/src/precomputed_ecmult.c"
#include "../build/secp256k1/src/modules/extrakeys/main_impl.h"
#include "../build/secp256k1/src/modules/schnorrsig/main_impl.h"
#include "../build/secp256k1/src/modules/ecdh/main_impl.h"
#include "../build/secp256k1/src/modules/recovery/main_impl.h"
