import 'dart:typed_data';
import 'package:coinlib/src/crypto/ec_public_key.dart';
import 'package:coinlib/src/scripts/script.dart';
import 'package:coinlib/src/scripts/operations.dart';
import 'taproot.dart';

/// A TapLeaf containing a single CHECKSIG operation for a key
class TapLeafChecksig extends TapLeaf {

  /// The 1-byte APO key, referring to the internal Taproot key that must be
  /// be tweaked prior to signing
  static final apoInternal = TapLeafChecksig._(ScriptOpCode.number1);

  TapLeafChecksig._(ScriptOp keyPush) : super(
    Script([keyPush, ScriptOpCode.checksig]),
  );

  /// Regular key
  TapLeafChecksig(ECPublicKey key) : this._(ScriptPushData(key.x));

  /// A specified APO key
  TapLeafChecksig.apo(
    ECPublicKey key,
  ) : this._(
    ScriptPushData(Uint8List.fromList([1, ...key.x])),
  );

  static TapLeafChecksig? match(Script script) {

    final ops = script.ops;
    if (ops.length != 2 || !ops.last.match(ScriptOpCode.checksig)) return null;

    final first = ops.first;
    if (first.match(ScriptOpCode.number1)) return apoInternal;
    if (first is! ScriptPushData) return null;

    final data = first.data;
    final pubkeyData = switch(data.length) {
      32 => data,
      33 => data.first != 1 ? null : data.sublist(1),
      _ => null,
    };
    if (pubkeyData == null) return null;

    try {
      ECPublicKey.fromXOnly(pubkeyData);
    } on InvalidPublicKey {
      return null;
    }

    return TapLeafChecksig._(first);

  }

  bool get isApo {
    final push = script.ops.first;
    return push.match(ScriptOpCode.number1) || (
      push is ScriptPushData
      && push.data.length == 33
      && push.data.first == 1
    );
  }

}
