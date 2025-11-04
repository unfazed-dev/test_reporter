/// Test fixture with flaky/intermittent failures
///
/// This file is used to test the analyze_tests tool's flaky test detection.
/// Tests use random behavior to simulate real-world flakiness, producing
/// approximately 50% pass rate when run multiple times.
///
/// The analyze_tests tool should detect these as flaky tests with reliability
/// scores around 40-60% (depending on randomness).
///
/// Usage:
/// ```bash
/// dart test test/fixtures/flaky_test.dart
/// dart run test_reporter:analyze_tests test/fixtures/flaky_test.dart --runs=10
/// ```
import 'dart:math';

import 'package:test/test.dart';

void main() {
  final random = Random();

  group('Flaky Tests - Random Failures', () {
    test('random boolean check (50% pass rate)', () {
      final shouldPass = random.nextBool();
      expect(shouldPass, isTrue); // Fails ~50% of the time
    });

    test('random number comparison (50% pass rate)', () {
      final value = random.nextInt(10);
      expect(value < 5, isTrue); // Fails when value >= 5
    });

    test('random list operation (50% pass rate)', () {
      final list = List.generate(10, (i) => random.nextInt(100));
      final hasEvenNumber = list.any((n) => n % 2 == 0);
      expect(hasEvenNumber, isTrue); // Usually passes but can fail
    });
  });

  group('Flaky Tests - Timing-Sensitive', () {
    test('microsecond timing check (intermittent)', () {
      final now = DateTime.now().microsecond;
      // Passes when microsecond is even, fails when odd (~50% each)
      expect(now % 2, equals(0));
    });

    test('millisecond-based random (intermittent)', () {
      final millis = DateTime.now().millisecondsSinceEpoch;
      final isEven = millis % 2 == 0;
      expect(isEven, isTrue); // ~50% pass rate
    });
  });

  group('Flaky Tests - State-Dependent', () {
    var counter = 0;

    test('alternating test (flaky across runs)', () {
      counter++;
      // Passes on even runs, fails on odd runs
      expect(counter % 2, equals(0));
    });

    test('threshold-based test (flaky)', () {
      final value = random.nextDouble();
      expect(value > 0.5, isTrue); // ~50% pass rate
    });
  });

  group('Flaky Tests - List Shuffling', () {
    test('shuffled list order check (flaky)', () {
      final list = [1, 2, 3, 4, 5]..shuffle();
      // Passes only if list starts with 1 after shuffle (~20% chance)
      expect(list.first, equals(1));
    });

    test('random selection from set (flaky)', () {
      final options = ['pass', 'fail', 'maybe'];
      final selected = options[random.nextInt(options.length)];
      expect(selected, equals('pass')); // ~33% pass rate
    });
  });

  group('Flaky Tests - Cumulative Probability', () {
    test('multiple random conditions (very flaky)', () {
      final condition1 = random.nextBool();
      final condition2 = random.nextBool();
      final condition3 = random.nextBool();

      // All three must be true - only ~12.5% pass rate
      expect(condition1 && condition2 && condition3, isTrue);
    });

    test('random string generation (flaky)', () {
      final chars = 'abcdefghijklmnopqrstuvwxyz';
      final randomChar = chars[random.nextInt(chars.length)];
      // Passes only if random char is a vowel (~20% chance)
      expect('aeiou'.contains(randomChar), isTrue);
    });
  });
}
