/// Test fixture that always passes
///
/// This file is used to test the analyze_tests tool's handling of
/// consistently passing tests. It should always produce a 100% reliability
/// score and have 0 failures across multiple runs.
///
/// Usage:
/// ```bash
/// dart test test/fixtures/passing_test.dart
/// dart run test_reporter:analyze_tests test/fixtures/passing_test.dart --runs=5
/// ```
import 'package:test/test.dart';

void main() {
  group('Passing Tests', () {
    test('basic arithmetic should work', () {
      expect(1 + 1, equals(2));
      expect(2 * 3, equals(6));
      expect(10 - 5, equals(5));
    });

    test('string operations should work', () {
      expect('hello'.toUpperCase(), equals('HELLO'));
      expect('world'.length, equals(5));
      expect('test'.contains('es'), isTrue);
    });

    test('list operations should work', () {
      final list = [1, 2, 3, 4, 5];
      expect(list.length, equals(5));
      expect(list.first, equals(1));
      expect(list.last, equals(5));
      expect(list.contains(3), isTrue);
    });

    test('boolean logic should work', () {
      final a = DateTime.now().year > 2000; // true
      final b = DateTime.now().year < 2000; // false
      expect(a && a, isTrue);
      expect(a || b, isTrue);
      expect(!b, isTrue);
      expect(b && a, isFalse);
    });

    test('null safety checks should work', () {
      String? nullableString;
      expect(nullableString, isNull);

      final nonNullString = 'not null';
      expect(nonNullString, isNotNull);
      expect(nonNullString, equals('not null'));
    });
  });
}
