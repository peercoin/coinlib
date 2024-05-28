import 'dart:convert';
import 'dart:io';
import 'docker_util.dart';
import 'util.dart';

/// Run Dockerfile content to generate wasm file and then convert into a dart
/// file with the wasm as a Uint8List static variable

String dockerfile = r"""
FROM debian:bookworm

# Install dependenices
RUN apt-get update -y \
  && apt-get install -y autoconf libtool build-essential git wget

# Download and install wasi-sdk

ENV WASI_VERSION=19
ENV WASI_VERSION_FULL=${WASI_VERSION}.0
ENV WASI_SDK_PATH=/wasi-sdk-${WASI_VERSION_FULL}
ENV WASI_ARCHIVE=wasi-sdk-${WASI_VERSION_FULL}-linux.tar.gz

RUN wget -nv https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-${WASI_VERSION}/$WASI_ARCHIVE
RUN tar xvf $WASI_ARCHIVE
RUN rm $WASI_ARCHIVE

# Clone libsecp256k1 and use v0.5.0
RUN git clone https://github.com/bitcoin-core/secp256k1 \
  && cd secp256k1 \
  && git checkout e3a885d42a7800c1ccebad94ad1e2b82c4df5c65
WORKDIR /secp256k1

# Build using wasi-sdk
RUN ./autogen.sh
RUN ./configure \
  --enable-module-recovery --disable-tests --disable-shared \
  --disable-exhaustive-tests --disable-benchmark \
  --with-sysroot=${WASI_SDK_PATH}/share/wasi-sysroot \
  --host=wasm32 --target=wasm32-unknown-wasi \
  CFLAGS="-O2 -fPIC" CC=${WASI_SDK_PATH}/bin/clang
RUN make

# Link output with wasi standard library and export required functions
RUN mkdir output
RUN ${WASI_SDK_PATH}/bin/wasm-ld \
  -o output/secp256k1.wasm \
  --no-entry \
  --export malloc \
  --export free \
  --export secp256k1_context_create \
  --export secp256k1_context_randomize \
  --export secp256k1_ec_seckey_verify \
  --export secp256k1_ec_pubkey_create \
  --export secp256k1_ec_pubkey_serialize \
  --export secp256k1_ec_pubkey_parse \
  --export secp256k1_ecdsa_sign \
  --export secp256k1_ecdsa_signature_serialize_compact \
  --export secp256k1_ecdsa_signature_parse_compact \
  --export secp256k1_ecdsa_signature_normalize \
  --export secp256k1_ecdsa_verify \
  --export secp256k1_ecdsa_signature_serialize_der \
  --export secp256k1_ecdsa_signature_parse_der \
  --export secp256k1_ecdsa_recoverable_signature_serialize_compact \
  --export secp256k1_ecdsa_recoverable_signature_parse_compact \
  --export secp256k1_ecdsa_sign_recoverable \
  --export secp256k1_ecdsa_recover \
  --export secp256k1_ec_seckey_tweak_add \
  --export secp256k1_ec_pubkey_tweak_add \
  --export secp256k1_ec_seckey_negate \
  --export secp256k1_keypair_create \
  --export secp256k1_xonly_pubkey_parse \
  --export secp256k1_schnorrsig_sign32 \
  --export secp256k1_schnorrsig_verify \
  --export secp256k1_ecdh \
  # The secp256k1 library object files
  src/libsecp256k1_la-secp256k1.o \
  src/libsecp256k1_precomputed_la-precomputed_ecmult.o \
  src/libsecp256k1_precomputed_la-precomputed_ecmult_gen.o \
  # Need to include libc for wasi here as it isn't done for us
  ${WASI_SDK_PATH}/share/wasi-sysroot/lib/wasm32-wasi/libc.a \
  # Need to include another library from clang that isn't included either
  # See https://github.com/WebAssembly/wasi-libc/issues/98
  ${WASI_SDK_PATH}/lib/clang/15.0.7/lib/wasi/libclang_rt.builtins-wasm32.a
""";

void binaryFileToDart(String inPath, String outPath, String name) {
  final bytes = File(inPath).readAsBytesSync();
  final b64 = base64Encode(bytes);
  final output = """\
import 'dart:convert';
final $name = base64Decode("$b64");""";
  File(outPath).writeAsStringSync(output, flush: true);
}

void main() async {

  String cmd = await getDockerCmd();
  print("Using $cmd to run dockerfile");

  // Create temporary directory to receive wasm file
  final tmpDir = createTmpDir();
  print("Temporary build artifacts at $tmpDir");

  // Build secp256k1 to wasm and copy wasm file to tempdir
  if (!await dockerRun(
      cmd,
      dockerfile,
      "coinlib_build_secp256k1_wasm",
      tmpDir,
      "cp output/secp256k1.wasm /host/secp256k1.wasm",
  )) {
    exit(1);
  }

  // Convert secp256k1.wasm file into Uint8List in dart file
  binaryFileToDart(
    "$tmpDir/secp256k1.wasm",
    "${Directory.current.path}/lib/src/secp256k1/secp256k1.wasm.g.dart",
    "secp256k1WasmData",
  );
  print("Output secp256k1.wasm.g.dart successfully");

}
