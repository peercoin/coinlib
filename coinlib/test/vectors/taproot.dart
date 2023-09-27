
class TaprootVector {
  final String xInternalPubKeyHex;
  final String xTweakedKeyHex;
  TaprootVector({
    required this.xInternalPubKeyHex,
    required this.xTweakedKeyHex,
  });
}

final taprootVectors = [
  TaprootVector(
    xInternalPubKeyHex: "d6889cb081036e0faefa3a35157ad71086b123b2b144b649798b494c300a961d",
    xTweakedKeyHex: "53a1f6e454df1aa2776a2814a721372d6258050de330b3c6d10ee8f4e0dda343",
  ),
];
