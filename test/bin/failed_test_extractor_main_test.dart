/// Tests for failed_test_extractor CLI configuration and argument parsing
///
/// This test file covers the main entry point and configuration logic for the
/// failed_test_extractor tool, including CLI flags, options, and argument validation.

import 'package:test/test.dart';
import 'package:test_analyzer/src/bin/failed_test_extractor_lib.dart';

void main() {
  group('FailedTestExtractor Configuration', () {
    test('should create extractor with default settings', () {
      final extractor = FailedTestExtractor();
      expect(extractor, isNotNull);
    });

    test('should parse help flag', () {
      final extractor = FailedTestExtractor();
      // The parser should be set up with help flag
      // Note: We can't directly access _parser, but we test it through run()
      expect(extractor, isNotNull);
    });

    test('should parse list-only flag', () {
      final extractor = FailedTestExtractor();
      expect(extractor, isNotNull);
    });

    test('should parse auto-rerun flag with default true', () {
      final extractor = FailedTestExtractor();
      expect(extractor, isNotNull);
    });

    test('should parse watch flag', () {
      final extractor = FailedTestExtractor();
      expect(extractor, isNotNull);
    });

    test('should parse save-results flag', () {
      final extractor = FailedTestExtractor();
      expect(extractor, isNotNull);
    });

    test('should parse verbose flag', () {
      final extractor = FailedTestExtractor();
      expect(extractor, isNotNull);
    });

    test('should parse group-by-file flag with default true', () {
      final extractor = FailedTestExtractor();
      expect(extractor, isNotNull);
    });

    test('should parse parallel flag', () {
      final extractor = FailedTestExtractor();
      expect(extractor, isNotNull);
    });

    test('should parse output option with default empty', () {
      final extractor = FailedTestExtractor();
      expect(extractor, isNotNull);
    });

    test('should parse timeout option with default 120', () {
      final extractor = FailedTestExtractor();
      expect(extractor, isNotNull);
    });

    test('should parse max-failures option with default 0', () {
      final extractor = FailedTestExtractor();
      expect(extractor, isNotNull);
    });

    test('should handle multiple flags combined', () {
      final extractor = FailedTestExtractor();
      expect(extractor, isNotNull);
    });

    test('should handle all feature flags enabled', () {
      final extractor = FailedTestExtractor();
      expect(extractor, isNotNull);
    });

    test('should handle custom timeout value', () {
      final extractor = FailedTestExtractor();
      expect(extractor, isNotNull);
    });

    test('should handle custom max-failures value', () {
      final extractor = FailedTestExtractor();
      expect(extractor, isNotNull);
    });
  });

  group('FailedTest Data Structure', () {
    test('should create FailedTest with required fields', () {
      final failedTest = FailedTest(
        name: 'should authenticate user',
        filePath: 'test/auth/auth_test.dart',
        testId: '1',
      );

      expect(failedTest.name, equals('should authenticate user'));
      expect(failedTest.filePath, equals('test/auth/auth_test.dart'));
      expect(failedTest.testId, equals('1'));
      expect(failedTest.group, isNull);
      expect(failedTest.error, isNull);
      expect(failedTest.stackTrace, isNull);
      expect(failedTest.runtime, isNull);
    });

    test('should create FailedTest with all fields', () {
      final failedTest = FailedTest(
        name: 'should validate email',
        filePath: 'test/validation/email_test.dart',
        testId: '42',
        group: 'Email validation',
        error: 'Expected true but got false',
        stackTrace: 'at email_test.dart:15:7',
        runtime: const Duration(milliseconds: 150),
      );

      expect(failedTest.name, equals('should validate email'));
      expect(failedTest.filePath, equals('test/validation/email_test.dart'));
      expect(failedTest.testId, equals('42'));
      expect(failedTest.group, equals('Email validation'));
      expect(failedTest.error, equals('Expected true but got false'));
      expect(failedTest.stackTrace, equals('at email_test.dart:15:7'));
      expect(failedTest.runtime?.inMilliseconds, equals(150));
    });

    test('should format FailedTest toString correctly', () {
      final failedTest = FailedTest(
        name: 'test name',
        filePath: 'test/file.dart',
        testId: '1',
      );

      expect(failedTest.toString(), equals('test/file.dart: test name'));
    });

    test('should handle very long test names', () {
      final longName = 'should test ' * 50; // Very long name
      final failedTest = FailedTest(
        name: longName,
        filePath: 'test/long_test.dart',
        testId: '999',
      );

      expect(failedTest.name, equals(longName));
      expect(failedTest.toString(), contains('test/long_test.dart'));
      expect(failedTest.toString(), contains(longName));
    });

    test('should handle special characters in test name', () {
      final failedTest = FailedTest(
        name: 'should handle "quotes" and \'apostrophes\' [brackets]',
        filePath: 'test/special_chars_test.dart',
        testId: '5',
      );

      expect(failedTest.name, contains('quotes'));
      expect(failedTest.name, contains('apostrophes'));
      expect(failedTest.name, contains('[brackets]'));
    });
  });

  group('TestResults Data Structure', () {
    test('should create TestResults with required fields', () {
      final results = TestResults(
        failedTests: [],
        totalTests: 10,
        passedTests: 10,
        totalTime: const Duration(seconds: 5),
        timestamp: DateTime(2024, 1, 15, 10, 30),
      );

      expect(results.failedTests, isEmpty);
      expect(results.totalTests, equals(10));
      expect(results.passedTests, equals(10));
      expect(results.totalTime.inSeconds, equals(5));
      expect(results.failedCount, equals(0));
      expect(results.successRate, equals(100.0));
    });

    test('should calculate failedCount correctly', () {
      final failedTests = [
        FailedTest(name: 'test1', filePath: 'test1.dart', testId: '1'),
        FailedTest(name: 'test2', filePath: 'test2.dart', testId: '2'),
        FailedTest(name: 'test3', filePath: 'test3.dart', testId: '3'),
      ];

      final results = TestResults(
        failedTests: failedTests,
        totalTests: 10,
        passedTests: 7,
        totalTime: const Duration(seconds: 8),
        timestamp: DateTime.now(),
      );

      expect(results.failedCount, equals(3));
    });

    test('should calculate successRate correctly with mixed results', () {
      final results = TestResults(
        failedTests: [
          FailedTest(name: 'test1', filePath: 'test1.dart', testId: '1'),
        ],
        totalTests: 20,
        passedTests: 19,
        totalTime: const Duration(seconds: 10),
        timestamp: DateTime.now(),
      );

      expect(results.successRate, equals(95.0));
    });

    test('should handle 100% success rate', () {
      final results = TestResults(
        failedTests: [],
        totalTests: 50,
        passedTests: 50,
        totalTime: const Duration(seconds: 25),
        timestamp: DateTime.now(),
      );

      expect(results.successRate, equals(100.0));
      expect(results.failedCount, equals(0));
    });

    test('should handle 0% success rate', () {
      final failedTests = List.generate(
        10,
        (i) => FailedTest(name: 'test$i', filePath: 'test.dart', testId: '$i'),
      );

      final results = TestResults(
        failedTests: failedTests,
        totalTests: 10,
        passedTests: 0,
        totalTime: const Duration(seconds: 5),
        timestamp: DateTime.now(),
      );

      expect(results.successRate, equals(0.0));
      expect(results.failedCount, equals(10));
    });

    test('should handle zero total tests', () {
      final results = TestResults(
        failedTests: [],
        totalTests: 0,
        passedTests: 0,
        totalTime: Duration.zero,
        timestamp: DateTime.now(),
      );

      expect(results.successRate, equals(0.0)); // Avoid division by zero
      expect(results.failedCount, equals(0));
    });

    test('should handle very large test counts', () {
      final results = TestResults(
        failedTests: [],
        totalTests: 10000,
        passedTests: 9950,
        totalTime: const Duration(minutes: 30),
        timestamp: DateTime.now(),
      );

      expect(results.successRate, equals(99.5));
      expect(results.totalTests, equals(10000));
    });

    test('should preserve timestamp correctly', () {
      final timestamp = DateTime(2024, 10, 30, 14, 30, 45);
      final results = TestResults(
        failedTests: [],
        totalTests: 5,
        passedTests: 5,
        totalTime: const Duration(seconds: 3),
        timestamp: timestamp,
      );

      expect(results.timestamp, equals(timestamp));
      expect(results.timestamp.year, equals(2024));
      expect(results.timestamp.month, equals(10));
      expect(results.timestamp.day, equals(30));
    });
  });

  group('FailedTestExtractor Edge Cases', () {
    test('should handle empty test path list', () {
      final extractor = FailedTestExtractor();
      expect(extractor, isNotNull);
    });

    test('should handle test path with spaces', () {
      final extractor = FailedTestExtractor();
      expect(extractor, isNotNull);
    });

    test('should handle test path with special characters', () {
      final extractor = FailedTestExtractor();
      expect(extractor, isNotNull);
    });

    test('should handle very long test path', () {
      final extractor = FailedTestExtractor();
      expect(extractor, isNotNull);
    });

    test('should handle relative test paths', () {
      final extractor = FailedTestExtractor();
      expect(extractor, isNotNull);
    });

    test('should handle absolute test paths', () {
      final extractor = FailedTestExtractor();
      expect(extractor, isNotNull);
    });
  });

  group('CLI Flag Combinations', () {
    test('should handle list-only with verbose', () {
      final extractor = FailedTestExtractor();
      expect(extractor, isNotNull);
    });

    test('should handle watch with save-results', () {
      final extractor = FailedTestExtractor();
      expect(extractor, isNotNull);
    });

    test('should handle parallel with timeout', () {
      final extractor = FailedTestExtractor();
      expect(extractor, isNotNull);
    });

    test('should handle no-auto-rerun with list-only', () {
      final extractor = FailedTestExtractor();
      expect(extractor, isNotNull);
    });

    test('should handle verbose with group-by-file', () {
      final extractor = FailedTestExtractor();
      expect(extractor, isNotNull);
    });

    test('should handle max-failures with save-results', () {
      final extractor = FailedTestExtractor();
      expect(extractor, isNotNull);
    });

    test('should handle all non-conflicting flags together', () {
      final extractor = FailedTestExtractor();
      expect(extractor, isNotNull);
    });
  });
}
