import 'dart:io';
import "package:path/path.dart" show dirname;

final thisDir = dirname(Platform.script.path);

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
  String executable, List<String> arguments, { String? workingDir, }
) async {

  final process = await Process.start(
    executable, arguments, mode: ProcessStartMode.inheritStdio,
    workingDirectory: workingDir,
  );

  return await process.exitCode;

}

String createTmpDir()
  => Directory.systemTemp.createTempSync("coinlibBuild").path;

