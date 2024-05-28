import 'dart:io';
import 'util.dart';

/// Build a universal macOS framework for secp256k1 directly on a mac machine

void main() async {

  // Clone secp256k1 to temporary directory to keep source clean

  final tmpDir = createTmpDir();
  print("Building in $tmpDir");
  final libDir = "$tmpDir/secp256k1";

  exitOnCode(
    await execWithStdio(
      "git", ["clone", "https://github.com/bitcoin-core/secp256k1", libDir],
    ),
    "Could not clone secp256k1 to temporary build directory",
  );

  // Checkout to 0.5.0 commit
  exitOnCode(
    await execWithStdio(
      "git", ["checkout", "e3a885d42a7800c1ccebad94ad1e2b82c4df5c65"],
      workingDir: libDir,
    ),
    "Could not checkout to v0.5.0 commit",
  );

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
      "CFLAGS=-O2 -arch x86_64 -arch arm64",
    ],
    workingDir: libDir,
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
  final buildDir = "${Directory.current.path}/build";
  Directory(buildDir).create();
  final libFile = File("$libDir/build/lib/libsecp256k1.2.dylib");
  await libFile.copy("$buildDir/libsecp256k1.dylib");
  print("Created dylib in build directory");

}
