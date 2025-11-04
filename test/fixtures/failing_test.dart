/// Test fixture that always fails
///
/// This file is used to test the analyze_tests tool's handling of
/// consistently failing tests. It should always produce a 0% reliability
/// score and have 100% failures across multiple runs.
///
/// It also demonstrates various types of failures that the failure pattern
/// detection system should recognize (assertions, null errors, type errors, etc.).
///
/// Usage:
/// ```bash
/// dart test test/fixtures/failing_test.dart
/// dart run test_reporter:analyze_tests test/fixtures/failing_test.dart --runs=5
/// dart run test_reporter:extract_failures test/fixtures/
/// ```
import 'package:test/test.dart';

void main() {
  group('Failing Tests - Assertion Failures', () {
    test('basic arithmetic assertion failure', () {
      expect(1 + 1, equals(3)); // Always fails: 1 + 1 = 2, not 3
    });

    test('string comparison assertion failure', () {
      expect('hello'.toUpperCase(), equals('hello')); // Should be 'HELLO'
    });

    test('list length assertion failure', () {
      final list = [1, 2, 3];
      expect(list.length, equals(5)); // Length is 3, not 5
    });
  });

  group('Failing Tests - Null Errors', () {
    test('null reference error', () {
      String? nullString;
      // ignore: unnecessary_null_comparison
      expect(nullString!.length, equals(0)); // Throws null error
    });

    test('null list access', () {
      List<int>? nullList;
      // ignore: unnecessary_null_comparison
      expect(nullList!.first, equals(1)); // Throws null error
    });
  });

  group('Failing Tests - Type Errors', () {
    test('incorrect type cast', () {
      final dynamic value = 'string';
      expect((value as int) + 1, equals(2)); // Type cast fails
    });

    test('wrong type comparison', () {
      final dynamic value = 42;
      expect(value as String, equals('42')); // Type cast fails
    });
  });

  group('Failing Tests - Range Errors', () {
    test('list index out of range', () {
      final list = [1, 2, 3];
      expect(list[10], equals(1)); // Index 10 out of range
    });

    test('substring out of range', () {
      final str = 'hello';
      expect(str.substring(0, 20), equals('hello')); // Length is only 5
    });
  });

  group('Failing Tests - Logic Errors', () {
    test('boolean logic failure', () {
      expect(true && false, isTrue); // Always false
    });

    test('equality check failure', () {
      expect(10, equals(20)); // Never equal
    });

    test('contains check failure', () {
      expect([1, 2, 3].contains(5), isTrue); // 5 not in list
    });
  });
}
