## 1.0.0

Final release for 1.0.0

## 1.0.0-rc.3

- Make static variables immutable as final or const.

## 1.0.0-rc.2

- Add `forceLowR` to `ECDSASignature.sign` that is true by default. This forces
    signatures to use a low r-value.
- Transaction signatures now use low r-values.

## 1.0.0-rc.1

- Add witness transactions
- `LegacyTransaction` is replaced with a single `Transaction` class.

## 1.0.0-alpha.3

- Return HDPrivateKey from HDPrivateKey derivation
- Add example code
- hexToBytes and bytesToHex are now exposed

## 1.0.0-alpha.2

- Allow building secp256k1 for macOS using github download
- Require Dart 3

## 1.0.0-alpha

Alpha pre-release of initial library.
