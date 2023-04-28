import 'package:coinlib/coinlib.dart';
import 'package:test/test.dart';

void main() {

  group("Hash256", () {
    test("must be 32 bytes", () {
      for (final hash in [
        "56282d1366c4b5d34a259fff5bdfd44e7013fa8213bc713758fdeed212d62f",
        "56282d1366c4b5d34a259fff5bdfd44e7013fa8213bc713758fdeed212d62fe8ff",
      ]) {
        expect(() => Hash256.fromHashHex(hash), throwsA(isA<ArgumentError>()));
      }
    });
  });

}
