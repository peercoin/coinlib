import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'heap.dart';

class HeapFfi<T extends SizedNativeType> implements Heap<Pointer<T>> {

  static final Finalizer<Pointer> _finalizer = Finalizer(
    (ptr) => malloc.free(ptr),
  );

  @override
  final Pointer<T> ptr;

  HeapFfi(this.ptr) {
    _finalizer.attach(this, ptr);
  }

}

class HeapBytesFfi
extends HeapFfi<UnsignedChar>
implements HeapBytes<Pointer<UnsignedChar>> {

  final int size;

  HeapBytesFfi(this.size) : super(malloc.allocate(size));

  Uint8List get _view => ptr.cast<Uint8>().asTypedList(size);

  @override
  Uint8List get copy => _view.sublist(0);

  @override
  Uint8List copyNBytes(int n) => _view.sublist(0, n);

  @override
  load(Uint8List data) => _view.setAll(0, data);

}

// I couldn't find a way to abstract the implementation of HeapInt that wouldn't
// lead to errors during Dart compilation, so each seperate integer type needs
// duplicated code.

class HeapIntFfi extends HeapFfi<Int> implements HeapInt<Pointer<Int>> {

  HeapIntFfi() : super(malloc());

  @override
  set value(int i) => ptr.value = i;

  @override
  int get value => ptr.value;

}

class HeapSizeFfi extends HeapFfi<Size> implements HeapInt<Pointer<Size>> {

  HeapSizeFfi() : super(malloc());

  @override
  set value(int i) => ptr.value = i;

  @override
  int get value => ptr.value;

}

class HeapPointerArrayFfi<T extends SizedNativeType>
extends HeapFfi<Pointer<T>>
implements HeapPointerArray<Pointer<Pointer<T>>, Pointer<T>> {

  // Keep objects referenced by this object so they are not freed whilst this
  // object is alive.
  final List<HeapFfi<T>> _objs;

  HeapPointerArrayFfi.assign(
    super.ptr,
    Iterable<HeapFfi<T>> objs,
  ) : _objs = objs.toList() {
    for (int i = 0; i < objs.length; i++) {
      ptr[i] = _objs[i].ptr;
    }
  }

  HeapPointerArrayFfi.alloc(
    Pointer<Pointer<T>> ptr,
    int length,
    Pointer<T> Function() alloc,
  ) : this.assign(
    ptr,
    List.generate(length, (_) => HeapFfi(alloc())),
  );

  @override
  List<Pointer<T>> get list => List.generate(_objs.length, (i) => ptr[i]);

}
