import 'package:example/src/b.dart';
import 'package:test/test.dart';

void main() {
  test('concat test', () {
    expect(concat('a', 'b'), 'ab');
  });
}
