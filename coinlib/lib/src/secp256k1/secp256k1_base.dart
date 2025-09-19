import 'dart:typed_data';
import 'heap.dart';

class Secp256k1Exception implements Exception {
  final String what;
  Secp256k1Exception(this.what);
  @override
  String toString() => what;
}

class SigWithRecId {
  final Uint8List signature;
  final int recid;
  SigWithRecId(this.signature, this.recid);
}

class MuSigCacheGeneric<MuSigAggCachePtr> {
  final Heap<MuSigAggCachePtr> _cache;
  MuSigCacheGeneric(this._cache);
}

abstract class Secp256k1Base<
  CtxPtr, UCharPtr, PubKeyPtr, SizeTPtr, SignaturePtr,
  RecoverableSignaturePtr, KeyPairPtr, XPubKeyPtr, IntPtr, MuSigAggCachePtr,
  PubKeyPtrPtr, NullPtr
> {

  static const contextNone = 1;
  static const compressedFlags = 258;
  static const uncompressedFlags = 2;
  static const privkeySize = 32;
  static const hashSize = 32;
  static const entropySize = 32;
  static const pubkeySize = 64;
  static const compressedPubkeySize = 33;
  static const uncompressedPubkeySize = 65;
  static const sigSize = 64;
  static const derSigSize = 72;
  static const recSigSize = 65;
  static const keyPairSize = 96;
  static const xonlySize = 32;

  // Functions
  late int Function(CtxPtr, UCharPtr) extEcSeckeyVerify;
  late int Function(CtxPtr, PubKeyPtr, UCharPtr) extEcPubkeyCreate;
  late int Function(
    CtxPtr, UCharPtr, SizeTPtr, PubKeyPtr, int,
  ) extEcPubkeySerialize;
  late int Function(CtxPtr, PubKeyPtr, UCharPtr, int) extEcPubkeyParse;
  late int Function(
    CtxPtr, UCharPtr, SignaturePtr,
  ) extEcdsaSignatureSerializeCompact;
  late int Function(
    CtxPtr, SignaturePtr, UCharPtr,
  ) extEcdsaSignatureParseCompact;
  late int Function(
    CtxPtr, SignaturePtr, SignaturePtr,
  ) extEcdsaSignatureNormalize;
  late int Function(
    CtxPtr, UCharPtr, SizeTPtr, SignaturePtr,
  ) extEcdsaSignatureSerializeDer;
  late int Function(
    CtxPtr, SignaturePtr, UCharPtr, int,
  ) extEcdsaSignatureParseDer;
  late int Function(
    CtxPtr, SignaturePtr, UCharPtr, UCharPtr, NullPtr, NullPtr,
  ) extEcdsaSign;
  late int Function(
    CtxPtr, SignaturePtr, UCharPtr, PubKeyPtr,
  ) extEcdsaVerify;
  late int Function(
    CtxPtr, UCharPtr, IntPtr, RecoverableSignaturePtr,
  ) extEcdsaRecoverableSignatureSerializeCompact;
  late int Function(
    CtxPtr, RecoverableSignaturePtr, UCharPtr, int,
  ) extEcdsaRecoverableSignatureParseCompact;
  late int Function(
    CtxPtr, RecoverableSignaturePtr, UCharPtr, UCharPtr, NullPtr,
    NullPtr,
  ) extEcdsaSignRecoverable;
  late int Function(
    CtxPtr, PubKeyPtr, RecoverableSignaturePtr, UCharPtr,
  ) extEcdsaRecover;
  late int Function(CtxPtr, UCharPtr, UCharPtr) extEcSeckeyTweakAdd;
  late int Function(CtxPtr, PubKeyPtr, UCharPtr) extEcPubkeyTweakAdd;
  late int Function(CtxPtr, UCharPtr) extEcSeckeyNegate;

  // Schnorr functions
  late int Function(CtxPtr, KeyPairPtr, UCharPtr) extKeypairCreate;
  late int Function(CtxPtr, XPubKeyPtr, UCharPtr) extXOnlyPubkeyParse;
  late int Function(CtxPtr, UCharPtr, XPubKeyPtr) extXOnlyPubkeySerialize;
  late int Function(
    CtxPtr, UCharPtr, UCharPtr, KeyPairPtr, UCharPtr,
  ) extSchnorrSign32;
  late int Function(
    CtxPtr, UCharPtr, UCharPtr, int, XPubKeyPtr,
  ) extSchnorrVerify;
  late int Function(
    CtxPtr, UCharPtr, PubKeyPtr, UCharPtr, NullPtr, NullPtr,
  ) extEcdh;

  // MuSig2 relevant functions
  late int Function(CtxPtr, PubKeyPtrPtr, int) extEcPubkeySort;
  late int Function(
    CtxPtr, XPubKeyPtr, MuSigAggCachePtr, PubKeyPtrPtr, int,
  ) extMuSigPubkeyAgg;

  // Heap arrays

  // Used for private keys and x-only public keys
  late HeapBytes<UCharPtr> key32Array;

  late HeapBytes<UCharPtr> scalarArray;
  late HeapBytes<UCharPtr> serializedPubKeyArray;
  late HeapBytes<UCharPtr> hashArray;
  late HeapBytes<UCharPtr> entropyArray;
  late HeapBytes<UCharPtr> serializedSigArray;
  late HeapBytes<UCharPtr> derSigArray;

  // Other pre-allocated heap objects
  late Heap<PubKeyPtr> pubKey;
  late HeapInt<SizeTPtr> sizeT;
  late Heap<SignaturePtr> sig;
  late Heap<RecoverableSignaturePtr> recSig;
  late Heap<KeyPairPtr> keyPair;
  late Heap<XPubKeyPtr> xPubKey;
  late HeapInt<IntPtr> recId;

  // Context pointer is allocated by underlying library
  late CtxPtr ctxPtr;

  // Null pointer value
  late NullPtr nullPtr;

  Uint8List _serializePubKeyFromPtr(bool compressed) {

    sizeT.value = compressed
      ? Secp256k1Base.compressedPubkeySize
      : Secp256k1Base.uncompressedPubkeySize;

    final flags = compressed
      ? Secp256k1Base.compressedFlags
      : Secp256k1Base.uncompressedFlags;

    extEcPubkeySerialize(
      ctxPtr, serializedPubKeyArray.ptr, sizeT.ptr, pubKey.ptr, flags,
    );

    // Return copy of public key
    return serializedPubKeyArray.list.sublist(0, sizeT.value);

  }

  Uint8List _serializeXPubKeyFromPtr() {
    extXOnlyPubkeySerialize(ctxPtr, key32Array.ptr, xPubKey.ptr);
    // Return copy of public key
    return Uint8List.fromList(key32Array.list);
  }

  Uint8List _serializeSignatureFromPtr() {
    extEcdsaSignatureSerializeCompact(ctxPtr, serializedSigArray.ptr, sig.ptr);
    return serializedSigArray.list.sublist(0);
  }

  void _parsePubkeyIntoPtr(Uint8List bytes, [PubKeyPtr? ptr]) {
    serializedPubKeyArray.load(bytes);
    if (
      extEcPubkeyParse(
        ctxPtr, ptr ?? pubKey.ptr, serializedPubKeyArray.ptr, bytes.length,
      ) != 1
    ) {
      throw Secp256k1Exception("Invalid public key");
    }
  }

  void _parseSignatureIntoPtr(Uint8List signature) {
    serializedSigArray.load(signature);
    if (
      extEcdsaSignatureParseCompact(
        ctxPtr, sig.ptr, serializedSigArray.ptr,
      ) != 1
    ) {
      throw Secp256k1Exception("Invalid compact signature");
    }
  }

  void _parseRecoverableSignatureIntoPtr(Uint8List signature, int recid) {
    serializedSigArray.load(signature);
    if (
      extEcdsaRecoverableSignatureParseCompact(
        ctxPtr, recSig.ptr, serializedSigArray.ptr, recid,
      ) != 1
    ) {
      throw Secp256k1Exception("Invalid compact recoverable signature");
    }
  }

  void _parsePrivKeyIntoKeyPairPtr(Uint8List privKey) {
    key32Array.load(privKey);
    if (extKeypairCreate(ctxPtr, keyPair.ptr, key32Array.ptr) != 1) {
      throw Secp256k1Exception("Invalid private key");
    }
  }

  void _parseXPubKeyIntoPtr(Uint8List pubKey) {
    key32Array.load(pubKey);
    if (extXOnlyPubkeyParse(ctxPtr, xPubKey.ptr, key32Array.ptr) != 1) {
      throw Secp256k1Exception("Invalid x-only public key");
    }
  }

  bool _noRaiseAfterRequireLoad(void Function() fn) {
    _requireLoad();
    try {
      fn();
    } on Secp256k1Exception {
      return false;
    }
    return true;
  }

  // This may be overriden by the subclass to load the library asynchronously
  Future<void> internalLoad() async {}

  bool _loaded = false;
  void _requireLoad() {
    if (!_loaded) throw Secp256k1Exception("load() not called");
  }

  /// Asynchronously load the library. `await` must be used to ensure the
  /// library is loaded. Must be called before other methods are available.
  Future<void> load() async {
    if (_loaded) return;
    await internalLoad();
    _loaded = true;
  }

  /// Returns true if a 32-byte [privKey] is valid.
  bool privKeyVerify(Uint8List privKey) {
    _requireLoad();
    key32Array.load(privKey);
    return extEcSeckeyVerify(ctxPtr, key32Array.ptr) == 1;
  }

  /// Returns true if a compressed or uncompressed public key is valid.
  bool pubKeyVerify(Uint8List pubKey)
    => _noRaiseAfterRequireLoad(() => _parsePubkeyIntoPtr(pubKey));

  /// Returns true if the compact [signature] can be parsed with valid R and S
  /// values
  bool ecdsaCompactSignatureVerify(Uint8List signature)
    => _noRaiseAfterRequireLoad(() => _parseSignatureIntoPtr(signature));

  /// Returns true if the compact recoverable signature can be parsed given the
  /// [signature] and [recid]
  bool ecdsaCompactRecoverableSignatureVerify(Uint8List signature, int recid)
    => _noRaiseAfterRequireLoad(
      () => _parseRecoverableSignatureIntoPtr(signature, recid),
    );

  /// Converts a 32-byte [privKey] into a either a 33-byte compressed or a
  /// 65-byte uncompressed public key.
  Uint8List privToPubKey(Uint8List privKey, bool compressed) {
    _requireLoad();

    key32Array.load(privKey);

    // Derive public key from private key
    if (extEcPubkeyCreate(ctxPtr, pubKey.ptr, key32Array.ptr) != 1) {
      throw Secp256k1Exception("Cannot compute public key from private key");
    }

    return _serializePubKeyFromPtr(compressed);

  }

  /// Takes a [signature] and returns an equally valid signature that has a low
  /// s-value.
  Uint8List ecdsaSignatureNormalize(Uint8List signature) {
    _requireLoad();
    _parseSignatureIntoPtr(signature);
    extEcdsaSignatureNormalize(ctxPtr, sig.ptr, sig.ptr);
    return _serializeSignatureFromPtr();
  }

  /// Takes a compact [signature] and returns a DER encoded signature
  Uint8List ecdsaSignatureToDer(Uint8List signature) {
    _requireLoad();

    _parseSignatureIntoPtr(signature);
    sizeT.value = derSigArray.list.length;

    // Should always have space
    extEcdsaSignatureSerializeDer(ctxPtr, derSigArray.ptr, sizeT.ptr, sig.ptr);

    return derSigArray.list.sublist(0, sizeT.value);

  }

  /// Takes a BIP66 DER ([der]) representation of a signature and returns the
  /// compact representation
  Uint8List ecdsaSignatureFromDer(Uint8List der) {
    _requireLoad();

    derSigArray.load(der);

    if (
      extEcdsaSignatureParseDer(
        ctxPtr, sig.ptr, derSigArray.ptr, der.length,
      ) != 1
    ) {
      throw Secp256k1Exception("Invalid DER signature");
    }

    return _serializeSignatureFromPtr();

  }

  /// Constructs a signature in the compact format using a 32-byte message
  /// [hash] and 32-byte [privKey] scalar. The signature contains a 32-byte
  /// big-endian R value followed by a 32-byte big-endian low-S value.
  /// Signatures are deterministic according to RFC6979. Additional entropy may
  /// be added as 32 bytes with [extraEntropy].
  Uint8List ecdsaSign(
    Uint8List hash, Uint8List privKey, [Uint8List? extraEntropy,]
  ) {
    _requireLoad();

    key32Array.load(privKey);
    hashArray.load(hash);
    if (extraEntropy != null) entropyArray.load(extraEntropy);

    // Sign
    if (
      extEcdsaSign(
        ctxPtr, sig.ptr, hashArray.ptr, key32Array.ptr,
        // Passing null will give secp256k1_nonce_function_rfc6979. If secp256k1
        // changes this default function in the future,
        // secp256k1_nonce_function_rfc6979 should be used directly.
        // Using null as it doesn't require passing an additional constant from
        // the web and io implementations.
        nullPtr,
        // The pointer is not actually null when entropy is provided but NullPtr
        // works for void pointers too
        extraEntropy == null ? nullPtr : entropyArray.ptr as NullPtr,
      ) != 1
    ) {
      throw Secp256k1Exception("Cannot sign message with private key");
    }

    return _serializeSignatureFromPtr();

  }

  /// Verifies a compact [signature] against a 32-byte [hash] for a
  /// [pubKeyBytes] that is either compressed or uncompressed in size
  bool ecdsaVerify(Uint8List signature, Uint8List hash, Uint8List pubKeyBytes) {
    _requireLoad();

    _parseSignatureIntoPtr(signature);
    _parsePubkeyIntoPtr(pubKeyBytes);
    hashArray.load(hash);

    return extEcdsaVerify(ctxPtr, sig.ptr, hashArray.ptr, pubKey.ptr) == 1;

  }

  SigWithRecId ecdsaSignRecoverable(Uint8List hash, Uint8List privKey) {
    _requireLoad();

    key32Array.load(privKey);
    hashArray.load(hash);

    if (
      extEcdsaSignRecoverable(
        ctxPtr, recSig.ptr, hashArray.ptr, key32Array.ptr, nullPtr, nullPtr,
      ) != 1
    ) {
      throw Secp256k1Exception("Cannot sign message with private key");
    }

    extEcdsaRecoverableSignatureSerializeCompact(
      ctxPtr, serializedSigArray.ptr, recId.ptr, recSig.ptr,
    );
    return SigWithRecId(serializedSigArray.list.sublist(0), recId.value);

  }

  /// Takes a compact recoverable [signature] with [recid] and message [hash]
  /// and recovers the associated public key. If [compressed] is true, the
  /// public key will be compressed or else it shall be uncompressed. Will
  /// return null if no public key can be extracted.
  Uint8List? ecdaSignatureRecoverPubKey(
    Uint8List signature, int recid, Uint8List hash, bool compressed,
  ) {
    _requireLoad();

    _parseRecoverableSignatureIntoPtr(signature, recid);
    hashArray.load(hash);

    if (extEcdsaRecover(ctxPtr, pubKey.ptr, recSig.ptr, hashArray.ptr) != 1) {
      return null;
    }

    return _serializePubKeyFromPtr(compressed);

  }

  /// Tweaks a 32-byte private key ([privKey]) by a [scalar]. Returns null if a
  /// tweaked private key could not be created.
  Uint8List? privKeyTweak(Uint8List privKey, Uint8List scalar) {
    _requireLoad();

    key32Array.load(privKey);
    scalarArray.load(scalar);

    if (extEcSeckeyTweakAdd(ctxPtr, key32Array.ptr, scalarArray.ptr) != 1) {
      return null;
    }

    // Return copy of private key or contents are subject to change
    return Uint8List.fromList(key32Array.list);

  }

  /// Tweaks a public key ([pubKeyBytes]) by adding the generator point multiplied by
  /// the givern [scalar]. The resulting public key corresponds to the
  /// private key tweaked by the same scalar. Returns null if a public key could
  /// not be created. Will return a compressed public key if [compressed] is
  /// true regardless of the size of the passed [pubKey].
  Uint8List? pubKeyTweak(
    Uint8List pubKeyBytes, Uint8List scalar, bool compressed,
  ) {
    _requireLoad();

    _parsePubkeyIntoPtr(pubKeyBytes);
    scalarArray.load(scalar);

    if (extEcPubkeyTweakAdd(ctxPtr, pubKey.ptr, scalarArray.ptr) != 1) {
      return null;
    }

    return _serializePubKeyFromPtr(compressed);

  }

  /// Takes a 32-byte private key ([privKey]) and negates it.
  Uint8List privKeyNegate(Uint8List privKey) {
    _requireLoad();

    key32Array.load(privKey);

    if (extEcSeckeyNegate(ctxPtr, key32Array.ptr) != 1) {
      throw Secp256k1Exception("Invalid private key for negation");
    }

    return Uint8List.fromList(key32Array.list);

  }

  /// Constructs a 64-byte Schnorr signature for the 32-byte message [hash] and
  /// [privKey] scalar. [extraEntropy] (known as auxiliary data) is optional. It
  /// is recommended by secp256k1 for protection against side-channel attacks
  /// but the Peercoin client does not use it and it causes signatures to lose
  /// determinism.
  Uint8List schnorrSign(
    Uint8List hash, Uint8List privKey, [Uint8List? extraEntropy,]
  ) {
    _requireLoad();

    _parsePrivKeyIntoKeyPairPtr(privKey);
    hashArray.load(hash);

    if (
      extSchnorrSign32(
        ctxPtr, serializedSigArray.ptr, hashArray.ptr, keyPair.ptr,
        extraEntropy == null ? nullPtr as UCharPtr : entropyArray.ptr,
      ) != 1
    ) {
      throw Secp256k1Exception("Cannot sign Schnorr signature");
    }

    return serializedSigArray.list.sublist(0);

  }

  /// Verifies a 64-byte Schnorr [signature] against a 32-byte [hash] with a
  /// 32-byte x-only public key ([xBytes]).
  bool schnorrVerify(Uint8List signature, Uint8List hash, Uint8List xBytes) {
    _requireLoad();

    serializedSigArray.load(signature);
    hashArray.load(hash);
    _parseXPubKeyIntoPtr(xBytes);

    return extSchnorrVerify(
      ctxPtr, serializedSigArray.ptr, hashArray.ptr, 32, xPubKey.ptr,
    ) == 1;

  }

  /// Generates a Diffie-Hellman shared 32-byte hash between a private and
  /// public key where the hash can be used as a shared key.
  Uint8List ecdh(Uint8List privKey, Uint8List pubKeyBytes) {
    _requireLoad();

    key32Array.load(privKey);
    _parsePubkeyIntoPtr(pubKeyBytes);

    if (
      extEcdh(
        ctxPtr, hashArray.ptr, pubKey.ptr, key32Array.ptr, nullPtr,
        nullPtr,
      ) != 1
    ) {
      throw Secp256k1Exception("Cannot generate ECDH shared key");
    }

    return hashArray.list.sublist(0);

  }

  /// Given a list of 32-byte x-only [pubKeysBytes], orders and aggregates them
  /// into a 32-byte public key.
  ///
  /// Returns the aggregated public key bytes and an opaque object for the MuSig
  /// aggregation cache used for signing.
  (Uint8List, MuSigCacheGeneric<MuSigAggCachePtr>) muSigAgggregate(
    List<Uint8List> pubKeysBytes,
  ) {
    _requireLoad();

    final n = pubKeysBytes.length;

    // Load public keys
    final heapPubKeys = allocPubKeyArray(n);
    for (int i = 0; i < n; i++) {
      _parsePubkeyIntoPtr(pubKeysBytes[i], heapPubKeys.list[i]);
    }

    // Sort public keys
    if (extEcPubkeySort(ctxPtr, heapPubKeys.ptr, n) != 1) {
      throw Secp256k1Exception("Couldn't sort public keys for MuSig2");
    }

    // Aggregate public keys
    final musigCache = allocMuSigCache();
    if (
      extMuSigPubkeyAgg(
        ctxPtr, xPubKey.ptr, musigCache.ptr, heapPubKeys.ptr, n,
      ) != 1
    ) {
      throw Secp256k1Exception("Couldn't aggregate public keys for MuSig2");
    }

    return (_serializeXPubKeyFromPtr(), MuSigCacheGeneric(musigCache));

  }

  /// Specialised sub-classes should override to allocate a [size] number of
  /// secp256k1_pubkey and then alloate and set an array of pointers on the heap
  /// to them.
  HeapPointerArray<PubKeyPtrPtr, PubKeyPtr> allocPubKeyArray(int size);

  /// Specialised sub-classes should override to allocate an
  /// secp256k1_musig_keyagg_cache on the heap.
  Heap<MuSigAggCachePtr> allocMuSigCache();

}
