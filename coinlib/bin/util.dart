import 'dart:convert';
import 'dart:io';

Future<bool> cmdAvailable(String cmd) async {
  try {
    final result = await Process.run(cmd, ["--version"]);
    final out = result.stdout as String;
    return out.toLowerCase().startsWith(cmd);
  } on ProcessException {
    return false;
  }
}

Future<int> execWithStdio(
  String executable,
  List<String> arguments, {
  String? workingDir,
  String? stdin,
}) async {
  final process = await Process.start(
    executable,
    arguments,
    workingDirectory: workingDir,
  );

  if (stdin != null) {
    process.stdin.write(stdin);
    await process.stdin.close();
  }

  // Pipe stdout and stderr to terminal
  await Future.wait([
    for (final stream in [process.stdout, process.stderr])
      stream.transform(utf8.decoder).forEach(stdout.write),
  ]);

  return await process.exitCode;
}

String createTmpDir() =>
    Directory.systemTemp.createTempSync("coinlibBuild").path;
