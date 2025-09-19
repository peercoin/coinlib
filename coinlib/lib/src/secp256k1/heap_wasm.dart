import 'dart:typed_data';
import 'heap.dart';

typedef MallocFunction = int Function(int);
typedef FreeFunction = int Function(int);

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
  @override
  final Uint8List list;

  HeapBytesWasm._(this.size, super.ptr, this.list, super.free) : super._();

  @override
  load(Uint8List data) => list.setAll(0, data);

}

class HeapIntWasm extends HeapWasm implements HeapInt<int> {

  final ByteData _data;

  HeapIntWasm._(this._data, super.ptr, super.free) : super._();
  HeapIntWasm._withMemory(Uint8List memory, super.ptr, super.free)
    : _data = ByteData.view(memory.buffer), super._();

  @override
  set value(int i) => _data.setUint32(ptr, i, Endian.little);

  @override
  int get value => _data.getUint32(ptr, Endian.little);

  /// If this represents an integer array, get the integer at the [i] position.
  HeapIntWasm operator[](int i)
    => HeapIntWasm._(_data, ptr+_intBytes*i, (_) => 0);

}

class HeapPointerArrayWasm
extends HeapIntWasm
implements HeapPointerArray<int, int> {

  // Also store the objects in dart to handle the lifetimes
  final List<HeapWasm> _objs;

  HeapPointerArrayWasm._(
    super.memory, super.ptr, super.free, this._objs,
  ) : super._withMemory() {
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

  final Uint8List _memory;
  final MallocFunction _malloc;
  final FreeFunction _free;

  HeapFactory(this._memory, this._malloc, this._free);

  /// Allocate a byte array of [size].
  HeapBytesWasm bytes(int size) {
    final ptr = _malloc(size);
    final list = Uint8List.view(_memory.buffer, ptr, size);
    return HeapBytesWasm._(size, ptr, list, _free);
  }

  /// Allocate data for a miscellaneous object with [size] bytes.
  HeapWasm alloc(int size) => HeapWasm._(_malloc(size), _free);

  /// Allocates an integer on the heap.
  HeapIntWasm integer() => HeapIntWasm._withMemory(
    _memory, _malloc(_intBytes), _free,
  );

  /// Creates an array with [length] of pointers of objects allocated with
  /// [objSize].
  HeapPointerArrayWasm pointerArray(int length, int objSize)
    => HeapPointerArrayWasm._(
      _memory,
      _malloc(length*_intBytes),
      _free,
      List.generate(length, (_) => HeapWasm._(_malloc(objSize), _free)),
    );

}
