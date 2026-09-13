import 'dart:io';

import 'package:coinlib/src/secp256k1/source_archive.dart';
import 'package:ffigen/ffigen.dart';

Future<void> main() async {
  final packageRoot = Platform.script.resolve('../');
  final sourceRoot = await ensureSecp256k1Source(
    packageRoot.resolve('.dart_tool/secp256k1-source/'),
  );
  final includeRoot = sourceRoot.resolve('include/');

  final generator = FfiGenerator(
    input: Input(
      entryPoints: [
        includeRoot.resolve('secp256k1_recovery.h'),
        includeRoot.resolve('secp256k1_schnorrsig.h'),
        includeRoot.resolve('secp256k1_ecdh.h'),
        includeRoot.resolve('secp256k1_musig.h'),
      ],
    ),
    visitors: [
      Visitor(
        func: (function) {
          function.isIncluded = true;
          function.recordUse = true;
        },
        global: (global) => global.isIncluded = false,
        macroConstant: (macro) => macro.isIncluded = false,
        struct: (struct) {
          struct.isIncluded = !struct.name.startsWith('_');
          struct.dependencies = CompoundDependencies.full;
        },
        typealias: (typealias) =>
            typealias.isIncluded = typealias.name.startsWith('_')
            ? TypealiasInclude.never
            : TypealiasInclude.ifUsed,
        union: (union) {
          union.isIncluded = !union.name.startsWith('_');
          union.dependencies = CompoundDependencies.full;
        },
      ),
    ],
    output: Output(
      dart: DartOutput(
        path: packageRoot.resolve(
          'lib/src/secp256k1/secp256k1.ffi.g.dart',
        ),
      ),
      recordUseMapping: packageRoot.resolve(
        'lib/src/secp256k1/record_use_mapping.g.dart',
      ),
      preamble:
          '''
// Copyright (c) 2013 Pieter Wuille
//
// Generated from libsecp256k1 headers distributed under the MIT license.
// Source: https://github.com/peercoin/secp256k1-coinlib/tree/$secp256k1Commit
''',
    ),
  );

  await generator.generate();
}
