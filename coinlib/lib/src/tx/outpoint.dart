import 'dart:typed_data';
import 'package:coinlib/src/common/bytes.dart';
import 'package:coinlib/src/common/serial.dart';

class OutPoint with Writable {

  final Uint8List _hash;
  final int n;

  OutPoint(Uint8List hash, this.n)
    : _hash = copyCheckBytes(hash, 32, name: "Tx hash") {
    if (n < 0 || n > 0xffffffff) {
      throw ArgumentError.value(n, "this.n", "must be a uint32");
    }
  }

  OutPoint.fromReader(BytesReader reader)
    : _hash = reader.readSlice(32), n = reader.readUInt32();

  @override
  void write(Writer writer) {
    writer.writeSlice(_hash);
    writer.writeUInt32(n);
  }

  Uint8List get hash => Uint8List.fromList(_hash);

}
