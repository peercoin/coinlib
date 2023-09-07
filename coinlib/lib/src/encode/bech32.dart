final alphabet = "qpzry9x8gf2tvdw0s3jn54khce6mua7l";

/// Returns true if a bech32 hrp uses valid characters.
bool hrpValid(String hrp)
  => hrp.codeUnits.every((c) => c > 32 && c < 127);

void _throwOnInvalidHrp(String hrp) {
  if (!hrpValid(hrp)) {
    throw InvalidBech32("$hrp is an invalid bech32 HRP");
  }
}

List<int> _charsToWords(String encoded)
  => encoded.codeUnits.map((c) => alphabet.codeUnits.indexOf(c)).toList();

List<int> _hrpExpand(String hrp) => [
  ...hrp.codeUnits.map((c) => c >> 5),
  0,
  ...hrp.codeUnits.map((c) => c & 31),
];

int _polymodStep(int pre) {
  final b = pre >> 25;
  return (((pre & 0x1ffffff) << 5) ^
      (-((b >> 0) & 1) & 0x3b6a57b2) ^
      (-((b >> 1) & 1) & 0x26508e6d) ^
      (-((b >> 2) & 1) & 0x1ea119fa) ^
      (-((b >> 3) & 1) & 0x3d4233dd) ^
      (-((b >> 4) & 1) & 0x2a1462b3));
}

int _polymod(String hrp, List<int> words)
  => [1, ..._hrpExpand(hrp), ...words].reduce((a, b) => _polymodStep(a) ^ b);

List<int> _checksum(String hrp, List<int> words, int checkConst) {
  final polymod = _polymod(hrp, [...words,0,0,0,0,0,0]) ^ checkConst;
  return List.generate(6, (i) => (polymod >> 5 * (5 - i)) & 31);
}

/// Converts [data] from "[from]" bits to "[to]" bits with optional padding
/// ([pad]). Returns the new data or null if conversion was not possible.
/// Used to convert to and from the 5-bit words for bech32.
List<int>? convertBits(List<int> data, int from, int to, bool pad) {

  var acc = 0;
  var bits = 0;
  List<int> result = [];
  final maxv = (1 << to) - 1;

  for (final v in data) {
    if (v < 0 || (v >> from) != 0) return null;
    acc = (acc << from) | v;
    bits += from;
    while (bits >= to) {
      bits -= to;
      result.add((acc >> bits) & maxv);
    }
  }

  if (pad) {
    if (bits > 0) {
      result.add((acc << (to - bits)) & maxv);
    }
  } else if (bits >= from || ((acc << (to - bits)) & maxv) != 0) {
    return null;
  }

  return result;

}

class InvalidBech32 implements Exception {
  final String message;
  InvalidBech32([this.message = ""]);
}
class InvalidBech32Checksum implements Exception {}

enum Bech32Type { bech32, bech32m }

/// Encapsules 5-bit words that can be bech32 encoded and decoded. The 5-bit
/// words may need to be further converted into the required data.
class Bech32 {

  static const maxLength = 90;
  static const checksumLength = 6;
  static const bech32CheckConst = 1;
  static const bech32mCheckConst = 0x2bc830a3;

  final String hrp;
  final List<int> words;
  final Bech32Type type;

  Bech32._skipValidation({
    required this.hrp, required List<int> words, required this.type,
  }): words = List.unmodifiable(words);

  /// Creates an encodable object with the human-readable-part ([hrp]), [words]
  /// for the given bech32 [type] (bech32 or bech32m).
  Bech32({
    required String hrp, required List<int> words, required this.type,
  }) : hrp = hrp.toLowerCase(), words = List.unmodifiable(words) {

    if (hrp.isEmpty) throw InvalidBech32("Missing HRP");
    _throwOnInvalidHrp(hrp);

    if (words.any((w) => w < 0 || w > 31)) {
      throw InvalidBech32("Words outside of 5-bit range");
    }

    if (hrp.length + 1 + words.length + checksumLength > maxLength) {
      throw InvalidBech32("Bech32 too long");
    }

  }

  /// Decodes a bech32 string into the hrp, 5-bit words and type. May throw an
  /// [InvalidBech32]. It will throw [InvalidBech32Checksum] if the bech32 is
  /// valid but doesn't have a valid checksum for either bech32 or bech32m.
  factory Bech32.decode(String encoded) {

    if (encoded.length > maxLength) {
      throw InvalidBech32("Bech32 too long");
    }

    final lower = encoded.toLowerCase();

    if (lower != encoded && encoded.toUpperCase() != encoded) {
      throw InvalidBech32("Bech32 cannot be mixed case");
    }

    final split = lower.lastIndexOf('1');
    if (split < 1) throw InvalidBech32("Missing HRP");
    if (lower.length - split - 1 < checksumLength) {
      throw InvalidBech32("Checksum too short");
    }

    final hrp = lower.substring(0, split);
    _throwOnInvalidHrp(hrp);

    final words = _charsToWords(lower.substring(split + 1));
    final dataWords = words.sublist(0, words.length - 6);

    if (words.any((w) => w == -1)) throw InvalidBech32("Invalid character");

    // Verify type
    final pm = _polymod(hrp, words);
    late Bech32Type type;
    if (pm == bech32CheckConst) {
      type = Bech32Type.bech32;
    } else if (pm == bech32mCheckConst) {
      type = Bech32Type.bech32m;
    } else {
      throw InvalidBech32Checksum();
    }

    final bech32 = Bech32._skipValidation(hrp: hrp, words: dataWords, type: type);
    bech32._encodedCache = encoded;
    return bech32;

  }

  String? _encodedCache;
  /// Encodes a bech32 string
  String encode() {

    if (_encodedCache != null) return _encodedCache!;

    final wordsWithChecksum = [
      ...words, ..._checksum(
        hrp, words,
        type == Bech32Type.bech32 ? bech32CheckConst : bech32mCheckConst,
      ),
    ];
    final encodedWords = wordsWithChecksum.map((w) => alphabet[w]).join();
    return _encodedCache = "${hrp}1$encodedWords";

  }

}

