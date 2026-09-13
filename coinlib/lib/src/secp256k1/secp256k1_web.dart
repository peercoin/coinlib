import 'package:coinlib/src/secp256k1/heap.dart';
import 'package:coinlib/src/crypto/random.dart';
import 'package:coinlib/src/secp256k1/wasm.dart';
import 'heap_wasm.dart';
import "secp256k1_base.dart";
import 'secp256k1.wasm.g.dart';

typedef OpaqueMuSigCache = OpaqueGeneric<int>;
typedef OpaqueMuSigSecretNonce = OpaqueGeneric<int>;
typedef OpaqueMuSigPublicNonce = OpaqueGeneric<int>;
typedef OpaqueMuSigSession = OpaqueGeneric<int>;
typedef OpaqueMuSigPartialSig = OpaqueGeneric<int>;

typedef WebInt2 = int Function(int, int);
typedef WebInt3 = int Function(int, int, int);
typedef WebInt4 = int Function(int, int, int, int);
typedef WebInt5 = int Function(int, int, int, int, int);
typedef WebInt6 = int Function(int, int, int, int, int, int);
typedef WebInt9 = int Function(int, int, int, int, int, int, int, int, int);

/// Loads and wraps WASM code to be run via the browser JS APIs
class Secp256k1 extends Secp256k1Base<int, int, int, int, int, int, int, int,
    int, int, int, int, int, int, int, int, int, int, int> {
  static const _muSigCacheSize = 197;
  static const _muSigNonceSize = 132;
  static const _muSigSessionSize = 133;
  static const _muSigPartialSigSize = 36;

  late final HeapFactory _heapFactory;

  @override
  late WebInt2 extEcSeckeyVerify;
  @override
  late WebInt3 extEcPubkeyCreate;
  @override
  late WebInt5 extEcPubkeySerialize;
  @override
  late WebInt4 extEcPubkeyParse;
  @override
  late WebInt3 extEcdsaSignatureSerializeCompact;
  @override
  late WebInt3 extEcdsaSignatureParseCompact;
  @override
  late WebInt3 extEcdsaSignatureNormalize;
  @override
  late WebInt4 extEcdsaSignatureSerializeDer;
  @override
  late WebInt4 extEcdsaSignatureParseDer;
  @override
  late WebInt6 extEcdsaSign;
  @override
  late WebInt4 extEcdsaVerify;
  @override
  late WebInt4 extEcdsaRecoverableSignatureSerializeCompact;
  @override
  late WebInt4 extEcdsaRecoverableSignatureParseCompact;
  @override
  late WebInt6 extEcdsaSignRecoverable;
  @override
  late WebInt4 extEcdsaRecover;
  @override
  late WebInt3 extEcSeckeyTweakAdd;
  @override
  late WebInt3 extEcPubkeyTweakAdd;
  @override
  late WebInt2 extEcSeckeyNegate;
  @override
  late WebInt3 extKeypairCreate;
  @override
  late WebInt3 extXOnlyPubkeyParse;
  @override
  late WebInt3 extXOnlyPubkeySerialize;
  @override
  late WebInt5 extSchnorrSign32;
  @override
  late WebInt5 extSchnorrVerify;
  @override
  late WebInt6 extEcdh;
  @override
  late WebInt3 extEcPubkeySort;
  @override
  late WebInt5 extMuSigPubkeyAgg;
  @override
  late WebInt4 extMuSigPubkeyXOnlyTweakAdd;
  @override
  late WebInt9 extMuSigNonceGen;
  @override
  late WebInt3 extMuSigPubNonceParse;
  @override
  late WebInt3 extMuSigPubNonceSerialize;
  @override
  late WebInt4 extMuSigNonceAgg;
  @override
  late WebInt6 extMuSigNonceProcess;
  @override
  late WebInt6 extMuSigPartialSign;
  @override
  late WebInt3 extMuSigPartialSigParse;
  @override
  late WebInt3 extMuSigPartialSigSerialize;
  @override
  late WebInt6 extMuSigPartialSigVerify;
  @override
  late WebInt5 extMuSigPartialSigAgg;
  @override
  late WebInt3 extMuSigNonceParity;
  @override
  late WebInt5 extMuSigAdapt;
  @override
  late WebInt5 extMuSigExtractAdaptor;

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
    extEcdsaSignatureSerializeCompact =
        wasm.field("secp256k1_ecdsa_signature_serialize_compact");
    extEcdsaSignatureParseCompact =
        wasm.field("secp256k1_ecdsa_signature_parse_compact");
    extEcdsaSignatureNormalize =
        wasm.field("secp256k1_ecdsa_signature_normalize");
    extEcdsaSignatureSerializeDer =
        wasm.field("secp256k1_ecdsa_signature_serialize_der");
    extEcdsaSignatureParseDer =
        wasm.field("secp256k1_ecdsa_signature_parse_der");
    extEcdsaVerify = wasm.field("secp256k1_ecdsa_verify");
    extEcdsaRecoverableSignatureSerializeCompact =
        wasm.field("secp256k1_ecdsa_recoverable_signature_serialize_compact");
    extEcdsaRecoverableSignatureParseCompact =
        wasm.field("secp256k1_ecdsa_recoverable_signature_parse_compact");
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
    extMuSigPubkeyXOnlyTweakAdd =
        wasm.field("secp256k1_musig_pubkey_xonly_tweak_add");
    extMuSigNonceGen = wasm.field("secp256k1_musig_nonce_gen");
    extMuSigPubNonceParse = wasm.field("secp256k1_musig_pubnonce_parse");
    extMuSigPubNonceSerialize =
        wasm.field("secp256k1_musig_pubnonce_serialize");
    extMuSigNonceAgg = wasm.field("secp256k1_musig_nonce_agg");
    extMuSigNonceProcess = wasm.field("secp256k1_musig_nonce_process");
    extMuSigPartialSign = wasm.field("secp256k1_musig_partial_sign");
    extMuSigPartialSigParse = wasm.field("secp256k1_musig_partial_sig_parse");
    extMuSigPartialSigSerialize =
        wasm.field("secp256k1_musig_partial_sig_serialize");
    extMuSigPartialSigVerify = wasm.field("secp256k1_musig_partial_sig_verify");
    extMuSigPartialSigAgg = wasm.field("secp256k1_musig_partial_sig_agg");
    extMuSigNonceParity = wasm.field("secp256k1_musig_nonce_parity");
    extMuSigAdapt = wasm.field("secp256k1_musig_adapt");
    extMuSigExtractAdaptor = wasm.field("secp256k1_musig_extract_adaptor");

    // Local functions for loading purposes
    final int Function(int) contextCreate =
        wasm.field("secp256k1_context_create");
    final int Function(int, int) contextRandomize =
        wasm.field("secp256k1_context_randomize");

    final MallocFunction malloc = wasm.field("malloc");
    final FreeFunction free = wasm.field("free");
    _heapFactory = HeapFactory(() => wasm.memory, malloc, free);

    // Heap arrays
    key32Array = _heapFactory.bytes(Secp256k1Base.privkeySize);
    scalarArray = _heapFactory.bytes(Secp256k1Base.privkeySize);
    hashArray = _heapFactory.bytes(Secp256k1Base.hashSize);
    entropyArray = _heapFactory.bytes(Secp256k1Base.entropySize);
    serializedPubKeyArray = _heapFactory.bytes(
      Secp256k1Base.uncompressedPubkeySize,
    );
    preSigArray = _heapFactory.bytes(Secp256k1Base.sigSize);
    serializedSigArray = _heapFactory.bytes(Secp256k1Base.sigSize);
    derSigArray = _heapFactory.bytes(Secp256k1Base.derSigSize);
    muSigPubNonceArray = _heapFactory.bytes(Secp256k1Base.muSigPubNonceSize);

    // Heap objects
    pubKey = _heapFactory.alloc(Secp256k1Base.pubkeySize);
    sizeT = _heapFactory.integer();
    integer = _heapFactory.integer();
    sig = _heapFactory.alloc(Secp256k1Base.sigSize);
    recSig = _heapFactory.alloc(Secp256k1Base.recSigSize);
    keyPair = _heapFactory.alloc(Secp256k1Base.keyPairSize);
    xPubKey = _heapFactory.alloc(Secp256k1Base.xonlySize);
    muSigAggNonce = _heapFactory.alloc(_muSigNonceSize);
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
  HeapPointerArray<int, int> allocPubKeyArray(int size) =>
      _heapFactory.allocPointerArray(size, Secp256k1Base.pubkeySize);

  @override
  HeapPointerArray<int, int> setMuSigPubNonceArray(
    Iterable<Heap<int>> objs,
  ) =>
      _heapFactory.assignPointerArray(objs.toList().cast());

  @override
  // Identical in implementation to setMuSigPubNonceArray
  HeapPointerArray<int, int> setMuSigPartialSigArray(
    Iterable<Heap<int>> objs,
  ) =>
      setMuSigPubNonceArray(objs);

  @override
  Heap<int> allocMuSigCache() => _heapFactory.alloc(_muSigCacheSize);

  @override
  Heap<int> copyMuSigCache(int copyFrom) => _heapFactory.alloc(
        _muSigCacheSize,
        copyFrom: copyFrom,
      );

  @override
  Heap<int> allocMuSigSecNonce() => _heapFactory.alloc(_muSigNonceSize);

  @override
  Heap<int> allocMuSigPubNonce() => _heapFactory.alloc(_muSigNonceSize);

  @override
  Heap<int> allocMuSigSession() => _heapFactory.alloc(_muSigSessionSize);

  @override
  Heap<int> allocMuSigPartialSig() => _heapFactory.alloc(_muSigPartialSigSize);
}
