import 'package:coinlib/coinlib.dart';
import 'package:test/test.dart';

final privPrefix = Network.mainnet.privHDPrefix;
final pubPrefix = Network.mainnet.pubHDPrefix;

class HDVector {
  final String? seedHex;
  final String privHex;
  final String chaincodeHex;
  final String privEncoded;
  final String pubEncoded;
  final String identifierHex;
  final int fingerprint;
  final int depth;
  final int index;
  final bool hardened;

  HDVector({
    required this.seedHex,
    required this.privHex,
    required this.chaincodeHex,
    required this.privEncoded,
    required this.pubEncoded,
    required this.identifierHex,
    required this.fingerprint,
    required this.depth,
    required this.index,
    required this.hardened,
  });

  void expectHDKey(HDKey key) {

    late HDPublicKey pubKey;
    if (key is HDPrivateKey) {
      expect(bytesToHex(key.privateKey.data), privHex);
      expect(key.encode(privPrefix), privEncoded);
      pubKey = key.hdPublicKey;
    } else {
      expect(key.privateKey, null);
      pubKey = key as HDPublicKey;
    }

    expect(pubKey.encode(pubPrefix), pubEncoded);
    expect(bytesToHex(key.chaincode), chaincodeHex);
    expect(bytesToHex(key.identifier), identifierHex);
    expect(key.fingerprint, fingerprint);
    expect(key.depth, depth);
    expect(key.index, index);

  }

  // Adds a static check to the key type
  void expectHDPrivateKey(HDPrivateKey key) => expectHDKey(key);

}

final hdVectors = [
  [
    HDVector(
      seedHex: "000102030405060708090a0b0c0d0e0f",
      privHex: "e8f32e723decf4051aefac8e2c93c9c5b214313817cdb01a1494b917c8436b35",
      chaincodeHex: "873dff81c02f525623fd1fe5167eac3a55a049de3d314bb42ee227ffed37d508",
      privEncoded: "xprv9s21ZrQH143K3QTDL4LXw2F7HEK3wJUD2nW2nRk4stbPy6cq3jPPqjiChkVvvNKmPGJxWUtg6LnF5kejMRNNU3TGtRBeJgk33yuGBxrMPHi",
      pubEncoded: "xpub661MyMwAqRbcFtXgS5sYJABqqG9YLmC4Q1Rdap9gSE8NqtwybGhePY2gZ29ESFjqJoCu1Rupje8YtGqsefD265TMg7usUDFdp6W1EGMcet8",
      identifierHex: "3442193e1bb70916e914552172cd4e2dbc9df811",
      fingerprint: 0x3442193e,
      depth: 0,
      index: 0,
      hardened: true,
    ),
    HDVector(
      seedHex: null,
      privHex: "edb2e14f9ee77d26dd93b4ecede8d16ed408ce149b6cd80b0715a2d911a0afea",
      chaincodeHex: "47fdacbd0f1097043b78c63c20c34ef4ed9a111d980047ad16282c7ae6236141",
      privEncoded: "xprv9uHRZZhk6KAJC1avXpDAp4MDc3sQKNxDiPvvkX8Br5ngLNv1TxvUxt4cV1rGL5hj6KCesnDYUhd7oWgT11eZG7XnxHrnYeSvkzY7d2bhkJ7",
      pubEncoded: "xpub68Gmy5EdvgibQVfPdqkBBCHxA5htiqg55crXYuXoQRKfDBFA1WEjWgP6LHhwBZeNK1VTsfTFUHCdrfp1bgwQ9xv5ski8PX9rL2dZXvgGDnw",
      identifierHex: "5c1bd648ed23aa5fd50ba52b2457c11e9e80a6a7",
      fingerprint: 0x5c1bd648,
      depth: 1,
      index: 2147483648,
      hardened: true,
    ),
    HDVector(
      seedHex: null,
      privHex: "3c6cb8d0f6a264c91ea8b5030fadaa8e538b020f0a387421a12de9319dc93368",
      chaincodeHex: "2a7857631386ba23dacac34180dd1983734e444fdbf774041578e9b6adb37c19",
      privEncoded: "xprv9wTYmMFdV23N2TdNG573QoEsfRrWKQgWeibmLntzniatZvR9BmLnvSxqu53Kw1UmYPxLgboyZQaXwTCg8MSY3H2EU4pWcQDnRnrVA1xe8fs",
      pubEncoded: "xpub6ASuArnXKPbfEwhqN6e3mwBcDTgzisQN1wXN9BJcM47sSikHjJf3UFHKkNAWbWMiGj7Wf5uMash7SyYq527Hqck2AxYysAA7xmALppuCkwQ",
      identifierHex: "bef5a2f9a56a94aab12459f72ad9cf8cf19c7bbe",
      fingerprint: 0xbef5a2f9,
      depth: 2,
      index: 1,
      hardened: false,
    ),
    HDVector(
      seedHex: null,
      privHex: "cbce0d719ecf7431d88e6a89fa1483e02e35092af60c042b1df2ff59fa424dca",
      chaincodeHex: "04466b9cc8e161e966409ca52986c584f07e9dc81f735db683c3ff6ec7b1503f",
      privEncoded: "xprv9z4pot5VBttmtdRTWfWQmoH1taj2axGVzFqSb8C9xaxKymcFzXBDptWmT7FwuEzG3ryjH4ktypQSAewRiNMjANTtpgP4mLTj34bhnZX7UiM",
      pubEncoded: "xpub6D4BDPcP2GT577Vvch3R8wDkScZWzQzMMUm3PWbmWvVJrZwQY4VUNgqFJPMM3No2dFDFGTsxxpG5uJh7n7epu4trkrX7x7DogT5Uv6fcLW5",
      identifierHex: "ee7ab90cde56a8c0e2bb086ac49748b8db9dce72",
      fingerprint: 0xee7ab90c,
      depth: 3,
      index: 2147483650,
      hardened: true,
    ),
    HDVector(
      seedHex: null,
      privHex: "0f479245fb19a38a1954c5c7c0ebab2f9bdfd96a17563ef28a6a4b1a2a764ef4",
      chaincodeHex: "cfb71883f01676f587d023cc53a35bc7f88f724b1f8c2892ac1275ac822a3edd",
      privEncoded: "xprvA2JDeKCSNNZky6uBCviVfJSKyQ1mDYahRjijr5idH2WwLsEd4Hsb2Tyh8RfQMuPh7f7RtyzTtdrbdqqsunu5Mm3wDvUAKRHSC34sJ7in334",
      pubEncoded: "xpub6FHa3pjLCk84BayeJxFW2SP4XRrFd1JYnxeLeU8EqN3vDfZmbqBqaGJAyiLjTAwm6ZLRQUMv1ZACTj37sR62cfN7fe5JnJ7dh8zL4fiyLHV",
      identifierHex: "d880d7d893848509a62d8fb74e32148dac68412f",
      fingerprint: 0xd880d7d8,
      depth: 4,
      index: 2,
      hardened: false,
    ),
    HDVector(
      seedHex: null,
      privHex: "471b76e389e528d6de6d816857e012c5455051cad6660850e58372a6c3e6e7c8",
      chaincodeHex: "c783e67b921d2beb8f6b389cc646d7263b4145701dadd2161548a8b078e65e9e",
      privEncoded: "xprvA41z7zogVVwxVSgdKUHDy1SKmdb533PjDz7J6N6mV6uS3ze1ai8FHa8kmHScGpWmj4WggLyQjgPie1rFSruoUihUZREPSL39UNdE3BBDu76",
      pubEncoded: "xpub6H1LXWLaKsWFhvm6RVpEL9P4KfRZSW7abD2ttkWP3SSQvnyA8FSVqNTEcYFgJS2UaFcxupHiYkro49S8yGasTvXEYBVPamhGW6cFJodrTHy",
      identifierHex: "d69aa102255fed74378278c7812701ea641fdf32",
      fingerprint: 0xd69aa102,
      depth: 5,
      index: 1000000000,
      hardened: false,
    ),
  ],
  [
    HDVector(
      seedHex: "fffcf9f6f3f0edeae7e4e1dedbd8d5d2cfccc9c6c3c0bdbab7b4b1aeaba8a5a29f9c999693908d8a8784817e7b7875726f6c696663605d5a5754514e4b484542",
      privHex: "4b03d6fc340455b363f51020ad3ecca4f0850280cf436c70c727923f6db46c3e",
      chaincodeHex: "60499f801b896d83179a4374aeb7822aaeaceaa0db1f85ee3e904c4defbd9689",
      privEncoded: "xprv9s21ZrQH143K31xYSDQpPDxsXRTUcvj2iNHm5NUtrGiGG5e2DtALGdso3pGz6ssrdK4PFmM8NSpSBHNqPqm55Qn3LqFtT2emdEXVYsCzC2U",
      pubEncoded: "xpub661MyMwAqRbcFW31YEwpkMuc5THy2PSt5bDMsktWQcFF8syAmRUapSCGu8ED9W6oDMSgv6Zz8idoc4a6mr8BDzTJY47LJhkJ8UB7WEGuduB",
      identifierHex: "bd16bee53961a47d6ad888e29545434a89bdfe95",
      fingerprint: 0xbd16bee5,
      depth: 0,
      index: 0,
      hardened: true,
    ),
    HDVector(
      seedHex: null,
      privHex: "abe74a98f6c7eabee0428f53798f0ab8aa1bd37873999041703c742f15ac7e1e",
      chaincodeHex: "f0909affaa7ee7abe5dd4e100598d4dc53cd709d5a5c2cac40e7412f232f7c9c",
      privEncoded: "xprv9vHkqa6EV4sPZHYqZznhT2NPtPCjKuDKGY38FBWLvgaDx45zo9WQRUT3dKYnjwih2yJD9mkrocEZXo1ex8G81dwSM1fwqWpWkeS3v86pgKt",
      pubEncoded: "xpub69H7F5d8KSRgmmdJg2KhpAK8SR3DjMwAdkxj3ZuxV27CprR9LgpeyGmXUbC6wb7ERfvrnKZjXoUmmDznezpbZb7ap6r1D3tgFxHmwMkQTPH",
      identifierHex: "5a61ff8eb7aaca3010db97ebda76121610b78096",
      fingerprint: 0x5a61ff8e,
      depth: 1,
      index: 0,
      hardened: false,
    ),
    HDVector(
      seedHex: null,
      privHex: "877c779ad9687164e9c2f4f0f4ff0340814392330693ce95a58fe18fd52e6e93",
      chaincodeHex: "be17a268474a6bb9c61e1d720cf6215e2a88c5406c4aee7b38547f585c9a37d9",
      privEncoded: "xprv9wSp6B7kry3Vj9m1zSnLvN3xH8RdsPP1Mh7fAaR7aRLcQMKTR2vidYEeEg2mUCTAwCd6vnxVrcjfy2kRgVsFawNzmjuHc2YmYRmagcEPdU9",
      pubEncoded: "xpub6ASAVgeehLbnwdqV6UKMHVzgqAG8Gr6riv3Fxxpj8ksbH9ebxaEyBLZ85ySDhKiLDBrQSARLq1uNRts8RuJiHjaDMBU4Zn9h8LZNnBC5y4a",
      identifierHex: "d8ab493736da02f11ed682f88339e720fb0379d1",
      fingerprint: 0xd8ab4937,
      depth: 2,
      index: 4294967295,
      hardened: true,
    ),
    HDVector(
      seedHex: null,
      privHex: "704addf544a06e5ee4bea37098463c23613da32020d604506da8c0518e1da4b7",
      chaincodeHex: "f366f48f1ea9f2d1d3fe958c95ca84ea18e4c4ddb9366c336c927eb246fb38cb",
      privEncoded: "xprv9zFnWC6h2cLgpmSA46vutJzBcfJ8yaJGg8cX1e5StJh45BBciYTRXSd25UEPVuesF9yog62tGAQtHjXajPPdbRCHuWS6T8XA2ECKADdw4Ef",
      pubEncoded: "xpub6DF8uhdarytz3FWdA8TvFSvvAh8dP3283MY7p2V4SeE2wyWmG5mg5EwVvmdMVCQcoNJxGoWaU9DCWh89LojfZ537wTfunKau47EL2dhHKon",
      identifierHex: "78412e3a2296a40de124307b6485bd19833e2e34",
      fingerprint: 0x78412e3a,
      depth: 3,
      index: 1,
      hardened: false,
    ),
    HDVector(
      seedHex: null,
      privHex: "f1c7c871a54a804afe328b4c83a1c33b8e5ff48f5087273f04efa83b247d6a2d",
      chaincodeHex: "637807030d55d01f9a0cb3a7839515d796bd07706386a6eddf06cc29a65a0e29",
      privEncoded: "xprvA1RpRA33e1JQ7ifknakTFpgNXPmW2YvmhqLQYMmrj4xJXXWYpDPS3xz7iAxn8L39njGVyuoseXzU6rcxFLJ8HFsTjSyQbLYnMpCqE2VbFWc",
      pubEncoded: "xpub6ERApfZwUNrhLCkDtcHTcxd75RbzS1ed54G1LkBUHQVHQKqhMkhgbmJbZRkrgZw4koxb5JaHWkY4ALHY2grBGRjaDMzQLcgJvLJuZZvRcEL",
      identifierHex: "31a507b815593dfc51ffc7245ae7e5aee304246e",
      fingerprint: 0x31a507b8,
      depth: 4,
      index: 4294967294,
      hardened: true,
    ),
    HDVector(
      seedHex: null,
      privHex: "bb7d39bdb83ecf58f2fd82b6d918341cbef428661ef01ab97c28a4842125ac23",
      chaincodeHex: "9452b549be8cea3ecb7a84bec10dcfd94afe4d129ebfd3b3cb58eedf394ed271",
      privEncoded: "xprvA2nrNbFZABcdryreWet9Ea4LvTJcGsqrMzxHx98MMrotbir7yrKCEXw7nadnHM8Dq38EGfSh6dqA9QWTyefMLEcBYJUuekgW4BYPJcr9E7j",
      pubEncoded: "xpub6FnCn6nSzZAw5Tw7cgR9bi15UV96gLZhjDstkXXxvCLsUXBGXPdSnLFbdpq8p9HmGsApME5hQTZ3emM2rnY5agb9rXpVGyy3bdW6EEgAtqt",
      identifierHex: "26132fdbe7bf89cbc64cf8dafa3f9f88b8666220",
      fingerprint: 0x26132fdb,
      depth: 5,
      index: 2,
      hardened: false,
    ),
  ],
  [
    HDVector(
      seedHex:
      "4b381541583be4423346c643850da4b320e46a87ae3d2a4e6da11eba819cd4acba45d239319ac14f863b8d5ab5a0d0c64d2e8a1e7d1457df2e5a3c51c73235be",
      privHex: "00ddb80b067e0d4993197fe10f2657a844a384589847602d56f0c629c81aae32",
      chaincodeHex: "01d28a3e53cffa419ec122c968b3259e16b65076495494d97cae10bbfec3c36f",
      privEncoded: "xprv9s21ZrQH143K25QhxbucbDDuQ4naNntJRi4KUfWT7xo4EKsHt2QJDu7KXp1A3u7Bi1j8ph3EGsZ9Xvz9dGuVrtHHs7pXeTzjuxBrCmmhgC6",
      pubEncoded: "xpub661MyMwAqRbcEZVB4dScxMAdx6d4nFc9nvyvH3v4gJL378CSRZiYmhRoP7mBy6gSPSCYk6SzXPTf3ND1cZAceL7SfJ1Z3GC8vBgp2epUt13",
      identifierHex: "41d63b50d8dd5e730cdf4c79a56fc929a757c548",
      fingerprint: 0x41d63b50,
      depth: 0,
      index: 0,
      hardened: true,
    ),
    HDVector(
      seedHex: null,
      privHex: "491f7a2eebc7b57028e0d3faa0acda02e75c33b03c48fb288c41e2ea44e1daef",
      chaincodeHex: "e5fea12a97b927fc9dc3d2cb0d1ea1cf50aa5a1fdc1f933e8906bb38df3377bd",
      privEncoded: "xprv9uPDJpEQgRQfDcW7BkF7eTya6RPxXeJCqCJGHuCJ4GiRVLzkTXBAJMu2qaMWPrS7AANYqdq6vcBcBUdJCVVFceUvJFjaPdGZ2y9WACViL4L",
      pubEncoded: "xpub68NZiKmJWnxxS6aaHmn81bvJeTESw724CRDs6HbuccFQN9Ku14VQrADWgqbhhTHBaohPX4CjNLf9fq9MYo6oDaPPLPxSb7gwQN3ih19Zm4Y",
      identifierHex: "c61368bb50e066acd95bd04a0b23d3837fb75698",
      fingerprint: 0xc61368bb,
      depth: 1,
      index: 0x80000000,
      hardened: true,
    ),
  ],
  [
    HDVector(
      seedHex: "3ddd5602285899a946114506157c7997e5444528f3003f6134712147db19b678",
      privHex: "12c0d59c7aa3a10973dbd3f478b65f2516627e3fe61e00c345be9a477ad2e215",
      chaincodeHex: "d0c8a1f6edf2500798c3e0b54f1b56e45f6d03e6076abd36e5e2f54101e44ce6",
      privEncoded: "xprv9s21ZrQH143K48vGoLGRPxgo2JNkJ3J3fqkirQC2zVdk5Dgd5w14S7fRDyHH4dWNHUgkvsvNDCkvAwcSHNAQwhwgNMgZhLtQC63zxwhQmRv",
      pubEncoded: "xpub661MyMwAqRbcGczjuMoRm6dXaLDEhW1u34gKenbeYqAix21mdUKJyuyu5F1rzYGVxyL6tmgBUAEPrEz92mBXjByMRiJdba9wpnN37RLLAXa",
      identifierHex: "ad85d95573bc609b98f2af5e06e150351f818ba9",
      fingerprint: 0xad85d955,
      depth: 0,
      index: 0,
      hardened: true,
    ),
    HDVector(
      seedHex: null,
      privHex: "00d948e9261e41362a688b916f297121ba6bfb2274a3575ac0e456551dfd7f7e",
      chaincodeHex: "cdc0f06456a14876c898790e0b3b1a41c531170aec69da44ff7b7265bfe7743b",
      privEncoded: "xprv9vB7xEWwNp9kh1wQRfCCQMnZUEG21LpbR9NPCNN1dwhiZkjjeGRnaALmPXCX7SgjFTiCTT6bXes17boXtjq3xLpcDjzEuGLQBM5ohqkao9G",
      pubEncoded: "xpub69AUMk3qDBi3uW1sXgjCmVjJ2G6WQoYSnNHyzkmdCHEhSZ4tBok37xfFEqHd2AddP56Tqp4o56AePAgCjYdvpW2PU2jbUPFKsav5ut6Ch1m",
      identifierHex: "cfa61281b1762be25710658757221a6437cbcdd6",
      fingerprint: 0xcfa61281,
      depth: 1,
      index: 0x80000000,
      hardened: true,
    ),
    HDVector(
      seedHex: null,
      privHex: "3a2086edd7d9df86c3487a5905a1712a9aa664bce8cc268141e07549eaa8661d",
      chaincodeHex: "a48ee6674c5264a237703fd383bccd9fad4d9378ac98ab05e6e7029b06360c0d",
      privEncoded: "xprv9xJocDuwtYCMNAo3Zw76WENQeAS6WGXQ55RCy7tDJ8oALr4FWkuVoHJeHVAcAqiZLE7Je3vZJHxspZdFHfnBEjHqU5hG1Jaj32dVoS6XLT1",
      pubEncoded: "xpub6BJA1jSqiukeaesWfxe6sNK9CCGaujFFSJLomWHprUL9DePQ4JDkM5d88n49sMGJxrhpjazuXYWdMf17C9T5XnxkopaeS7jGk1GyyVziaMt",
      identifierHex: "48b2a62638e9cb9b68f87671bc80041dbd3acf70",
      fingerprint: 0x48b2a626,
      depth: 2,
      index: 0x80000001,
      hardened: true,
    ),
  ]
];

final masterVector = hdVectors[0][0];
final masterHDKey = HDPrivateKey.decode(masterVector.privEncoded, privPrefix);

