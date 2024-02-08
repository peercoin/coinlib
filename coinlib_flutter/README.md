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
  <a href="https://pub.dev/packages/coinlib_flutter">
    <img alt="pub.dev" src="https://img.shields.io/pub/v/coinlib_flutter?logo=dart&label=pub.dev">
  </a>
</p>

# Coinlib for Flutter

This package provides flutter support for the
[coinlib](https://pub.dev/packages/coinlib) library for Peercoin and
other cryptocoins. A `CoinlibLoader` widget is included that must be used when
targeting web to ensure the library is ready to be used.

An example app is provided in `example/` that demonstrates use of the loader
widget. Beyond this, the [coinlib](https://pub.dev/packages/coinlib) library
documentation can be followed.

Android, iOS, Linux, macOS, web, and Windows are supported. If you are using the
package for Android, iOS, Linux, macOS or web, the library is ready to use. For
Windows, run `dart run coinlib:build_windows` to build the library. See
[coinlib's documentation](https://pub.dev/packages/coinlib) for more detailed
instructions on and options for building the native library.
