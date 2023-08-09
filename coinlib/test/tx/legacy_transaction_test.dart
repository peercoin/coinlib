import 'dart:typed_data';
import 'package:coinlib/coinlib.dart';
import 'package:test/test.dart';
import '../vectors/tx.dart';
import '../vectors/keys.dart';

void main() {

  group("LegacyTransaction", () {

    setUpAll(loadCoinlib);

    expectVectorWithoutObj(LegacyTransaction tx, TxVector vec) {
      expect(tx.toHex(), vec.hex);
      expect(tx.hashHex, vec.hashHex);
      expect(tx.txid, vec.hashHex);
      expect(tx.hash, hexToBytes(vec.hashHex).reversed);
      expect(tx.isCoinBase, vec.isCoinBase);
      expect(tx.isCoinStake, vec.isCoinStake);
      expect(tx.complete, vec.complete);
      expect(tx.size, vec.size);
      expect(tx.inputs.map((input) => input.runtimeType), vec.inputTypes);
    }

    mapToHex(List<Writable> list) => list.map((e) => e.toHex());

    expectFullVector(LegacyTransaction tx, TxVector vec) {
      expectVectorWithoutObj(tx, vec);
      expect(tx.version, vec.obj.version);
      expect(tx.locktime, vec.obj.locktime);
      // Simplify input and output checking by converting both to hex
      expect(mapToHex(tx.inputs), mapToHex(vec.obj.inputs));
      expect(mapToHex(tx.outputs), mapToHex(vec.obj.outputs));
    }

    test("valid txs", () {
      for (final vec in validTxVecs) {
        expectVectorWithoutObj(vec.obj, vec);
        expectFullVector(LegacyTransaction.fromHex(vec.hex), vec);
      }
    });

    test("invalid txs", () {
      for (final vec in [
        "030000000000000000",
        "03000000010000000000",
        "03000000000100000000",
        "030000000001a0860100000000001a76a914c42e7ef92fdb603af844d064faad95db9bcdfd3d88ac04030201",
      ]) {
        expect(() => LegacyTransaction.fromHex(vec), throwsA(isA<OutOfData>()));
      }
    });

    test("tx too large", () {

      final nonScriptSize = 4 + 1 + 32 + 4 + 5 + 4 + 1 + 4;

      Uint8List dataOfSize(int size) {

        final scriptSize = size - nonScriptSize;
        final varBytes = Uint8List(5);
        BytesWriter(varBytes).writeVarInt(BigInt.from(scriptSize));

        return Uint8List.fromList([
          3, 0, 0, 0,
          1,
          ...hexToBytes("f1fefefefefefefefefefefefefefefefefefefefefefefefefefefefefefefe00000000"),
          ...varBytes,
          ...Iterable.generate(scriptSize),
          0xff, 0xff, 0xff, 0xff,
          0,
          0,0,0,0
        ]);

      }

      LegacyTransaction txOfSize(int size) => LegacyTransaction(
        inputs: [
          RawInput(
            prevOut: examplePrevOut,
            scriptSig: Uint8List(size-nonScriptSize),
          ),
        ],
        outputs: [],
      );

      expect(LegacyTransaction.fromBytes(dataOfSize(1000000)).size, 1000000);
      expect(txOfSize(1000000).size, 1000000);

      expect(
        () => LegacyTransaction.fromBytes(dataOfSize(1000001)),
        throwsA(isA<TransactionTooLarge>()),
      );
      expect(() => txOfSize(1000001), throwsA(isA<TransactionTooLarge>()));

    });

    test("signatureHash", () {

      final tx = LegacyTransaction.fromHex(sigHashTxHex);

      for (final vec in sighashVectors) {
        expect(
          bytesToHex(
            tx.signatureHash(
              vec.inputN,
              Script.fromAsm(vec.prevScriptAsm),
              vec.type,
            ),
          ),
          vec.hash,
        );
      }

    });

    test("signatureHash input out of range", () {
      expect(
        () => LegacyTransaction.fromHex(sigHashTxHex)
          .signatureHash(2, Script([]), SigHashType.all()),
        throwsArgumentError,
      );
    });


    test("sign() failure", () {

      final privkey = ECPrivateKey.generate();
      final pubkey = privkey.pubkey;
      final wrongkey = ECPrivateKey.generate();

      final txNoOutput = LegacyTransaction(
        inputs: [
          P2WPKHInput(prevOut: examplePrevOut, publicKey: pubkey),
          P2PKHInput(
            prevOut: examplePrevOut,
            publicKey: pubkey,
          ),
        ],
        outputs: [],
      );

      // SIGHASH_NONE OK with no outputs
      expect(
        txNoOutput.sign(inputN: 1, key: privkey, hashType: SigHashType.none()),
        isA<LegacyTransaction>(),
      );

      // No outputs
      expect(
        () => txNoOutput.sign(inputN: 1, key: privkey),
        throwsA(isA<CannotSignInput>()),
      );

      final tx = txNoOutput.addOutput(exampleOutput);

      // OK
      expect(tx.sign(inputN: 1, key: privkey), isA<LegacyTransaction>());

      // Input out of range
      expect(() => tx.sign(inputN: 2, key: privkey), throwsArgumentError);

      // Wrong key
      expect(
        () => tx.sign(inputN: 1, key: wrongkey),
        throwsA(isA<CannotSignInput>()),
      );

      // Cannot sign witness input
      expect(
        () => tx.sign(inputN: 0, key: privkey),
        throwsA(isA<CannotSignInput>()),
      );

    });

    test("immutable inputs/outputs", () {
      final tx = validTxVecs[0].obj;
      expect(
        () => tx.inputs[0] = RawInput(
          prevOut: examplePrevOut,
          scriptSig: Uint8List(0),
        ),
        throwsA(anything),
      );
      expect(() => tx.outputs[0] = exampleOutput, throwsA(anything));
    });

    test("sign P2PKH", () {

      final keyVec = keyPairVectors[0];

      expectP2PKH({
        required List<String> prevTxIds,
        required SigHashType hashType,
        required String hex,
      }) {

        final tx = LegacyTransaction(
          inputs: prevTxIds.map((txid) => P2PKHInput(
              prevOut: OutPoint.fromHex(txid, 1), publicKey: keyVec.publicObj,
            ),
          ),
          outputs: [exampleOutput],
        );

        var signed = tx;
        for (int i = 0; i < tx.inputs.length; i++) {
          signed = signed.sign(
            inputN: i,
            key: keyVec.privateObj,
            hashType: hashType,
          );
        }

        expect(tx.complete, false);
        expect(signed.complete, true);
        expect(signed.toHex(), hex);

      }

      // SIGHASH_ALL
      // Sent on testnet: d19ba7e3e446ab3ff4691620a8b139a8c0072f05a7ddcb317995ec9731416840
      // Sent 10tppc via 32d1f1cf811456c6da4ef9e1cb7f8bb80c4c5e9f2d2c3d743f2b68a9c6857823
      expectP2PKH(
        prevTxIds: ["32d1f1cf811456c6da4ef9e1cb7f8bb80c4c5e9f2d2c3d743f2b68a9c6857823"],
        hashType: SigHashType.all(),
        hex: "0300000001237885c6a9682b3f743d2c2d9f5e4c0cb88b7fcbe1f94edac6561481cff1d132010000006b4830450221008510cfb34f3875903fe167ed3b11ea56ba76c70b5fdfa50a0720a647391f84da022047efc8fa5f3a71df4b60a71ffd2742ce8fea33f07715e898c3819ea07a159a4001210279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798ffffffff01a0860100000000001976a914c42e7ef92fdb603af844d064faad95db9bcdfd3d88ac00000000",
      );

      // SIGHASH_NONE
      // Sent on testnet: 0123044a97c992fce48bb237ebaf6652fb4d9f1800a25db19c977664191eb5ef
      // Sent 2tppc via 48549a243098dc58219319670653a1b45999af6cb13e9892d7d009134bb53e45
      expectP2PKH(
        prevTxIds: ["48549a243098dc58219319670653a1b45999af6cb13e9892d7d009134bb53e45"],
        hashType: SigHashType.none(),
        hex: "0300000001453eb54b1309d0d792983eb16caf9959b4a153066719932158dc9830249a5448010000006b4830450221009ea52075bdca55ada96fafe28eb1b577d1c2b6be32bee79af6038029a7ff5ef402201d6f8bcafccbb98fac62fd1851005876cf52df31ef8cd4a2c100c50022cfb70602210279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798ffffffff01a0860100000000001976a914c42e7ef92fdb603af844d064faad95db9bcdfd3d88ac00000000",
      );

      // SIGHASH_SINGLE | ANYONECANPAY
      // Sent on testnet: 7c40ba01c4616b68d716675538e7b1f7641f523bb690a578333f42c054884e64
      // Sent 6tppc via 690dc3e65c07281f1b17017008525b8a51d31f7e82db5e124cc4e225412ceec1
      expectP2PKH(
        prevTxIds: ["690dc3e65c07281f1b17017008525b8a51d31f7e82db5e124cc4e225412ceec1"],
        hashType: SigHashType.single(anyOneCanPay: true),
        hex: "0300000001c1ee2c4125e2c44c125edb827e1fd3518a5b52087001171b1f28075ce6c30d69010000006b483045022100efe4bee34f255e474203b445ac4157cc8d208944fef30ae881c9fe82cf4f2d9802202d030d711fa4ef4dc2194126f2c691c9b4fce6772ce47f4d3665296b90bef3e383210279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798ffffffff01a0860100000000001976a914c42e7ef92fdb603af844d064faad95db9bcdfd3d88ac00000000",
      );

      // SIGHASH_ALL with 2x inputs
      // Sent on testnet: 56a58956e480f861e1cf9bdd0d3321b0305975d3256fb50f55d6f0092eb5f601
      // Sent 0.5tppc via 135ef5f16c7db3d979a64d057e46694ef74489afc4c678e231d32c8eddac1004
      // Sent 0.9tppc via 59b672e58547b984ab69d45d1dbbda4ba52f24b473585633dd335f5e4e3d4489j
      expectP2PKH(
        prevTxIds: [
          "135ef5f16c7db3d979a64d057e46694ef74489afc4c678e231d32c8eddac1004",
          "59b672e58547b984ab69d45d1dbbda4ba52f24b473585633dd335f5e4e3d4489",
        ],
        hashType: SigHashType.all(),
        hex: "03000000020410acdd8e2cd331e278c6c4af8944f74e69467e054da679d9b37d6cf1f55e13010000006b4830450221009866a172e139826b7af7d41c11459d73028b332a90d7841be2cf06d54c2143f502201d0063183324692af6cc07431e60e50c8afa9d32ffad09463ad2002a61743f8001210279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798ffffffff89443d4e5e5f33dd33565873b4242fa54bdabb1d5dd469ab84b94785e572b659010000006b48304502210097b929e7b300fe335bd4459c9c728864513ac73edab1dc235d90ac25d1f9544c02201c83eecc13193194e17aff7b4b03a031a8d09e0c957f32b197d4ca551ae1472901210279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798ffffffff01a0860100000000001976a914c42e7ef92fdb603af844d064faad95db9bcdfd3d88ac00000000",
      );

      // SIGHASH_ALL | ANYONECANPAY with 2x inputs
      // Sent on testnet: 69336fac23e06be14f330730593d4137b3f33a339e19eacaac0d7b9593650d5f
      // Sent 3tppc via 21bbd6717cda6a8bdfd722059f8e415929a91f82405359963be0fc4d32194cfb
      // Sent 7tppc via 870c78b9ac6406ed820c026147cfd32b65fbd6335fad8eeca6ecaa76b231b335
      expectP2PKH(
        prevTxIds: [
          "21bbd6717cda6a8bdfd722059f8e415929a91f82405359963be0fc4d32194cfb",
          "870c78b9ac6406ed820c026147cfd32b65fbd6335fad8eeca6ecaa76b231b335",
        ],
        hashType: SigHashType.all(anyOneCanPay: true),
        hex: "0300000002fb4c19324dfce03b96595340821fa92959418e9f0522d7df8b6ada7c71d6bb21010000006a47304402203d2104bca35cb5774d677940145267a0c665b135dda845221937831e98155d02022073fe3afa725e0cef6458ae9cc1ef79b42839bf3832dbc9a9363d2c3f4c01ca9d81210279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798ffffffff35b331b276aaeca6ec8ead5f33d6fb652bd3cf4761020c82ed0664acb9780c87010000006b483045022100bdf9f141ed69b24429299bec9f6a9ff34acb3c3de83190403b8ed9fa2b549e370220355b7b7116309b25f1a8195ad4c5fc2ee97dc4598a4e0690e764cbdafcd1aa2481210279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798ffffffff01a0860100000000001976a914c42e7ef92fdb603af844d064faad95db9bcdfd3d88ac00000000",
      );

    });

    test("sign P2SH multisig and add inputs/outputs", () {
      // Sign 3-of-4 with keys 3, 1, 2 on the second input
      // Sent on testnet: dbf617127245f1a1c774e9f80273186f363b6daed795447452bb10071c6ee0f9
      // Used mrCDrCybB6J1vRfbwM5hemdJz73FwDBC8r for P2PKH on input 0
      //   via 75e92412972a0708ee68bc94fef11fec7b2d36de8816c59c4a836a7de8288607
      // Used 2MzzakuAACiDBCpi2Au2Ckiux33mjSuKMK3 for P2SH on input 1
      //   via 92935b9b2681b1f417c7b5ed5cb873df1bc0d8bf8fa8feec00f8e7e16c031680

      final privkeys = List<ECPrivateKey>.generate(
        4, (i) => ECPrivateKey(
          Uint8List.fromList([...List<int>.filled(31, 0), i+1]),
        ),
      );
      final pubkeys = privkeys.map((k) => k.pubkey).toList();
      final multisig = MultisigProgram(3, pubkeys);

      final tx = LegacyTransaction(
        inputs: [
          P2PKHInput(
            prevOut: OutPoint.fromHex(
              "75e92412972a0708ee68bc94fef11fec7b2d36de8816c59c4a836a7de8288607",
              1,
            ),
            publicKey: pubkeys[0],
          ),
          P2SHMultisigInput(
            prevOut: OutPoint.fromHex(
              "92935b9b2681b1f417c7b5ed5cb873df1bc0d8bf8fa8feec00f8e7e16c031680",
              1,
            ),
            program: multisig,
          ),
        ],
        outputs: [exampleOutput, exampleOutput],
      );

      // Sign first P2PKH input
      var signed = tx.sign(inputN: 0, key: privkeys[0]);
      expect(signed.complete, false);

      // Sign 3 with SIGHASH_ALL and ANYONECANPAY
      signed = signed.sign(
        inputN: 1,
        key: privkeys[3],
        hashType: SigHashType.all(anyOneCanPay: true),
      );
      expect(signed.complete, false);

      // Sign 1 with SIGHASH_SINGLE
      signed = signed.sign(
        inputN: 1,
        key: privkeys[1],
        hashType: SigHashType.single(),
      );
      expect(signed.complete, false);

      // Sign 2 with SIGHASH_NONE
      signed = signed.sign(
        inputN: 1,
        key: privkeys[2],
        hashType: SigHashType.none(),
      );

      // Check insigs by reference to their hash types
      expectMultisigSigs(LegacyTransaction tx, List<SigHashType> types) {
        final sigs = (tx.inputs[1] as P2SHMultisigInput).sigs;
        expect(sigs.length, types.length);
        expect(sigs.map((s) => s.hashType), types);
      }

      // Check final tx
      expect(signed.complete, true);
      expectMultisigSigs(
        signed, [
          SigHashType.single(),
          SigHashType.none(),
          SigHashType.all(anyOneCanPay: true),
        ],
      );
      expect(
        signed.toHex(),
        "0300000002078628e87d6a834a9cc51688de362d7bec1ff1fe94bc68ee08072a971224e975010000006a47304402206d7be73300157f32f91766952b06075038617b9b4459bc3b098236b71e9970240220082c601548835e36d37eae2de1dc2137dceae8805b8b6981f27c5a84f7db3cfb01210279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798ffffffff8016036ce1e7f800ecfea88fbfd8c01bdf73b85cedb5c717f4b181269b5b939201000000fd670100483045022100bae652b729225f679035f779f7f9c63300f73fc54b6542bbfb968929d026cb2a022023f5b2f8ec8168fd307ffadd8cf071efec77a0282bf1f4f90601f5dbf3080a9703473044022042f105df80241b52041a079a59cb59547bd555eee7d813fc1df1064809d0b52302201585d99e580b555af80bcb7c84e45c42b9208b190367cab82e693b54fa7007d602473044022025fbf12e1e50f15683a2f03ce7332e4aa16c0b39d72ae735a7758c082127308b0220650edd9bbbe0038aaddbea37d122fb781dc58bb29902d6eb0af0d2763f7077e7814c8b53210279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f817982102c6047f9441ed7d6d3045406e95c07cd85c778e4b8cef3ca7abac09b95c709ee52102f9308a019258c31049344f85f89d5229b531c845836f99b08601f113bce036f92102e493dbf1c10d80f3581e4904930b1404cc6c13900ee0758474fa94abe8c4cd1354aeffffffff02a0860100000000001976a914c42e7ef92fdb603af844d064faad95db9bcdfd3d88aca0860100000000001976a914c42e7ef92fdb603af844d064faad95db9bcdfd3d88ac00000000",
      );

      // addInput doesn't invalidate ANYONECANPAY
      expectMultisigSigs(
        signed.addInput(
          P2PKHInput(prevOut: examplePrevOut, publicKey: examplePubkey),
        ),
        [SigHashType.all(anyOneCanPay: true)],
      );

      // addOutput only invalidates SIGHASH_ALL
      expectMultisigSigs(
        signed.addOutput(exampleOutput),
        [SigHashType.single(), SigHashType.none()],
      );

    });

  });

  test("invalid SIGHASH_SINGLE when adding corresponding output", () {

    final privkey = ECPrivateKey.generate();
    final pubkey = privkey.pubkey;

    var tx = LegacyTransaction(
      inputs: [
        P2PKHInput(prevOut: examplePrevOut, publicKey: pubkey),
        P2PKHInput(prevOut: examplePrevOut, publicKey: pubkey),
      ],
      outputs: [exampleOutput],
    );

    for (int i = 0; i < 2; i++) {
      expect(tx.complete, false);
      tx = tx.sign(inputN: i, key: privkey, hashType: SigHashType.single());
    }

    expect(tx.complete, true);
    tx = tx.addOutput(exampleOutput);
    expect(tx.complete, false);

    // Added output for second input which is therefore invalidated
    expect((tx.inputs[0] as P2PKHInput).insig, isNotNull);
    expect((tx.inputs[1] as P2PKHInput).insig, isNull);

  });

}
