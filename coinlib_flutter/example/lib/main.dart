import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:coinlib_flutter/coinlib_flutter.dart' as coinlib;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static String expPubkey =
    "0279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798";

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      appBar: AppBar(title: const Text("Coinlib Example")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: _getCoinLibWidget(context)
        )
      )
    )
  );

  Widget _getCoinLibWidget(BuildContext context) => coinlib.CoinlibLoader(
    loadChild: const Text("Loading coinlib..."),
    errorBuilder: (context, error) => Text("Error $error"),
    builder: (context) {

      final privKey = coinlib.ECPrivateKey.fromHex(
        "0000000000000000000000000000000000000000000000000000000000000001",
      );

      const msg = "Hello World";
      final msgSignature = coinlib.MessageSignature.sign(
        key: privKey,
        message: msg,
        prefix: coinlib.Network.mainnet.messagePrefix,
      );

      final schnorrSignature = coinlib.SchnorrSignature.sign(
        privKey, Uint8List(32),
      );

      return Column(
        spacing: 10,
        children: [
          Text(
            "Public key is ${privKey.pubkey.hex} and should equal $expPubkey."
          ),
          Text(
            "The message '$msg' signed with the key gives the signature"
            " $msgSignature."
          ),
          Text(
            "An example Schnorr signature is"
            " ${coinlib.bytesToHex(schnorrSignature.data)}."
          ),
        ],
      );

    }
  );

}
