FROM debian:bullseye

# Install dependenices
RUN apt-get update -y \
  && apt-get install -y autoconf libtool build-essential git

# Clone libsecp256k1.
# Could use secp256k1 already in code-base but this makes the dockerfile more
# independent and avoids complexity of copying everything into the correct
# context. It's not a large library to download.
RUN git clone https://github.com/bitcoin-core/secp256k1
WORKDIR /secp256k1

# Use 0.2.0 release
RUN git checkout 21ffe4b22a9683cf24ae0763359e401d1284cc7a

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
RUN cp /usr/local/lib/libsecp256k1.so.1.0.0 output/libsecp256k1.so
