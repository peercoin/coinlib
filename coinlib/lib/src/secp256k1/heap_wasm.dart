import 'dart:typed_data';
import 'heap.dart';

typedef MallocFunction = int Function(int);
typedef FreeFunction = void Function(int);
typedef MemoryGetter = Uint8List Function();

// Using wasm32, so integers are 32 bits
final int _intBytes = 4;

/// Represents objects on the heap. These can be created using [HeapFactory].
class HeapWasm implements Heap<int> {

  static final Finalizer<void Function()> _finalizer = Finalizer(
    (free) => free(),
  );

  @override
  final int ptr;

  HeapWasm._(this.ptr, FreeFunction free) {
    _finalizer.attach(this, () => free(ptr));
  }

}

/// Encapsulates a WASM heap-allocated unsigned char array, accessible as a
/// Uint8List. Must be created through [HeapFactory].
class HeapBytesWasm extends HeapWasm implements HeapBytes<int> {

  final int size;
  final MemoryGetter _memory;

  HeapBytesWasm._(this.size, super.ptr, this._memory, super.free) : super._();

  Uint8List get _view => Uint8List.view(_memory().buffer, ptr, size);

  @override
  Uint8List get copy => _view.sublist(0);

  @override
  Uint8List copyNBytes(int n) => _view.sublist(0, n);

  @override
  load(Uint8List data) => _view.setAll(0, data);

}

class HeapIntWasm extends HeapWasm implements HeapInt<int> {

  final MemoryGetter _memory;

  HeapIntWasm._(this._memory, super.ptr, super.free) : super._();

  ByteData get _data => ByteData.view(_memory().buffer);

  @override
  set value(int i) => _data.setUint32(ptr, i, Endian.little);

  @override
  int get value => _data.getUint32(ptr, Endian.little);

  /// If this represents an integer array, get the integer at the [i] position.
  HeapIntWasm operator[](int i)
    => HeapIntWasm._(_memory, ptr+_intBytes*i, (_) {});

}

class HeapPointerArrayWasm
extends HeapIntWasm
implements HeapPointerArray<int, int> {

  // Also store the objects in dart to handle the lifetimes
  final List<HeapWasm> _objs;

  HeapPointerArrayWasm._(
    super._memory,
    super.ptr,
    super.free,
    this._objs,
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

  final MemoryGetter _memory;
  final MallocFunction _malloc;
  final FreeFunction _free;

  HeapFactory(this._memory, this._malloc, this._free);

  /// Allocate a byte array of [size].
  HeapBytesWasm bytes(int size) {
    final ptr = _malloc(size);
    return HeapBytesWasm._(size, ptr, _memory, _free);
  }

  /// Allocate data for a miscellaneous object with [size] bytes.
  /// If [copyFrom] is specified, data shall be copied from this pointer.
  HeapWasm alloc(int size, { int? copyFrom }) {
    final heap = HeapWasm._(_malloc(size), _free);
    if (copyFrom != null) {
      final memory = _memory();
      memory.setRange(heap.ptr, heap.ptr + size, memory, copyFrom);
    }
    return heap;
  }

  /// Allocates an integer on the heap.
  HeapIntWasm integer() => HeapIntWasm._(_memory, _malloc(_intBytes), _free);

  /// Creates an array of pointers to the [objs].
  HeapPointerArrayWasm assignPointerArray(List<HeapWasm> objs)
    => HeapPointerArrayWasm._(
      _memory,
      _malloc(objs.length*_intBytes),
      _free,
      objs,
    );

  /// Creates an array with [length] of pointers to objects allocated with
  /// [objSize].
  HeapPointerArrayWasm allocPointerArray(int length, int objSize)
    => assignPointerArray(
      List.generate(length, (_) => HeapWasm._(_malloc(objSize), _free)),
    );

}
