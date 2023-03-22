# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(coinlib_library VERSION 1.0.0 LANGUAGES C)

# Build secp256k1 using the ExternalProject module

include(ExternalProject)

set(
  SECP256K1_OUTDIR
  ${CMAKE_BINARY_DIR}/secp256k1/output
)

ExternalProject_Add(

  secp256k1_external

  GIT_REPOSITORY https://github.com/bitcoin-core/secp256k1
  GIT_TAG 21ffe4b22a9683cf24ae0763359e401d1284cc7a
  SOURCE_DIR "${CMAKE_BINARY_DIR}/secp256k1/src"

  CONFIGURE_COMMAND ./autogen.sh
  COMMAND ./configure --prefix=${SECP256K1_OUTDIR}
    --enable-module-recovery --disable-tests
    --disable-exhaustive-tests --disable-benchmark
    CFLAGS=-O2

  BUILD_COMMAND make
  INSTALL_COMMAND make install

  # Remove versioned sonames to load library directly
  COMMAND rm ${SECP256K1_OUTDIR}/lib/libsecp256k1.so
  COMMAND mv ${SECP256K1_OUTDIR}/lib/libsecp256k1.so.1.0.0 ${SECP256K1_OUTDIR}/lib/libsecp256k1.so

  BUILD_IN_SOURCE TRUE

)

