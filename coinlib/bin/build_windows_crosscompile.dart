import 'dart:io';
import 'docker_util.dart';

/// Build a Windows DLL for secp256k1 using a Dockerfile string.

String dockerfile = r"""
FROM debian:bullseye

# Install dependenices.
RUN apt-get update -y \
  && apt-get install -y autoconf libtool build-essential git cmake gcc-mingw-w64

# Clone libsecp256k1 0.4.1 release.
RUN git clone https://github.com/bitcoin-core/secp256k1 \
  && cd secp256k1 \
  && git checkout 1ad5185cd42c0636104129fcc9f6a4bf9c67cc40 \
  && mkdir build

WORKDIR /secp256k1/build

# Build shared library for Windows.
RUN cmake .. -DCMAKE_TOOLCHAIN_FILE=../cmake/x86_64-w64-mingw32.toolchain.cmake
RUN make

# Build DLL and copy into output.
RUN make install
RUN mkdir output
RUN cp src/libsecp256k1-2.dll output/secp256k1.dll
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
