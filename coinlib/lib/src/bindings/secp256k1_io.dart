import "dart:ffi";
import "dart:io";
import "dart:typed_data";
import "package:coinlib/src/bindings/uchar_heap_array.dart";
import "package:coinlib/src/crypto/random.dart";
import 'package:ffi/ffi.dart';
import "package:coinlib/src/generated/secp256k1.ffi.g.dart";
import "package:path/path.dart";
import "secp256k1_interface.dart";

const _name = "secp256k1";

String _libraryPath() {

  final String localLib, flutterLib;
  if (Platform.isLinux || Platform.isAndroid) {
    flutterLib = localLib = "lib$_name.so";
  } else if (Platform.isMacOS || Platform.isIOS) {
    // Dylib if built in build directory, or framework if using flutter
    localLib = "lib$_name.dylib";
    flutterLib = "$_name.framework/$_name";
  } else if (Platform.isWindows) {
    // Not provided yet, so should fail to load unless added outside of library
    flutterLib = localLib = "$_name.dll";
  } else {
    throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
  }

  // Exists in build directory?
  final libBuildPath = join(Directory.current.path, "build", localLib);
  if (File(libBuildPath).existsSync()) {
    return libBuildPath;
  }

  // Load from flutter library name
  return flutterLib;

}

DynamicLibrary _openLibrary() => DynamicLibrary.open(_libraryPath());

class Secp256k1 implements Secp256k1Interface {

  final _lib = NativeSecp256k1(_openLibrary());

  // Memory
  // A finalizer could be added to free allocated memory but as this class will
  // used for a singleton object throughout the entire lifetime of the program,
  // it doesn't matter
  late Pointer<secp256k1_context> _ctxPtr;
  final _privKeyArray = UnsignedCharHeapArray(Secp256k1Interface.privkeySize);
  final Pointer<secp256k1_pubkey> _pubKeyPtr = malloc();
  final _serializedPubKeyArray = UnsignedCharHeapArray(
    Secp256k1Interface.uncompressedPubkeySize,
  );
  final Pointer<Size> _sizeTPtr = malloc();

  Secp256k1() {

    // Create context
    _ctxPtr = _lib.secp256k1_context_create(Secp256k1Interface.contextNone);

    // Randomise context with 32 bytes

    final randBytes = generateRandomBytes(32);
    final randArray = UnsignedCharHeapArray(32);
    randArray.list.setAll(0, randBytes);

    if (_lib.secp256k1_context_randomize(_ctxPtr, randArray.ptr) != 1) {
      throw Secp256k1Exception("Secp256k1 context couldn't be randomised");
    }

  }

  @override
  /// Does nothing as no asynchronous loading is required via ffi
  Future<void> load() async {}

  @override
  Uint8List privToPubKey(Uint8List privKey, bool compressed) {

    // Write private key into memory
    _privKeyArray.list.setAll(0, privKey);

    // Derive public key from private key
    if (
      _lib.secp256k1_ec_pubkey_create(
        _ctxPtr, _pubKeyPtr, _privKeyArray.ptr,
      ) != 1
    ) {
      throw Secp256k1Exception("Cannot compute public key from private key");
    }

    // Parse public key

    _sizeTPtr.value = compressed
      ? Secp256k1Interface.compressedPubkeySize
      : Secp256k1Interface.uncompressedPubkeySize;

    final flags = compressed
      ? Secp256k1Interface.compressedFlags
      : Secp256k1Interface.uncompressedFlags;

    _lib.secp256k1_ec_pubkey_serialize(
      _ctxPtr, _serializedPubKeyArray.ptr, _sizeTPtr, _pubKeyPtr, flags,
    );

    // Return copy of public key
    return _serializedPubKeyArray.list.sublist(0, _sizeTPtr.value);

  }

}
