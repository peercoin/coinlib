import 'dart:io';
import 'docker_util.dart';

/// Build the linux shared library for secp256k1 using the Dockerfile string

String dockerfile = r"""
FROM debian:bookworm

# Install dependenices
RUN apt-get update -y \
  && apt-get install -y autoconf libtool build-essential git

# Clone libsecp256k1.
# Could use secp256k1 already in code-base but this makes the dockerfile more
# independent and avoids complexity of copying everything into the correct
# context. It's not a large library to download.
# Use 0.5.0 release
RUN git clone https://github.com/bitcoin-core/secp256k1 \
  && cd secp256k1 \
  && git checkout e3a885d42a7800c1ccebad94ad1e2b82c4df5c65

WORKDIR /secp256k1

# Build shared library for linux
RUN ./autogen.sh
RUN ./configure \
  --enable-module-recovery --disable-tests \
  --disable-exhaustive-tests --disable-benchmark \
  CFLAGS="-O2"
RUN make

# Build shared library into /usr/local/lib as usual and then copy into output
# Unused symbols could be stripped. But for future ease, all symbols are
# maintained.
RUN make install
RUN mkdir output
RUN cp /usr/local/lib/libsecp256k1.so.2.2.0 output/libsecp256k1.so
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
