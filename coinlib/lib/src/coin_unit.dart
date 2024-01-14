/// Thrown when a number does not match the expected format for a given
/// [CoinUnit].
class BadAmountString implements Exception {}

/// Objects of this class represent a coin denomination with a given number of
/// [decimals]. Use [coin] for whole coins with 6 decimal places and [sats] for
/// the smallest unit with no decimal places.
class CoinUnit {

  static final _numberRegex = RegExp(r"^\d+(\.\d+)?$");
  static final _trailZeroRegex = RegExp(r"\.?0*$");

  /// The number of decimal places for this unit
  final int decimals;
  /// The number of satoshis per unit
  final BigInt satsPerUnit;

  /// Creates a unit with a given number of [decimals].
  CoinUnit(this.decimals) : satsPerUnit = BigInt.from(10).pow(decimals);

  /// Obtains the number of satoshis from a string representation of this unit.
  ///
  /// Numbers must only contain digits and optionally one decimal point (".") in
  /// the event that there are any decimals. Ensure that there is at least one
  /// digit before and after the decimal point. There may only be decimals upto
  /// [decimals] in number. Zeros are striped from the left and stripped from
  /// the right after the decimal point.
  ///
  /// May throw [BadAmountString] if the number is not formatted correctly.
  BigInt toSats(String amount) {

    // Check format
    if (!_numberRegex.hasMatch(amount)) throw BadAmountString();

    // Split decimal
    final split = amount.split(".");
    final includesPoint = split.length == 2;

    // Decimal places must not exceed expected decimals
    if (includesPoint && split[1].length > decimals) throw BadAmountString();

    // Parse both sides into BigInt
    final left = BigInt.parse(split[0]);
    final right = includesPoint
      ? BigInt.parse(split[1].padRight(decimals, "0"))
      : BigInt.zero;

    return left*satsPerUnit + right;

  }

  /// Obtains the string representation of the satoshis ([sats]) converted into
  /// this unit.
  String fromSats(BigInt sats) {

    final padded = sats.toString().padLeft(decimals+1, "0");
    final insertIdx = padded.length-decimals;
    final left = padded.substring(0, insertIdx);
    final right = padded.substring(insertIdx);
    final withPoint = "$left.$right";

    // Remove any trailing zeros and the decimal point if it comes before those
    // zeros
    return withPoint.replaceFirst(_trailZeroRegex, "");

  }

  /// Represents a whole coin with 6 decimal places
  static final coin = CoinUnit(6);
  /// Represents a satoshi
  static final sats = CoinUnit(0);

}
