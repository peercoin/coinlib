class Network {
  final int wifPrefix, p2pkhPrefix, p2shPrefix, privHDPrefix, pubHDPrefix;
  final String bech32Hrp, messagePrefix, mwebBech32Hrp;
  final BigInt minFee, minOutput, feePerKb;

  Network({
    required this.wifPrefix,
    required this.p2pkhPrefix,
    required this.p2shPrefix,
    required this.privHDPrefix,
    required this.pubHDPrefix,
    required this.bech32Hrp,
    this.mwebBech32Hrp = "",
    required this.messagePrefix,
    required this.minFee,
    required this.minOutput,
    required this.feePerKb,
  });

  // copyWith function
  Network copyWith({
    int? wifPrefix,
    int? p2pkhPrefix,
    int? p2shPrefix,
    int? privHDPrefix,
    int? pubHDPrefix,
    String? bech32Hrp,
    String? mwebBech32Hrp,
    String? messagePrefix,
    BigInt? minFee,
    BigInt? minOutput,
    BigInt? feePerKb,
  }) {
    return Network(
      wifPrefix: wifPrefix ?? this.wifPrefix,
      p2pkhPrefix: p2pkhPrefix ?? this.p2pkhPrefix,
      p2shPrefix: p2shPrefix ?? this.p2shPrefix,
      privHDPrefix: privHDPrefix ?? this.privHDPrefix,
      pubHDPrefix: pubHDPrefix ?? this.pubHDPrefix,
      bech32Hrp: bech32Hrp ?? this.bech32Hrp,
      mwebBech32Hrp: mwebBech32Hrp ?? this.mwebBech32Hrp,
      messagePrefix: messagePrefix ?? this.messagePrefix,
      minFee: minFee ?? this.minFee,
      minOutput: minOutput ?? this.minOutput,
      feePerKb: feePerKb ?? this.feePerKb,
    );
  }

  @override
  String toString() {
    return 'Network(\n'
        '  wifPrefix: $wifPrefix,\n'
        '  p2pkhPrefix: $p2pkhPrefix,\n'
        '  p2shPrefix: $p2shPrefix,\n'
        '  privHDPrefix: 0x${privHDPrefix.toRadixString(16)},\n'
        '  pubHDPrefix: 0x${pubHDPrefix.toRadixString(16)},\n'
        '  bech32Hrp: "$bech32Hrp",\n'
        '  mwebBech32Hrp: "$mwebBech32Hrp",\n'
        '  messagePrefix: "$messagePrefix",\n'
        '  minFee: $minFee,\n'
        '  minOutput: $minOutput,\n'
        '  feePerKb: $feePerKb\n'
        ')';
  }

  static final mainnet = Network(
    wifPrefix: 183,
    p2pkhPrefix: 55,
    p2shPrefix: 117,
    privHDPrefix: 0x0488ade4,
    pubHDPrefix: 0x0488b21e,
    bech32Hrp: "pc",
    mwebBech32Hrp: "",
    messagePrefix: "Peercoin Signed Message:\n",
    minFee: BigInt.from(1000),
    minOutput: BigInt.from(10000),
    feePerKb: BigInt.from(10000),
  );

  static final testnet = Network(
    wifPrefix: 239,
    p2pkhPrefix: 111,
    p2shPrefix: 196,
    privHDPrefix: 0x043587CF,
    pubHDPrefix: 0x04358394,
    bech32Hrp: "tpc",
    mwebBech32Hrp: "",
    messagePrefix: "Peercoin Signed Message:\n",
    minFee: BigInt.from(1000),
    minOutput: BigInt.from(10000),
    feePerKb: BigInt.from(10000),
  );
}
