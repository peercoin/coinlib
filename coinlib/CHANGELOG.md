## 2.0.0

Final release for 2.0.0

## 2.0.0-rc.10

Fixes documentation links and improves usage of `bytesEqual`.

## 2.0.0-rc.9

- Update secp256k1 to 0.4.1
- Update dart dependencies and FFI bindings

## 2.0.0-rc.8

Add windows build support

## 2.0.0-rc.7

- Add `CoinUnit` class to convert between amount strings and satoshis.
- Change `NetworkParams` to `Network`.

## 2.0.0-rc.6

- `P2WSHAddress.fromScript` is now `P2WSHAddress.fromRedeemScript` and
    `P2WSHAddress.fromScript` is now `P2WSHAddress.fromWitnessScript` to remove
    ambiguity.
- `P2WSH.fromRedeemScript` is now `P2WSH.fromWitnessScript` in accordance with
    usual naming for P2WSH.
- Added `MultisigProgram.sorted` to allow multisig programs with ordered public
    keys.

## 2.0.0-rc.5

Reduce output size of JavaScript by encoding WASM as base64

## 2.0.0-rc.4

Fixed issues with build scripts

## 2.0.0-rc.3

Move secp256k1 code to secp256k1 directory

## 2.0.0-rc.2

Adds `CoinSelection` class with coin selection algorithms.

## 2.0.0-rc.1

- Add Taproot support for key-path spends and script-path spends.
- Taproot keys and MAST trees are provided with the `Taproot` class.
- `P2TRAddress` support for Taproot addresses.
- `P2TR` provides Taproot program support for outputs.
- `TaprootKeyInput` and `TaprootScriptInput` provide Taproot input support.
- `NUMSPublicKey` allows key-path spending to be omitted.
- Signing logic has been moved to the inputs.
- `InputSignature` renamed to `ECDSAInputSignature` and some other name changes.

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
