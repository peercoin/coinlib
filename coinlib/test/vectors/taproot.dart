
class TaprootVector {
  final String xInternalPubKeyHex;
  final String tweakScalarHex;
  final String xTweakedKeyHex;
  TaprootVector({
    required this.xInternalPubKeyHex,
    required this.tweakScalarHex,
    required this.xTweakedKeyHex,
  });
}

final taprootVectors = [
  TaprootVector(
    xInternalPubKeyHex: "d6889cb081036e0faefa3a35157ad71086b123b2b144b649798b494c300a961d",
    tweakScalarHex: "b86e7be8f39bab32a6f2c0443abbc210f0edac0e2c53d501b36b64437d9c6c70",
    xTweakedKeyHex: "53a1f6e454df1aa2776a2814a721372d6258050de330b3c6d10ee8f4e0dda343",
  ),
];
