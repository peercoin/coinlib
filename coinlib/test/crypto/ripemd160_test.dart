import 'dart:convert';
import 'dart:typed_data';

import 'package:coinlib/coinlib.dart';
import 'package:coinlib/src/crypto/ripemd160.dart';
import 'package:test/test.dart';

void main() {
  group('ripemd160', () {
    final textVectors = <(String, String)>[
      ('', '9c1185a5c5e9fc54612808977ee8f548b2258d31'),
      ('a', '0bdc9d2d256b3ee9daae347be6f4dc835a467ffe'),
      ('abc', '8eb208f7e05d987a9b044a8e98c6b087f15a0bfc'),
      ('message digest', '5d0689ef49d2fae572b881b123a85ffa21595f36'),
      (
        'abcdefghijklmnopqrstuvwxyz',
        'f71c27109c692c1b56bbdceb5b9d2865b3708dbc',
      ),
      (
        'abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq',
        '12a053384a9c0c88e405a06c27dcf49ada62eb2b',
      ),
      (
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789',
        'b0e20b6e3116640286ed3a87a5713079b21f5189',
      ),
      (
        '1234567890' * 8,
        '9b752e45573d4b39f4dbd3323cab82bf63326bfb',
      ),
      (
        'The quick brown fox jumps over the lazy dog',
        '37f332f68db77bd9d7edd4969571ad671cf9dd3b',
      ),
      (
        'The quick brown fox jumps over the lazy cog',
        '132072df690933835eb8b6ad0b77e7b6f14acad7',
      ),
      (
        'RIPEMD-160: Živio Peercoin! 🚀',
        '331f25053f3c3ba83f8705d2ebac176a6456023d',
      ),
    ];

    for (final (message, expected) in textVectors) {
      test(
        'text vector for ${message.isEmpty ? 'empty input' : message}',
        () {
          expect(bytesToHex(ripemd160(utf8.encode(message))), expected);
        },
      );
    }

    test('official million-byte vector', () {
      final input = Uint8List(1000000)..fillRange(0, 1000000, 0x61);
      expect(
        bytesToHex(ripemd160(input)),
        '52783243c1697bdbe16d37f97f68f08325dc1528',
      );
    });

    test('accepts arbitrary binary input', () {
      expect(
        bytesToHex(ripemd160([0x00, 0x01, 0x02, 0xff])),
        'ea081363ff1934d0243cc3bdfe51ff9678dc0723',
      );
    });

    final binaryVectors = <(String, List<int>, String)>[
      (
        'all byte values',
        List<int>.generate(256, (index) => index),
        '9c4fa072db2c871a5635e37f791e93ab45049676',
      ),
      (
        '1000 zero bytes',
        Uint8List(1000),
        'ac0e58926d9f7cb482f4f3daced731b1d627b40b',
      ),
      (
        '1000 0xff bytes',
        Uint8List(1000)..fillRange(0, 1000, 0xff),
        'f8759fc4e52811fb9c01739cdfa136f5f24d0716',
      ),
      (
        '1024 patterned bytes',
        List<int>.generate(1024, (index) => (index * 73 + 19) & 0xff),
        '644901d37fa815366dff74986a5adbbbf6230507',
      ),
      (
        '4097 patterned bytes',
        List<int>.generate(4097, (index) => (index * 73 + 19) & 0xff),
        'fc6f5dd73583d686e2ab19f43bd6e649d2d65a76',
      ),
    ];

    for (final (description, input, expected) in binaryVectors) {
      test(description, () {
        expect(bytesToHex(ripemd160(input)), expected);
      });
    }

    test('hashes only the bytes exposed by a Uint8List view', () {
      final backing = Uint8List.fromList(
        List<int>.generate(260, (index) => (index * 29 + 7) & 0xff),
      );
      final view = Uint8List.sublistView(backing, 2, 258);

      expect(
        bytesToHex(ripemd160(view)),
        '3b78e7b31d7f5d4fc715dd1812ce773c12695eff',
      );
    });

    test('does not modify the input and returns a fresh 20-byte digest', () {
      final input = Uint8List.fromList(
        List<int>.generate(200, (index) => (index * 11) & 0xff),
      );
      final originalInput = Uint8List.fromList(input);

      final first = ripemd160(input);
      final second = ripemd160(input);

      expect(input, originalInput);
      expect(first, second);
      expect(first, hasLength(20));
      expect(identical(first, second), isFalse);
    });

    test('returned digest can be mutated without affecting later calls', () {
      final input = utf8.encode('independent result buffers');
      final first = ripemd160(input)..fillRange(0, 20, 0);
      final second = ripemd160(input);

      expect(first, everyElement(0));
      expect(
        bytesToHex(second),
        '959c73c6834712b512e94d2957cb3d8eb6610a20',
      );
    });

    test('hash160 integration', () {
      expect(
        bytesToHex(hash160(Uint8List(0))),
        'b472a266d0bd89c13706a4132ccfb16f7c3b9fcb',
      );
    });

    final paddingBoundaryVectors = <int, String>{
      55: 'cb9a91b689c2e5a5aff392733f33c8fb75998dbb',
      56: '0fde8285ccc694b28a3205e30e3153c3f2a2dfa2',
      63: '28d9c6a82ecf3196a0c5ab9cd79053118ca43301',
      64: 'c9b1871a7c604823d7cc8cc48e4ea37a4f841001',
      65: '26bc5a01292f459c7bd3310eaf53b72d25df1e71',
      119: '3e51052aaeaf2b4b120980b0c3c79f26301ff2f9',
      120: '0268020acd3f91628e14766d7791dbf683bff67d',
      127: '24ba60dff396cf212ad4c3969eb1e281f044a7b0',
      128: '2349a24ad9bd73b09329b1c014c333610548ac55',
    };

    for (final MapEntry(key: length, value: expected)
        in paddingBoundaryVectors.entries) {
      test('padding boundary at $length bytes', () {
        final input = List<int>.generate(
          length,
          (index) => (index * 37 + 11) & 0xff,
        );
        expect(bytesToHex(ripemd160(input)), expected);
      });
    }
  });
}
