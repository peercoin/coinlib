import 'dart:io';

import 'util.dart';

/// Follows bitcoin-core/secp256k1's "Cross compiling" instructions.
///
/// Runnable in WSL.  Install the dependencies listed in the README:
/// ```
/// apt-get install -y autoconf libtool build-essential git cmake mingw-w64
/// ```

void main() async {
  // Make temporary directory.
  final workDir = Directory.current.path;
  final tmpDir = createTmpDir();

  // Clone bitcoin-core/secp256k1.
  await execWithStdio(
    "git",
    ["clone", "https://github.com/bitcoin-core/secp256k1", "$tmpDir/secp256k1"],
  );
  Directory.current = Directory("$tmpDir/secp256k1");
  await execWithStdio(
    "git",
    // Use version 0.5.0
    ["checkout", "e3a885d42a7800c1ccebad94ad1e2b82c4df5c65"],
  );

  // Build in tmpDir/secp256k1/lib.
  Directory("lib").createSync();
  Directory.current = Directory("lib");

  // Run cmake with the provided toolchain file.
  await execWithStdio("cmake", [
    "..",
    "-DCMAKE_TOOLCHAIN_FILE=../cmake/x86_64-w64-mingw32.toolchain.cmake",
  ]);

  // Build the project using "make".
  await execWithStdio("make", []);

  // Copy the DLL to build/libsecp256k1.dll.
  Directory("$workDir/build").createSync();
  File("src/libsecp256k1.dll").copySync("$workDir/build/secp256k1.dll");

  print("Output libsecp256k1.dll successfully");

}
