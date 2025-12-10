import 'dart:io';
import 'docker_util.dart';

/// Build a Windows DLL for secp256k1 using a Dockerfile string.

String dockerfile = r"""
FROM debian:bookworm

# Install dependenices.
RUN apt-get update -y && apt-get install -y git cmake gcc-mingw-w64

# Clone libsecp256k1-coinlib v0.7.0
RUN git clone https://github.com/peercoin/secp256k1-coinlib \
  && cd secp256k1-coinlib \
  && git checkout 69018e5b939d8d540ca6b237945100f4ecb5681e

WORKDIR /secp256k1-coinlib

# Build shared library for Windows.
RUN cmake -B build \
      -DCMAKE_TOOLCHAIN_FILE=cmake/x86_64-w64-mingw32.toolchain.cmake \
      -DSECP256K1_ENABLE_MODULE_RECOVERY=ON \
      -DSECP256K1_BUILD_TESTS=OFF \
      -DSECP256K1_BUILD_EXHAUSTIVE_TESTS=OFF \
      -DSECP256K1_BUILD_BENCHMARK=OFF \
      -DSECP256K1_BUILD_EXAMPLES=OFF \
      -DSECP256K1_BUILD_CTIME_TESTS=OFF \
      -DCMAKE_BUILD_TYPE=Release
RUN cmake --build build

# Build DLL and copy into output.
RUN cmake --install build
RUN mkdir output
RUN cp build/bin/libsecp256k1-6.dll output/secp256k1.dll
""";

void main() async {

  String cmd = await getDockerCmd();
  print("Using $cmd to run dockerfile");

  // Build secp256k1 and copy shared library to build directory
  if (!await dockerBuild(
    cmd,
    dockerfile,
    "coinlib_build_secp256k1_windows",
    "output/secp256k1.dll",
  )) {
    exit(1);
  }

}
