import 'dart:typed_data';
import 'package:coinlib/coinlib.dart';
import 'package:test/test.dart';

const String txHex =
"02000000097de20cbff686da83a54981d2b9bab3586f4ca7e48f57f5b55963115f3b334e9c010000000000000000d7b7cab57b1393ace2d064f4d4a2cb8af6def61273e127517d44759b6dafdd990000000000fffffffff8e1f583384333689228c5d28eac13366be082dc57441760d957275419a418420000000000fffffffff0689180aa63b30cb162a73c6d2a38b7eeda2a83ece74310fda0843ad604853b0100000000feffffffaa5202bdf6d8ccd2ee0f0202afbbb7461d9264a25e5bfd3c5a52ee1239e0ba6c0000000000feffffff956149bdc66faa968eb2be2d2faa29718acbfe3941215893a2a3446d32acd050000000000000000000e664b9773b88c09c32cb70a2a3e4da0ced63b7ba3b22f848531bbb1d5d5f4c94010000000000000000e9aa6b8e6c9de67619e6a3924ae25696bb7b694bb677a632a74ef7eadfd4eabf0000000000ffffffffa778eb6a263dc090464cd125c466b5a99667720b1c110468831d058aa1b82af10100000000ffffffff0200ca9a3b000000001976a91406afd46bcdfd22ef94ac122aa11f241244a37ecc88ac807840cb0000000020ac9a87f5594be208f8532db38cff670c450ed2fea8fcdefcc9a663f78bab962b0065cd1d";

final prevOuts = [
  Output.fromScriptBytes(
    BigInt.parse("420000000"),
    hexToBytes("512053a1f6e454df1aa2776a2814a721372d6258050de330b3c6d10ee8f4e0dda343"),
  ),
  Output.fromScriptBytes(
    BigInt.parse("462000000"),
    hexToBytes("5120147c9c57132f6e7ecddba9800bb0c4449251c92a1e60371ee77557b6620f3ea3"),
  ),
  Output.fromScriptBytes(
    BigInt.parse("294000000"),
    hexToBytes("76a914751e76e8199196d454941c45d1b3a323f1433bd688ac"),
  ),
  Output.fromScriptBytes(
    BigInt.parse("504000000"),
    hexToBytes("5120e4d810fd50586274face62b8a807eb9719cef49c04177cc6b76a9a4251d5450e"),
  ),
  Output.fromScriptBytes(
    BigInt.parse("630000000"),
    hexToBytes("512091b64d5324723a985170e4dc5a0f84c041804f2cd12660fa5dec09fc21783605"),
  ),
  Output.fromScriptBytes(
    BigInt.parse("378000000"),
    hexToBytes("00147dd65592d0ab2fe0d0257d571abf032cd9db93dc"),
  ),
  Output.fromScriptBytes(
    BigInt.parse("672000000"),
    hexToBytes("512075169f4001aa68f15bbed28b218df1d0a62cbbcf1188c6665110c293c907b831"),
  ),
  Output.fromScriptBytes(
    BigInt.parse("546000000"),
    hexToBytes("5120712447206d7a5238acc7ff53fbe94a3b64539ad291c7cdbc490b7577e4b17df5"),
  ),
  Output.fromScriptBytes(
    BigInt.parse("588000000"),
    hexToBytes("512077e30a5522dd9f894c3f8b8bd4c4b2cf82ca7da8a3ea6a239655c39c050ab220"),
  ),
];

class TaprootSignatureVector {

  final int inputN;
  final SigHashType hashType;
  final bool useLeafHash;
  final String sigHashHex;

  TaprootSignatureVector({
    required this.inputN,
    required this.hashType,
    this.useLeafHash = false,
    required this.sigHashHex,
  });

  Uint8List? get leafHash => useLeafHash
    ? hexToBytes(
        "2bfe58ab6d9fd575bdc3a624e4825dd2b375d64ac033fbc46ea79dbab4f69a3e",
      )
    : null;

}

final taprootSigVectors = [
  TaprootSignatureVector(
    inputN: 0,
    hashType: SigHashType.single(),
    sigHashHex: "2514a6272f85cfa0f45eb907fcb0d121b808ed37c6ea160a5a9046ed5526d555",
  ),
  TaprootSignatureVector(
    inputN: 1,
    hashType: SigHashType.single(inputs: InputSigHashOption.anyOneCanPay),
    sigHashHex: "325a644af47e8a5a2591cda0ab0723978537318f10e6a63d4eed783b96a71a4d",
  ),
  TaprootSignatureVector(
    inputN: 3,
    hashType: SigHashType.all(),
    sigHashHex: "bf013ea93474aa67815b1b6cc441d23b64fa310911d991e713cd34c7f5d46669",
  ),
  TaprootSignatureVector(
    inputN: 4,
    hashType: SigHashType.schnorrDefault(),
    sigHashHex: "4f900a0bae3f1446fd48490c2958b5a023228f01661cda3496a11da502a7f7ef",
  ),
  TaprootSignatureVector(
    inputN: 6,
    hashType: SigHashType.none(),
    sigHashHex: "15f25c298eb5cdc7eb1d638dd2d45c97c4c59dcaec6679cfc16ad84f30876b85",
  ),
  TaprootSignatureVector(
    inputN: 7,
    hashType: SigHashType.none(inputs: InputSigHashOption.anyOneCanPay),
    sigHashHex: "cd292de50313804dabe4685e83f923d2969577191a3e1d2882220dca88cbeb10",
  ),
  TaprootSignatureVector(
    inputN: 8,
    hashType: SigHashType.all(inputs: InputSigHashOption.anyOneCanPay),
    sigHashHex: "cccb739eca6c13a8a89e6e5cd317ffe55669bbda23f2fd37b0f18755e008edd2",
  ),
  TaprootSignatureVector(
    inputN: 0,
    hashType: SigHashType.single(),
    sigHashHex: "20834f382e040a8b6d03600667c2c593b4ffa955f15476ba3b70b72c2538320c",
    useLeafHash: true,
  ),
  TaprootSignatureVector(
    inputN: 0,
    hashType: SigHashType.all(inputs: InputSigHashOption.anyPrevOut),
    sigHashHex: "d36ed3bfe384ab0308b3ee90d1f11d1ad9624072f3bfa47580ff2b9a07c25d16",
    useLeafHash: true,
  ),
  TaprootSignatureVector(
    inputN: 0,
    hashType: SigHashType.all(inputs: InputSigHashOption.anyPrevOutAnyScript),
    sigHashHex: "16c8b2007c8c66d708f536a8b676fc7d392de8e0bfb009da9343f9c9e9be3bf9",
    useLeafHash: true,
  ),
];

void main() {

  late Transaction tx;

  setUpAll(() async {
    await loadCoinlib();
    tx = Transaction.fromHex(txHex);
  });

  test("produces correct signature hash", () {
    for (final vec in taprootSigVectors) {
      expect(
        bytesToHex(
          TaprootSignatureHasher(
            TaprootSignDetails(
              tx: tx,
              inputN: vec.inputN,
              prevOuts: (vec.hashType.anyOneCanPay || vec.hashType.anyPrevOut)
                ? [prevOuts[vec.inputN]]
                : (vec.hashType.anyPrevOutAnyScript ? [] : prevOuts),
              isScript: vec.leafHash != null,
              leafHash: vec.leafHash,
              hashType: vec.hashType,
            ),
          ).hash,
        ),
        vec.sigHashHex,
      );
    }
  });

  test("input out of range", () => expect(
    () => TaprootSignatureHasher(
      TaprootKeySignDetails(
        tx: tx,
        inputN: 9,
        prevOuts: prevOuts,
        hashType: SigHashType.all(),
      ),
    ),
    throwsArgumentError,
  ),);

  test("prevOuts length incorrect", () {
    for(final (hashType, length) in [
      (SigHashType.all(), prevOuts.length-1),
      (SigHashType.all(inputs: InputSigHashOption.anyOneCanPay), prevOuts.length),
      (SigHashType.all(inputs: InputSigHashOption.anyPrevOut), prevOuts.length),
      (
        SigHashType.all(inputs: InputSigHashOption.anyPrevOutAnyScript),
        prevOuts.length,
      ),
      (SigHashType.all(inputs: InputSigHashOption.anyOneCanPay), 2),
      (SigHashType.all(inputs: InputSigHashOption.anyPrevOut), 2),
      (SigHashType.all(inputs: InputSigHashOption.anyPrevOutAnyScript), 1),
    ]) {
      () => expect(
        () => TaprootSignatureHasher(
          TaprootKeySignDetails(
            tx: tx,
            inputN: 0,
            prevOuts: prevOuts.sublist(0, length),
            hashType: hashType,
          ),
        ),
        throwsArgumentError,
      );
    }
  });

}
