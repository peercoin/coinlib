BigInt addBigInts(Iterable<BigInt> ints) => ints.fold(
  BigInt.zero, (a, b) => a+b,
);
