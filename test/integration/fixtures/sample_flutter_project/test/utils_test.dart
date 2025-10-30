import 'package:test/test.dart';
import '../lib/utils.dart';

void main() {
  group('Utils', () {
    group('isEven', () {
      test('returns true for even numbers', () {
        expect(Utils.isEven(2), isTrue);
        expect(Utils.isEven(0), isTrue);
        expect(Utils.isEven(-4), isTrue);
      });

      test('returns false for odd numbers', () {
        expect(Utils.isEven(1), isFalse);
        expect(Utils.isEven(3), isFalse);
        expect(Utils.isEven(-5), isFalse);
      });
    });

    group('isOdd', () {
      test('returns true for odd numbers', () {
        expect(Utils.isOdd(1), isTrue);
        expect(Utils.isOdd(3), isTrue);
        expect(Utils.isOdd(-7), isTrue);
      });

      test('returns false for even numbers', () {
        expect(Utils.isOdd(2), isFalse);
        expect(Utils.isOdd(0), isFalse);
      });
    });

    group('formatNumber', () {
      test('formats large numbers with commas', () {
        expect(Utils.formatNumber(1000), equals('1,000'));
        expect(Utils.formatNumber(1000000), equals('1,000,000'));
      });

      test('does not format small numbers', () {
        expect(Utils.formatNumber(100), equals('100'));
        expect(Utils.formatNumber(10), equals('10'));
      });
    });
  });
}
