import 'package:code_assets/code_assets.dart';
import 'package:coinlib/src/secp256k1/c_library.dart';
import 'package:coinlib/src/secp256k1/source_archive.dart';
import 'package:hooks/hooks.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    if (input.config.buildCodeAssets) {
      final sourceRoot = await ensureSecp256k1Source(
        input.outputDirectoryShared.resolve('secp256k1-source/'),
      );
      await secp256k1Library(
        sourceRoot: sourceRoot,
      ).build(input: input, output: output);
    }
  });
}
