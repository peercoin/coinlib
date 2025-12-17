import 'dart:typed_data';
import 'heap.dart';
import 'wasm.dart';

typedef MallocFunction = int Function(int);
typedef FreeFunction = void Function(int);

// Using wasm32, so integers are 32 bits
final int _intBytes = 4;

/// Represents objects on the heap. These can be created using [HeapFactory].
class HeapWasm implements Heap<int> {

  static final Finalizer<void Function()> _finalizer = Finalizer(
    (free) => free(),
  );

  final Wasm _wasm;

  @override
  final int ptr;

  HeapWasm._(this._wasm, this.ptr, FreeFunction? free) {
    if (free == null) return;
    // Copy avoids reference to object by finalizer ensuring that the object is
    // indeed freed.
    final ptrCopy = ptr;
    _finalizer.attach(this, () => free(ptrCopy));
  }

  Uint8List get memory => _wasm.memory;

}

/// Encapsulates a WASM heap-allocated unsigned char array, accessible as a
/// Uint8List. Must be created through [HeapFactory].
class HeapBytesWasm extends HeapWasm implements HeapBytes<int> {

  final int size;

  HeapBytesWasm._(super._wasm, this.size, super.ptr, super.free) : super._();

  @override
  Uint8List get copy => memory.sublist(ptr, ptr+size);

  @override
  Uint8List copyNBytes(int n) => memory.sublist(ptr, ptr+n);

  @override
  load(Uint8List data) => memory.setAll(ptr, data);

}

class HeapIntWasm extends HeapWasm implements HeapInt<int> {

  HeapIntWasm._(super._wasm, super.ptr, super.free) : super._();

  ByteData get _view => ByteData.view(memory.buffer);

  @override
  set value(int i) => _view.setUint32(ptr, i, Endian.little);

  @override
  int get value => _view.getUint32(ptr, Endian.little);

  /// If this represents an integer array, get the integer at the [i] position.
  HeapIntWasm operator[](int i) => HeapIntWasm._(_wasm, ptr+_intBytes*i, null);

}

class HeapPointerArrayWasm
extends HeapIntWasm
implements HeapPointerArray<int, int> {

  // Also store the objects in dart to handle the lifetimes
  final List<HeapWasm> _objs;

  HeapPointerArrayWasm._(
    super._wasm, super.ptr, super.free, this._objs,
  ) : super._() {
    // Set pointers of array
    for (int i = 0; i < _objs.length; i++) {
      this[i].value = _objs[i].ptr;
    }
  }

  @override
  List<int> get list => List.generate(_objs.length, (i) => this[i].value);

}

/// Provides [HeapWasm] objects with the same memory and malloc and free
/// functions.
class HeapFactory {

  final Wasm _wasm;
  final MallocFunction _malloc;
  final FreeFunction _free;

  HeapFactory(this._wasm, this._malloc, this._free);

  /// Allocate a byte array of [size].
  HeapBytesWasm bytes(int size)
    => HeapBytesWasm._(_wasm, size, _malloc(size), _free);

  /// Allocate data for a miscellaneous object with [size] bytes.
  /// If [copyFrom] is specified, data shall be copied from this pointer.
  HeapWasm alloc(int size, { int? copyFrom }) {
    final heap = HeapWasm._(_wasm, _malloc(size), _free);
    if (copyFrom != null) {
      heap.memory.setRange(heap.ptr, heap.ptr + size, heap.memory, copyFrom);
    }
    return heap;
  }

  /// Allocates an integer on the heap.
  HeapIntWasm integer() => HeapIntWasm._(_wasm, _malloc(_intBytes), _free);

  /// Creates an array of pointers to the [objs].
  HeapPointerArrayWasm assignPointerArray(List<HeapWasm> objs)
    => HeapPointerArrayWasm._(
      _wasm,
      _malloc(objs.length*_intBytes),
      _free,
      objs,
    );

  /// Creates an array with [length] of pointers to objects allocated with
  /// [objSize].
  HeapPointerArrayWasm allocPointerArray(int length, int objSize)
    => assignPointerArray(
      List.generate(length, (_) => HeapWasm._(_wasm, _malloc(objSize), _free)),
    );

}
