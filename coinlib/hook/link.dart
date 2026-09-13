import 'package:code_assets/code_assets.dart';
import 'package:coinlib/src/secp256k1/c_library.dart';
import 'package:coinlib/src/secp256k1/record_use_mapping.g.dart';
import 'package:hooks/hooks.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';
import 'package:record_use/record_use.dart';

void main(List<String> args) async {
  await link(args, (input, output) async {
    if (input.config.buildCodeAssets) {
      await secp256k1Library.link(
        input: input,
        output: output,
        linkerOptions: LinkerOptions.treeshake(
          symbolsToKeep: input.recordedUses?.calls.keys.cast<Method>().map(
            (method) => recordUseMapping[method.name]!,
          ),
        ),
      );
    }
  });
}
