import 'package:coinlib/src/secp256k1/heap.dart';
import 'package:coinlib/src/crypto/random.dart';
import 'package:coinlib/src/secp256k1/wasm.dart';
import 'heap_wasm.dart';
import "secp256k1_base.dart";
import 'secp256k1.wasm.g.dart';

typedef MuSigCache = MuSigCacheGeneric<int>;

/// Loads and wraps WASM code to be run via the browser JS APIs
class Secp256k1 extends Secp256k1Base<
  int, int, int, int, int, int, int, int, int, int, int, int
> {

  static const _muSigCacheSize = 197;

  late final HeapFactory _heapFactory;

  @override
  Future<void> internalLoad() async {

    // Load Instance

    final wasm = await Wasm.loadWasi(secp256k1WasmData);

    // Set functions
    extEcSeckeyVerify = wasm.field("secp256k1_ec_seckey_verify");
    extEcSeckeyVerify = wasm.field("secp256k1_ec_seckey_verify");
    extEcPubkeyCreate = wasm.field("secp256k1_ec_pubkey_create");
    extEcPubkeySerialize = wasm.field("secp256k1_ec_pubkey_serialize");
    extEcPubkeyParse = wasm.field("secp256k1_ec_pubkey_parse");
    extEcdsaSign = wasm.field("secp256k1_ecdsa_sign");
    extEcdsaSignatureSerializeCompact
      = wasm.field("secp256k1_ecdsa_signature_serialize_compact");
    extEcdsaSignatureParseCompact
      = wasm.field("secp256k1_ecdsa_signature_parse_compact");
    extEcdsaSignatureNormalize
      = wasm.field("secp256k1_ecdsa_signature_normalize");
    extEcdsaSignatureSerializeDer
      = wasm.field("secp256k1_ecdsa_signature_serialize_der");
    extEcdsaSignatureParseDer
      = wasm.field("secp256k1_ecdsa_signature_parse_der");
    extEcdsaVerify = wasm.field("secp256k1_ecdsa_verify");
    extEcdsaRecoverableSignatureSerializeCompact
      = wasm.field("secp256k1_ecdsa_recoverable_signature_serialize_compact");
    extEcdsaRecoverableSignatureParseCompact
      = wasm.field("secp256k1_ecdsa_recoverable_signature_parse_compact");
    extEcdsaSignRecoverable = wasm.field("secp256k1_ecdsa_sign_recoverable");
    extEcdsaRecover = wasm.field("secp256k1_ecdsa_recover");
    extEcSeckeyTweakAdd = wasm.field("secp256k1_ec_seckey_tweak_add");
    extEcPubkeyTweakAdd = wasm.field("secp256k1_ec_pubkey_tweak_add");
    extEcSeckeyNegate = wasm.field("secp256k1_ec_seckey_negate");
    extKeypairCreate = wasm.field("secp256k1_keypair_create");
    extXOnlyPubkeyParse = wasm.field("secp256k1_xonly_pubkey_parse");
    extXOnlyPubkeySerialize = wasm.field("secp256k1_xonly_pubkey_serialize");
    extSchnorrSign32 = wasm.field("secp256k1_schnorrsig_sign32");
    extSchnorrVerify = wasm.field("secp256k1_schnorrsig_verify");
    extEcdh = wasm.field("secp256k1_ecdh");
    extEcPubkeySort = wasm.field("secp256k1_ec_pubkey_sort");
    extMuSigPubkeyAgg = wasm.field("secp256k1_musig_pubkey_agg");
    extMuSigPubkeyXOnlyTweakAdd
      = wasm.field("secp256k1_musig_pubkey_xonly_tweak_add");

    // Local functions for loading purposes
    final int Function(int) contextCreate
      = wasm.field("secp256k1_context_create");
    final int Function(int, int) contextRandomize
      = wasm.field("secp256k1_context_randomize");

    final MallocFunction malloc = wasm.field("malloc");
    final FreeFunction free = wasm.field("free");
    _heapFactory = HeapFactory(wasm.memory, malloc, free);

    // Heap arrays
    key32Array = _heapFactory.bytes(Secp256k1Base.privkeySize);
    scalarArray = _heapFactory.bytes(Secp256k1Base.privkeySize);
    hashArray = _heapFactory.bytes(Secp256k1Base.hashSize);
    entropyArray = _heapFactory.bytes(Secp256k1Base.entropySize);
    serializedPubKeyArray = _heapFactory.bytes(
      Secp256k1Base.uncompressedPubkeySize,
    );
    serializedSigArray = _heapFactory.bytes(Secp256k1Base.sigSize);
    derSigArray = _heapFactory.bytes(Secp256k1Base.derSigSize);

    // Heap objects
    pubKey = _heapFactory.alloc(Secp256k1Base.pubkeySize);
    sizeT = _heapFactory.integer();
    sig = _heapFactory.alloc(Secp256k1Base.sigSize);
    recSig = _heapFactory.alloc(Secp256k1Base.recSigSize);
    keyPair = _heapFactory.alloc(Secp256k1Base.keyPairSize);
    xPubKey = _heapFactory.alloc(Secp256k1Base.xonlySize);
    recId = _heapFactory.integer();

    nullPtr = 0;

    // Create and randomise context with 32 bytes
    ctxPtr = contextCreate(Secp256k1Base.contextNone);

    final randomBytes = generateRandomBytes(32);
    final randArray = _heapFactory.bytes(32);
    randArray.load(randomBytes);

    if (contextRandomize(ctxPtr, randArray.ptr) != 1) {
      throw Secp256k1Exception("Secp256k1 context couldn't be randomised");
    }

  }

  @override
  HeapPointerArray<int, int> allocPubKeyArray(int size)
    => _heapFactory.pointerArray(size, Secp256k1Base.pubkeySize);

  @override
  Heap<int> allocMuSigCache() => _heapFactory.alloc(_muSigCacheSize);

  @override
  Heap<int> copyMuSigCache(int copyFrom) => _heapFactory.alloc(
    _muSigCacheSize, copyFrom: copyFrom,
  );

}
