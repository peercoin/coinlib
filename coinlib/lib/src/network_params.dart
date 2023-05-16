
class NetworkParams {

  final int wifPrefix;
  final int p2pkhPrefix;
  final int p2shPrefix;
  final String bech32Hrp;
  final String messagePrefix;

  const NetworkParams({
    required this.wifPrefix,
    required this.p2pkhPrefix,
    required this.p2shPrefix,
    required this.bech32Hrp,
    required this.messagePrefix,
  });

  static const mainnet = NetworkParams(
    wifPrefix: 183,
    p2pkhPrefix: 55,
    p2shPrefix: 117,
    bech32Hrp: "pc",
    messagePrefix: "Peercoin Signed Message:\n",
  );

}
