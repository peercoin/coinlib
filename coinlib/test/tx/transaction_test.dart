import 'dart:typed_data';
import 'package:coinlib/coinlib.dart';
import 'package:test/test.dart';
import '../vectors/tx.dart';
import '../vectors/keys.dart';

void main() {

  group("Transaction", () {

    setUpAll(loadCoinlib);

    final keyVec = keyPairVectors[0];

    expectVectorWithoutObj(Transaction tx, TxVector vec) {
      expect(tx.toHex(), vec.hex);

      expect(tx.hashHex, vec.hashHex);
      expect(tx.hash, hexToBytes(vec.hashHex).reversed);

      expect(tx.txid, vec.txidHex);
      expect(tx.legacyHash, hexToBytes(vec.txidHex).reversed);

      expect(tx.isWitness, vec.isWitness);
      expect(tx.isCoinBase, vec.isCoinBase);
      expect(tx.isCoinStake, vec.isCoinStake);
      expect(tx.complete, vec.complete);
      expect(tx.size, vec.size);
      expect(tx.inputs.map((input) => input.runtimeType), vec.inputTypes);
    }

    mapToHex(List<Writable> list) => list.map((e) => e.toHex());

    expectFullVector(Transaction tx, TxVector vec) {
      expectVectorWithoutObj(tx, vec);
      expect(tx.version, vec.obj.version);
      expect(tx.locktime, vec.obj.locktime);
      // Simplify input and output checking by converting both to hex
      expect(mapToHex(tx.inputs), mapToHex(vec.obj.inputs));
      expect(mapToHex(tx.outputs), mapToHex(vec.obj.outputs));
    }

    expectInputSignedSize(Input input) => expect(
      input.size, lessThanOrEqualTo(input.signedSize!),
    );

    test("valid txs", () {
      for (final vec in validTxVecs) {

        expectVectorWithoutObj(vec.obj, vec);
        expectFullVector(Transaction.fromHex(vec.hex), vec);
        expectFullVector(
          Transaction.fromHex(vec.hex, expectWitness: vec.isWitness), vec,
        );
        expect(vec.obj == vec.obj.legacy, !vec.isWitness);

        if (vec.isWitness) {
          final legacy = vec.obj.legacy;
          expect(legacy.isWitness, false);
          expect(legacy.inputs, everyElement(isA<RawInput>()));
          expect(legacy.toHex(), vec.legacyHex);
          expect(legacy.size, vec.legacyHex!.length/2);
          expect(legacy.hashHex, vec.txidHex);
        }

      }
    });

    test("invalid txs", () {
      for (final vec in [
        "030000000000000000",
        "03000000010000000000",
        "03000000000100000000",
        "030000000001a0860100000000001a76a914c42e7ef92fdb603af844d064faad95db9bcdfd3d88ac04030201",
      ]) {
        expect(
          () => Transaction.fromHex(vec),
          throwsA(isA<InvalidTransaction>()),
        );
      }
    });

    test("tx too large", () {

      final nonScriptSize
        = 4 // Version
        + 1 // nIn
        + 36 // Prevout
        + 5 // Script varint
        + 4 // Sequence
        + 1 // nOut
        + 4; // Locktime

      final witnessNonScriptSize
        = 4 // Version
        + 2 // Marker and flag
        + 1 // nIn
        + 36 // Prevout
        + 1 // Empty script
        + 4 // Sequence
        + 1 // nOut
        + 6 // Witness varints
        + 4; // Locktime

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
          0,0,0,0,
        ]);

      }

      Transaction txOfSize(int size) => Transaction(
        inputs: [
          RawInput(
            prevOut: examplePrevOut,
            scriptSig: Uint8List(size-nonScriptSize),
          ),
        ],
        outputs: [],
      );

      Transaction witnessTxOfSize(int size) => Transaction(
        inputs: [
          WitnessInput(
            prevOut: examplePrevOut,
            witness: [Uint8List(size-witnessNonScriptSize)],
          ),
        ],
        outputs: [],
      );


      expect(Transaction.fromBytes(dataOfSize(1000000)).size, 1000000);
      expect(txOfSize(1000000).size, 1000000);
      expect(witnessTxOfSize(1000000).size, 1000000);

      expect(
        () => Transaction.fromBytes(dataOfSize(1000001)),
        throwsA(isA<TransactionTooLarge>()),
      );
      expect(() => txOfSize(1000001), throwsA(isA<TransactionTooLarge>()));
      expect(
        () => witnessTxOfSize(1000001),
        throwsA(isA<TransactionTooLarge>()),
      );

    });

    test("ambiguous tx", () {

      expectFullVector(
        Transaction.fromHex(ambiguousHex, expectWitness: false),
        ambiguousLegacy,
      );

      expectFullVector(
        Transaction.fromHex(ambiguousHex, expectWitness: true),
        ambiguousWitness,
      );

      // Witness assumed by default
      expectFullVector(Transaction.fromHex(ambiguousHex), ambiguousWitness);

    });

    test("sign() failure", () {

      final privkey = ECPrivateKey.generate();
      final pubkey = privkey.pubkey;
      final wrongkey = ECPrivateKey.generate();

      final txNoOutput = Transaction(
        inputs: [
          P2WPKHInput(prevOut: examplePrevOut, publicKey: pubkey),
          P2PKHInput(
            prevOut: examplePrevOut,
            publicKey: pubkey,
          ),
          TaprootKeyInput(prevOut: examplePrevOut),
          RawInput(prevOut: examplePrevOut, scriptSig: Uint8List(0)),
        ],
        outputs: [],
      );

      // SIGHASH_NONE OK with no outputs
      expect(
        txNoOutput.sign(inputN: 1, key: privkey, hashType: SigHashType.none()),
        isA<Transaction>(),
      );

      // No outputs
      expect(
        () => txNoOutput.sign(inputN: 1, key: privkey),
        throwsA(isA<CannotSignInput>()),
      );

      final tx = txNoOutput.addOutput(exampleOutput);

      // OK
      expect(tx.sign(inputN: 1, key: privkey), isA<Transaction>());

      // Input out of range
      expect(() => tx.sign(inputN: 4, key: privkey), throwsArgumentError);

      // Wrong key for P2PKH
      expect(
        () => tx.sign(inputN: 1, key: wrongkey),
        throwsA(isA<CannotSignInput>()),
      );

      // Cannot sign witness input without value
      expect(
        () => tx.sign(inputN: 0, key: privkey),
        throwsA(isA<CannotSignInput>()),
      );

      // Cannot sign raw unmatched input
      expect(
        () => tx.sign(inputN: 3, key: privkey),
        throwsA(isA<CannotSignInput>()),
      );

      // Cannot use schnorrDefault to sign legacy inputs
      expect(
        () => tx.sign(
          inputN: 1,
          key: privkey,
          hashType: SigHashType.schnorrDefault(),
        ),
        throwsA(isA<CannotSignInput>()),
      );
      expect(
        () => tx.sign(
          inputN: 0,
          key: privkey,
          hashType: SigHashType.schnorrDefault(),
          value: BigInt.parse("10000"),
        ),
        throwsA(isA<CannotSignInput>()),
      );

      // Taproot tests
      final tr = Taproot(internalKey: pubkey);
      final tweakedKey = tr.tweakPrivateKey(privkey);

      final val = BigInt.from(10000);
      final prevOuts = [
        Output.fromProgram(val, P2WPKH.fromPublicKey(pubkey)),
        Output.fromProgram(val, P2PKH.fromPublicKey(pubkey)),
        Output.fromProgram(val, P2TR.fromTaproot(tr)),
        Output.blank(),
      ];

      // Require prev outs for TR
      expect(
        () => tx.sign(
          inputN: 2,
          key: tweakedKey,
        ),
        throwsA(isA<CannotSignInput>()),
      );

      // Require prev out number to match number of inputs
      expect(
        () => tx.sign(
          inputN: 2,
          key: tweakedKey,
          prevOuts: prevOuts.sublist(0, 3),
        ),
        throwsA(isA<CannotSignInput>()),
      );

      // Wrong (untweaked) key for TR
      expect(
        () => tx.sign(
          inputN: 2,
          key: privkey,
          prevOuts: prevOuts,
        ),
        throwsA(isA<CannotSignInput>()),
      );

      // Ensure it does work with correct key
      expect(
        tx.sign(inputN: 2, key: tweakedKey, prevOuts: prevOuts),
        isA<Transaction>(),
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

      expectP2PKH({
        required List<String> prevTxIds,
        required SigHashType hashType,
        required String hex,
      }) {

        final tx = Transaction(
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
          expectInputSignedSize(signed.inputs[i]);
        }

        expect(tx.complete, false);
        expect(signed.complete, true);
        expect(signed.toHex(), hex);

      }

      // SIGHASH_ALL
      // Sent on testnet: c52154f5b3cec84dc651d9102950914d259477a9d013efcece769ad07643df5d
      // Sent 10tppc via 6003525edfd29b63767e465bdf3d61aa60105e4368366c46a62d0f1fb0c6b34b
      expectP2PKH(
        prevTxIds: ["6003525edfd29b63767e465bdf3d61aa60105e4368366c46a62d0f1fb0c6b34b"],
        hashType: SigHashType.all(),
        hex: "03000000014bb3c6b01f0f2da6466c3668435e1060aa613ddf5b467e76639bd2df5e520360010000006a4730440220103774421b86d889dcf0b68052431f7d78c19acb470922aff6f93c6648d29c50022008cf92d373035b8b3ad6e8a8f061c30ad16967e98eeb04a34fd2bab7aa67d92b01210279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798ffffffff01a0860100000000001976a914c42e7ef92fdb603af844d064faad95db9bcdfd3d88ac00000000",
      );

      // SIGHASH_NONE
      // Sent on testnet: a67a6e12d93a51fb3f3fffd0a5827e312227f5824ccd1bb2ef3b941d2dfa47ca
      // Sent 2tppc via 5ce897c22438be2ab7fac85c7fdea596c81b0b515a1163969d0c9805e97ff561
      expectP2PKH(
        prevTxIds: ["5ce897c22438be2ab7fac85c7fdea596c81b0b515a1163969d0c9805e97ff561"],
        hashType: SigHashType.none(),
        hex: "030000000161f57fe905980c9d9663115a510b1bc896a5de7f5cc8fab72abe3824c297e85c010000006a47304402201d570d9d1823badb6247a1f1f71eca517fdd1ef93cde819a94caa3fb2d0530cf02204f0cf2517c363dd2e1c46c3f37f1a3c36c869e9013b6741ed2736ba5e73baf9f02210279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798ffffffff01a0860100000000001976a914c42e7ef92fdb603af844d064faad95db9bcdfd3d88ac00000000",
      );

      // SIGHASH_SINGLE | ANYONECANPAY
      // Sent on testnet: c75d5e7c2323160240de255d188d8c4b125425a7da744b5ba371ddc43dda96a6
      // Sent 6tppc via f47fe6ce6a79734f252ceac7a0468a077b3d27e5289c5c0fb5294e0c7c07a51a
      expectP2PKH(
        prevTxIds: ["f47fe6ce6a79734f252ceac7a0468a077b3d27e5289c5c0fb5294e0c7c07a51a"],
        hashType: SigHashType.single(anyOneCanPay: true),
        hex: "03000000011aa5077c0c4e29b50f5c9c28e5273d7b078a46a0c7ea2c254f73796acee67ff4010000006a47304402206716517f2f9ee8d4fbcbc186f2e31e366e54821b2cbf4d1f9df480be300a4657022016572e39f86552958e043252390f4a17cd08caf1667a08e342b93b9b3ac020ab83210279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798ffffffff01a0860100000000001976a914c42e7ef92fdb603af844d064faad95db9bcdfd3d88ac00000000",
      );

      // SIGHASH_ALL with 2x inputs
      // Sent on testnet: 7ed419ea7f5618e71215681fc451657050fa40a605549aac68f84a527cf5ed9f
      // Sent 0.5tppc via 8424eeaf7e0859f2b19a70e5181ae8dcee99cc0eaf4247f831b27ea655f37bb8
      // Sent 0.9tppc via 22eb14eef7eb88d7b653943aac5f38016fa4ee0aaf51462f8737f788e11b3d78
      expectP2PKH(
        prevTxIds: [
          "8424eeaf7e0859f2b19a70e5181ae8dcee99cc0eaf4247f831b27ea655f37bb8",
          "22eb14eef7eb88d7b653943aac5f38016fa4ee0aaf51462f8737f788e11b3d78",
        ],
        hashType: SigHashType.all(),
        hex: "0300000002b87bf355a67eb231f84742af0ecc99eedce81a18e5709ab1f259087eafee2484010000006a4730440220251b28722dd16982c91a2f1aefbfd2d35ff4ce55785e8a7030decfe970c63ad302207e98ac50fa45aad1039bea2e2a18051b693e25efbc7eb83580596cee0d587acf01210279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798ffffffff783d1be188f737872f4651af0aeea46f01385fac3a9453b6d788ebf7ee14eb22010000006a473044022021142171ef3e40b89ed1083ab57a612cbbf5f039a20e1e02fc25c3f57e01a16b0220087c7f087edcb0014f981b0def6623bebee254c9290d1f7fe9a1a1276ab3d29601210279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798ffffffff01a0860100000000001976a914c42e7ef92fdb603af844d064faad95db9bcdfd3d88ac00000000",
      );

      // SIGHASH_ALL | ANYONECANPAY with 2x inputs
      // Sent on testnet: a56f9b2c69fe61638e3b5d05205007728faada21a551ac499a5f097eecfab786
      // Sent 3tppc via c8d7587c66e8d803a2a802658d51e2accb6ede1e472ecd1e55b6202a47447e7f
      // Sent 7tppc via ead28731d0bf3d5d2ac014edb5b4edfa862d9ea6a67ae1147e32b5c4c6cfebab 
      expectP2PKH(
        prevTxIds: [
          "c8d7587c66e8d803a2a802658d51e2accb6ede1e472ecd1e55b6202a47447e7f",
          "ead28731d0bf3d5d2ac014edb5b4edfa862d9ea6a67ae1147e32b5c4c6cfebab",
        ],
        hashType: SigHashType.all(anyOneCanPay: true),
        hex: "03000000027f7e44472a20b6551ecd2e471ede6ecbace2518d6502a8a203d8e8667c58d7c8010000006a47304402201117e6fb5b1cb0fd893c506051f60b1a7b0cf7bd404a1793a6a02c3fca6b0d5b0220761bef6978d8820694707de4569cd8ece2226ad8f67b6d97b5156cfc17697c3081210279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798ffffffffabebcfc6c4b5327e14e17aa6a69e2d86faedb4b5ed14c02a5d3dbfd03187d2ea010000006a47304402202afa1ec80ed42799869da5698b5ee0341a25bcdf3a4eafd142be5b4f90f4a03e022019bb83ad4b12a7ea7c65d8bdc4f112825ba2327f502377fa18f0395854bfa77581210279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798ffffffff01a0860100000000001976a914c42e7ef92fdb603af844d064faad95db9bcdfd3d88ac00000000",
      );

    });

    test("sign P2WPKH input", () {
      // Includes a P2PKH input for good measure
      // Sent on testnet:
      //    9e8d50325d0dac936483943beab51d6936768e0fd723da677e2b1b4c489e690c
      // Includes 5ppc and 3ppc inputs
      //    via 6ef0ccd045d0f29b4b52ac4804ac0378ef10b0dc68cfb3283e744a056238799f

      final prevHashHex
        = "6ef0ccd045d0f29b4b52ac4804ac0378ef10b0dc68cfb3283e744a056238799f";

      final tx = Transaction(
        inputs: [
          P2PKHInput(
            prevOut: OutPoint.fromHex(prevHashHex, 1),
            publicKey: keyVec.publicObj,
          ),
          P2WPKHInput(
            prevOut: OutPoint.fromHex(prevHashHex, 2),
            publicKey: keyVec.publicObj,
          ),
        ],
        outputs: [exampleOutput],
      );
      expect(tx.complete, false);

      final partSigned = tx.sign(inputN: 0, key: keyVec.privateObj);
      expect(partSigned.complete, false);

      final signed = partSigned.sign(
        inputN: 1, key: keyVec.privateObj, value: BigInt.from(3000000),
      );
      expect(signed.complete, true);
      expectInputSignedSize(signed.inputs[1]);

      expect(
        signed.toHex(),
        "030000000001029f793862054a743e28b3cf68dcb010ef7803ac0448ac524b9bf2d045d0ccf06e0100000069463043022042a3d36745bd1beaa6f7f81dcddae8f7a0986af10488f31d50037cc4d55b6b6d021f0f3872b51900d058afea10a0f8a80a69a1547379fa87c7e127c345c11723ac01210279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798ffffffff9f793862054a743e28b3cf68dcb010ef7803ac0448ac524b9bf2d045d0ccf06e0200000000ffffffff01a0860100000000001976a914c42e7ef92fdb603af844d064faad95db9bcdfd3d88ac000247304402202bc4a1b3d7ac22b2311fc1f113ce191768ee56ee8d4b20c9d528dae70f6af009022022babf3c47f99a2772da1a1a68dc1739c938b8518e7abe0bef856e8651cb5d4b01210279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f8179800000000",
      );

    });

    test("sign key-path P2TR input", () {
      // Sent on testnet:
      //   5bfa50b41c372e8ec5710766e9d5292845ba2c22d7d144dfff622d1c3eaa6dbf
      // Includes 6ppc input via:
      //   ec68cf7fa9599c96b87c176c9d2fa0ee2fcc8a0f3469b7da5b637963e67470c1
      // And includes 2ppc input via:
      //   cada1d0756465151d8fe7195f5702d48ff5e8f56b5d19ecd7815c8e82687211e

      final taproot = Taproot(internalKey: keyVec.publicObj);
      final tx = Transaction(
        inputs: [
          TaprootKeyInput(
            prevOut: OutPoint.fromHex(
              "ec68cf7fa9599c96b87c176c9d2fa0ee2fcc8a0f3469b7da5b637963e67470c1",
              1,
            ),
          ),
          TaprootKeyInput(
            prevOut: OutPoint.fromHex(
              "cada1d0756465151d8fe7195f5702d48ff5e8f56b5d19ecd7815c8e82687211e",
              1,
            ),
          ),
        ],
        outputs: [exampleOutput],
      );
      final program = P2TR.fromTaproot(taproot);
      final prevOuts = [
        Output.fromProgram(BigInt.from(6000000), program),
        Output.fromProgram(BigInt.from(2000000), program),
      ];
      final tweakedPriv = taproot.tweakPrivateKey(keyVec.privateObj);

      final signed = tx.sign(
        inputN: 0,
        key: tweakedPriv,
        prevOuts: prevOuts,
      ).sign(
        inputN: 1,
        key: tweakedPriv,
        prevOuts: prevOuts,
        hashType: SigHashType.all(anyOneCanPay: true),
      );

      expect(signed.complete, true);
      for (final input in signed.inputs) {
        expectInputSignedSize(input);
      }

      expect(
        signed.toHex(),
        "03000000000102c17074e66379635bdab769340f8acc2feea02f9d6c177cb8969c59a97fcf68ec0100000000ffffffff1e218726e8c81578cd9ed1b5568f5eff482d70f59571fed851514656071ddaca0100000000ffffffff01a0860100000000001976a914c42e7ef92fdb603af844d064faad95db9bcdfd3d88ac0141525f7f8e98fe4a116131c1d51aba29bbe15852260faa5308d23768d4d99251004b56306396f5f07018e7a94b41594a485455107b818d1c8899a18afbc98618b0010141399278f778c70fc3a7eee1997cb53acbef4a86ab65d85c12d40286f26cb50b189656df26d86e9be4f16bfe0b574d3f632e2b537d19d0e04d545e61c3d76b07058100000000",
      );

      // Invalidates first input and keeps ANYONECANPAY when adding new input
      final newTx = signed.addInput(
        P2PKHInput(prevOut: examplePrevOut, publicKey: keyVec.publicObj),
      );
      expect((newTx.inputs[0] as TaprootKeyInput).insig, null);
      // Should be same object as there is no change
      expect(newTx.inputs[1], signed.inputs[1]);

    });

    test("sign script-path P2TR input with NUMS key", () {
      // Sent on testnet:
      //  7353bd0fd3c2f572b45f144b1c8ad17b555b52eee6493b27d41b168783bec0f2
      // Includes 12ppc input via:
      //  980d55a017d166d4b26e45c81e958f2c751bc0abb8e3116bd3354158be44c53c

      TapLeaf checkSigLeafForVector(KeyTestVector vec) => TapLeaf(
        Script([
          ScriptPushData(vec.publicObj.x),
          ScriptOpCode.fromName("CHECKSIG"),
        ]),
      );

      final rTweak = hexToBytes(
        "b8bbb28a422ab2f235f27b7e40f0189bd1c581bf44342fb6e8f3b6e772b29627",
      );

      final taproot = Taproot(
        internalKey: NUMSPublicKey.fromRTweak(rTweak),
        mast: TapBranch(
          TapBranch(
            checkSigLeafForVector(keyPairVectors[1]),
            checkSigLeafForVector(keyPairVectors[2]),
          ),
          checkSigLeafForVector(keyPairVectors[3]),
        ),
      );

      final secondLeaf = taproot.leaves[1];

      final tx = Transaction(
        inputs: [
          TaprootScriptInput.fromTaprootLeaf(
            prevOut: OutPoint.fromHex(
              "980d55a017d166d4b26e45c81e958f2c751bc0abb8e3116bd3354158be44c53c",
              1,
            ),
            taproot: taproot,
            leaf: secondLeaf,
          ),
        ],
        outputs: [exampleOutput],
      );

      // Doesn't know when arbitrary taproot script input is complete so assume
      // it is even when it isn't.
      expect(tx.complete, true);

      // Manual signing of input as Transaction.sign doesn't know how to handle
      // these arbitrary inputs.
      final inputToSign = tx.inputs[0] as TaprootScriptInput;
      final prevOut = Output.fromProgram(
        BigInt.from(12000000),
        P2TR.fromTaproot(taproot),
      );

      final solvedTx = tx.replaceInput(
        inputToSign.updateStack([
          inputToSign.createScriptSignature(
            tx: tx,
            inputN: 0,
            key: keyPairVectors[2].privateObj,
            prevOuts: [prevOut],
          ).bytes,
        ]),
        0,
      );

      expect(
        solvedTx.toHex(),
        "030000000001013cc544be584135d36b11e3b8abc01b752c8f951ec8456eb2d466d117a0550d980100000000ffffffff01a0860100000000001976a914c42e7ef92fdb603af844d064faad95db9bcdfd3d88ac034194435688998751de388e3a240d488f68f86d70a631a90355472673ccfa14e323a147eedea0b4da14a73195abe22be29fcafeb60cf3bb9de94891969f2c546088012220b80011a883a0fd621ad46dfc405df1e74bf075cbaf700fd4aebef6e96f848340ac61c1b33ff3fab0fd16daef5f4916bfbd83244bf3b9f446eb0f1b7b5b1f97a9e99065763e9da064b9dc0471fb0f3c8fa2c84b4b84d2ca992497c12d2274386795aa8ef91bcc8ea862a20c20ecb36adc4a8c29ca24475f9685d07e76e19379328e847e00000000",
      );

    });

    test("sign P2SH multisig and add inputs/outputs", () {
      // Sign 3-of-4 with keys 3, 1, 2 on the second input
      // Sent on testnet: 665d6d195bd128e99cf4ca2c78d5fcd5b67c54a3c111dfb8a3f8c8a82b0f1f1b
      // Used mrCDrCybB6J1vRfbwM5hemdJz73FwDBC8r for P2PKH on input 0
      // Used 2MzzakuAACiDBCpi2Au2Ckiux33mjSuKMK3 for P2SH on input 1
      //   both via 90024b0b92707fa505b4183951ac755d45ecab5e6855ea78370063b365e0687b

      final privkeys = List<ECPrivateKey>.generate(
        4, (i) => ECPrivateKey(
          Uint8List.fromList([...List<int>.filled(31, 0), i+1]),
        ),
      );
      final pubkeys = privkeys.map((k) => k.pubkey).toList();
      final multisig = MultisigProgram(3, pubkeys);

      final prevHashHex
        = "90024b0b92707fa505b4183951ac755d45ecab5e6855ea78370063b365e0687b";

      final tx = Transaction(
        inputs: [
          P2PKHInput(
            prevOut: OutPoint.fromHex(prevHashHex, 1),
            publicKey: pubkeys[0],
          ),
          P2SHMultisigInput(
            prevOut: OutPoint.fromHex(prevHashHex, 2),
            program: multisig,
          ),
        ],
        outputs: [exampleOutput, exampleOutput],
      );

      final signedSizeFromUnsigned = tx.inputs[1].signedSize;

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
      expectMultisigSigs(Transaction tx, List<SigHashType> types) {
        final sigs = (tx.inputs[1] as P2SHMultisigInput).sigs;
        expect(sigs.length, types.length);
        expect(sigs.map((s) => s.hashType), types);
      }

      // Check final tx
      expect(signed.complete, true);
      expectInputSignedSize(signed.inputs[1]);
      expect(signed.inputs[1].signedSize, signedSizeFromUnsigned);
      expectMultisigSigs(
        signed, [
          SigHashType.single(),
          SigHashType.none(),
          SigHashType.all(anyOneCanPay: true),
        ],
      );
      expect(
        signed.toHex(),
        "03000000027b68e065b363003778ea55685eabec455d75ac513918b405a57f70920b4b0290010000006a4730440220744291cb8fd71145926b1931b86118a2b32df69f39310fbb10b534e33a402be602204f12a79c89531ea4b0ac7787ee9b4e05f15c9fce855b7f1be0918aba772e4c7b01210279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798ffffffff7b68e065b363003778ea55685eabec455d75ac513918b405a57f70920b4b029002000000fd66010047304402207b57e088066016d9dc17fc0691f7c532cb4c1fa4b7ef2d0ba94aa4a8c35996d6022031fd1173b91c4c4e573b68910498428686bfca67bcc50c7ab3b440b4f25c1afc0347304402207840c79c40cae5241d7861d290a821571a2727f7dd392ead20303cc0c32aa66902205dba519f55fa544c1b1f753b5cc12d332c797b334f7e1994cbdf34c8dfc1d802024730440220526309d108bfdbca461831d2fcbd9b26a1080bffaaae749a36a21c55b75b91d602202d48198eb56755851c41f37d6d88238e6bf10217a5d9acf744518ce28206e0de814c8b53210279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f817982102c6047f9441ed7d6d3045406e95c07cd85c778e4b8cef3ca7abac09b95c709ee52102f9308a019258c31049344f85f89d5229b531c845836f99b08601f113bce036f92102e493dbf1c10d80f3581e4904930b1404cc6c13900ee0758474fa94abe8c4cd1354aeffffffff02a0860100000000001976a914c42e7ef92fdb603af844d064faad95db9bcdfd3d88aca0860100000000001976a914c42e7ef92fdb603af844d064faad95db9bcdfd3d88ac00000000",
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

    test("invalid SIGHASH_SINGLE when adding corresponding output", () {

      final privkey = ECPrivateKey.generate();
      final pubkey = privkey.pubkey;

      var tx = Transaction(
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

    test("replaceInput", () {

      // Create tx with 4 legacy (the 2nd to be replaced), 3 witness and 3
      // taproot inputs to test invalidation when an input is replaced

      final value = BigInt.from(1000000);
      final taprootPrevOuts = [
        ...List.filled(
          4,
          Output.fromProgram(value, P2PKH.fromPublicKey(keyVec.publicObj)),
        ),
        ...List.filled(
          3,
          Output.fromProgram(value, P2WPKH.fromPublicKey(keyVec.publicObj)),
        ),
        ...List.filled(
          3,
          Output.fromProgram(value, P2TR.fromTweakedKey(keyVec.publicObj)),
        ),
      ];

      final tx = Transaction(
        inputs: [
          // Legacy inputs
          ...List.generate(
            4,
            (i) => P2PKHInput(prevOut: examplePrevOut, publicKey: keyVec.publicObj),
          ),
          // Witness inputs
          ...List.generate(
            3,
            (i) => P2WPKHInput(prevOut: examplePrevOut, publicKey: keyVec.publicObj),
          ),
          // Taproot inputs
          ...List.generate(
            3,
            (i) => TaprootKeyInput(prevOut: examplePrevOut),
          ),
        ],
        outputs: [exampleOutput],
      )
      // Sign legacy
      .sign(inputN: 0, key: keyVec.privateObj)
      .sign(
        inputN: 2,
        key: keyVec.privateObj,
        hashType: SigHashType.all(anyOneCanPay: true),
      )
      .sign(
        inputN: 3,
        key: keyVec.privateObj,
        hashType: SigHashType.single(),
      )
      // Sign witness
      .sign(inputN: 4, key: keyVec.privateObj, value: value)
      .sign(
        inputN: 5,
        key: keyVec.privateObj,
        hashType: SigHashType.all(anyOneCanPay: true),
        value: value,
      )
      .sign(
        inputN: 6,
        key: keyVec.privateObj,
        hashType: SigHashType.none(),
        value: value,
      )
      // Sign taproot
      .sign(inputN: 7, key: keyVec.privateObj, prevOuts: taprootPrevOuts)
      .sign(
        inputN: 8,
        key: keyVec.privateObj,
        hashType: SigHashType.all(anyOneCanPay: true),
        prevOuts: taprootPrevOuts,
      )
      .sign(
        inputN: 9,
        key: keyVec.privateObj,
        hashType: SigHashType.none(),
        prevOuts: taprootPrevOuts,
      );

      void expectComplete(Transaction tx, Iterable<bool> completes)
        => expect(tx.inputs.map((i) => i.complete), completes);

      // All but the 2nd input is complete
      expectComplete(tx, Iterable.generate(10, (i) => i != 1));

      // Do not invalidate anything when prevout and sequence is the same
      expectComplete(
        tx.replaceInput(
          RawInput(
            prevOut: examplePrevOut,
            scriptSig: hexToBytes("00"),
          ),
          1,
        ),
        Iterable.generate(10, (i) => true),
      );

      // Only invalidate SIGHASH_ALL or taproot inputs without ANYONECANPAY when
      // sequence changes
      expectComplete(
        tx.replaceInput(
          RawInput(
            prevOut: examplePrevOut,
            scriptSig: hexToBytes("00"),
            sequence: 0,
          ),
          1,
        ),
        [
          // Legacy
          false, true, true, true,
          // Witness
          false, true, true,
          // Taproot
          false, true, false,
        ],
      );


      // Only keep ANYONECANPAY when prevout changes
      expectComplete(
        tx.replaceInput(
          RawInput(
            prevOut: OutPoint(examplePrevOut.hash, 1),
            scriptSig: hexToBytes("00"),
          ),
          1,
        ),
        [
          // Legacy
          false, true, true, false,
          // Witness
          false, true, false,
          // Taproot
          false, true, false,
        ],
      );

      // Sign second input outside tx and check it is OK
      final signedIn = (tx.inputs[1] as P2PKHInput).sign(
        tx: tx,
        inputN: 1,
        key: keyVec.privateObj,
      );
      final signedTx = tx.replaceInput(signedIn, 1);

      expectComplete(signedTx, Iterable.generate(10, (i) => true));

      expect(
        signedTx.toHex(),
        "0300000000010af1fefefefefefefefefefefefefefefefefefefefefefefefefefefefefefefe000000006a473044022079f777b6059975ce333332bb3ecde653be038dcbddefc7920072124b1ffe43fc022030926798d6440ea69aab4e28a3ebf84fa46f3f31ae2c1c38b04c73120abea2cf01210279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798fffffffff1fefefefefefefefefefefefefefefefefefefefefefefefefefefefefefefe000000006a47304402201e8ab341d37d9cdd8563d649e710eee973ae601fe61b57da6e1d7ae10ba21a7a022023a9d5b20a43df3c60697c876ba2030d754dda0e07804a699222616ffce3cf3801210279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798fffffffff1fefefefefefefefefefefefefefefefefefefefefefefefefefefefefefefe000000006a47304402202c2f712bbef221026214ae9e54e817eb73df6c73aca4d35b5190caf28c454cd102207dc3750935a86b4431e55476a1e049d3d8ee7cf13162f264ce9964afa4b09c7181210279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798fffffffff1fefefefefefefefefefefefefefefefefefefefefefefefefefefefefefefe000000006a47304402205a0d9a76a926bce5a74db8fa127d8c8779d868de26c1422f4b8acd3f8735ba580220381287903eeb349023c8d6a0d77ddcdf9fcbc01ce968627183f124ecd5e860c203210279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798fffffffff1fefefefefefefefefefefefefefefefefefefefefefefefefefefefefefefe0000000000fffffffff1fefefefefefefefefefefefefefefefefefefefefefefefefefefefefefefe0000000000fffffffff1fefefefefefefefefefefefefefefefefefefefefefefefefefefefefefefe0000000000fffffffff1fefefefefefefefefefefefefefefefefefefefefefefefefefefefefefefe0000000000fffffffff1fefefefefefefefefefefefefefefefefefefefefefefefefefefefefefefe0000000000fffffffff1fefefefefefefefefefefefefefefefefefefefefefefefefefefefefefefe0000000000ffffffff01a0860100000000001976a914c42e7ef92fdb603af844d064faad95db9bcdfd3d88ac00000000024730440220487c6b12556adc75a199a8b390d38b928bd4efbb831f2010250389995fee821302204dfa74a4e7711a8b96249a6ec7836e4cc374d6dbf3864fdd142a25a67663ebfe01210279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f817980247304402206e47c35235a3f5dab7420ad3e2ecdc395cb402b9fc29e8ada89ff6e380ac4df3022010812c5beacf5ef47ac380511989d204804b33a664ffe9019ea8be23ccf56f2981210279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f817980247304402202b4600fe4e9823210f36074f9e3d1fa442d940e00970b707014630f2a2f695b402203e2468c4c2501959a92fafe6475cff1ba1497b5e50c77701188923399654d1d602210279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f8179801416dc042d6c7ada370318f0d33e16421154964ad39c8b7ee275fcaa681a2ebfe48d9b53033672b232821e94aafa0772174d20c99a97e8b44b53937a0cd9caf904d010141af1a113a9cd6f83655cb1444e8f8e3bf07751381a942a3a35b40bac08f61c56a8736a49d8998380305e488e156ecd0516b40474db401ba359ef46cd49d96743d810141f2edfd966b88a16e30c840bf8a93e05bd2bc2bed954a01712bc0ff2fbfcdff654f6262054ba965b09c08e03c8e29c2bd19fd6a2294e5464fa45f58908fab0c8e0200000000",
      );

    });

  });

}
