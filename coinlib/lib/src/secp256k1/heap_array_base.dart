import 'dart:typed_data';

/// Represents a unsigned char array and can read/write a Uint8List
abstract class HeapArrayBase<Ptr> {
  Ptr get ptr;
  Uint8List get list;
  void load(Uint8List data);
}
