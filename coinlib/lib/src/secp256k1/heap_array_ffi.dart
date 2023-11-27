import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';

import 'heap_array_base.dart';

typedef UCharPointer = Pointer<UnsignedChar>;

/// Encapsulates a FFI heap-allocated unsigned char array, accessible as a
/// Uint8List
class HeapArrayFfi extends HeapArrayBase<UCharPointer> {

  static final Finalizer<UCharPointer> _finalizer = Finalizer(
    (ptr) => malloc.free(ptr),
  );

  final int size;
  @override
  final UCharPointer ptr;

  HeapArrayFfi(this.size) : ptr = malloc.allocate(size) {
    _finalizer.attach(this, ptr);
  }

  @override
  Uint8List get list => ptr.cast<Uint8>().asTypedList(size);
  @override
  load(Uint8List data) => list.setAll(0, data);

}
