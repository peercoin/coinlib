# Coinlib

Coinlib is a straight-forward and modular library for Peercoin and other similar
cryptocoins. This library allows for the construction and signing of
transactions and management of BIP32 wallets.

## Usage

This library requires a shared or dynamic library for linux or macOS, and a
WebAssembly module for web. The WebAssembly module is precompiled and included
with the library, but the linux and macOS libraries are not and must be built
before use. See
["Building Native & WebAssembly"](#building-native-and-webassembly) below.

The library can be imported via:

```
import 'package:coinlib/coinlib.dart';
```

The library must be asynchronously loaded by awaiting the `loadCoinlib()`
function.

## Building Native and WebAssembly

The secp256k1 dependency must be provided to the library as a shared/dynamic
library or as a WebAssembly module for web. Build scripts are provided and can
be run from the root project directory.

Docker or Podman is required to build the library for linux or web. macOS
requires autotools that may be installed using homebrew:

```
brew install autoconf automake libtool
```

The WebAssembly module has been pre-built to
`lib/src/generated/secp256k1.wasm.g.dart`. It may be rebuilt using `dart run
bin/build_wasm.dart`.

The linux shared library can be built using `bin/build_linux.dart` which will
produce a shared library into `build/libsecp256k1.so`.

The macOS dynamic library can be built using `bin/build_macos.dart` which will
produce a universal library for both x86_64 and arm64 to
`build/libsecp256k1.dylib`.

No script is included for Windows at the present time, however a `secp256k1.dll`
may be built into the `build/` directory separately.

Bindings for the native libraries (excluding WebAssembly) are generated from the
`headers/secp256k1.h` file using `dart run ffigen`. These are already included.

