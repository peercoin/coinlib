import 'dart:io';
import 'util.dart';

/// Follows peercoin/secp256k1-coinlib's "Cross compiling" instructions.
///
/// Runnable in WSL.  Install the dependencies listed in the README:
/// ```
/// apt-get install -y autoconf libtool build-essential git cmake mingw-w64
/// ```
void main() async {

  final workDir = Directory.current.path;

  // Clone into tmp directory
  await cloneForWindowsInTmpDir();

  // Run cmake with the provided toolchain file.
  await execWithStdio("cmake", [
    "-B", "build",
    "-DCMAKE_TOOLCHAIN_FILE=../cmake/x86_64-w64-mingw32.toolchain.cmake",
    "-DSECP256K1_ENABLE_MODULE_RECOVERY=ON",
    "-DSECP256K1_BUILD_TESTS=OFF",
    "-DSECP256K1_BUILD_EXHAUSTIVE_TESTS=OFF",
    "-DSECP256K1_BUILD_BENCHMARK=OFF",
    "-DSECP256K1_BUILD_EXAMPLES=OFF",
    "-DSECP256K1_BUILD_CTIME_TESTS=OFF",
    "-DCMAKE_BUILD_TYPE=Release",
  ]);

  await execWithStdio("cmake", ["--build", "build"]);

  // Copy the DLL to build/libsecp256k1.dll.
  Directory("$workDir/build").createSync();
  File("build/bin/libsecp256k1-6.dll").copySync("$workDir/build/secp256k1.dll");

  print("Output libsecp256k1.dll successfully");

}
