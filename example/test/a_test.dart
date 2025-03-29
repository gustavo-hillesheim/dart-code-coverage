import 'package:test/test.dart';
import 'package:example/src/a.dart';

void main() {
  test('sum test', () {
    expect(sum(1, 2), equals(3));
  });
  test('max test', () {
    expect(max(3, 4), equals(4));
  });
  test('max test', () {
    expect(min(4, 3), equals(3));
  }, tags: ['tagged-test']);
}
