import 'dart:io';
import 'docker_util.dart';

/// Build the linux shared library for secp256k1 using the Dockerfile string

String dockerfile = r"""
FROM debian:bookworm

# Install dependenices
RUN apt-get update -y && apt-get install -y cmake git

# Clone libsecp256k1-coinlib v0.7.0
RUN git clone https://github.com/peercoin/secp256k1-coinlib \
  && cd secp256k1-coinlib \
  && git checkout 69018e5b939d8d540ca6b237945100f4ecb5681e

WORKDIR /secp256k1-coinlib

# Build shared library for linux
RUN cmake -B build \
      -DSECP256K1_ENABLE_MODULE_RECOVERY=ON \
      -DSECP256K1_BUILD_TESTS=OFF \
      -DSECP256K1_BUILD_EXHAUSTIVE_TESTS=OFF \
      -DSECP256K1_BUILD_BENCHMARK=OFF \
      -DSECP256K1_BUILD_EXAMPLES=OFF \
      -DSECP256K1_BUILD_CTIME_TESTS=OFF \
      -DCMAKE_BUILD_TYPE=Release
RUN cmake --build build

# Build shared library into /usr/local/lib as usual and then copy into output
# Unused symbols could be stripped. But for future ease, all symbols are
# maintained.
RUN cmake --install build
RUN mkdir output
RUN cp /usr/local/lib/libsecp256k1.so.6.0.0 output/libsecp256k1.so
""";

void main() async {

  String cmd = await getDockerCmd();
  print("Using $cmd to run dockerfile");

  // Build secp256k1 and copy shared library to build directory
  if (!await dockerBuild(
      cmd,
      dockerfile,
      "coinlib_build_secp256k1_linux",
      "output/libsecp256k1.so",
  )) {
    exit(1);
  }

}
