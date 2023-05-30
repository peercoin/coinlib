
class NetworkParams {

  final int wifPrefix;
  final int p2pkhPrefix;
  final int p2shPrefix;
  final int privHDPrefix;
  final int pubHDPrefix;
  final String bech32Hrp;
  final String messagePrefix;

  const NetworkParams({
    required this.wifPrefix,
    required this.p2pkhPrefix,
    required this.p2shPrefix,
    required this.privHDPrefix,
    required this.pubHDPrefix,
    required this.bech32Hrp,
    required this.messagePrefix,
  });

  static const mainnet = NetworkParams(
    wifPrefix: 183,
    p2pkhPrefix: 55,
    p2shPrefix: 117,
    privHDPrefix: 0x0488ade4,
    pubHDPrefix: 0x0488b21e,
    bech32Hrp: "pc",
    messagePrefix: "Peercoin Signed Message:\n",
  );

}
