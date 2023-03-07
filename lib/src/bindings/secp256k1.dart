import 'dart:typed_data';
import 'package:coinlib/src/generated/secp256k1.wasm.g.dart';
import 'package:wasm/wasm.dart';
import '../crypto/random.dart';

class Secp256k1Exception implements Exception {
  final String what;
  Secp256k1Exception(this.what);
  @override
  String toString() => what;
}

/// Wraps the secp256k1 WASM module for use in dart code using wasmer. Maintains
/// a randomised context upon construction.
class Secp256k1 {

  static const _contextNone = 1;
  static const _compressionFlags = 258;
  static const _privkeySize = 32;
  static const _pubkeySize = 64;
  static const _compressedPubkeySize = 33;
  static const _sizeTSize = 4; // 32-bit memory architecture

  late WasmMemory _memory;

  // Functions
  // Having to use dynamic is less than ideal but necessary
  late dynamic _ecPubkeyCreate;
  late dynamic _ecPubkeySerialize;

  // Memory pointers
  late int _ctxPtr;
  late int _privKeyPtr;
  late int _pubKeyPtr;
  late int _serializedPubKeyPtr; /// Always compressed 33 bytes
  late int _sizeTPtr; /// Used as pointer to size_t values

  Secp256k1() {

    final module = WasmModule(secp256k1WasmData);
    final builder = module
      .builder()
      ..enableWasi(
        captureStdout: true,
        captureStderr: true,
      );
    final inst = builder.build();

    _memory = inst.memory;

    // Lookup functions
    _ecPubkeyCreate = inst.lookupFunction("secp256k1_ec_pubkey_create");
    _ecPubkeySerialize = inst.lookupFunction("secp256k1_ec_pubkey_serialize");
    final contextCreate = inst.lookupFunction("secp256k1_context_create");
    final contextRandomize = inst.lookupFunction("secp256k1_context_randomize");
    final malloc = inst.lookupFunction("malloc");
    final free = inst.lookupFunction("free");

    // Allocate memory
    _privKeyPtr = malloc(_privkeySize);
    _pubKeyPtr = malloc(_pubkeySize);
    _serializedPubKeyPtr = malloc(_compressedPubkeySize);
    _sizeTPtr = malloc(_sizeTSize);

    // Create universal context and randomise it as recommended
    // Generate 32 random bytes in the module memory
    final randBytePtr = malloc(32);
    final randomBytes = generateRandomBytes(32);
    _memory.view.setAll(randBytePtr, randomBytes);
    free(randBytePtr);

    _ctxPtr = contextCreate(_contextNone);
    if (contextRandomize(_ctxPtr, randBytePtr) != 1) {
      throw Secp256k1Exception("Secp256k1 context couldn't be randomised");
    }

  }

  /// Converts a 32-byte [privKey] into a 33-byte compressed public key
  Uint8List privToPubKey(Uint8List privKey) {

    // Write private key to memory
    _memory.view.setRange(_privKeyPtr, _privKeyPtr+_privkeySize, privKey);

    // Derive public key from private key
    if (_ecPubkeyCreate(_ctxPtr, _pubKeyPtr, _privKeyPtr) != 1) {
      throw Secp256k1Exception("Cannot compute public key from private key");
    }

    // Set length to 33 via size_t value. Should be little endian.
    ByteData.sublistView(
      _memory.view, _sizeTPtr, _sizeTPtr+_sizeTSize,
    ).setUint32(0, _compressedPubkeySize, Endian.little);

    // Parse and return public key
    _ecPubkeySerialize(
      _ctxPtr, _serializedPubKeyPtr, _sizeTPtr, _pubKeyPtr, _compressionFlags,
    );

    return _memory.view.sublist(
      _serializedPubKeyPtr, _serializedPubKeyPtr+_compressedPubkeySize,
    );

  }

}

final secp256k1 = Secp256k1();

