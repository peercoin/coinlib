import 'dart:typed_data';

// Implemented from the RIPEMD-160 specification, cross-checked against the
// MIT-licensed Bitcoin Core and Hashbase reference implementations.
// https://homes.esat.kuleuven.be/~bosselae/ripemd160.html
// https://github.com/bitcoin/bitcoin/blob/master/test/functional/test_framework/crypto/ripemd160.py
// https://github.com/hasnainroopawalla/hashbase/blob/master/hashbase/ripemd160.py

const _mask32 = 0xffffffff;

// dart format off
const _messageLeft = <int>[
  0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15,
  7, 4, 13, 1, 10, 6, 15, 3, 12, 0, 9, 5, 2, 14, 11, 8,
  3, 10, 14, 4, 9, 15, 8, 1, 2, 7, 0, 6, 13, 11, 5, 12,
  1, 9, 11, 10, 0, 8, 12, 4, 13, 3, 7, 15, 14, 5, 6, 2,
  4, 0, 5, 9, 7, 12, 2, 10, 14, 1, 3, 8, 11, 6, 15, 13,
];

const _messageRight = <int>[
  5, 14, 7, 0, 9, 2, 11, 4, 13, 6, 15, 8, 1, 10, 3, 12,
  6, 11, 3, 7, 0, 13, 5, 10, 14, 15, 8, 12, 4, 9, 1, 2,
  15, 5, 1, 3, 7, 14, 6, 9, 11, 8, 12, 2, 10, 0, 4, 13,
  8, 6, 4, 1, 3, 11, 15, 0, 5, 12, 2, 13, 9, 7, 10, 14,
  12, 15, 10, 4, 1, 5, 8, 7, 6, 2, 13, 14, 0, 3, 9, 11,
];

const _rotationLeft = <int>[
  11, 14, 15, 12, 5, 8, 7, 9, 11, 13, 14, 15, 6, 7, 9, 8,
  7, 6, 8, 13, 11, 9, 7, 15, 7, 12, 15, 9, 11, 7, 13, 12,
  11, 13, 6, 7, 14, 9, 13, 15, 14, 8, 13, 6, 5, 12, 7, 5,
  11, 12, 14, 15, 14, 15, 9, 8, 9, 14, 5, 6, 8, 6, 5, 12,
  9, 15, 5, 11, 6, 8, 13, 12, 5, 12, 13, 14, 11, 8, 5, 6,
];

const _rotationRight = <int>[
  8, 9, 9, 11, 13, 15, 15, 5, 7, 7, 8, 11, 14, 14, 12, 6,
  9, 13, 15, 7, 12, 8, 9, 11, 7, 7, 12, 7, 6, 15, 13, 11,
  9, 7, 15, 11, 8, 6, 6, 14, 12, 13, 5, 14, 13, 13, 7, 5,
  15, 5, 8, 11, 14, 14, 6, 14, 6, 9, 12, 9, 12, 5, 15, 8,
  8, 5, 12, 9, 12, 5, 14, 6, 8, 13, 6, 5, 15, 13, 11, 11,
];

const _constantLeft = <int>[
  0x00000000,
  0x5a827999,
  0x6ed9eba1,
  0x8f1bbcdc,
  0xa953fd4e,
];

const _constantRight = <int>[
  0x50a28be6,
  0x5c4dd124,
  0x6d703ef3,
  0x7a6d76e9,
  0x00000000,
];
// dart format on

/// Computes the 20-byte RIPEMD-160 digest of [data].
///
/// RIPEMD-160 is retained here for compatibility with Bitcoin-style HASH160;
/// it should not be selected for new cryptographic protocols.
Uint8List ripemd160(List<int> data) {
  final state = <int>[
    0x67452301,
    0xefcdab89,
    0x98badcfe,
    0x10325476,
    0xc3d2e1f0,
  ];

  final fullBlockEnd = data.length & ~63;
  for (var offset = 0; offset < fullBlockEnd; offset += 64) {
    _compress(state, data, offset);
  }

  final remaining = data.length - fullBlockEnd;
  final finalBlocks = Uint8List(remaining < 56 ? 64 : 128);
  finalBlocks.setRange(0, remaining, data, fullBlockEnd);
  finalBlocks[remaining] = 0x80;

  // Store the message size modulo 2^64 without relying on shifts wider than
  // 32 bits, which keeps this implementation consistent when compiled to JS.
  final bitLengthLow = (data.length << 3) & _mask32;
  final bitLengthHigh = (data.length ~/ 0x20000000) & _mask32;
  _writeUint32LittleEndian(
    finalBlocks,
    finalBlocks.length - 8,
    bitLengthLow,
  );
  _writeUint32LittleEndian(
    finalBlocks,
    finalBlocks.length - 4,
    bitLengthHigh,
  );

  for (var offset = 0; offset < finalBlocks.length; offset += 64) {
    _compress(state, finalBlocks, offset);
  }

  final digest = Uint8List(20);
  for (var i = 0; i < state.length; i++) {
    _writeUint32LittleEndian(digest, i * 4, state[i]);
  }
  return digest;
}

void _compress(List<int> state, List<int> block, int offset) {
  final words = List<int>.filled(16, 0);
  for (var i = 0; i < words.length; i++) {
    final wordOffset = offset + i * 4;
    words[i] =
        block[wordOffset] |
        (block[wordOffset + 1] << 8) |
        (block[wordOffset + 2] << 16) |
        (block[wordOffset + 3] << 24);
  }

  var al = state[0];
  var bl = state[1];
  var cl = state[2];
  var dl = state[3];
  var el = state[4];
  var ar = al;
  var br = bl;
  var cr = cl;
  var dr = dl;
  var er = el;

  for (var roundIndex = 0; roundIndex < 80; roundIndex++) {
    final round = roundIndex >> 4;
    final left =
        (_rotateLeft(
              al +
                  _roundFunction(bl, cl, dl, round) +
                  words[_messageLeft[roundIndex]] +
                  _constantLeft[round],
              _rotationLeft[roundIndex],
            ) +
            el) &
        _mask32;
    al = el;
    el = dl;
    dl = _rotateLeft(cl, 10);
    cl = bl;
    bl = left;

    final right =
        (_rotateLeft(
              ar +
                  _roundFunction(br, cr, dr, 4 - round) +
                  words[_messageRight[roundIndex]] +
                  _constantRight[round],
              _rotationRight[roundIndex],
            ) +
            er) &
        _mask32;
    ar = er;
    er = dr;
    dr = _rotateLeft(cr, 10);
    cr = br;
    br = right;
  }

  final nextH0 = (state[1] + cl + dr) & _mask32;
  state[1] = (state[2] + dl + er) & _mask32;
  state[2] = (state[3] + el + ar) & _mask32;
  state[3] = (state[4] + al + br) & _mask32;
  state[4] = (state[0] + bl + cr) & _mask32;
  state[0] = nextH0;
}

int _roundFunction(int x, int y, int z, int round) => switch (round) {
  0 => x ^ y ^ z,
  1 => (x & y) | (~x & z),
  2 => (x | ~y) ^ z,
  3 => (x & z) | (y & ~z),
  4 => x ^ (y | ~z),
  _ => throw RangeError.range(round, 0, 4, 'round'),
};

int _rotateLeft(int value, int amount) {
  final word = value & _mask32;
  return ((word << amount) | (word >> (32 - amount))) & _mask32;
}

void _writeUint32LittleEndian(Uint8List output, int offset, int value) {
  output[offset] = value;
  output[offset + 1] = value >> 8;
  output[offset + 2] = value >> 16;
  output[offset + 3] = value >> 24;
}
