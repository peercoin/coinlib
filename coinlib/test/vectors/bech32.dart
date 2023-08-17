// Taken from Bitcoin Core test vectors

const validBech32 = [
  "A12UEL5L",
  "a12uel5l",
  "an83characterlonghumanreadablepartthatcontainsthenumber1andtheexcludedcharactersbio1tt5tgs",
  "abcdef1qpzry9x8gf2tvdw0s3jn54khce6mua7lmqqqxw",
  "11qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqc8247j",
  "split1checkupstagehandshakeupstreamerranterredcaperred2y9e3w",
  "?1ezyfcl",
];

const validBech32m = [
  "A1LQFN3A",
  "a1lqfn3a",
  "an83characterlonghumanreadablepartthatcontainsthetheexcludedcharactersbioandnumber11sg7hg6",
  "abcdef1l7aum6echk45nj3s0wdvt2fg8x9yrzpqzd3ryx",
  "11llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllludsr8",
  "split1checkupstagehandshakeupstreamerranterredcaperredlc445v",
  "?1v759aa",
];

final invalidBech32 = [
  [" 1nwldj5", "  is an invalid bech32 HRP"],
  ["\x7f""1axkwrx", "\x7f is an invalid bech32 HRP"],
  ["\x80""1eym55h", "\x80 is an invalid bech32 HRP"],
  [
    "an84characterslonghumanreadablepartthatcontainsthenumber1andtheexcludedcharactersbio1569pvx",
    "Bech32 too long",
  ],
  ["pzry9x0s0muk", "Missing HRP"],
  ["1pzry9x0s0muk", "Missing HRP"],
  ["x1b4n0q5v", "Invalid character"],
  ["li1dgmt3", "Checksum too short"],
  ["de1lg7wt\xff", "Invalid character"],
  ["10a06t8", "Missing HRP"],
  ["1qzzfhee",  "Missing HRP"],
  ["a12UEL5L", "Bech32 cannot be mixed case"],
  ["A12uEL5L", "Bech32 cannot be mixed case"],
];

final invalidBech32Checksum = [
  "A1G7SGD8",
  "abcdef1qpzrz9x8gf2tvdw0s3jn54khce6mua7lmqqqxw",
  "test1zg69w7y6hn0aqy352euf40x77qddq3dc",
  "M1VUXWEZ",
  "abcdef1l7aum6echk45nj2s0wdvt2fg8x9yrzpqzd3ryx",
  "test1zg69v7y60n00qy352euf40x77qcusag6",
];
