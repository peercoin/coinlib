import 'dart:io';
import 'util.dart';

/// Build a universal macOS framework for secp256k1 directly on a mac machine

void main() async {

  // Copy secp256k1 to temporary directory to keep source clean

  final tmpDir = createTmpDir();
  print("Building in $tmpDir");
  final libDir = "$tmpDir/secp256k1";

  var exitCode = await execWithStdio(
    "cp", ["-r", "$thisDir/../src/secp256k1", libDir]
  );
  if (exitCode != 0) {
    print("Could not copy secp256k1 to temporary build directory");
    exit(1);
  }

  // Generate configure
  exitCode = await execWithStdio("sh", ["./autogen.sh"], workingDir: libDir);
  if (exitCode != 0) {
    print("Couldn't generate configure for secp256k1");
    exit(1);
  }

  // Run configure
  exitCode = await execWithStdio(
    "sh",
    [
      "./configure", "--enable-module-recovery", "--disable-tests",
      "--disable-exhaustive-tests", "--disable-benchmark",
      // Install final dylib in local directory so it can be copied
      "--prefix", "$libDir/build",
      // Build for arm and x86 architectures
      "CFLAGS=-O2 -arch x86_64 -arch arm64"
    ],
    workingDir: libDir
  );
  if (exitCode != 0) {
    print("Failed to configure secp256k1");
    exit(1);
  }

  // Run make
  exitCode = await execWithStdio("make", [], workingDir: libDir);
  if (exitCode != 0) {
    print("Failed to make secp256k1");
    exit(1);
  }

  // Need to run make install
  exitCode = await execWithStdio("make", ["install"], workingDir: libDir);
  if (exitCode != 0) {
    print("Couldn't create final dylib file");
    exit(1);
  }

  // Copy framework to build directory
  final buildDir = "$thisDir/../build";
  Directory(buildDir).create();
  final libFile = File("$libDir/build/lib/libsecp256k1.1.dylib");
  await libFile.copy("$buildDir/libsecp256k1.dylib");
  print("Created dylib in build directory");

}
