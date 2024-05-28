import "dart:typed_data";
import 'package:wasm_interop/wasm_interop.dart';
import 'package:coinlib/src/crypto/random.dart';
import 'heap_array_wasm.dart';
import "secp256k1_base.dart";
import 'secp256k1.wasm.g.dart';

typedef IntFunc1 = int Function(int);
typedef IntFunc2 = int Function(int, int);
typedef IntFunc3 = int Function(int, int, int);
typedef IntFunc4 = int Function(int, int, int, int);
typedef IntFunc5 = int Function(int, int, int, int, int);
typedef IntFunc6 = int Function(int, int, int, int, int, int);

/// Loads and wraps WASM code to be run via the browser JS APIs
class Secp256k1 extends Secp256k1Base<
  int, int, int, int, int, int, int, int, int, int
> {

  static final int _ptrBytes = 4; // 32-bit architecture
  static final int _intBytes = 8; // Allocate 8 bytes to be on the safe side
  late Uint8List _memory;

  @override
  Future<void> internalLoad() async {

    // Load Instance

    final inst = await Instance.fromBytesAsync(
      secp256k1WasmData,
      // Dummy WASI imports. No file descriptor support provided.
      importMap: {
        "wasi_snapshot_preview1" : {
          "fd_close": () => Object(),
          "fd_seek": () => Object(),
          "fd_write": () => Object(),
        },
      },
    );
    _memory = inst.memories["memory"]!.buffer.asUint8List();

    // Set functions
    extEcSeckeyVerify = inst.functions["secp256k1_ec_seckey_verify"]
      as IntFunc2;
    extEcSeckeyVerify = inst.functions["secp256k1_ec_seckey_verify"]
      as IntFunc2;
    extEcPubkeyCreate = inst.functions["secp256k1_ec_pubkey_create"]
      as IntFunc3;
    extEcPubkeySerialize = inst.functions["secp256k1_ec_pubkey_serialize"]
      as IntFunc5;
    extEcPubkeyParse = inst.functions["secp256k1_ec_pubkey_parse"]
      as IntFunc4;
    extEcdsaSign = inst.functions["secp256k1_ecdsa_sign"]
      as IntFunc6;
    extEcdsaSignatureSerializeCompact
      = inst.functions["secp256k1_ecdsa_signature_serialize_compact"]
      as IntFunc3;
    extEcdsaSignatureParseCompact
      = inst.functions["secp256k1_ecdsa_signature_parse_compact"]
      as IntFunc3;
    extEcdsaSignatureNormalize
      = inst.functions["secp256k1_ecdsa_signature_normalize"]
      as IntFunc3;
    extEcdsaSignatureSerializeDer
      = inst.functions["secp256k1_ecdsa_signature_serialize_der"]
      as IntFunc4;
    extEcdsaSignatureParseDer
      = inst.functions["secp256k1_ecdsa_signature_parse_der"]
      as IntFunc4;
    extEcdsaVerify = inst.functions["secp256k1_ecdsa_verify"]
      as IntFunc4;
    extEcdsaRecoverableSignatureSerializeCompact
      = inst.functions["secp256k1_ecdsa_recoverable_signature_serialize_compact"]
      as IntFunc4;
    extEcdsaRecoverableSignatureParseCompact
      = inst.functions["secp256k1_ecdsa_recoverable_signature_parse_compact"]
      as IntFunc4;
    extEcdsaSignRecoverable
      = inst.functions["secp256k1_ecdsa_sign_recoverable"]
      as IntFunc6;
    extEcdsaRecover = inst.functions["secp256k1_ecdsa_recover"] as IntFunc4;
    extEcSeckeyTweakAdd
      = inst.functions["secp256k1_ec_seckey_tweak_add"]
      as IntFunc3;
    extEcPubkeyTweakAdd
      = inst.functions["secp256k1_ec_pubkey_tweak_add"]
      as IntFunc3;
    extEcSeckeyNegate
      = inst.functions["secp256k1_ec_seckey_negate"]
      as IntFunc2;
    extKeypairCreate = inst.functions["secp256k1_keypair_create"] as IntFunc3;
    extXOnlyPubkeyParse
      = inst.functions["secp256k1_xonly_pubkey_parse"]
      as IntFunc3;
    extSchnorrSign32
      = inst.functions["secp256k1_schnorrsig_sign32"]
      as IntFunc5;
    extSchnorrVerify
      = inst.functions["secp256k1_schnorrsig_verify"]
      as IntFunc5;
    extEcdh = inst.functions["secp256k1_ecdh"] as IntFunc6;

    // Local functions for loading purposes
    final contextCreate = inst.functions["secp256k1_context_create"]
      as IntFunc1;
    final contextRandomize = inst.functions["secp256k1_context_randomize"]
      as IntFunc2;

    final malloc = inst.functions["malloc"]! as MallocFunction;
    final free = inst.functions["free"]! as FreeFunction;

    // Heap arrays
    final arrayFactory = HeapArrayWasmFactory(_memory, malloc, free);
    key32Array = arrayFactory.create(Secp256k1Base.privkeySize);
    scalarArray = arrayFactory.create(Secp256k1Base.privkeySize);
    hashArray = arrayFactory.create(Secp256k1Base.hashSize);
    entropyArray = arrayFactory.create(Secp256k1Base.entropySize);
    serializedPubKeyArray = arrayFactory.create(
      Secp256k1Base.uncompressedPubkeySize,
    );
    serializedSigArray = arrayFactory.create(Secp256k1Base.sigSize);
    derSigArray = arrayFactory.create(Secp256k1Base.derSigSize);

    // Other pointers
    pubKeyPtr = malloc(Secp256k1Base.pubkeySize);
    sizeTPtr = malloc(_ptrBytes);
    sigPtr = malloc(Secp256k1Base.sigSize);
    recSigPtr = malloc(Secp256k1Base.recSigSize);
    keyPairPtr = malloc(Secp256k1Base.keyPairSize);
    xPubKeyPtr = malloc(Secp256k1Base.xonlySize);
    recIdPtr = malloc(_intBytes);
    nullPtr = 0;

    // Create and randomise context with 32 bytes
    ctxPtr = contextCreate(Secp256k1Base.contextNone);

    final randomBytes = generateRandomBytes(32);
    final randArray = arrayFactory.create(32);
    randArray.load(randomBytes);

    if (contextRandomize(ctxPtr, randArray.ptr) != 1) {
      throw Secp256k1Exception("Secp256k1 context couldn't be randomised");
    }

  }

  @override
  set sizeT(int size)
    => ByteData.view(_memory.buffer).setUint32(sizeTPtr, size, Endian.little);

  @override
  int get sizeT
    => ByteData.view(_memory.buffer).getUint32(sizeTPtr, Endian.little);

  @override
  // Given the little-endian architecture, it is safe to take the first byte as
  // the desired recid.
  int get internalRecId => _memory.buffer.asUint8List()[recIdPtr];

}
