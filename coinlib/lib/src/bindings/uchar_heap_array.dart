import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';

typedef UCharPointer = Pointer<UnsignedChar>;

/// Encapsulates a heap-allocated unsigned char array, accessible as a Uint8List
class UnsignedCharHeapArray {

  static final Finalizer<UCharPointer> _finalizer = Finalizer(
    (ptr) => malloc.free(ptr),
  );

  final int size;
  final UCharPointer ptr;

  UnsignedCharHeapArray(this.size) : ptr = malloc.allocate(size) {
    _finalizer.attach(this, ptr);
  }

  Uint8List get list => ptr.cast<Uint8>().asTypedList(size);
  load(Uint8List data) => list.setAll(0, data);

}
