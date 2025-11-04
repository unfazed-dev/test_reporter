/// Integration test fixture: Quick "slow" tests
///
/// This fixture provides tests with moderate delays (500ms-1s) that are:
/// - Slow enough to be detected by performance profiling
/// - Fast enough for integration testing without timeouts
/// - Suitable for CI/CD pipelines
///
/// Total execution time: ~3 seconds (suitable for integration tests)
///
/// Usage in integration tests:
/// ```dart
/// dart bin/analyze_tests.dart test/fixtures/quick_slow_test.dart --runs=1 --performance
/// ```
library;

import 'package:test/test.dart';

void main() {
  group('Quick Slow Tests', () {
    test('moderately slow test (500ms)', () async {
      await Future<void>.delayed(Duration(milliseconds: 500));
      expect(1 + 1, equals(2));
    });

    test('moderately slow test (800ms)', () async {
      await Future<void>.delayed(Duration(milliseconds: 800));
      expect('hello'.length, equals(5));
    });

    test('moderately slow test (1 second)', () async {
      await Future<void>.delayed(Duration(seconds: 1));
      expect([1, 2, 3].length, equals(3));
    });

    test('quick test with simulated work (200ms)', () async {
      // Simulate CPU work
      var sum = 0;
      for (var i = 0; i < 1000000; i++) {
        sum += i;
      }
      await Future<void>.delayed(Duration(milliseconds: 200));
      expect(sum, greaterThan(0));
    });

    test('async operations (600ms)', () async {
      await Future<void>.delayed(Duration(milliseconds: 300));
      final result = await Future.value(42);
      await Future<void>.delayed(Duration(milliseconds: 300));
      expect(result, equals(42));
    });
  });
}
