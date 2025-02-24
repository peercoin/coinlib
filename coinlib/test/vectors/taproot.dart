import 'package:coinlib/coinlib.dart';

class TaprootVector {

  final Taproot object;
  final String tweakScalarHex;
  final String xTweakedKeyHex;

  final List<String> leafHashes;
  final List<String> controlBlocks;

  TaprootVector({
    required this.object,
    required this.tweakScalarHex,
    required this.xTweakedKeyHex,
    this.leafHashes = const [],
    this.controlBlocks = const [],
  });

}

TapLeaf leafFromHex(String hex) => TapLeaf(
  Script.decompile(hexToBytes(hex)),
);

final taprootVectors = [

  TaprootVector(
    object: Taproot(
      internalKey: ECPublicKey.fromXOnlyHex(
        "d6889cb081036e0faefa3a35157ad71086b123b2b144b649798b494c300a961d",
      ),
    ),
    tweakScalarHex: "b86e7be8f39bab32a6f2c0443abbc210f0edac0e2c53d501b36b64437d9c6c70",
    xTweakedKeyHex: "53a1f6e454df1aa2776a2814a721372d6258050de330b3c6d10ee8f4e0dda343",
  ),

  TaprootVector(
    object: Taproot(
      internalKey: ECPublicKey.fromXOnlyHex(
        "187791b6f712a8ea41c8ecdd0ee77fab3e85263b37e1ec18a3651926b3a6cf27",
      ),
      mast: leafFromHex(
        "20d85a959b0290bf19bb89ed43c916be835475d013da4b362117393e25a48229b8ac",
      ),
    ),
    tweakScalarHex: "cbd8679ba636c1110ea247542cfbd964131a6be84f873f7f3b62a777528ed001",
    xTweakedKeyHex: "147c9c57132f6e7ecddba9800bb0c4449251c92a1e60371ee77557b6620f3ea3",
    leafHashes: [
      "5b75adecf53548f3ec6ad7d78383bf84cc57b55a3127c72b9a2481752dd88b21",
    ],
    controlBlocks: [
      "c1187791b6f712a8ea41c8ecdd0ee77fab3e85263b37e1ec18a3651926b3a6cf27",
    ],
  ),

  TaprootVector(
    object: Taproot(
      internalKey: ECPublicKey.fromXOnlyHex(
        "93478e9488f956df2396be2ce6c5cced75f900dfa18e7dabd2428aae78451820",
      ),
      mast: leafFromHex(
        "20b617298552a72ade070667e86ca63b8f5789a9fe8731ef91202a91c9f3459007ac",
      ),
    ),
    tweakScalarHex: "6af9e28dbf9d6aaf027696e2598a5b3d056f5fd2355a7fd5a37a0e5008132d30",
    xTweakedKeyHex: "e4d810fd50586274face62b8a807eb9719cef49c04177cc6b76a9a4251d5450e",
    leafHashes: [
      "c525714a7f49c28aedbbba78c005931a81c234b2f6c99a73e4d06082adc8bf2b",
    ],
    controlBlocks: [
      "c093478e9488f956df2396be2ce6c5cced75f900dfa18e7dabd2428aae78451820",
    ],
  ),

  TaprootVector(
    object: Taproot(
      internalKey: ECPublicKey.fromXOnlyHex(
        "f9f400803e683727b14f463836e1e78e1c64417638aa066919291a225f0e8dd8",
      ),
      mast: TapBranch(
        leafFromHex(
          "2044b178d64c32c4a05cc4f4d1407268f764c940d20ce97abfd44db5c3592b72fdac",
        ),
        leafFromHex("07546170726f6f74"),
      ),
    ),
    tweakScalarHex: "639f0281b7ac49e742cd25b7f188657626da1ad169209078e2761cefd91fd65e",
    xTweakedKeyHex: "77e30a5522dd9f894c3f8b8bd4c4b2cf82ca7da8a3ea6a239655c39c050ab220",
    leafHashes: [
      "64512fecdb5afa04f98839b50e6f0cb7b1e539bf6f205f67934083cdcc3c8d89",
      "2cb2b90daa543b544161530c925f285b06196940d6085ca9474d41dc3822c5cb",
    ],
    controlBlocks: [
      "c1f9f400803e683727b14f463836e1e78e1c64417638aa066919291a225f0e8dd82cb2b90daa543b544161530c925f285b06196940d6085ca9474d41dc3822c5cb",
      "c1f9f400803e683727b14f463836e1e78e1c64417638aa066919291a225f0e8dd864512fecdb5afa04f98839b50e6f0cb7b1e539bf6f205f67934083cdcc3c8d89",
    ],
  ),

  TaprootVector(
    object: Taproot(
      internalKey: ECPublicKey.fromXOnlyHex(
        "e0dfe2300b0dd746a3f8674dfd4525623639042569d829c7f0eed9602d263e6f",
      ),
      mast: TapBranch(
        leafFromHex(
          "2072ea6adcf1d371dea8fba1035a09f3d24ed5a059799bae114084130ee5898e69ac",
        ),
        TapBranch(
          leafFromHex(
            "202352d137f2f3ab38d1eaa976758873377fa5ebb817372c71e2c542313d4abda8ac",
          ),
          leafFromHex(
            "207337c0dd4253cb86f2c43a2351aadd82cccb12a172cd120452b9bb8324f2186aac",
          ),
        ),
      ),
    ),
    tweakScalarHex: "b57bfa183d28eeb6ad688ddaabb265b4a41fbf68e5fed2c72c74de70d5a786f4",
    xTweakedKeyHex: "91b64d5324723a985170e4dc5a0f84c041804f2cd12660fa5dec09fc21783605",
    leafHashes: [
      "2645a02e0aac1fe69d69755733a9b7621b694bb5b5cde2bbfc94066ed62b9817",
      "ba982a91d4fc552163cb1c0da03676102d5b7a014304c01f0c77b2b8e888de1c",
      "9e31407bffa15fefbf5090b149d53959ecdf3f62b1246780238c24501d5ceaf6",
    ],
    controlBlocks: [
      "c0e0dfe2300b0dd746a3f8674dfd4525623639042569d829c7f0eed9602d263e6fffe578e9ea769027e4f5a3de40732f75a88a6353a09d767ddeb66accef85e553",
      "c0e0dfe2300b0dd746a3f8674dfd4525623639042569d829c7f0eed9602d263e6f9e31407bffa15fefbf5090b149d53959ecdf3f62b1246780238c24501d5ceaf62645a02e0aac1fe69d69755733a9b7621b694bb5b5cde2bbfc94066ed62b9817",
      "c0e0dfe2300b0dd746a3f8674dfd4525623639042569d829c7f0eed9602d263e6fba982a91d4fc552163cb1c0da03676102d5b7a014304c01f0c77b2b8e888de1c2645a02e0aac1fe69d69755733a9b7621b694bb5b5cde2bbfc94066ed62b9817",
    ],
  ),

  TaprootVector(
    object: Taproot(
      internalKey: ECPublicKey.fromXOnlyHex(
        "55adf4e8967fbd2e29f20ac896e60c3b0f1d5b0efa9d34941b5958c7b0a0312d",
      ),
      mast: TapBranch(
        leafFromHex(
          "2071981521ad9fc9036687364118fb6ccd2035b96a423c59c5430e98310a11abe2ac",
        ),
        TapBranch(
          leafFromHex(
            "20d5094d2dbe9b76e2c245a2b89b6006888952e2faa6a149ae318d69e520617748ac",
          ),
          leafFromHex(
            "20c440b462ad48c7a77f94cd4532d8f2119dcebbd7c9764557e62726419b08ad4cac",
          ),
        ),
      ),
    ),
    tweakScalarHex: "6579138e7976dc13b6a92f7bfd5a2fc7684f5ea42419d43368301470f3b74ed9",
    xTweakedKeyHex: "75169f4001aa68f15bbed28b218df1d0a62cbbcf1188c6665110c293c907b831",
    leafHashes: [
      "f154e8e8e17c31d3462d7132589ed29353c6fafdb884c5a6e04ea938834f0d9d",
      "737ed1fe30bc42b8022d717b44f0d93516617af64a64753b7a06bf16b26cd711",
      "d7485025fceb78b9ed667db36ed8b8dc7b1f0b307ac167fa516fe4352b9f4ef7",
    ],
    controlBlocks: [
      "c155adf4e8967fbd2e29f20ac896e60c3b0f1d5b0efa9d34941b5958c7b0a0312d3cd369a528b326bc9d2133cbd2ac21451acb31681a410434672c8e34fe757e91",
      "c155adf4e8967fbd2e29f20ac896e60c3b0f1d5b0efa9d34941b5958c7b0a0312dd7485025fceb78b9ed667db36ed8b8dc7b1f0b307ac167fa516fe4352b9f4ef7f154e8e8e17c31d3462d7132589ed29353c6fafdb884c5a6e04ea938834f0d9d",
      "c155adf4e8967fbd2e29f20ac896e60c3b0f1d5b0efa9d34941b5958c7b0a0312d737ed1fe30bc42b8022d717b44f0d93516617af64a64753b7a06bf16b26cd711f154e8e8e17c31d3462d7132589ed29353c6fafdb884c5a6e04ea938834f0d9d",
    ],
  ),

];

final exampleControlBlock = hexToBytes(
  "c093478e9488f956df2396be2ce6c5cced75f900dfa18e7dabd2428aae78451820",
);
