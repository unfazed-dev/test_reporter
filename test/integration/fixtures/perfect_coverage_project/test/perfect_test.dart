import 'package:test/test.dart';
import '../lib/perfect.dart';

void main() {
  group('Perfect', () {
    late Perfect perfect;

    setUp(() {
      perfect = Perfect();
    });

    test('isPositive returns true for positive numbers', () {
      expect(perfect.isPositive(1), isTrue);
      expect(perfect.isPositive(100), isTrue);
    });

    test('isPositive returns false for negative numbers', () {
      expect(perfect.isPositive(-1), isFalse);
      expect(perfect.isPositive(0), isFalse);
    });

    test('isNegative returns true for negative numbers', () {
      expect(perfect.isNegative(-1), isTrue);
      expect(perfect.isNegative(-100), isTrue);
    });

    test('isNegative returns false for positive numbers', () {
      expect(perfect.isNegative(1), isFalse);
      expect(perfect.isNegative(0), isFalse);
    });

    test('abs returns absolute value', () {
      expect(perfect.abs(5), equals(5));
      expect(perfect.abs(-5), equals(5));
      expect(perfect.abs(0), equals(0));
    });
  });
}
