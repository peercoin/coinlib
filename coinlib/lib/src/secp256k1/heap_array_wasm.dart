import 'dart:typed_data';

import 'heap_array_base.dart';

typedef MallocFunction = int Function(int);
typedef FreeFunction = int Function(int);

/// Encapsulates a WASM heap-allocated unsigned char array, accessible as a
/// Uint8List
class HeapArrayWasm extends HeapArrayBase<int> {

  static final Finalizer<void Function()> _finalizer = Finalizer(
    (free) => free(),
  );

  final int size;
  @override
  final int ptr;
  @override
  final Uint8List list;

  HeapArrayWasm._(this.size, this.ptr, this.list, FreeFunction free) {
    _finalizer.attach(this, () => free(ptr));
  }

  factory HeapArrayWasm(
    int size, Uint8List memory, MallocFunction malloc, FreeFunction free,
  ) {
    final ptr = malloc(size);
    final list = Uint8List.view(memory.buffer, ptr, size);
    return HeapArrayWasm._(size, ptr, list, free);
  }

  @override
  load(Uint8List data) => list.setAll(0, data);

}

/// Provides [HeapArrayWasm] objects with the same memory and malloc and free
/// functions.
class HeapArrayWasmFactory {

  final Uint8List memory;
  final MallocFunction malloc;
  final FreeFunction free;

  HeapArrayWasmFactory(this.memory, this.malloc, this.free);

  HeapArrayWasm create(int size) => HeapArrayWasm(size, memory, malloc, free);

}
