
import 'package:coinlib/coinlib.dart';

class KeyTestVector {
  final String private;
  final String public;
  final bool compressed;
  final String wif;
  KeyTestVector({
    required this.private,
    required this.public,
    required this.compressed,
    required this.wif,
  });
  get privateObj => ECPrivateKey.fromHex(private, compressed: compressed);
}

final keyPairVectors = [
  KeyTestVector(
    private: "0000000000000000000000000000000000000000000000000000000000000001",
    public: "0279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798",
    compressed: true,
    wif: "KwDiBf89QgGbjEhKnhXJuH7LrciVrZi3qYjgd9M7rFU73sVHnoWn",
  ),
  KeyTestVector(
    private: "0000000000000000000000000000000000000000000000000000000000000001",
    public: "0479be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8",
    compressed: false,
    wif: "5HpHagT65TZzG1PH3CSu63k8DbpvD8s5ip4nEB3kEsreAnchuDf",
  ),
  KeyTestVector(
    private: "2bfe58ab6d9fd575bdc3a624e4825dd2b375d64ac033fbc46ea79dbab4f69a3e",
    public: "02b80011a883a0fd621ad46dfc405df1e74bf075cbaf700fd4aebef6e96f848340",
    compressed: true,
    wif: "KxhEDBQyyEFymvfJD96q8stMbJMbZUb6D1PmXqBWZDU2WvbvVs9o",
  ),
  KeyTestVector(
    private: "6c4313b03f2e7324d75e642f0ab81b734b724e13fec930f309e222470236d66b",
    public: "024289801366bcee6172b771cf5a7f13aaecd237a0b9a1ff9d769cabc2e6b70a34",
    compressed: true,
    wif: "KzrA86mCVMGWnLGBQu9yzQa32qbxb5dvSK4XhyjjGAWSBKYX4rHx",
  ),
  KeyTestVector(
    private: "6c4313b03f2e7324d75e642f0ab81b734b724e13fec930f309e222470236d66b",
    public: "044289801366bcee6172b771cf5a7f13aaecd237a0b9a1ff9d769cabc2e6b70a34cec320a0565fb7caf11b1ca2f445f9b7b012dda5718b3cface369ee3a034ded6",
    compressed: false,
    wif: "5JdxzLtFPHNe7CAL8EBC6krdFv9pwPoRo4e3syMZEQT9srmK8hh",
  ),
  KeyTestVector(
    private: "6c4313b03f2e7324d75e642f0ab81b734b724e13fec930f309e222470236d66b",
    public: "024289801366bcee6172b771cf5a7f13aaecd237a0b9a1ff9d769cabc2e6b70a34",
    compressed: true,
    wif: "cRD9b1m3vQxmwmjSoJy7Mj56f4uNFXjcWMCzpQCEmHASS4edEwXv",
  ),
  KeyTestVector(
    private: "6c4313b03f2e7324d75e642f0ab81b734b724e13fec930f309e222470236d66b",
    public: "044289801366bcee6172b771cf5a7f13aaecd237a0b9a1ff9d769cabc2e6b70a34cec320a0565fb7caf11b1ca2f445f9b7b012dda5718b3cface369ee3a034ded6",
    compressed: false,
    wif: "92Qba5hnyWSn5Ffcka56yMQauaWY6ZLd91Vzxbi4a9CCetaHtYj",
  ),
  KeyTestVector(
    private: "fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364140",
    public: "0379be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798",
    compressed: true,
    wif: "L5oLkpV3aqBjhki6LmvChTCV6odsp4SXM6FfU2Gppt5kFLaHLuZ9",
  )
];
