import 'dart:io';
import "util.dart";

/// Determine if podman is available, if not try docker
Future<String> getDockerCmd() async {

  if (await cmdAvailable("podman")) {
    return "podman";
  } else if (await cmdAvailable("docker")) {
    return "docker";
  } else {
    print("Could not find podman or docker to use for build");
    exit(1);
  }

}

/// Runs the contents of [dockerScript] as a Dockerfile, binding [bindDir] to
/// /host in the container and running [containerCmd]
Future<bool> dockerRun(
  String dockerCmd, String dockerScript, String tag, String bindDir,
  String containerCmd,
) async {

  // Build
  print("Building $tag");
  var exitCode = await execWithStdio(
    dockerCmd, ["build", "-t", tag, "-"],
    stdin: dockerScript,
  );

  if (exitCode != 0) {
    print("Build of $tag failed");
    return false;
  }

  // Run
  print("Running $containerCmd");
  exitCode = await execWithStdio(
    dockerCmd, [
      "run", "--rm", "--volume", "$bindDir:/host:Z", tag, "bash", "-c",
      containerCmd,
    ],
  );

  if (exitCode != 0) {
    print("Execution of $tag failed");
    return false;
  }

  print("Execution of $tag succeeded. It may be removed from the image store if desired");

  return true;

}

/// Runs the docker container and copies the [internalFile] to the build
/// directory
Future<bool> dockerBuild(
  String dockerCmd, String dockerScript, String tag, String internalFile,
) async {

  // Ensure build directory is created
  final buildDir = "${Directory.current.path}/build";
  Directory(buildDir).create();

  return dockerRun(
    dockerCmd, dockerScript, tag, buildDir, "cp $internalFile /host/",
  );

}
