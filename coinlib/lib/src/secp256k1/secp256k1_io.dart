import "dart:ffi";
import "dart:io";
import "package:coinlib/src/crypto/random.dart";
import "package:coinlib/src/secp256k1/heap.dart";
import 'package:ffi/ffi.dart';
import "heap_ffi.dart";
import "secp256k1.ffi.g.dart";
import "package:path/path.dart";
import "secp256k1_base.dart";

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

typedef PubKeyPtr = Pointer<secp256k1_pubkey>;
typedef MuSigAggCachePtr = Pointer<secp256k1_musig_keyagg_cache>;
typedef MuSigSecNoncePtr = Pointer<secp256k1_musig_secnonce>;
typedef MuSigPublicNoncePtr = Pointer<secp256k1_musig_pubnonce>;
typedef MuSigSessionPtr = Pointer<secp256k1_musig_session>;
typedef MuSigPartialSigPtr = Pointer<secp256k1_musig_partial_sig>;

typedef OpaqueMuSigCache = OpaqueGeneric<MuSigAggCachePtr>;
typedef OpaqueMuSigSecretNonce = OpaqueGeneric<MuSigSecNoncePtr>;
typedef OpaqueMuSigPublicNonce = OpaqueGeneric<MuSigPublicNoncePtr>;
typedef OpaqueMuSigSession = OpaqueGeneric<MuSigSessionPtr>;
typedef OpaqueMuSigPartialSig = OpaqueGeneric<MuSigPartialSigPtr>;

/// Specialises Secp256k1Base to use the FFI
class Secp256k1 extends Secp256k1Base<
  Pointer<secp256k1_context>,
  Pointer<UnsignedChar>,
  PubKeyPtr,
  Pointer<Size>,
  Pointer<secp256k1_ecdsa_signature>,
  Pointer<secp256k1_ecdsa_recoverable_signature>,
  Pointer<secp256k1_keypair>,
  Pointer<secp256k1_xonly_pubkey>,
  Pointer<Int>,
  MuSigAggCachePtr,
  Pointer<PubKeyPtr>,
  MuSigSecNoncePtr,
  MuSigPublicNoncePtr,
  Pointer<secp256k1_musig_aggnonce>,
  Pointer<MuSigPublicNoncePtr>,
  MuSigSessionPtr,
  MuSigPartialSigPtr,
  Pointer<Never>
> {

  final _lib = NativeSecp256k1(_openLibrary());

  Secp256k1() {

    // Set functions
    extEcSeckeyVerify = _lib.secp256k1_ec_seckey_verify;
    extEcPubkeyCreate = _lib.secp256k1_ec_pubkey_create;
    extEcPubkeySerialize = _lib.secp256k1_ec_pubkey_serialize;
    extEcPubkeyParse = _lib.secp256k1_ec_pubkey_parse;
    extEcdsaSign = _lib.secp256k1_ecdsa_sign;
    extEcdsaSignatureSerializeCompact
      = _lib.secp256k1_ecdsa_signature_serialize_compact;
    extEcdsaSignatureParseCompact
      = _lib.secp256k1_ecdsa_signature_parse_compact;
    extEcdsaSignatureNormalize = _lib.secp256k1_ecdsa_signature_normalize;
    extEcdsaSignatureSerializeDer =
      _lib.secp256k1_ecdsa_signature_serialize_der;
    extEcdsaSignatureParseDer = _lib.secp256k1_ecdsa_signature_parse_der;
    extEcdsaVerify = _lib.secp256k1_ecdsa_verify;
    extEcdsaRecoverableSignatureSerializeCompact
      = _lib.secp256k1_ecdsa_recoverable_signature_serialize_compact;
    extEcdsaRecoverableSignatureParseCompact
      = _lib.secp256k1_ecdsa_recoverable_signature_parse_compact;
    extEcdsaSignRecoverable = _lib.secp256k1_ecdsa_sign_recoverable;
    extEcdsaRecover = _lib.secp256k1_ecdsa_recover;
    extEcSeckeyTweakAdd = _lib.secp256k1_ec_seckey_tweak_add;
    extEcPubkeyTweakAdd = _lib.secp256k1_ec_pubkey_tweak_add;
    extEcSeckeyNegate = _lib.secp256k1_ec_seckey_negate;
    extKeypairCreate = _lib.secp256k1_keypair_create;
    extXOnlyPubkeyParse = _lib.secp256k1_xonly_pubkey_parse;
    extXOnlyPubkeySerialize = _lib.secp256k1_xonly_pubkey_serialize;
    extSchnorrSign32 = _lib.secp256k1_schnorrsig_sign32;
    extSchnorrVerify = _lib.secp256k1_schnorrsig_verify;
    extEcdh = _lib.secp256k1_ecdh;
    extEcPubkeySort = _lib.secp256k1_ec_pubkey_sort;
    extMuSigPubkeyAgg = _lib.secp256k1_musig_pubkey_agg;
    extMuSigPubkeyXOnlyTweakAdd = _lib.secp256k1_musig_pubkey_xonly_tweak_add;
    extMuSigNonceGen = _lib.secp256k1_musig_nonce_gen;
    extMuSigPubNonceParse = _lib.secp256k1_musig_pubnonce_parse;
    extMuSigPubNonceSerialize = _lib.secp256k1_musig_pubnonce_serialize;
    extMuSigNonceAgg = _lib.secp256k1_musig_nonce_agg;
    extMuSigNonceProcess = _lib.secp256k1_musig_nonce_process;
    extMuSigPartialSign = _lib.secp256k1_musig_partial_sign;
    extMuSigPartialSigParse = _lib.secp256k1_musig_partial_sig_parse;
    extMuSigPartialSigSerialize = _lib.secp256k1_musig_partial_sig_serialize;
    extMuSigPartialSigVerify = _lib.secp256k1_musig_partial_sig_verify;

    // Set heap arrays
    key32Array = HeapBytesFfi(Secp256k1Base.privkeySize);
    scalarArray = HeapBytesFfi(Secp256k1Base.privkeySize);
    serializedPubKeyArray = HeapBytesFfi(Secp256k1Base.uncompressedPubkeySize);
    hashArray = HeapBytesFfi(Secp256k1Base.hashSize);
    entropyArray = HeapBytesFfi(Secp256k1Base.entropySize);
    serializedSigArray = HeapBytesFfi(Secp256k1Base.sigSize);
    derSigArray = HeapBytesFfi(Secp256k1Base.derSigSize);
    muSigPubNonceArray = HeapBytesFfi(Secp256k1Base.muSigPubNonceSize);

    // Set other heap data
    sizeT = HeapSizeFfi();
    pubKey = HeapFfi(malloc());
    sig = HeapFfi(malloc());
    recSig = HeapFfi(malloc());
    keyPair = HeapFfi(malloc());
    xPubKey = HeapFfi(malloc());
    muSigAggNonce = HeapFfi(malloc());
    recId = HeapIntFfi();

    nullPtr = nullptr;

    // Create context
    ctxPtr = _lib.secp256k1_context_create(Secp256k1Base.contextNone);

    // Randomise context with 32 bytes

    final randBytes = generateRandomBytes(32);
    final randArray = HeapBytesFfi(32);
    randArray.load(randBytes);

    if (_lib.secp256k1_context_randomize(ctxPtr, randArray.ptr) != 1) {
      throw Secp256k1Exception("Secp256k1 context couldn't be randomised");
    }

  }

  @override
  HeapPointerArray<Pointer<PubKeyPtr>, PubKeyPtr> allocPubKeyArray(int size)
    => HeapPointerArrayFfi.alloc(malloc(size), size, () => malloc());

  @override
  HeapPointerArray<
    Pointer<MuSigPublicNoncePtr>, MuSigPublicNoncePtr
  > setMuSigPubNonceArray(Iterable<Heap<MuSigPublicNoncePtr>> objs)
    => HeapPointerArrayFfi.assign(malloc(objs.length), objs.cast());

  @override
  Heap<MuSigAggCachePtr> allocMuSigCache() => HeapFfi(malloc());

  @override
  Heap<MuSigAggCachePtr> copyMuSigCache(MuSigAggCachePtr copyFrom) {
    final newCache = HeapFfi<secp256k1_musig_keyagg_cache>(malloc());
    newCache.ptr.ref = copyFrom.ref;
    return newCache;
  }

  @override
  Heap<MuSigSecNoncePtr> allocMuSigSecNonce() => HeapFfi(malloc());

  @override
  Heap<MuSigPublicNoncePtr> allocMuSigPubNonce() => HeapFfi(malloc());

  @override
  Heap<MuSigSessionPtr> allocMuSigSession() => HeapFfi(malloc());

  @override
  Heap<MuSigPartialSigPtr> allocMuSigPartialSig() => HeapFfi(malloc());

}
