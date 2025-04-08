import 'dart:typed_data';
import 'package:coinlib/coinlib.dart';

class TxVector {
  Transaction obj;
  String hashHex;
  String txidHex;
  bool isWitness;
  bool isCoinBase;
  bool isCoinStake;
  bool complete;
  int size;
  List<Type> inputTypes;
  String hex;
  String? legacyHex;
  TxVector({
    required this.obj,
    required this.hashHex,
    String? txidHex,
    required this.isWitness,
    required this.isCoinBase,
    required this.isCoinStake,
    required this.complete,
    required this.size,
    required this.inputTypes,
    required this.hex,
    this.legacyHex,
  }): txidHex = txidHex ?? hashHex;
}

final examplePrevOut = OutPoint.fromHex(
  "fefefefefefefefefefefefefefefefefefefefefefefefefefefefefefefef1", 0,
);
final exampleAltPrevOut = OutPoint(examplePrevOut.hash, 1);
final examplePubkey = ECPublicKey.fromHex(
  "0279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798",
);

final exampleOutput = Output.fromAddress(
  BigInt.from(100000),
  Address.fromString(
    "PSUVJAon4oTrVZgHEKg3UfppFEDP7gBSkt",
    Network.mainnet,
  ),
);

final exampleInsig = ECDSAInputSignature.fromBytes(
  hexToBytes(
    "30450221008732a460737d956fd94d49a31890b2908f7ed7025a9c1d0f25e43290f1841716022004fa7d608a291d44ebbbebbadaac18f943031e7de39ef3bf9920998c43e60c0401",
  ),
);

final exampleMultisig = MultisigProgram(
  2,
  [
    ECPublicKey.fromHex(
      "03df7940ee7cddd2f97763f67e1fb13488da3fbdd7f9c68ec5ef0864074745a289",
    ),
    ECPublicKey.fromHex(
      "03e05ce435e462ec503143305feb6c00e06a3ad52fbf939e85c65f3a765bb7baac",
    ),
    ECPublicKey.fromHex(
      "03aea0dfd576151cb399347aa6732f8fdf027b9ea3ea2e65fb754803f776e0a509",
    ),
  ]
);

final validTxVecs = [

  // P2PKH with 1 input and 1 output
  TxVector(
    obj: Transaction(
      version: 3,
      inputs: [
        P2PKHInput(
          prevOut: examplePrevOut,
          publicKey: examplePubkey,
          insig: exampleInsig,
        ),
      ],
      outputs: [exampleOutput],
    ),
    hashHex: "422440b9b5f046d03de2ebcb848d64d76ce88170555dcb73a8faea7a10d08572",
    isWitness: false,
    isCoinBase: false,
    isCoinStake: false,
    complete: true,
    size: 192,
    inputTypes: [P2PKHInput],
    hex: "0300000001f1fefefefefefefefefefefefefefefefefefefefefefefefefefefefefefefe000000006b4830450221008732a460737d956fd94d49a31890b2908f7ed7025a9c1d0f25e43290f1841716022004fa7d608a291d44ebbbebbadaac18f943031e7de39ef3bf9920998c43e60c0401210279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798ffffffff01a0860100000000001976a914c42e7ef92fdb603af844d064faad95db9bcdfd3d88ac00000000",
  ),

  // Transaction with 2 inputs and 2 outputs
  TxVector(
    obj: Transaction(
      version: 3,
      inputs: [
        P2PKHInput(
          prevOut: OutPoint.fromHex(
            "a0433f8dfe388be842d9b8c556416af23c3b8171c8f0029ae7c19097223eb7e7",
            0,
          ),
          publicKey: ECPublicKey.fromHex(
            "04aa592c859fd00ed2a02609aad3a1bf72e0b42de67713e632c70a33cc488c15598a0fb419370a54d1c275b44380e8777fc01b6dc3cd43a416c6bab0e30dc1e19f",
          ),
          insig: ECDSAInputSignature.fromBytes(
            hexToBytes(
              "3046022100fd3d8fef44fb0962ba3f07bee1d4cafb84e60e38e6c7d9274504b3638a8d2f520221009fce009044e615b6883d4bf62e04c48f9fe236e19d644b082b2f0ae5c98e045c01",
            ),
          ),
        ),
        P2PKHInput(
          prevOut: OutPoint.fromHex(
            "eaa79536e11b3158a11aa984eb2e57a6f6a002ddd77c7c0206a680385f00fc7b",
            1,
          ),
          publicKey: ECPublicKey.fromHex(
            "04aa592c859fd00ed2a02609aad3a1bf72e0b42de67713e632c70a33cc488c15598a0fb419370a54d1c275b44380e8777fc01b6dc3cd43a416c6bab0e30dc1e19f",
          ),
          insig: ECDSAInputSignature.fromBytes(
            hexToBytes(
              "3045022100e2e61c40f26e2510b76dc72ea2f568ec514fce185c719e18bca9caaef2b20e9e02207f1100fc79eb0584e970c7f18fb226f178951d481767b4092d50d13c50ccba8b01",
            ),
          ),
        ),
      ],
      outputs: [
        Output.fromAddress(
          BigInt.from(52680000),
          Address.fromString(
            "PAe4rizffK1jrg84AEoaYv75uyLoWgtbB1",
            Network.mainnet,
          ),
        ),
        Output.fromAddress(
          BigInt.from(3032597),
          Address.fromString(
            "PCLHR5x8X2bitLes8DiSMTswpc46zt6THo",
            Network.mainnet,
          ),
        ),
      ],
    ),
    hashHex: "6b1944794c215482f9b4532ccd0f982a3be80f0a349394cc2de2c95014c563be",
    isWitness: false,
    isCoinBase: false,
    isCoinStake: false,
    complete: true,
    size: 439,
    inputTypes: [P2PKHInput, P2PKHInput],
    hex: "0300000002e7b73e229790c1e79a02f0c871813b3cf26a4156c5b8d942e88b38fe8d3f43a0000000008c493046022100fd3d8fef44fb0962ba3f07bee1d4cafb84e60e38e6c7d9274504b3638a8d2f520221009fce009044e615b6883d4bf62e04c48f9fe236e19d644b082b2f0ae5c98e045c014104aa592c859fd00ed2a02609aad3a1bf72e0b42de67713e632c70a33cc488c15598a0fb419370a54d1c275b44380e8777fc01b6dc3cd43a416c6bab0e30dc1e19fffffffff7bfc005f3880a606027c7cd7dd02a0f6a6572eeb84a91aa158311be13695a7ea010000008b483045022100e2e61c40f26e2510b76dc72ea2f568ec514fce185c719e18bca9caaef2b20e9e02207f1100fc79eb0584e970c7f18fb226f178951d481767b4092d50d13c50ccba8b014104aa592c859fd00ed2a02609aad3a1bf72e0b42de67713e632c70a33cc488c15598a0fb419370a54d1c275b44380e8777fc01b6dc3cd43a416c6bab0e30dc1e19fffffffff0240d52303000000001976a914167c3e1f10cc3b691c73afbdb211e156e3e3f25c88ac15462e00000000001976a914290f7d617b75993e770e5606335fa0999a28d71388ac00000000",
  ),

  // Transaction with P2PKH input missing signature
  TxVector(
    obj: Transaction(
      version: 3,
      inputs: [P2PKHInput(prevOut: examplePrevOut, publicKey: examplePubkey)],
      outputs: [exampleOutput],
    ),
    hashHex: "38f460ea55b2676b0e5cc1483d63f97d66fb1648bdc508eee79a402a75b97f5b",
    isWitness: false,
    isCoinBase: false,
    isCoinStake: false,
    complete: false,
    size: 119,
    inputTypes: [P2PKHInput],
    hex: "0300000001f1fefefefefefefefefefefefefefefefefefefefefefefefefefefefefefefe0000000022210279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798ffffffff01a0860100000000001976a914c42e7ef92fdb603af844d064faad95db9bcdfd3d88ac00000000",
  ),

  // Transaction with P2PKH input missing output
  TxVector(
    obj: Transaction(
      version: 3,
      inputs: [
        P2PKHInput(
          prevOut: examplePrevOut,
          publicKey: examplePubkey,
          insig: exampleInsig,
        ),
      ],
      outputs: [],
    ),
    hashHex: "404c8e738ae31d63d8b26b7b056632779f8b1d27dfe9ef314d2649f005971910",
    isWitness: false,
    isCoinBase: false,
    isCoinStake: false,
    complete: false,
    size: 158,
    inputTypes: [P2PKHInput],
    hex:
    "0300000001f1fefefefefefefefefefefefefefefefefefefefefefefefefefefefefefefe000000006b4830450221008732a460737d956fd94d49a31890b2908f7ed7025a9c1d0f25e43290f1841716022004fa7d608a291d44ebbbebbadaac18f943031e7de39ef3bf9920998c43e60c0401210279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798ffffffff0000000000",
  ),

  // Transaction with complete P2SH 2-of-3 multisig
  TxVector(
    obj: Transaction(
      version: 3,
      inputs: [
        P2SHMultisigInput(
          prevOut: examplePrevOut,
          program: exampleMultisig,
          sigs: [
            ECDSAInputSignature.fromBytes(
              hexToBytes(
                "304402200773352a6c70b5ddfe8f6af883d9ea7b9abf7a96fdabe4d3b4a7a590f142c84402206fbf9b634221f206b7c99b3d9bc9dbdc5fec16536d7fd1eac352bbb4feff2a6f01",
              ),
            ),
            ECDSAInputSignature.fromBytes(
              hexToBytes(
                "304402207567ea17703e2df7993ce70ead3f9f051e3bf7b8dfcdc6e9edc7547c0c0c4ef302204332066de953f267db9c31ca934052f1cfabd4281fd2649f928a66b1deb604e701",
              ),
            ),
          ],
        ),
      ],
      outputs: [exampleOutput],
    ),
    hashHex: "1dcb0d65b0e5938b430ad49a197648d04b4f7d076d23870aba047f4884c785d7",
    isWitness: false,
    isCoinBase: false,
    isCoinStake: false,
    complete: true,
    size: 337,
    inputTypes: [P2SHMultisigInput],
    hex: "0300000001f1fefefefefefefefefefefefefefefefefefefefefefefefefefefefefefefe00000000fc0047304402200773352a6c70b5ddfe8f6af883d9ea7b9abf7a96fdabe4d3b4a7a590f142c84402206fbf9b634221f206b7c99b3d9bc9dbdc5fec16536d7fd1eac352bbb4feff2a6f0147304402207567ea17703e2df7993ce70ead3f9f051e3bf7b8dfcdc6e9edc7547c0c0c4ef302204332066de953f267db9c31ca934052f1cfabd4281fd2649f928a66b1deb604e7014c69522103df7940ee7cddd2f97763f67e1fb13488da3fbdd7f9c68ec5ef0864074745a2892103e05ce435e462ec503143305feb6c00e06a3ad52fbf939e85c65f3a765bb7baac2103aea0dfd576151cb399347aa6732f8fdf027b9ea3ea2e65fb754803f776e0a50953aeffffffff01a0860100000000001976a914c42e7ef92fdb603af844d064faad95db9bcdfd3d88ac00000000",
  ),

  // Transaction with P2SH 2-of-3 multisig and only 1 signature
  TxVector(
    obj: Transaction(
      version: 3,
      inputs: [
        P2SHMultisigInput(
          prevOut: examplePrevOut,
          program: exampleMultisig,
          sigs: [
            ECDSAInputSignature.fromBytes(
              hexToBytes(
                "304402207567ea17703e2df7993ce70ead3f9f051e3bf7b8dfcdc6e9edc7547c0c0c4ef302204332066de953f267db9c31ca934052f1cfabd4281fd2649f928a66b1deb604e701",
              ),
            ),
          ],
        ),
      ],
      outputs: [exampleOutput],
    ),
    hashHex: "23fdd138ea95b7154017dc8e8b9e43c009aced55d0bc4b3d3f2eb2214223b378",
    isWitness: false,
    isCoinBase: false,
    isCoinStake: false,
    complete: false,
    size: 265,
    inputTypes: [P2SHMultisigInput],
    hex: "0300000001f1fefefefefefefefefefefefefefefefefefefefefefefefefefefefefefefe00000000b40047304402207567ea17703e2df7993ce70ead3f9f051e3bf7b8dfcdc6e9edc7547c0c0c4ef302204332066de953f267db9c31ca934052f1cfabd4281fd2649f928a66b1deb604e7014c69522103df7940ee7cddd2f97763f67e1fb13488da3fbdd7f9c68ec5ef0864074745a2892103e05ce435e462ec503143305feb6c00e06a3ad52fbf939e85c65f3a765bb7baac2103aea0dfd576151cb399347aa6732f8fdf027b9ea3ea2e65fb754803f776e0a50953aeffffffff01a0860100000000001976a914c42e7ef92fdb603af844d064faad95db9bcdfd3d88ac00000000",
  ),

  // Transaction with no inputs, one output and alternative locktime
  // This transaction ambiguously looks like a witness transaction
  TxVector(
    obj: Transaction(
      version: 3,
      inputs: [],
      outputs: [exampleOutput],
      locktime: 0x01020304,
    ),
    hashHex: "586cf7ffc988e620d69c4164f0eeff7a9ff89a04f6a13a7b9297d1819f4d1730",
    isWitness: false,
    isCoinBase: false,
    isCoinStake: false,
    complete: false,
    size: 44,
    inputTypes: [],
    hex:
    "030000000001a0860100000000001976a914c42e7ef92fdb603af844d064faad95db9bcdfd3d88ac04030201",
  ),

  // Transaction with no inputs or outputs
  TxVector(
    obj: Transaction(
      version: 3,
      inputs: [],
      outputs: [],
    ),
    hashHex: "d668682214aa0e8827974155a7c76562205c046ebaeb41e163457d03e9f02822",
    isWitness: false,
    isCoinBase: false,
    isCoinStake: false,
    complete: false,
    size: 10,
    inputTypes: [],
    hex:
    "03000000000000000000",
  ),

  // Bad output scripts
  TxVector(
    obj: Transaction(
      version: 3,
      inputs: [
        P2PKHInput(
          prevOut: OutPoint.fromHex(
            "6d7ed9914625c73c0288694a6819196a27ef6c08f98e1270d975a8e65a3dc09a",
            1,
          ),
          publicKey: ECPublicKey.fromHex(
            "02d5ede09a8ae667d0f855ef90325e27f6ce35bbe60a1e6e87af7f5b3c652140fd",
          ),
          insig: ECDSAInputSignature.fromBytes(
            hexToBytes(
              "30450221009d41dc793ba24e65f571473d40b299b6459087cea1509f0d381740b1ac863cb6022039c425906fcaf51b2b84d8092569fb3213de43abaff2180e2a799d4fcb4dd0aa01",
            ),
          ),
        ),
      ],
      outputs: [
        Output.fromScriptBytes(BigInt.from(1), hexToBytes("01")),
        Output.fromScriptBytes(BigInt.from(1), hexToBytes("0201")),
        Output.fromScriptBytes(BigInt.from(1), hexToBytes("4c")),
        Output.fromScriptBytes(BigInt.from(1), hexToBytes("4c0201")),
        Output.fromScriptBytes(BigInt.from(1), hexToBytes("4d")),
        Output.fromScriptBytes(BigInt.from(1), hexToBytes("4dffff01")),
        Output.fromScriptBytes(BigInt.from(1), hexToBytes("4e")),
        Output.fromScriptBytes(BigInt.from(1), hexToBytes("4effffffff01")),
      ],
    ),
    hashHex: "8a219c494ae2fb64cb052c7ff5fbf3d89b4c8a7d4f9cf1aa9e3ba5274cb7dd72",
    isWitness: false,
    isCoinBase: false,
    isCoinStake: false,
    complete: true,
    size: 249,
    inputTypes: [P2PKHInput],
    hex: "03000000019ac03d5ae6a875d970128ef9086cef276a1919684a6988023cc7254691d97e6d010000006b4830450221009d41dc793ba24e65f571473d40b299b6459087cea1509f0d381740b1ac863cb6022039c425906fcaf51b2b84d8092569fb3213de43abaff2180e2a799d4fcb4dd0aa012102d5ede09a8ae667d0f855ef90325e27f6ce35bbe60a1e6e87af7f5b3c652140fdffffffff080100000000000000010101000000000000000202010100000000000000014c0100000000000000034c02010100000000000000014d0100000000000000044dffff010100000000000000014e0100000000000000064effffffff0100000000",
  ),

  // Coinbase
  TxVector(
    obj: Transaction(
      version: 3,
      inputs: [
        RawInput(
          prevOut: OutPoint(Uint8List(32), 0xffffffff),
          scriptSig: hexToBytes(
            "032832051c4d696e656420627920416e74506f6f6c20626a343a45ef0454c5de8d5e5300004e2c0000",
          ),
        ),
      ],
      outputs: [
        Output.fromAddress(
          BigInt.from(2501463873),
          Address.fromString(
            "PQfazmXYxj7BKQG9jGbjKaQzYyi8AGEkH1",
            Network.mainnet,
          ),
        ),
      ],
    ),
    hashHex: "c018ee785bea0ce31228bb60afa049341bb52e018d1b59046432e9ab0016fb57",
    isWitness: false,
    isCoinBase: true,
    isCoinStake: false,
    complete: true,
    size: 126,
    inputTypes: [RawInput],
    hex: "03000000010000000000000000000000000000000000000000000000000000000000000000ffffffff29032832051c4d696e656420627920416e74506f6f6c20626a343a45ef0454c5de8d5e5300004e2c0000ffffffff01414f1995000000001976a914b05793fe86a9f51a5f5ae3a6f07fd31932128a3f88ac00000000",
  ),

  // Coinstake
  TxVector(
    obj: Transaction(
      version: 3,
      inputs: [
        P2PKHInput(
          prevOut: examplePrevOut,
          publicKey: examplePubkey,
          insig: exampleInsig,
        ),
      ],
      outputs: [
        Output.fromScriptBytes(BigInt.zero, Uint8List(0)),
        exampleOutput,
      ],
    ),
    hashHex: "aec4ced88705b0eec2efa176ccdf91d78d6ac8a54a010c2ed42d5b7314a729b4",
    isWitness: false,
    isCoinBase: false,
    isCoinStake: true,
    complete: true,
    size: 201,
    inputTypes: [P2PKHInput],
    hex: "0300000001f1fefefefefefefefefefefefefefefefefefefefefefefefefefefefefefefe000000006b4830450221008732a460737d956fd94d49a31890b2908f7ed7025a9c1d0f25e43290f1841716022004fa7d608a291d44ebbbebbadaac18f943031e7de39ef3bf9920998c43e60c0401210279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798ffffffff02000000000000000000a0860100000000001976a914c42e7ef92fdb603af844d064faad95db9bcdfd3d88ac00000000",
  ),

  // P2WPKH witness missing signature
  TxVector(
    obj: Transaction(
      version: 3,
      inputs: [P2WPKHInput(prevOut: examplePrevOut, publicKey: examplePubkey)],
      outputs: [exampleOutput],
    ),
    hashHex: "e6bc97ca65d94b014a73fbc66e7829e60eb174fab0ad67c765cbcb74b6f5b36c",
    txidHex: "e9c9d11d7cf15ed903e44374103938aba52d1a0dced03b1af08ac640f2cd1554",
    isWitness: true,
    isCoinBase: false,
    isCoinStake: false,
    complete: false,
    size: 122,
    inputTypes: [P2WPKHInput],
    hex: "03000000000101f1fefefefefefefefefefefefefefefefefefefefefefefefefefefefefefefe0000000000ffffffff01a0860100000000001976a914c42e7ef92fdb603af844d064faad95db9bcdfd3d88ac01210279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f8179800000000",
    legacyHex: "0300000001f1fefefefefefefefefefefefefefefefefefefefefefefefefefefefefefefe0000000000ffffffff01a0860100000000001976a914c42e7ef92fdb603af844d064faad95db9bcdfd3d88ac00000000",
  ),

  // P2WPKH witness with signature
  TxVector(
    obj: Transaction(
      version: 3,
      inputs: [
        P2WPKHInput(
          prevOut: examplePrevOut,
          publicKey: examplePubkey,
          insig: exampleInsig,
          sequence: 0x01020304,
        ),
      ],
      outputs: [exampleOutput],
    ),
    hashHex: "f1cd5422c06f2f1a59bfb45307ab56f1a1720da5af766c06a2317ba43dfefafc",
    txidHex: "366710a884b21e2e3f93738dea6f5b2f1eef559c2a4b66bdbbeec2a9c968244e",
    isWitness: true,
    isCoinBase: false,
    isCoinStake: false,
    complete: true,
    size: 195,
    inputTypes: [P2WPKHInput],
    hex: "03000000000101f1fefefefefefefefefefefefefefefefefefefefefefefefefefefefefefefe00000000000403020101a0860100000000001976a914c42e7ef92fdb603af844d064faad95db9bcdfd3d88ac024830450221008732a460737d956fd94d49a31890b2908f7ed7025a9c1d0f25e43290f1841716022004fa7d608a291d44ebbbebbadaac18f943031e7de39ef3bf9920998c43e60c0401210279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f8179800000000",
    legacyHex: "0300000001f1fefefefefefefefefefefefefefefefefefefefefefefefefefefefefefefe00000000000403020101a0860100000000001976a914c42e7ef92fdb603af844d064faad95db9bcdfd3d88ac00000000",
  ),

  // Unknown witness
  TxVector(
    obj: Transaction(
      version: 3,
      inputs: [
        WitnessInput(
          prevOut: examplePrevOut,
          witness: [Uint8List(0), Uint8List.fromList([0xff, 1, 2, 3])],
        ),
      ],
      outputs: [exampleOutput],
    ),
    hashHex: "ef839df6a0094f5af7a8d4bc704e0ea9ad201c956784e7d7d99350de502028b0",
    txidHex: "e9c9d11d7cf15ed903e44374103938aba52d1a0dced03b1af08ac640f2cd1554",
    isWitness: true,
    isCoinBase: false,
    isCoinStake: false,
    complete: true,
    size: 94,
    inputTypes: [WitnessInput],
    hex: "03000000000101f1fefefefefefefefefefefefefefefefefefefefefefefefefefefefefefefe0000000000ffffffff01a0860100000000001976a914c42e7ef92fdb603af844d064faad95db9bcdfd3d88ac020004ff01020300000000",
    legacyHex: "0300000001f1fefefefefefefefefefefefefefefefefefefefefefefefefefefefefefefe0000000000ffffffff01a0860100000000001976a914c42e7ef92fdb603af844d064faad95db9bcdfd3d88ac00000000",
  ),

];

// Should deserialize as both legacy and witness transactions
final ambiguousHex = "03000000000101000000000000002d00000000000000000000000000000000000000000000000000000000005151510b01010203040506070800010000000000";

final ambiguousLegacy = TxVector(
  obj: Transaction(
    version: 3,
    inputs: [],
    outputs: [
      Output.fromScriptBytes(
        BigInt.one,
        hexToBytes(
          "00000000000000000000000000000000000000000000000000000000005151510b010102030405060708000100",
        ),
      ),
    ],
  ),
  hashHex: "c484fd792a2b6abc72572da2fdfbe207edbab594b5b3d7fa0e7963b78c29c60a",
  isWitness: false,
  isCoinBase: false,
  isCoinStake: false,
  complete: false,
  size: 64,
  inputTypes: [],
  hex: ambiguousHex,
);

final ambiguousWitness = TxVector(
  obj: Transaction(
    version: 3,
    inputs: [
      TaprootKeyInput(
        prevOut: OutPoint.fromHex(
          "0000000000000000000000000000000000000000000000002d00000000000000", 0,
        ),
        sequence: 189878609,
      ),
    ],
    outputs: [
      Output.fromScriptBytes(
        BigInt.parse("578437695752307201"),
        Uint8List(0),
      ),
    ],
  ),
  hashHex: "c484fd792a2b6abc72572da2fdfbe207edbab594b5b3d7fa0e7963b78c29c60a",
  txidHex: "a7905e577851b18db40986854f4d549a4cb8e759379bf783a0585a117792df1d",
  isWitness: true,
  isCoinBase: false,
  isCoinStake: false,
  complete: false,
  size: 64,
  inputTypes: [TaprootKeyInput],
  hex: ambiguousHex,
);

class SigHashVector {
  final int inputN;
  final String scriptCodeAsm;
  final SigHashType type;
  final String hash;
  final String witnessHash;
  SigHashVector({
    required this.inputN,
    required this.scriptCodeAsm,
    required this.type,
    required this.hash,
    required this.witnessHash,
  });
}

final sigHashTxHex = "010000000200000000000000000000000000000000000000000000000000000000000000000000000000ffffffff00000000000000000000000000000000000000000000000000000000000000000000000000ffffffff01e8030000000000000000000000";
final witnessValue = BigInt.from(0x0102030405);

final sighashVectors = [

  // SIGHASH_ALL
  SigHashVector(
    inputN: 0,
    scriptCodeAsm: "0 03",
    type: SigHashType.all(),
    hash: "c2360721e97635761cd6d94d9528de894448709ed7d40f59fc68f573320a7d9f",
    witnessHash: "3314821edf3f58f15b3763fbbd65353e6414c3494a4dd25e85345dbb4c0a9ac0",
  ),

  // SIGHASH_ALL with CODESEPARATOR
  SigHashVector(
    inputN: 0,
    scriptCodeAsm: "0 OP_CODESEPARATOR 03",
    type: SigHashType.all(),
    hash: "c2360721e97635761cd6d94d9528de894448709ed7d40f59fc68f573320a7d9f",
    witnessHash: "afb2d290a938c235743deadd0a77a616811c243dfd17b01dd8b1babc2d85e2ed",
  ),

  // SIGHASH_SINGLE
  SigHashVector(
    inputN: 0,
    scriptCodeAsm: "0",
    type: SigHashType.single(),
    hash: "43597296fa4f2bd356a21aec9dc66b4206f7d696a2d5468b840838be84d12987",
    witnessHash: "83ea6b964428e0f83ed692b87ce9138ef208d80bf013c47978cc15be1645773c",
  ),

  // No matching output for SIGHASH_SINGLE
  SigHashVector(
    inputN: 1,
    scriptCodeAsm: "0",
    type: SigHashType.single(),
    hash: "0000000000000000000000000000000000000000000000000000000000000001",
    witnessHash: "3c8876a85da2d81408d438b67d24df9bc9414be9b3e43654ba3ece7e24f87787",
  ),

  // SIGHASH_NONE
  SigHashVector(
    inputN: 0,
    scriptCodeAsm: "0",
    type: SigHashType.none(),
    hash: "539456df7e47a886a3e03323fab19881fcc195198bebac3f60d3108e86c0dbc0",
    witnessHash: "9741f66ec361eb3f8067fce5e43f22c0cbb4a7fbcb69d1e248dbd40b01fcf0b7",
  ),

  // ANYONECANPAY
  SigHashVector(
    inputN: 0,
    scriptCodeAsm: "0",
    type: SigHashType.all(inputs: InputSigHashOption.anyOneCanPay),
    hash: "6f432eb5ce9f1a48693bab90f84adc0080e87a4d03abe761d261ca8adffb3002",
    witnessHash: "9d39499db354af5517b52ea135091b237d47e5006ad322623e6d5634fabe17a9",
  ),
  SigHashVector(
    inputN: 1,
    scriptCodeAsm: "0",
    type: SigHashType.all(inputs: InputSigHashOption.anyOneCanPay),
    hash: "6f432eb5ce9f1a48693bab90f84adc0080e87a4d03abe761d261ca8adffb3002",
    witnessHash: "9d39499db354af5517b52ea135091b237d47e5006ad322623e6d5634fabe17a9",
  ),

];
