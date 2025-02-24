import 'dart:typed_data';
import 'package:coinlib/src/common/bytes.dart';
import 'package:coinlib/src/common/serial.dart';
import 'package:coinlib/src/crypto/ec_private_key.dart';
import 'package:coinlib/src/crypto/ec_public_key.dart';
import 'package:coinlib/src/crypto/hash.dart';
import 'package:coinlib/src/scripts/script.dart';
import 'package:collection/collection.dart';

/// This class encapsulates the construction of Taproot tweaked keys given an
/// internal key and MAST consisting of Tapscript leaves constructed with
/// [TapBranch] and [TapLeaf] objects.
class Taproot {

  final ECPublicKey internalKey;
  final TapNode? mast;
  /// A list of [TapLeaf] objects in the order that they appear in the MAST tree
  final List<TapLeaf> leaves;

  static final tweakHash = getTaggedHasher("TapTweak");

  /// Takes the [internalKey] to construct the tweaked key. The internal key
  /// will be forced to use an even Y coordinate and may not equal the
  /// passed [internalKey].
  /// The [mast] represents a "Merkelized Abstract Syntax Tree" which is a tree
  /// of scripts that can be spent. This can be constructed via [TapBranch] and
  /// [TapLeaf] objects.
  Taproot({
    required ECPublicKey internalKey,
    this.mast,
  })
  : internalKey = internalKey.xonly,
  leaves = List.unmodifiable(mast == null ? [] : mast._leaves) {
    if (leaves.toSet().length != leaves.length) {
      throw ArgumentError.value(mast, "mast", "contains duplicate leaves");
    }
  }

  /// Takes a private key and tweaks it for key-path spending
  ECPrivateKey tweakPrivateKey(ECPrivateKey key)
    => key.xonly.tweak(tweakScalar)!;

  /// Given the exact [leaf] object provided to this [Taproot] object, this
  /// provides the control block data for inclusion in a script-path input.
  Uint8List controlBlockForLeaf(TapLeaf leaf) {

    if (mast == null || !leaves.contains(leaf)) {
      throw ArgumentError.value(leaf, "leaf", "not in MAST tree");
    }

    // Find path to leaf
    final List<TapNode> path = [mast!];
    while (path.last != leaf) {

      if (path.last is TapLeaf) {

        // Move back to last left movement
        while (path.last == (path[path.length-2] as TapBranch).r) {
          path.removeLast();
        }
        // Remove left movement
        path.removeLast();

        // Move over to the right
        path.add((path.last as TapBranch).r);

      } else {
        // Is branch, move to the left-most
        path.add((path.last as TapBranch).l);
      }

    }

    final data = Uint8List(33+(path.length-1)*32);
    final writer = BytesWriter(data);

    // Control byte
    writer.writeUInt8(
      // Tapscript version
      (path.last as TapLeaf).version
      // Public key parity bit
      + (tweakedKey.yIsEven ? 0 : 1),
    );

    // Internal public key
    writer.writeSlice(internalKey.x);

    // Add path siblings, required for the merkle hash reconstruction
    // Start from leaf node and move backwards, adding the siblings of each node
    TapNode? prev;
    for (final node in path.reversed) {
      if (prev != null) {
        node as TapBranch;
        final sibling = node.l == prev ? node.r : node.l;
        writer.writeSlice(sibling.hash);
      }
      prev = node;
    }

    return data;

  }

  Uint8List? _tweakScalarCache;
  /// The scalar to tweak the internal key
  Uint8List get tweakScalar => _tweakScalarCache ??= tweakHash(
    Uint8List.fromList([
      ...internalKey.x,
      if (mast != null) ...mast!.hash,
    ]),
  );

  ECPublicKey? _tweakedKeyCache;
  /// Obtains the tweaked public key for use in a Taproot program
  ECPublicKey get tweakedKey => _tweakedKeyCache ??= internalKey.tweak(
    tweakScalar,
  )!; // Assert not-null. Failure should be practically impossible.

}

/// A node in the MAST tree, either a [TapBranch] or [TapLeaf].
abstract interface class TapNode {
  Uint8List get hash;
  List<TapLeaf> get _leaves;
}

/// Takes two child nodes within the MAST tree.
class TapBranch implements TapNode {

  static final branchHash = getTaggedHasher("TapBranch");

  final TapNode l, r;

  TapBranch(this.l, this.r);

  // Used to determine which hash should be encoded first. The smallest hash
  // should be first.
  bool _leftFirst() {

    for (final pair in IterableZip([l.hash, r.hash])) {
      if (pair[0] < pair[1]) return true;
      if (pair[0] > pair[1]) return false;
    }

    return true;

  }

  Uint8List? _hashCache;
  @override
  Uint8List get hash => _hashCache ??= branchHash(
    Uint8List.fromList(_leftFirst() ? l.hash+r.hash : r.hash+l.hash),
  );

  @override
  List<TapLeaf> get _leaves => l._leaves + r._leaves;

}

/// A leaf in the MAST tree representing the Tapscript [script].
class TapLeaf with Writable implements TapNode {

  static final leafHash = getTaggedHasher("TapLeaf");
  static const int tapscriptVersion = 0xc0;

  /// The Tapscript version is fixed as 0xc0 as this is the only implemented and
  /// enforced version
  final int version = tapscriptVersion;
  final Script script;

  TapLeaf(this.script);

  @override
  void write(Writer writer) {
    writer.writeUInt8(version);
    writer.writeVarSlice(script.compiled);
  }

  Uint8List? _hashCache;
  @override
  Uint8List get hash => _hashCache ??= leafHash(toBytes());

  @override
  List<TapLeaf> get _leaves => [this];

  @override
  bool operator ==(Object other)
    => (other is TapLeaf)
    && version == other.version
    && bytesEqual(script.compiled, other.script.compiled);

  @override
  int get hashCode => hash[0] | hash[1] << 8 | hash[2] << 16 | hash[3] << 24;

}
