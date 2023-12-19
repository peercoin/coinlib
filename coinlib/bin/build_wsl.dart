import 'dart:io';

import 'util.dart';

/// Follows bitcoin-core/secp256k1's "Cross compiling" instructions.
///
/// Run in WSL/WSL2.  Make sure to install the dependencies listed in the README.
/// ```
/// apt-get install -y autoconf libtool build-essential git cmake mingw-w64
/// ```

void main() async {
  // Clone bitcoin-core/secp256k1.
  await execWithStdio(
    "git",
    ["clone", "https://github.com/bitcoin-core/secp256k1", "src/secp256k1"],
  );
  await execWithStdio(
    "git",
    ["checkout", "346a053d4c442e08191f075c3932d03140579d47"],
  );

  // Build in "src/secp256k1/lib".
  Directory("src/secp256k1/lib").createSync();
  Directory.current = Directory("src/secp256k1/lib");

  // Run cmake with the provided toolchain file.
  await execWithStdio("cmake", [
    "..",
    "-DCMAKE_TOOLCHAIN_FILE=../cmake/x86_64-w64-mingw32.toolchain.cmake",
  ]);

  // Build the project using "make".
  await execWithStdio("make", []);
}
