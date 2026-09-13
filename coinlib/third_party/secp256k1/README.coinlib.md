# Vendored secp256k1

This directory contains the production sources and public headers required from
`peercoin/secp256k1-coinlib` 0.7.0 at commit
`69018e5b939d8d540ca6b237945100f4ecb5681e`. Upstream benchmarks, tests, test
vectors, and standalone build files are intentionally omitted.

The source is vendored so Dart Code Assets build and link hooks can compile and
tree-shake the native library without network access. See `COPYING` for the MIT
license.
