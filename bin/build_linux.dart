import 'dart:io';
import 'docker_util.dart';

/// Build the linux shared library for secp256k1 using the dockerfile

void main() async {

  String cmd = await getDockerCmd();
  print("Using $cmd to run dockerfile");

  // Build secp256k1 and copy shared library to build directory
  if (!await dockerBuild(
      cmd,
      "build_secp256k1_linux.Dockerfile",
      "coinlib_build_secp256k1_linux",
      "/secp256k1/output/libsecp256k1.so",
  )) {
    exit(1);
  }


}
