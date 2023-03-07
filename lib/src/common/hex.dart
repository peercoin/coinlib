import 'dart:typed_data';
import 'package:hex/hex.dart';

Uint8List hexToBytes(String hex) => Uint8List.fromList(HEX.decode(hex));
String bytesToHex(Uint8List bytes) => HEX.encode(bytes);
