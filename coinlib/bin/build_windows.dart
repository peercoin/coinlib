import 'dart:io';

import 'util.dart';

/// Follows bitcoin-core/secp256k1's "Building on Windows" instructions.
///
/// Runnable in "Developer Command Prompt for VS 2022".

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
    ["checkout", "346a053d4c442e08191f075c3932d03140579d47"],
  );

  // Build in tmpDir/secp256k1/build.
  Directory("build").createSync();

  // Configure cmake.
  await execWithStdio("cmake", [
    "-G",
    "Visual Studio 17 2022",
    "-A",
    "x64",
    "-S",
    ".",
    "-B",
    "build",
  ]);

  // Build.
  await execWithStdio("cmake", [
    "--build",
    "build",
    "--config",
    "RelWithDebInfo"
  ]);

  // Copy the DLL to build/windows/x64/secp256k1.dll.
  Directory("$workDir/build/windows/x64").createSync();
  File("$tmpDir/secp256k1/build/src/RelWithDebInfo/secp256k1.dll").copySync("$workDir/build/windows/x64/secp256k1.dll");
}
