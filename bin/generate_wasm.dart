import 'dart:io';
import "package:path/path.dart" show dirname;

/// Run Dockerfile to generate wasm file and then convert into a dart file with
/// the wasm as a Uint8List static variable

final thisDir = dirname(Platform.script.path);

Future<bool> cmdAvailable(String cmd) async {
    final result = await Process.run(cmd, ["--version"]);
    final out = result.stdout as String;
    return out.toLowerCase().startsWith(cmd);
}

Future<int> execWithStdio(
    String executable,
    List<String> arguments,
) async {

    final process = await Process.start(
        executable, arguments, mode: ProcessStartMode.inheritStdio,
    );

    return await process.exitCode;

}

void binaryFileToDart(String inPath, String outPath, String name) {
    final bytes = File(inPath).readAsBytesSync();
    final hexList = bytes.map((b) => "0x${b.toRadixString(16)}").join(",");
    final output = """\
import 'dart:typed_data';
final $name = Uint8List.fromList([$hexList]);
""";
    File(outPath).writeAsStringSync(output, flush: true);
}

Future<bool> dockerBuild(
    String dockerCmd, String dockerfile, String tag, String bindDir,
    String containerCmd,
) async {

    // Build
    print("Building $dockerfile using tag $tag");
    var exitCode = await execWithStdio(
        dockerCmd, ["build", "-f", "$thisDir/$dockerfile", "-t", tag],
    );

    if (exitCode != 0) {
        print("Build of $tag failed");
        return false;
    }

    // Run
    print("Running $containerCmd");
    exitCode = await execWithStdio(
        dockerCmd, ["run", "--volume", "$bindDir:/host", tag, "bash", "-c", containerCmd],
    );

    if (exitCode != 0) {
        print("Execution of $tag failed");
        return false;
    }

    print("Execution of $tag succeeded. It may be removed from the image store if desired");

    return true;

}

void main() async {

    // Determine if podman is available, if not try docker
    late String cmd;
    if (await cmdAvailable("podman")) {
        cmd = "podman";
    } else if (await cmdAvailable("docker")) {
        cmd = "docker";
    } else {
        print("Could not find podman or docker to use for wasm build");
        exit(1);
    }

    print("Using $cmd to run dockerfile");

    // Create temporary directory to receive wasm file
    final tmpDir = Directory.systemTemp.createTempSync("coinlibBuild").path;
    print("Temporary build artifacts at $tmpDir");

    // Build secp256k1 to wasm and copy wasm file to tempdir
    if (!await dockerBuild(
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

