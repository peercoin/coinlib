class Network({
  required final int wifPrefix,
  required final int p2pkhPrefix,
  required final int p2shPrefix,
  required final int privHDPrefix,
  required final int pubHDPrefix,
  required final String bech32Hrp,
  required final String messagePrefix,
  required final BigInt minFee,
  required final BigInt minOutput,
  required final BigInt feePerKb,
}) {
  static final mainnet = Network(
    wifPrefix: 183,
    p2pkhPrefix: 55,
    p2shPrefix: 117,
    privHDPrefix: 0x0488ade4,
    pubHDPrefix: 0x0488b21e,
    bech32Hrp: "pc",
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
    messagePrefix: "Peercoin Signed Message:\n",
    minFee: BigInt.from(1000),
    minOutput: BigInt.from(10000),
    feePerKb: BigInt.from(10000),
  );
}
