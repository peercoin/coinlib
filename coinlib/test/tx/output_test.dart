import 'dart:typed_data';
import 'package:coinlib/coinlib.dart';
import 'package:test/test.dart';
import '../vectors/keys.dart';

class OutputVector {
  final BigInt value;
  final Uint8List scriptBytes;
  final Uint8List outBytes;
  final Type progType;
  final String? address;
  OutputVector({
    required this.value,
    required String scriptHex,
    required String outHex,
    required this.progType,
    this.address,
  }) : scriptBytes = hexToBytes(scriptHex), outBytes = hexToBytes(outHex);
}

final vectors = [
  OutputVector(
    value: BigInt.from(0),
    scriptHex: "76a914${pubkeyhashVec}88ac",
    outHex:
    "00000000000000001976a914751e76e8199196d454941c45d1b3a323f1433bd688ac",
    progType: P2PKH,
    address: "PKGSi8HTQzLx89rkZrRrVkPFjrcSC55NP9",
  ),
  OutputVector(
    value: Output.maxValue,
    scriptHex: "0020ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff",
    outHex:
    "ffffffffffffffff220020ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff",
    progType: P2WSH,
    address: "pc1qlllllllllllllllllllllllllllllllllllllllllllllllllllsm5knxw",
  ),
  OutputVector(
    value: BigInt.from(1),
    scriptHex: "01",
    outHex: "01000000000000000101",
    progType: Null,
  ),
  OutputVector(
    value: BigInt.from(0xff),
    scriptHex: "00",
    outHex: "ff000000000000000100",
    progType: RawProgram,
  ),
];

void main() {

  group("Output", () {

    test("can read and write outputs", () {

      expectOutput(Output out, OutputVector vec) {

        expect(out.value, vec.value);
        expect(out.size, vec.outBytes.length);
        expect(out.scriptPubKey, vec.scriptBytes);
        expect(out.toBytes(), vec.outBytes);
        expect(out.program.runtimeType, vec.progType);

        if (vec.progType != Null) {
          expect(out.program!.script.compiled, vec.scriptBytes);
        }

      }

      for (final vec in vectors) {
        expectOutput(Output.fromReader(BytesReader(vec.outBytes)), vec);
        expectOutput(Output.fromScriptBytes(vec.value, vec.scriptBytes), vec);
        if (vec.progType != Null) {
          expectOutput(
            Output.fromProgram(vec.value, Program.decompile(vec.scriptBytes)),
            vec,
          );
        }
        if (vec.address != null) {
          expectOutput(
            Output.fromAddress(
              vec.value,
              Address.fromString(vec.address!, Network.mainnet),
            ),
            vec,
          );
        }
      }

    });

    test("requires value 0-uint8_max", () {
      for (final val in [BigInt.from(-1), BigInt.from(1) << 64]) {
        expect(
          () => Output.fromScriptBytes(val, Uint8List(0)),
          throwsArgumentError,
        );
      }
    });

    test("scriptPubKey cannot be mutated", () {
      final data = Uint8List(2);
      final output = Output.fromScriptBytes(BigInt.one, data);
      data[0] = 0xff;
      output.scriptPubKey[1] = 0xff;
      expect(output.scriptPubKey, Uint8List(2));
    });

  });

}
