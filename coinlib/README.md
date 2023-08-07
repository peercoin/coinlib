# Coinlib

**This is an alpha pre-release.**

Coinlib is a straight-forward and modular library for Peercoin and other similar
cryptocoins. This library allows for the construction and signing of
transactions and management of BIP32 wallets.

## Installation and Usage

If you are using flutter, please see `coinlib_flutter` instead. Otherwise you
may add `coinlib` to your project via:

```
dart pub add coinlib
```

If you are using the library for web, the library is ready to use. If you are
using the library on Linux or macOS then please see
["Building for Linux"](#building-for-linux) and
["Building for macOS"](#building-for-macos) below.

No script is included for building on Windows at the present time, however a
`secp256k1.dll` may be built into your `build/` directory separately.

The library can be imported via:

```
import 'package:coinlib/coinlib.dart';
```

The library must be asynchronously loaded by awaiting the `loadCoinlib()`
function before any part of the library is used.

## Building for Linux

Docker or Podman is required to build the library for Linux.

The linux shared library can be built using `dart run coinlib:build_linux` in
the root directory of your package which will produce a shared library into
`build/libsecp256k1.so`. This can also be run in the `coinlib` root directory
via `dart run bin/build_linux.dart`.

This library can be in the `build` directory under the PWD, installed as a
system library, or within `$LD_LIBRARY_PATH`.

## Building for macOS

Building for macOS requires autotools that may be installed using homebrew:

```
brew install autoconf automake libtool
```

The macOS dynamic library must either be provided as
`$PWD/build/libsecp256k1.dylib` when running dart code, or provided as a system
framework named `secp256k1.framework`.

To build the dynamic library, run `dart run coinlib:build_macos` which will
place the library under a `build` directory.

## Development

This section is only relevant to developers of the library.

### Bindings and WebAssembly

The WebAssembly (WASM) module is pre-compiled and ready to use. FFI bindings
are pre-generated. These only need to be updated when the underlying secp256k1
library is changed.

Bindings for the native libraries (excluding WebAssembly) are generated from the
`headers/secp256k1.h` file using `dart run ffigen` within the `coinlib` package.

The WebAssembly module has been pre-built to
`lib/src/generated/secp256k1.wasm.g.dart`. It may be rebuilt using `dart run
bin/build_wasm.dart` in the `coinlib` root directory.

