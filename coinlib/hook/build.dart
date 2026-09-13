import 'package:code_assets/code_assets.dart';
import 'package:coinlib/src/secp256k1/c_library.dart';
import 'package:hooks/hooks.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    if (input.config.buildCodeAssets) {
      await secp256k1Library.build(input: input, output: output);
    }
  });
}
