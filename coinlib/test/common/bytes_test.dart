import 'dart:typed_data';
import 'package:coinlib/coinlib.dart';
import 'package:test/test.dart';

void main() {

  group("bytes functions", () {

    expectBytes(Uint8List Function(Uint8List, int) f, bool same) {
      final li = Uint8List.fromList([1,2,3]);
      final result = f(li, 3);
      expect(result, li);
      expect(() => checkBytes(li, 2), throwsArgumentError);
      expect(() => checkBytes(li, 4), throwsArgumentError);
      li[0] = 0xff;
      expect(result[0], same ? 0xff : 1);
    }

    test("checkBytes()", () => expectBytes(checkBytes, true));
    test("copyCheckBytes()", () => expectBytes(copyCheckBytes, false));

    test("bytesEqual()", () {

      final li1 = Uint8List.fromList([1,2,3]);
      final copy = Uint8List.fromList(li1);

      expect(bytesEqual(li1, li1), true);
      expect(bytesEqual(li1, copy), true);
      expect(bytesEqual(li1, li1.sublist(0, 2)), false);

    });

  });

}
