import 'dart:io';
import 'util.dart';

/// Follows peercoin/secp256k1-coinlib's "Building on Windows" instructions.
///
/// Runnable in "Developer Command Prompt for VS 2022".
void main() async {

  final workDir = Directory.current.path;

  // Clone into tmp directory
  final tmpDir = await cloneForWindowsInTmpDir();

  // Configure cmake.
  await execWithStdioWin("cmake", [
    "-G",
    "Visual Studio 17 2022",
    "-A",
    "x64",
    "-S",
    ".",
    "-B",
    "build",
    "--debug-output",
    "-DSECP256K1_ENABLE_MODULE_RECOVERY=ON",
    "-DSECP256K1_BUILD_TESTS=OFF",
    "-DSECP256K1_BUILD_EXHAUSTIVE_TESTS=OFF",
    "-DSECP256K1_BUILD_BENCHMARK=OFF",
    "-DSECP256K1_BUILD_EXAMPLES=OFF",
    "-DSECP256K1_BUILD_CTIME_TESTS=OFF",
    "-DCMAKE_BUILD_TYPE=Release",
  ]);

  // Build.
  await execWithStdioWin("cmake", [
    "--build",
    "build",
    "--config",
    "RelWithDebInfo",
    "-v",
  ]);

  // Copy the DLL to build/windows/x64/secp256k1.dll.
  Directory("$workDir${Platform.pathSeparator}build").createSync();
  final dll = File(
    "$tmpDir"
    "${Platform.pathSeparator}secp256k1-coinlib"
    "${Platform.pathSeparator}build"
    "${Platform.pathSeparator}src"
    "${Platform.pathSeparator}RelWithDebInfo"
    "${Platform.pathSeparator}libsecp256k1-6.dll",
  );

  print("File exists: ${dll.existsSync()}");

  dll.copySync(
    "$workDir"
    "${Platform.pathSeparator}build"
    "${Platform.pathSeparator}secp256k1.dll",
  );

  print("Output libsecp256k1.dll successfully");

}
