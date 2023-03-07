# Coinlib

Coinlib is a straight-forward and modular library for Peercoin and other similar
cryptocoins. This library allows for the construction and signing of
transactions and management of BIP32 wallets.

## Getting started

This library requires that the wasmer runtime is setup for the underlying wasm
package. This requires that the
[Rust SDK](https://www.rust-lang.org/tools/install) is installed. `dart run
wasm:setup` can be run to build the wasmer runtime.

The library supports running on the host machine for which wasmer has been
built.

## Building WASM

The WebAssembly (wasm) code has been prebuilt and bundled into the library. This
includes the secp256k1 cryptography library. This can be rebuilt using `dart run
bin/generate_wasm.dart`. A dockerfile (`bin/build_secp256k1_wasm.Dockerfile`) is
used for the build process and podman or docker is required.

