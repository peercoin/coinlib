# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(coinlib_library VERSION 1.0.0 LANGUAGES C)

# Build secp256k1 using the ExternalProject module

include(ExternalProject)

set(SECP256K1_PREFIX ${CMAKE_BINARY_DIR}/secp256k1)
set(SECP256K1_CFLAGS "-O2 ${CMAKE_C_FLAGS}")

ExternalProject_Add(

  secp256k1

  GIT_REPOSITORY https://github.com/bitcoin-core/secp256k1
  GIT_TAG bdf39000b9c6a0818e7149ccb500873d079e6e85 # v0.3.0 with cmake system

  PREFIX ${SECP256K1_PREFIX}

  CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${SECP256K1_PREFIX}
    -DSECP256K1_ENABLE_MODULE_RECOVERY=ON
    -DSECP256K1_BUILD_TESTS=OFF
    -DSECP256K1_BUILD_EXHAUSTIVE_TESTS=OFF
    -DSECP256K1_BUILD_BENCHMARK=OFF
    -DCMAKE_C_FLAGS=${SECP256K1_CFLAGS}

)

# Move the versioned .so file to an unversioned .so file. This cannot be done in
# ExternalProject_Add as it causes an error
add_custom_command(
  TARGET secp256k1
  POST_BUILD
  COMMAND mv ${SECP256K1_PREFIX}/lib/libsecp256k1.so.2.0.0 ${SECP256K1_PREFIX}/lib/libsecp256k1.so
)

