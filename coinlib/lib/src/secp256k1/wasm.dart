import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

extension type Memory._(JSObject _) implements JSObject {
  external JSArrayBuffer get buffer;
}

extension type Exports._(JSObject _) implements JSObject {
  external Memory memory;
}

extension type Instance._(JSObject _) implements JSObject {
  external Exports exports;
}

extension type ResultObject._(JSObject _) implements JSObject {
  external Instance instance;
}

extension type WebAssembly._(JSObject _) implements JSObject {
  external static JSPromise<ResultObject> instantiate(
    JSUint8Array buffer,
    JSObject imports,
  );
}

/// Abstraction for loading WASI WASM modules through Javascript
class Wasm {

  final Exports _exports;
  Wasm._(this._exports);

  static final JSFunction _nop = (() {}).toJS;

  static Future<Wasm> loadWasi(Uint8List bytes) async {

    final module = await WebAssembly.instantiate(
      bytes.toJS,
      // Dummy WASI imports. No file descriptor support provided.
      JSObject()
      ..setProperty(
        "wasi_snapshot_preview1".toJS,
        JSObject()
        ..setProperty("fd_close".toJS, _nop)
        ..setProperty("fd_seek".toJS, _nop)
        ..setProperty("fd_write".toJS, _nop),
      ),
    ).toDart;

    return Wasm._(module.instance.exports);

  }

  Uint8List get memory => _exports.memory.buffer.toDart.asUint8List();
  T field<T>(String name) => _exports.getProperty(name.toJS).dartify() as T;

}
