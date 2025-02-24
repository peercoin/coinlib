import 'package:coinlib/coinlib.dart';

final validSignatures = [
  "a951b0cf98bd51c614c802a65a418fa42482dc5c45c9394e39c0d98773c51cd530104fdc36d91582b5757e1de73d982e803cc14d75e82c65daf924e38d27d834",
  "00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
  "fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364140fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364140",
];

final invalidSignatures = [
  "fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364140",
  "fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364140fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141",
];

final validDerSigs = [
  "3046022100813ef79ccefa9a56f7ba805f0e478584fe5f0dd5f567bc09b5123ccbc9832365022100900e75ad233fcc908509dbff5922647db37c21f4afd3203ae8dc4ae7794b0f87",
  "3046022100fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364140022100fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364140",
  "3006020101020101",
  "3006020100020100",
];

final invalidDerSigs = [
  "300602020000020100",
  "300602010002020000",
  "3006020100020100ff",
  "30060201000201",
  "4006020100020100",
  "3006030100020100",
  "3006020100030100",
  "3006020100020200",
  "3007020100020100",
  "3005020100020100",
];

final validSchnorrSig = "e907831f80848d1069a5371b402410364bdf1c5f8307b0084c55f1ce2dca821525f66a4a85ea8b71e482a74f382d2ce5ebeee8fdb2172f477df4900d310536c0";

class RecSigVector {
  final String compact;
  final bool compressed;
  final int recid;
  final String? pubkey;
  RecSigVector({
    required this.compact,
    required this.compressed,
    required this.recid,
    required this.pubkey,
  });
  String get signature => compact.substring(2);
}

final validRecoverableSigs = [
  // Compressed
  RecSigVector(
    compact: "201faf14ade8fd0e1a3e7a426cec7c1298d64a7a647a6fdd5926fc745eda006e4a4bd7ad09896ddb98e7aac15bb0c09b4d95cb48a8099d946d36738c582853a876",
    compressed: true,
    recid: 1,
    pubkey: "0335d4392797482c7531bf5c21464f8a4c64508b5feef83ba6e435dad04a3a35fe",
  ),
  // Uncompressed
  RecSigVector(
    compact: "1c1faf14ade8fd0e1a3e7a426cec7c1298d64a7a647a6fdd5926fc745eda006e4a4bd7ad09896ddb98e7aac15bb0c09b4d95cb48a8099d946d36738c582853a876",
    compressed: false,
    recid: 1,
    pubkey: "0435d4392797482c7531bf5c21464f8a4c64508b5feef83ba6e435dad04a3a35fe952f0c59b0bd8f99092657cdd3688ded3ce2cd0043e88424d475924c6424647b",
  ),
  // Good luck finding a signature with overflowing public key with recids 3 and 4
  RecSigVector(
    compact: "221faf14ade8fd0e1a3e7a426cec7c1298d64a7a647a6fdd5926fc745eda006e4a4bd7ad09896ddb98e7aac15bb0c09b4d95cb48a8099d946d36738c582853a876",
    compressed: true,
    recid: 3,
    pubkey: null,
  ),
  // A null signature (zeroed) will return a null public key
  RecSigVector(
    compact: "2000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
    compressed: true,
    recid: 1,
    pubkey: null,
  ),
];

final validRecSigSigns = [
  RecSigVector(
    compact: "20f2f7cfb77e04c808556500d39008337e9b02a788045d03de0a727636b6497675383ed64a7023d4850f99985fa8fbd7528ca803685db3d8376f10720436d3ed84",
    compressed: true,
    recid: 1,
    pubkey: "024289801366bcee6172b771cf5a7f13aaecd237a0b9a1ff9d769cabc2e6b70a34",
  ),
  RecSigVector(
    compact: "1cf2f7cfb77e04c808556500d39008337e9b02a788045d03de0a727636b6497675383ed64a7023d4850f99985fa8fbd7528ca803685db3d8376f10720436d3ed84",
    compressed: false,
    recid: 1,
    pubkey: "044289801366bcee6172b771cf5a7f13aaecd237a0b9a1ff9d769cabc2e6b70a34cec320a0565fb7caf11b1ca2f445f9b7b012dda5718b3cface369ee3a034ded6",
  ),
];

final sigHashAOCP = SigHashType.all(inputs: InputSigHashOption.anyOneCanPay);
final sigHashAPO = SigHashType.all(inputs: InputSigHashOption.anyPrevOut);
final sigHashAPOAS = SigHashType.all(inputs: InputSigHashOption.anyPrevOutAnyScript);

SchnorrInputSignature _sigForType(SigHashType type) => SchnorrInputSignature(
  SchnorrSignature.fromHex(validSchnorrSig),
  type,
);

final schnorrInSig = _sigForType(SigHashType.none());
final schnorrInSigAPO = _sigForType(sigHashAPO);
final schnorrInSigAPOAS = _sigForType(sigHashAPOAS);
