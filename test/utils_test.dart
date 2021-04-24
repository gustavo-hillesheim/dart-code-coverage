import 'package:code_coverage/src/utils.dart';
import 'package:test/test.dart';

void main() {
  test('should concatenate small group of lines as a range', () {
    final output = summarizeLines([5, 6]);
    expect(output, equals('5-6'));
  });

  test('should concatenate medium group of lines as a range', () {
    final output = summarizeLines([5, 6, 7, 8]);
    expect(output, equals('5-8'));
  });

  test('should concatenate two lines as separate', () {
    final output = summarizeLines([5, 7]);
    expect(output, equals('5, 7'));
  });

  test('should concatenate lines as range and separate', () {
    final output = summarizeLines([5, 6, 7, 8, 9, 11]);
    expect(output, equals('5-9, 11'));
  });

  test('should concatenate lines with a range followed by another range', () {
    final output = summarizeLines([5, 6, 7, 9, 10, 11]);
    expect(output, equals('5-7, 9-11'));
  });

  test('should concatenate lines as two ranges and two separate', () {
    final output = summarizeLines([5, 6, 7, 11, 14, 15, 16, 27]);
    expect(output, equals('5-7, 11, 14-16, 27'));
  });
}
