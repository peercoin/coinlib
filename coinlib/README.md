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
cryptocoins including Taproot support. This library allows for the construction
and signing of transactions and management of BIP32 wallets.

## Installation and Usage

Add `coinlib` to a Dart or Flutter project via:

```
dart pub add coinlib
```

The native secp256k1 library is compiled and bundled automatically on Android,
iOS, Linux, macOS, and Windows using Dart Code Assets. Web uses the bundled
WebAssembly module.

The library can be imported via:

```
import 'package:coinlib/coinlib.dart';
```

The library must be asynchronously loaded by awaiting the `loadCoinlib()`
function before any part of the library is used. In Flutter, do this before
calling `runApp()`:

```dart
Future<void> main() async {
  await loadCoinlib();
  runApp(const MyApp());
}
```

The library uses a functional-style of OOP. With some exceptions, objects are
immutable. New modified objects are returned from methods. For example, signing
a transaction returns a new signed transaction object:

```dart
final signedTx = unsignedTx.signLegacy(inputN: 0, key: privateKey);
```

An example is found in the `example/` directory.

For a native CLI release bundle, use the Code Assets-aware build command:

```
dart build cli --target bin/your_app.dart
```

The Dart 3.13 link hook records reachable FFI bindings and removes unused
native symbols from the bundled library. A platform C toolchain is required.

## Development

This section is only relevant to developers of the library.

### Bindings and WebAssembly

The WebAssembly (WASM) module is pre-compiled and ready to use. FFI bindings
are pre-generated. These only need to be updated when the underlying secp256k1
library is changed.

Bindings for the native libraries (excluding WebAssembly) are generated from
the vendored headers using `dart run tool/ffigen.dart` within the `coinlib`
package. The command also regenerates the mapping used by the native link hook.

The WebAssembly module has been pre-built to
`lib/src/secp256k1/secp256k1.wasm.g.dart`. It may be rebuilt using `dart run
bin/build_wasm.dart` in the `coinlib` root directory.
