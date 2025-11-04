/// Test fixture with slow/timeout tests
///
/// This file is used to test the analyze_tests tool's handling of slow and
/// timing-out tests. It includes tests with various delays to simulate
/// performance issues and timeout scenarios.
///
/// The analyze_tests tool should detect these as slow tests and potentially
/// timeout failures depending on the configured timeout duration.
///
/// Usage:
/// ```bash
/// dart test test/fixtures/slow_test.dart
/// dart run test_reporter:analyze_tests test/fixtures/slow_test.dart --runs=3
/// ```
import 'package:test/test.dart';

void main() {
  group('Slow Tests - Short Delays', () {
    test('500ms delay test', () async {
      await Future.delayed(const Duration(milliseconds: 500));
      expect(1 + 1, equals(2));
    });

    test('1 second delay test', () async {
      await Future.delayed(const Duration(seconds: 1));
      expect('slow'.length, equals(4));
    });

    test('1.5 second delay test', () async {
      await Future.delayed(const Duration(milliseconds: 1500));
      expect([1, 2, 3].length, equals(3));
    });
  });

  group('Slow Tests - Medium Delays', () {
    test('2 second delay test', () async {
      await Future.delayed(const Duration(seconds: 2));
      expect(true, isTrue);
    });

    test('2.5 second delay test', () async {
      await Future.delayed(const Duration(milliseconds: 2500));
      expect(10 * 10, equals(100));
    });

    test('3 second delay test', () async {
      await Future.delayed(const Duration(seconds: 3));
      expect('timeout'.contains('time'), isTrue);
    });
  });

  group('Slow Tests - Long Delays', () {
    test('4 second delay test', () async {
      await Future.delayed(const Duration(seconds: 4));
      expect([].isEmpty, isTrue);
    });

    test('5 second delay test', () async {
      await Future.delayed(const Duration(seconds: 5));
      expect('very slow test'.split(' ').length, equals(3));
    });
  });

  group('Slow Tests - Simulated Work', () {
    test('CPU-intensive calculation', () {
      var sum = 0;
      for (var i = 0; i < 10000000; i++) {
        sum += i;
      }
      expect(sum > 0, isTrue);
    });

    test('nested loops simulation', () {
      var count = 0;
      for (var i = 0; i < 1000; i++) {
        for (var j = 0; j < 1000; j++) {
          count++;
        }
      }
      expect(count, equals(1000000));
    });

    test('repeated string operations', () {
      var result = '';
      for (var i = 0; i < 10000; i++) {
        result += 'a';
      }
      expect(result.length, equals(10000));
    });
  });

  group('Slow Tests - Async Operations', () {
    test('multiple async delays', () async {
      await Future.delayed(const Duration(milliseconds: 500));
      await Future.delayed(const Duration(milliseconds: 500));
      await Future.delayed(const Duration(milliseconds: 500));
      expect(1 + 1 + 1, equals(3));
    });

    test('sequential async operations', () async {
      final results = <int>[];
      for (var i = 0; i < 5; i++) {
        await Future.delayed(const Duration(milliseconds: 200));
        results.add(i);
      }
      expect(results.length, equals(5));
    });

    test('nested async calls', () async {
      Future<int> slowOperation(int value) async {
        await Future.delayed(const Duration(milliseconds: 300));
        return value * 2;
      }

      var result = await slowOperation(5);
      result = await slowOperation(result);
      result = await slowOperation(result);

      expect(result, equals(40)); // 5 * 2 * 2 * 2
    });
  });

  group('Slow Tests - Progressive Delays', () {
    test('exponential backoff simulation', () async {
      var delay = 100;
      for (var i = 0; i < 4; i++) {
        await Future.delayed(Duration(milliseconds: delay));
        delay *= 2; // 100ms, 200ms, 400ms, 800ms
      }
      expect(delay, equals(1600));
    });

    test('cumulative delay test', () async {
      final delays = [100, 200, 300, 400, 500];
      for (final delay in delays) {
        await Future.delayed(Duration(milliseconds: delay));
      }
      expect(delays.reduce((a, b) => a + b), equals(1500));
    });
  });
}
