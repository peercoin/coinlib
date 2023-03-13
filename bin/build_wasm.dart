import 'dart:io';
import 'docker_util.dart';

/// Run Dockerfile to generate wasm file and then convert into a dart file with
/// the wasm as a Uint8List static variable

void binaryFileToDart(String inPath, String outPath, String name) {
  final bytes = File(inPath).readAsBytesSync();
  final hexList = bytes.map((b) => "0x${b.toRadixString(16)}").join(",");
  final output = """\
import 'dart:typed_data';
final $name = Uint8List.fromList([$hexList]);
  """;
  File(outPath).writeAsStringSync(output, flush: true);
}

void main() async {

  String cmd = await getDockerCmd();
  print("Using $cmd to run dockerfile");

  // Create temporary directory to receive wasm file
  final tmpDir = Directory.systemTemp.createTempSync("coinlibBuild").path;
  print("Temporary build artifacts at $tmpDir");

  // Build secp256k1 to wasm and copy wasm file to tempdir
  if (!await dockerRun(
      cmd,
      "build_secp256k1_wasm.Dockerfile",
      "coinlib_build_secp256k1_wasm",
      tmpDir,
      "cp /secp256k1/output/secp256k1.wasm /host/secp256k1.wasm",
  )) {
    exit(1);
  }

  // Convert secp256k1.wasm file into Uint8List in dart file
  binaryFileToDart(
    "$tmpDir/secp256k1.wasm",
    "$thisDir/../lib/src/generated/secp256k1.wasm.g.dart",
    "secp256k1WasmData",
  );
  print("Output secp256k1.wasm.g.dart successfully");

}
