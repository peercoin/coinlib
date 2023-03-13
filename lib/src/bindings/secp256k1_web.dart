import "dart:typed_data";
import 'package:coinlib/src/crypto/random.dart';
import "secp256k1_interface.dart";
import 'package:wasm_interop/wasm_interop.dart';
import 'package:coinlib/src/generated/secp256k1.wasm.g.dart';

typedef ContextCreateFunction = int Function(int);
typedef ContextRandomizeFunction = int Function(int, int);
typedef MallocFunction = int Function(int);
typedef FreeFunction = int Function(int);
typedef EcPublickeyCreateFunction = int Function(int, int, int);
typedef EcPublickeySerializeFunction = int Function(int, int, int, int, int);

/// Loads and wraps WASM code to be run via the browser JS APIs
class Secp256k1 implements Secp256k1Interface {

  static final int _ptrBytes = 4; // 32-bit architecture

  bool _loaded = false;
  late Instance _inst;
  late Uint8List _memory;

  // Functions
  late EcPublickeyCreateFunction _ecPubkeyCreate;
  late EcPublickeySerializeFunction _ecPubkeySerialize;

  // Memory pointers
  late int _ctxPtr;
  late int _privKeyPtr;
  late int _pubKeyPtr;
  late int _serializedPubKeyPtr; /// Always compressed 33 bytes
  late int _sizeTPtr; /// Used as pointer to size_t values

  void _requireLoad() {
    if (!_loaded) throw Secp256k1Exception("load() not called");
  }

  @override
  /// Must be called before web library is useable
  Future<void> load() async {

    if (_loaded) return;

    _inst = await Instance.fromBytesAsync(
      secp256k1WasmData,
      // Dummy WASI imports. No file descriptor support provided.
      importMap: {
        "wasi_snapshot_preview1" : {
          "fd_close": () => {},
          "fd_seek": () => {},
          "fd_write": () => {},
        },
      },
    );
    _memory = _inst.memories["memory"]!.buffer.asUint8List();

    // Member functions
    _ecPubkeyCreate = _inst.functions["secp256k1_ec_pubkey_create"]!
      as EcPublickeyCreateFunction;
    _ecPubkeySerialize = _inst.functions["secp256k1_ec_pubkey_serialize"]!
      as EcPublickeySerializeFunction;

    // Local functions for loading purposes
    final contextCreate = _inst.functions["secp256k1_context_create"]!
      as ContextCreateFunction;
    final contextRandomize = _inst.functions["secp256k1_context_randomize"]!
      as ContextRandomizeFunction;
    final malloc = _inst.functions["malloc"]! as MallocFunction;
    final free = _inst.functions["free"]! as FreeFunction;

    // Allocate memory
    _privKeyPtr = malloc(Secp256k1Interface.privkeySize);
    _pubKeyPtr = malloc(Secp256k1Interface.pubkeySize);
    _serializedPubKeyPtr = malloc(Secp256k1Interface.compressedPubkeySize);
    _sizeTPtr = malloc(_ptrBytes);

    // Create universal context and randomise it as recommended
    // Generate 32 random bytes in the module memory
    _ctxPtr = contextCreate(Secp256k1Interface.contextNone);

    final randBytePtr = malloc(32);
    final randomBytes = generateRandomBytes(32);
    _memory.setAll(randBytePtr, randomBytes);

    if (contextRandomize(_ctxPtr, randBytePtr) != 1) {
      throw Secp256k1Exception("Secp256k1 context couldn't be randomised");
    }

    free(randBytePtr);

    _loaded = true;

  }

  @override
  Uint8List privToPubKey(Uint8List privKey) {
    _requireLoad();

    // Write private key to memory
    _memory.setAll(_privKeyPtr, privKey);

    // Derive public key from private key
    if (_ecPubkeyCreate(_ctxPtr, _pubKeyPtr, _privKeyPtr) != 1) {
      throw Secp256k1Exception("Cannot compute public key from private key");
    }

    // Set length to 33 via size_t value. Should be little endian.
    ByteData.view(_memory.buffer)
      .setUint32(_sizeTPtr, Secp256k1Interface.compressedPubkeySize, Endian.little);

    // Parse and return public key
    _ecPubkeySerialize(
      _ctxPtr, _serializedPubKeyPtr, _sizeTPtr, _pubKeyPtr,
      Secp256k1Interface.compressionFlags,
    );

    return _memory.sublist(
      _serializedPubKeyPtr,
      _serializedPubKeyPtr+Secp256k1Interface.compressedPubkeySize,
    );

  }

}
