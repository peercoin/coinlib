<p align="center">
  <img
    src="https://raw.githubusercontent.com/peercoin/coinlib/master/logo.svg"
    alt="Coinlib"
    width="250px"
  >
</p>

<p align="center">
  <a href="https://chainz.cryptoid.info/ppc/address.dws?p77CZFn9jvg9waCzKBzkQfSvBBzPH1nRre">
    <img src="https://badgen.net/badge/peercoin/Donate/green?icon=https://raw.githubusercontent.com/peercoin/media/84710cca6c3c8d2d79676e5260cc8d1cd729a427/Peercoin%202020%20Logo%20Files/01.%20Icon%20Only/Inside%20Circle/Transparent/Green%20Icon/peercoin-icon-green-transparent.svg" alt="Peercoin Donate">
  </a>
  <a href="https://pub.dev/packages/coinlib">
    <img alt="pub.dev" src="https://img.shields.io/pub/v/coinlib?logo=dart&label=pub.dev">
  </a>
</p>

# Coinlib

Coinlib is a straight-forward and modular library for Peercoin and other similar
cryptocoins. This library allows for the construction and signing of
transactions and management of BIP32 wallets.

## Installation and Usage

If you are using flutter, please see
[coinlib_flutter](https://pub.dev/packages/coinlib_flutter) instead. Otherwise
you may add `coinlib` to your project via:

```
dart pub add coinlib
```

If you are using the library for web, the library is ready to use. If you are
using the library on Linux, macOS, or Windows, then please see
["Building for Linux"](#building-for-linux),
["Building for macOS"](#building-for-macos), or ["Building for Windows"](#building-for-windows) below.

The library can be imported via:

```
import 'package:coinlib/coinlib.dart';
```

The library must be asynchronously loaded by awaiting the `loadCoinlib()`
function before any part of the library is used.

The library uses a functional-style of OOP. With some exceptions, objects are
immutable. New modified objects are returned from methods. For example, signing
a transaction returns a new signed transaction object:

```dart
final signedTx = unsignedTx.sign(inputN: 0, key: privateKey);
```

An example is found in the `example/` directory.

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

## Building for Windows
### Building for Windows on Linux

Cross-compile a secp256k1 DLL for Windows on an Ubuntu 20.04 host with `dart run coinlib:build_windows` or `dart run bin/build_windows.dart`.

### Building for Windows on Windows

The above ["Building for Windows on Linux"](#building-for-windows-on-linux) can be completed in an Ubuntu 20.04 WSL2 instance on a Windows host.  You can also complete the build without installing Flutter to the WSL2 host by following [bitcoin-core/secp256k1's "Cross compiling" guide](https://github.com/bitcoin-core/secp256k1?tab=readme-ov-file#cross-compiling).

Building natively on Windows without WSL2 may also be possible by following [bitcoin-core/secp256k1's guide for Building on Windows](https://github.com/bitcoin-core/secp256k1?tab=readme-ov-file#building-on-windows) and placing the DLL at `src/secp256k1/lib/src/libsecp256k1-2.dll`.

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

