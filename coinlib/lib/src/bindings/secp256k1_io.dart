import "dart:ffi";
import "dart:io";
import "package:coinlib/src/bindings/heap_array_ffi.dart";
import "package:coinlib/src/crypto/random.dart";
import 'package:ffi/ffi.dart';
import "package:coinlib/src/generated/secp256k1.ffi.g.dart";
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

/// Specialises Secp256k1Base to use the FFI
class Secp256k1 extends Secp256k1Base<
  Pointer<secp256k1_context>,
  UCharPointer,
  Pointer<secp256k1_pubkey>,
  Pointer<Size>,
  Pointer<secp256k1_ecdsa_signature>,
  Pointer<secp256k1_ecdsa_recoverable_signature>,
  Pointer<Int>,
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

    // Set heap arrays
    privKeyArray = HeapArrayFfi(Secp256k1Base.privkeySize);
    serializedPubKeyArray = HeapArrayFfi(Secp256k1Base.uncompressedPubkeySize);
    hashArray = HeapArrayFfi(Secp256k1Base.hashSize);
    serializedSigArray = HeapArrayFfi(Secp256k1Base.sigSize);
    derSigArray = HeapArrayFfi(Secp256k1Base.derSigSize);

    // Set other pointers
    // A finalizer could be added to free allocated memory but as this class will
    // used for a singleton object throughout the entire lifetime of the program,
    // it doesn't matter
    sizeTPtr = malloc();
    pubKeyPtr = malloc();
    sigPtr = malloc();
    recSigPtr = malloc();
    recIdPtr = malloc();
    nullPtr = nullptr;

    // Create context
    ctxPtr = _lib.secp256k1_context_create(Secp256k1Base.contextNone);

    // Randomise context with 32 bytes

    final randBytes = generateRandomBytes(32);
    final randArray = HeapArrayFfi(32);
    randArray.load(randBytes);

    if (_lib.secp256k1_context_randomize(ctxPtr, randArray.ptr) != 1) {
      throw Secp256k1Exception("Secp256k1 context couldn't be randomised");
    }

  }

  @override
  set sizeT(int size) => sizeTPtr.value = size;

  @override
  int get sizeT => sizeTPtr.value;

  @override
  int get internalRecId => recIdPtr.value;

}
