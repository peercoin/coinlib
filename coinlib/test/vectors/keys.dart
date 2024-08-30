import 'package:coinlib/coinlib.dart';

class KeyTestVector {
  final String private;
  final String public;
  final bool compressed;
  final String wif;
  final int version;
  KeyTestVector({
    required this.private,
    required this.public,
    required this.compressed,
    required this.wif,
    required this.version,
  });
  ECPrivateKey get privateObj => ECPrivateKey.fromHex(private, compressed: compressed);
  ECPublicKey get publicObj => ECPublicKey.fromHex(public);
}

final pubkeyVec = "0279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798";
final longPubkeyVec = "0479be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8";
final pubkeyhashVec = "751e76e8199196d454941c45d1b3a323f1433bd6";
final xOnlyPubkeyVec = "d69c3509bb99e412e68b0fe8544e72837dfa30746d8be2aa65975f29d22dc7b9";

final keyPairVectors = [
  KeyTestVector(
    private: "0000000000000000000000000000000000000000000000000000000000000001",
    public: "0279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798",
    compressed: true,
    wif: "KwDiBf89QgGbjEhKnhXJuH7LrciVrZi3qYjgd9M7rFU73sVHnoWn",
    version: 0x80,
  ),
  KeyTestVector(
    private: "0000000000000000000000000000000000000000000000000000000000000001",
    public: "0479be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8",
    compressed: false,
    wif: "5HpHagT65TZzG1PH3CSu63k8DbpvD8s5ip4nEB3kEsreAnchuDf",
    version: 0x80,
  ),
  KeyTestVector(
    private: "2bfe58ab6d9fd575bdc3a624e4825dd2b375d64ac033fbc46ea79dbab4f69a3e",
    public: "02b80011a883a0fd621ad46dfc405df1e74bf075cbaf700fd4aebef6e96f848340",
    compressed: true,
    wif: "KxhEDBQyyEFymvfJD96q8stMbJMbZUb6D1PmXqBWZDU2WvbvVs9o",
    version: 0x80,
  ),
  KeyTestVector(
    private: "6c4313b03f2e7324d75e642f0ab81b734b724e13fec930f309e222470236d66b",
    public: "024289801366bcee6172b771cf5a7f13aaecd237a0b9a1ff9d769cabc2e6b70a34",
    compressed: true,
    wif: "KzrA86mCVMGWnLGBQu9yzQa32qbxb5dvSK4XhyjjGAWSBKYX4rHx",
    version: 0x80,
  ),
  KeyTestVector(
    private: "6c4313b03f2e7324d75e642f0ab81b734b724e13fec930f309e222470236d66b",
    public: "044289801366bcee6172b771cf5a7f13aaecd237a0b9a1ff9d769cabc2e6b70a34cec320a0565fb7caf11b1ca2f445f9b7b012dda5718b3cface369ee3a034ded6",
    compressed: false,
    wif: "5JdxzLtFPHNe7CAL8EBC6krdFv9pwPoRo4e3syMZEQT9srmK8hh",
    version: 0x80,
  ),
  KeyTestVector(
    private: "6c4313b03f2e7324d75e642f0ab81b734b724e13fec930f309e222470236d66b",
    public: "024289801366bcee6172b771cf5a7f13aaecd237a0b9a1ff9d769cabc2e6b70a34",
    compressed: true,
    wif: "cRD9b1m3vQxmwmjSoJy7Mj56f4uNFXjcWMCzpQCEmHASS4edEwXv",
    version: 0xef,
  ),
  KeyTestVector(
    private: "6c4313b03f2e7324d75e642f0ab81b734b724e13fec930f309e222470236d66b",
    public: "044289801366bcee6172b771cf5a7f13aaecd237a0b9a1ff9d769cabc2e6b70a34cec320a0565fb7caf11b1ca2f445f9b7b012dda5718b3cface369ee3a034ded6",
    compressed: false,
    wif: "92Qba5hnyWSn5Ffcka56yMQauaWY6ZLd91Vzxbi4a9CCetaHtYj",
    version: 0xef,
  ),
  KeyTestVector(
    private: "fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364140",
    public: "0379be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798",
    compressed: true,
    wif: "L5oLkpV3aqBjhki6LmvChTCV6odsp4SXM6FfU2Gppt5kFLaHLuZ9",
    version: 0x80,
  ),
];

class PubkeyVector {
  final String hex;
  final bool compressed;
  final bool evenY;
  PubkeyVector(this.hex, { required this.compressed, required this.evenY });
}

final validPubKeys = [
  PubkeyVector(
    "022bbfc800cdca5d0b63afc430bf700a8003864b979a56fda839990488a357d92d",
    compressed: true,
    evenY: true,
  ),
  PubkeyVector(
    "0307174f6d0c55806fb4f6b6112f2d74a90d8236bf230a0d4b99e5e2131448c209",
    compressed: true,
    evenY: false,
  ),
  PubkeyVector(
    "0439dfcfb935d6766b50e6af75630a3e72f2525014016cff0e46b2dc3d2c2b7b867707f63d3b254eb35287fc30138227286b8b56cee63c96ae4edccc5cd9f5c902",
    compressed: false,
    evenY: true,
  ),
  PubkeyVector(
    "06ef164284e2c3abc32b310eb62904af0d49196c51087bdf4038998f8818787c882433ae83422904f48ad36dcf351ac9a37e6b00e57cf40b469b650ec850640efe",
    compressed: false,
    evenY: true,
  ),
  PubkeyVector(
    "07576168b540f6f80e4d2a325f8cbd420ceb170ff42cd07e96bffc5e6a4a4ea04b1208f618306fd629cd2972cea45aa81ae7b24a64bf2e86704d7a63d82fd97a8f",
    compressed: false,
    evenY: false,
  ),
];

final invalidPubKeys = [
  // Wrong type for compressed
  "042bbfc800cdca5d0b63afc430bf700a8003864b979a56fda839990488a357d92d",
  // Wrong type for uncompressed
  "0339dfcfb935d6766b50e6af75630a3e72f2525014016cff0e46b2dc3d2c2b7b867707f63d3b254eb35287fc30138227286b8b56cee63c96ae4edccc5cd9f5c902",
];

// Assuming private key = 1
final invalidTweaks = [
  // Note that 0 scalars are allowed
  "fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364140",
  "fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141",
];
