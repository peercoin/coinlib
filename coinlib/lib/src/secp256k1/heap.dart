import 'dart:typed_data';

/// Represents a pointer to an object (or array of objects) allocated on the
/// heap. [Ptr] is a type that represents a pointer to the given object.
abstract interface class Heap<Ptr> {
  Ptr get ptr;
}

/// Represents a unsigned char array and can read/write a Uint8List
/// [Ptr] is the type that represents an `unsigned char *`.
abstract interface class HeapBytes<Ptr> extends Heap<Ptr> {
  Uint8List get list;
  void load(Uint8List data);
}

/// Represents an object on the heap that can be set as an int.
abstract interface class HeapInt<Ptr> extends Heap<Ptr> {
  set value(int size);
  int get value;
}

/// Represents a heap array containing pointers to other objects that are also
/// allocated as part of this object. [list] obtains a [List] to these allocated
/// objects.
abstract interface class HeapPointerArray<PtrPtr, Ptr> extends Heap<PtrPtr> {
  List<Ptr> get list;
}
