import "dart:typed_data";
import 'package:coinlib/src/crypto/random.dart';
import 'heap_array_wasm.dart';
import "secp256k1_base.dart";
import 'package:wasm_interop/wasm_interop.dart';
import 'package:coinlib/src/generated/secp256k1.wasm.g.dart';

typedef ContextCreateFunction = int Function(int);
typedef ContextRandomizeFunction = int Function(int, int);
typedef EcSeckeyVerifyFunction = int Function(int, int);
typedef EcPublickeyCreateFunction = int Function(int, int, int);
typedef EcPublickeySerializeFunction = int Function(int, int, int, int, int);
typedef EcdsaSignFunction = int Function(int, int, int, int, int, int);
typedef EcdsaSignatureSerializeCompactFunction = int Function(int, int, int);

/// Loads and wraps WASM code to be run via the browser JS APIs
class Secp256k1 extends Secp256k1Base<int, int, int, int,int, int>{

  static final int _ptrBytes = 4; // 32-bit architecture
  late Uint8List _memory;

  @override
  Future<void> internalLoad() async {

    // Load Instance

    final inst = await Instance.fromBytesAsync(
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
    _memory = inst.memories["memory"]!.buffer.asUint8List();

    // Set functions
    extEcSeckeyVerify = inst.functions["secp256k1_ec_seckey_verify"]!
      as EcSeckeyVerifyFunction;
    extEcSeckeyVerify = inst.functions["secp256k1_ec_seckey_verify"]!
      as EcSeckeyVerifyFunction;
    extEcPubkeyCreate = inst.functions["secp256k1_ec_pubkey_create"]!
      as EcPublickeyCreateFunction;
    extEcPubkeySerialize = inst.functions["secp256k1_ec_pubkey_serialize"]!
      as EcPublickeySerializeFunction;
    extEcdsaSign = inst.functions["secp256k1_ecdsa_sign"]!
      as EcdsaSignFunction;
    extEcdsaSignatureSerializeCompact =
      inst.functions["secp256k1_ecdsa_signature_serialize_compact"]!
      as EcdsaSignatureSerializeCompactFunction;

    // Local functions for loading purposes
    final contextCreate = inst.functions["secp256k1_context_create"]!
      as ContextCreateFunction;
    final contextRandomize = inst.functions["secp256k1_context_randomize"]!
      as ContextRandomizeFunction;

    final malloc = inst.functions["malloc"]! as MallocFunction;
    final free = inst.functions["free"]! as FreeFunction;

    // Heap arrays
    final arrayFactory = HeapArrayWasmFactory(_memory, malloc, free);
    privKeyArray = arrayFactory.create(Secp256k1Base.privkeySize);
    hashArray = arrayFactory.create(Secp256k1Base.hashSize);
    serializedPubKeyArray = arrayFactory.create(
      Secp256k1Base.uncompressedPubkeySize,
    );
    serializedSigArray = arrayFactory.create(Secp256k1Base.sigSize);

    // Other pointers
    sigPtr = malloc(Secp256k1Base.sigSize);
    pubKeyPtr = malloc(Secp256k1Base.pubkeySize);
    sizeTPtr = malloc(_ptrBytes);
    nullPtr = 0;

    // Create universal context and randomise it as recommended
    // Generate 32 random bytes in the module memory
    ctxPtr = contextCreate(Secp256k1Base.contextNone);

    final randBytePtr = malloc(32);
    final randomBytes = generateRandomBytes(32);
    _memory.setAll(randBytePtr, randomBytes);

    if (contextRandomize(ctxPtr, randBytePtr) != 1) {
      throw Secp256k1Exception("Secp256k1 context couldn't be randomised");
    }

    free(randBytePtr);

  }

  @override
  set sizeT(int size)
    => ByteData.view(_memory.buffer).setUint32(sizeTPtr, size, Endian.little);

}
