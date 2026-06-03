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
  }
) async {
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

Future<int> execWithStdioWin(String command, List<String> arguments) async {
  final process = await Process.start(command, arguments);

  process.stdout.transform(SystemEncoding().decoder).listen((data) {
    print('[stdout]: $data');
  });

  process.stderr.transform(SystemEncoding().decoder).listen((data) {
    print('[stderr]: $data');
  });

  return await process.exitCode;
}

void exitOnCode(int exitCode, String exitMsg) {
  if (exitCode != 0) {
    print(exitMsg);
    exit(1);
  }
}

String createTmpDir() =>
    Directory.systemTemp.createTempSync("coinlibBuild").path;

Future<String> cloneForWindowsInTmpDir() async {

  final tmpDir = createTmpDir();

  // Clone bitcoin-core/secp256k1.
  await execWithStdioWin("git", [
    "clone",
    "https://github.com/peercoin/secp256k1-coinlib",
    "$tmpDir/secp256k1-coinlib",
  ]);
  Directory.current = Directory("$tmpDir/secp256k1-coinlib");
  await execWithStdioWin(
    "git",
    // Use version 0.7.0
    ["checkout", "69018e5b939d8d540ca6b237945100f4ecb5681e"],
  );

  // Build in tmpDir/secp256k1-coinlib/build.
  Directory("build").createSync();

  return tmpDir;

}
