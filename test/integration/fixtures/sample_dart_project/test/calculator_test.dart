import 'package:test/test.dart';
import 'package:sample_dart_project/calculator.dart';

void main() {
  group('Calculator', () {
    late Calculator calculator;

    setUp(() {
      calculator = Calculator();
    });

    test('adds two numbers correctly', () {
      expect(calculator.add(2, 3), equals(5));
      expect(calculator.add(-1, 1), equals(0));
    });

    test('subtracts two numbers correctly', () {
      expect(calculator.subtract(5, 3), equals(2));
      expect(calculator.subtract(1, 1), equals(0));
    });

    test('multiplies two numbers correctly', () {
      expect(calculator.multiply(3, 4), equals(12));
      expect(calculator.multiply(-2, 3), equals(-6));
    });

    test('divides two numbers correctly', () {
      expect(calculator.divide(10, 2), equals(5.0));
      expect(calculator.divide(7, 2), equals(3.5));
    });

    test('throws error when dividing by zero', () {
      expect(() => calculator.divide(5, 0), throwsArgumentError);
    });
  });
}
