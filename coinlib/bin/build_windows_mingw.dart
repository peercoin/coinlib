import 'dart:io';
import 'util.dart';

/// Follows peercoin/secp256k1-coinlib's "Cross compiling" instructions
/// using MinGW Makefiles instead of Visual Studio.
///
/// Runnable in any terminal with CMake and MinGW in PATH.
void main() async {

  final workDir = Directory.current.path;

  final tmpDir = await cloneForWindowsMinGWInTmpDir();

  await execWithStdioWin("cmake", [
    "-G", "MinGW Makefiles",
    "-S", ".",
    "-B", "build",
    "-DSECP256K1_ENABLE_MODULE_RECOVERY=ON",
    "-DSECP256K1_BUILD_TESTS=OFF",
    "-DSECP256K1_BUILD_EXHAUSTIVE_TESTS=OFF",
    "-DSECP256K1_BUILD_BENCHMARK=OFF",
    "-DSECP256K1_BUILD_EXAMPLES=OFF",
    "-DSECP256K1_BUILD_CTIME_TESTS=OFF",
    "-DCMAKE_BUILD_TYPE=Release",
  ]);

  await execWithStdioWin("cmake", [
    "--build", "build",
    "--config", "Release",
  ]);

  Directory("$workDir${Platform.pathSeparator}build").createSync();
  final dll = File(
    "$tmpDir"
    "${Platform.pathSeparator}secp256k1-coinlib"
    "${Platform.pathSeparator}build"
    "${Platform.pathSeparator}bin"
    "${Platform.pathSeparator}libsecp256k1-6.dll",
  );

  dll.copySync(
    "$workDir"
    "${Platform.pathSeparator}build"
    "${Platform.pathSeparator}secp256k1.dll",
  );

  print("Output libsecp256k1.dll successfully");

}

Future<String> cloneForWindowsMinGWInTmpDir() async {

  final tmpDir = createTmpDir();

  await execWithStdioWin("git", [
    "clone",
    "https://github.com/peercoin/secp256k1-coinlib",
    "$tmpDir/secp256k1-coinlib",
  ]);
  Directory.current = Directory("$tmpDir/secp256k1-coinlib");
  await execWithStdioWin(
    "git",
    ["checkout", "69018e5b939d8d540ca6b237945100f4ecb5681e"],
  );

  Directory("build").createSync();

  return tmpDir;

}
