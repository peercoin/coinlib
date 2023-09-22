import 'dart:typed_data';
import 'package:coinlib/coinlib.dart';
import 'package:test/test.dart';

const wrongNetwork = NetworkParams(
  wifPrefix: 0,
  p2pkhPrefix: [0xfa],
  p2shPrefix: [0xfb],
  privHDPrefix: 0,
  pubHDPrefix: 0,
  bech32Hrp: "wrong",
  messagePrefix: "",
);

expectBase58Equal(Base58Address addr, Base58Address expected) {
  expect(addr.hash, expected.hash);
  expect(addr.version, expected.version);
  expect(addr.toString(), expected.toString());
  if (addr is P2PKHAddress) {
    expect(addr.program.pkHash, addr.hash);
  } else if (addr is P2SHAddress) {
    expect(addr.program.scriptHash, addr.hash);
  }
}

expectBech32Equal(Bech32Address addr, Bech32Address expected) {
  expect(addr.data, expected.data);
  expect(addr.hrp, expected.hrp);
  expect(addr.toString(), expected.toString());
  if (addr is P2WPKHAddress) {
    expect(addr.program.pkHash, addr.data);
  } else if (addr is P2WSHAddress) {
    expect(addr.program.scriptHash, addr.data);
  } else if (addr is UnknownWitnessAddress) {
    expect(addr.program.data, addr.data);
  }
}

expectValidAddress<T extends Address>(
  String encoded, NetworkParams network, T expected,
) {

  final baseDecoded = Address.fromString(encoded, network);
  expect(baseDecoded, isA<T>());

  late Address subDecoded;
  if (expected is Base58Address) {
    subDecoded = Base58Address.fromString(encoded, network);
  }
  if (expected is Bech32Address) {
    subDecoded = Bech32Address.fromString(encoded, network);
  }
  expect(subDecoded, isA<T>());

  expect(expected.toString(), encoded);

  expect(
    () => Address.fromString(encoded, wrongNetwork),
    throwsA(isA<InvalidAddressNetwork>()),
  );

  // Compare expected with both decoded addresses
  if (expected is Base58Address) {
    final b58Base = baseDecoded as Base58Address;
    final b58Sub = subDecoded as Base58Address;
    expectBase58Equal(b58Base, expected);
    expectBase58Equal(b58Sub, expected);
  }
  if (expected is Bech32Address) {
    final b32Base = baseDecoded as Bech32Address;
    final b32Sub = subDecoded as Bech32Address;
    expectBech32Equal(b32Base, expected);
    expectBech32Equal(b32Sub, expected);
  }

}

void main() {

  group("Address", () {

    late ECPublicKey pubkey;
    setUpAll(() async {
      await loadCoinlib();
      pubkey = ECPublicKey.fromHex(
        "03aea0dfd576151cb399347aa6732f8fdf027b9ea3ea2e65fb754803f776e0a509",
      );
    });

    test("valid P2PKH addresses", () {

      expectValidAddress(
        "P8bB9yPr3vVByqfmM5KXftyGckAtAdu6f8",
        NetworkParams.mainnet,
        P2PKHAddress.fromHash(
          hexToBytes("0000000000000000000000000000000000000000"),
          version: NetworkParams.mainnet.p2pkhPrefix,
        ),
      );

      expectValidAddress(
        "PGkLtYrKeMDbBCaFy4yMRhN9ZTjJp2y8Pb",
        NetworkParams.mainnet,
        P2PKHAddress.fromPublicKey(
          pubkey, version: NetworkParams.mainnet.p2pkhPrefix,
        ),
      );

    });

    test("valid P2SH addresses", () {

      expectValidAddress(
        "pUtBBpAznHgPW9TDtWJcDo7qGXQJqnf1W9",
        NetworkParams.mainnet,
        P2SHAddress.fromHash(
          hexToBytes("ffffffffffffffffffffffffffffffffffffffff"),
          version: NetworkParams.mainnet.p2shPrefix,
        ),
      );

      expectValidAddress(
        "pL5vkwAVx6Qo1AVm7dzW5XKxP4meAjZQS1",
        NetworkParams.mainnet,
        P2SHAddress.fromScript(
          Script.fromAsm("0"),
          version: NetworkParams.mainnet.p2shPrefix,
        ),
      );

    });

    test("valid P2WPKH addresses", () {

      expectValidAddress(
        "pc1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqmtd2rq",
        NetworkParams.mainnet,
        P2WPKHAddress.fromHash(
          hexToBytes("0000000000000000000000000000000000000000"),
          hrp: NetworkParams.mainnet.bech32Hrp,
        ),
      );

      expectValidAddress(
        "pc1qt97wqg464zrhnx23upykca5annqvwkwuvqmpk5",
        NetworkParams.mainnet,
        P2WPKHAddress.fromPublicKey(
          pubkey, hrp: NetworkParams.mainnet.bech32Hrp,
        ),
      );

    });

    test("valid P2WSH addresses", () {

      expectValidAddress(
        "pc1qlllllllllllllllllllllllllllllllllllllllllllllllllllsm5knxw",
        NetworkParams.mainnet,
        P2WSHAddress.fromHash(
          hexToBytes(
            "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff",
          ),
          hrp: NetworkParams.mainnet.bech32Hrp,
        ),
      );

      expectValidAddress(
        "pc1qdc6qh88lkdaf3899gnntk7q293ufq8flkvmnsa59zx3sv9a05qwsgzh235",
        NetworkParams.mainnet,
        P2WSHAddress.fromScript(
          Script.fromAsm("0"),
          hrp: NetworkParams.mainnet.bech32Hrp,
        ),
      );

    });

    test("valid unknown witness addresses", () {

      // 40 program bytes
      expectValidAddress(
        "pc1sqqqsyqcyq5rqwzqfpg9scrgwpugpzysnzs23v9ccrydpk8qarc0jqgfzyvjz2f38pj2w3g",
        NetworkParams.mainnet,
        UnknownWitnessAddress.fromHex(
          "000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f2021222324252627",
          version: 16,
          hrp: NetworkParams.mainnet.bech32Hrp,
        ),
      );

      // 2 program bytes
      expectValidAddress(
        "pc1sqqqsfrujuz",
        NetworkParams.mainnet,
        UnknownWitnessAddress.fromHex(
          "0001",
          version: 16,
          hrp: NetworkParams.mainnet.bech32Hrp,
        ),
      );

      // Taproot v=1, unknown at the moment
      expectValidAddress(
        "pc1pqqqsyqcyq5rqwzqfpg9scrgwpugpzysnzs23v9ccrydpk8qarc0s6f7fhu",
        NetworkParams.mainnet,
        UnknownWitnessAddress.fromHex(
          "000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f",
          version: 1,
          hrp: NetworkParams.mainnet.bech32Hrp,
        ),
      );

    });

    test("invalid addresses", () {

      for (final invalid in [
        // Neither valid bech32 or base58
        "",
        // Too-short
        "61pApofd7QTRzWAb5UebizEXJ6C1cCzLU",
        "TTazDDREDxxh1mPyGySut6H98h4UKPG6",
        "pc1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq3nu382",
        "pc1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq2zhzfj",
        // Too-long
        "9tT9KH26AxgN8j9uTpKdwUkK6LFcSKp4FpF",
        "pc1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqquk6wwa",
        // Segwit version 17
        "pc13qqqsyqcyq5rqwzqfpg9scrgwpugpzysnzs23v9ccrydpk8qarc0sxaytzs",
        // Too long unknown segwit
        "pc1sqqqsyqcyq5rqwzqfpg9scrgwpugpzysnzs23v9ccrydpk8qarc0jqgfzyvjz2f389qyd22c5",
        // Too short unknown segwit
        "pc1sqqwczah4",
        // Bech32m for v=0
        "pc1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqwhaxxz",
        // Bech32 for v=1
        "pc1pqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqs46pwt",
        // Unpadded bits
        "pc1qqqqsyqcyq5rqwzqfpg9scrgwpugpzysnzs23v9ccrydpk8qarc0pcfzdx",
      ]) {
        expect(
          () => Address.fromString(invalid, NetworkParams.mainnet),
          throwsA(isA<InvalidAddress>()),
          reason: invalid,
        );
      }

    });

    test("invalid checksums", () {
      expect(
        () => Address.fromString(
          "P8bB9yPr3vVByqfmM5KXftyGckAtAdu6f9", NetworkParams.mainnet,
        ),
        throwsA(isA<InvalidBase58Checksum>()),
      );
      expect(
        () => Address.fromString(
          "pc1qlllllllllllllllllllllllllllllllllllllllllllllllllllsm5knxx",
          NetworkParams.mainnet,
        ),
        throwsA(isA<InvalidBech32Checksum>()),
      );
    });

    test("invalid base58 version", () {
      for (final v in [-1, 256]) {
        expect(
          () => P2PKHAddress.fromPublicKey(pubkey, version: [v]),
          throwsArgumentError,
        );
      }
    });

    test("invalid version, program and hrp arguments", () {

      // Too small program
      expect(
        () => UnknownWitnessAddress.fromHex(
          "00",
          version: 16,
          hrp: NetworkParams.mainnet.bech32Hrp,
        ),
        throwsArgumentError,
      );

      // Too large program
      expect(
        () => UnknownWitnessAddress.fromHex(
          "000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728",
          version: 16,
          hrp: NetworkParams.mainnet.bech32Hrp,
        ),
        throwsArgumentError,
      );

      // Invalid HRP
      expect(
        () => UnknownWitnessAddress.fromHex(
          "0001",
          version: 16,
          hrp: "\x7f""1axkwrx",
        ),
        throwsArgumentError,
      );

      // Invalid version
      expect(
        () => UnknownWitnessAddress.fromHex(
          "0001",
          version: 17,
          hrp: NetworkParams.mainnet.bech32Hrp,
        ),
        throwsArgumentError,
      );
      expect(
        () => UnknownWitnessAddress.fromHex(
          "0001",
          version: -1,
          hrp: NetworkParams.mainnet.bech32Hrp,
        ),
        throwsArgumentError,
      );

    });

    final longHrp =
      "thishrpis78byteslongleadingthetotalsizetobe90characterswitheverythingincluded1";

    test("arguments correct size", () {

      final addr = UnknownWitnessAddress.fromHex("0001", version: 16, hrp: longHrp);

      expectValidAddress(
        "${longHrp}1sqqqs3t97ut",
        NetworkParams(
          wifPrefix: 0, p2shPrefix: [0], p2pkhPrefix: [0],
          privHDPrefix: 0, pubHDPrefix: 0,
          bech32Hrp: longHrp, messagePrefix: "",
        ),
        addr,
      );

    });

    test("arguments too long", () {
      expect(
        () => UnknownWitnessAddress.fromHex("0001", version: 16, hrp: "${longHrp}1"),
        throwsArgumentError,
      );
    });

  });

  group("Base58Address", () {
    test(".hash is copied and cannot be mutated", () {
      final hash = Uint8List(20);
      final addr = P2PKHAddress.fromHash(hash, version: [0]);
      addr.hash[0] = 0xff;
      hash[1] = 0xff;
      expect(addr.hash, Uint8List(20));
    });
  });

  group("Bech32Address", () {
    test(".data is copied and cannot be mutated", () {
      final hash = Uint8List(20);
      final addr = P2WPKHAddress.fromHash(hash, hrp: "pc");
      addr.data[0] = 0xff;
      hash[1] = 0xff;
      expect(addr.data, Uint8List(20));
    });
  });

}
