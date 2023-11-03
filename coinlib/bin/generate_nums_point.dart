import 'dart:io';
import 'package:coinlib/coinlib.dart';

void main() async {

  await loadCoinlib();

  // Point as in https://www.secg.org/sec2-v2.pdf
  final generatorBytes = hexToBytes(
    "0479BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8",
  );
  final generatorPoint = ECPublicKey(generatorBytes);

  // Verify point is the same as key from private key = 1
  final onePrivKey = ECPrivateKey.fromHex(
    "0000000000000000000000000000000000000000000000000000000000000001",
    compressed: false,
  );

  if (generatorPoint == onePrivKey.pubkey) {
    print("Generator is as expected");
  } else {
    print("Generator isn't as expected");
    exit(0);
  }

  // Take SHA-256 of uncompressed generator bytes
  final numsX = sha256Hash(generatorBytes);
  final numsXHex = bytesToHex(numsX);

  // Check against expected from BIP0341
  final expectedXHex
    = "50929b74c1a04954b78b4b6035e97a5e078a5a0f28ec96d547bfee9ace803ac0";

  if (numsXHex == expectedXHex) {
    print("NUMS Point X-Coordinate HEX: $numsXHex");
  } else {
    print("NUMS point isn't as expected");
  }

}
