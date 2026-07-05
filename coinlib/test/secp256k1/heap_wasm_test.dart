import 'dart:typed_data';

import 'package:coinlib/src/secp256k1/heap_wasm.dart';
import 'package:test/test.dart';

void main() {
  late Uint8List memory;
  late int heapEnd;
  late HeapFactory heap;

  int malloc(int size) {
    final ptr = heapEnd;
    heapEnd += size;

    if (heapEnd > memory.length) {
      final grown = Uint8List(heapEnd);
      grown.setAll(0, memory);
      memory = grown;
    }

    return ptr;
  }

  setUp(() {
    memory = Uint8List(4);
    heapEnd = 0;
    heap = HeapFactory(() => memory, malloc, (_) {});
  });

  test("byte arrays use current memory after growth", () {
    final bytes = heap.bytes(4);
    bytes.load(Uint8List.fromList([1, 2, 3, 4]));

    heap.bytes(4).load(Uint8List.fromList([9, 9, 9, 9]));

    bytes.load(Uint8List.fromList([5, 6, 7, 8]));

    expect(memory.sublist(0, 4), [5, 6, 7, 8]);
    expect(bytes.copy, [5, 6, 7, 8]);
  });

  test("integers use current memory after growth", () {
    final integer = heap.integer();
    integer.value = 0x01020304;

    heap.bytes(4);

    integer.value = 0x0a0b0c0d;

    expect(integer.value, 0x0a0b0c0d);
    expect(
      memory.buffer.asByteData().getUint32(integer.ptr, Endian.little),
      0x0a0b0c0d,
    );
  });

  test("copies heap data from current memory after growth", () {
    final bytes = heap.bytes(4);
    bytes.load(Uint8List.fromList([1, 2, 3, 4]));

    heap.bytes(4);
    final copy = heap.alloc(4, copyFrom: bytes.ptr);

    expect(memory.sublist(copy.ptr, copy.ptr + 4), [1, 2, 3, 4]);
  });
}
