/// Tests for failed_test_extractor advanced scenarios and edge cases
///
/// This test file covers complex test failure patterns, edge cases,
/// and advanced configuration scenarios for the failed test extractor.

import 'package:test/test.dart';
import 'package:test_reporter/src/bin/extract_failures_lib.dart';

void main() {
  group('Complex FailedTest Scenarios', () {
    test('should handle test with extremely long name', () {
      final longName = 'should test ' * 100; // Very long test name
      final failedTest = FailedTest(
        name: longName,
        filePath: 'test/long_test.dart',
        testId: '1',
      );

      expect(failedTest.name.length, greaterThan(1000));
      expect(failedTest.toString(), contains('test/long_test.dart'));
    });

    test('should handle test with multi-line error message', () {
      final multiLineError = '''
Expected: 42
  Actual: 43
   Which: differs by 1

Stack trace:
  at test.dart:15:7
''';

      final failedTest = FailedTest(
        name: 'should validate calculation',
        filePath: 'test/math_test.dart',
        testId: '1',
        error: multiLineError,
      );

      expect(failedTest.error, contains('\n'));
      expect(failedTest.error, contains('Expected'));
      expect(failedTest.error, contains('Stack trace'));
    });

    test('should handle test with nested group path', () {
      final failedTest = FailedTest(
        name: 'should handle edge case',
        filePath: 'test/integration/auth/login_test.dart',
        testId: '42',
        group: 'Auth > Login > Edge Cases',
      );

      expect(failedTest.group, contains('>'));
      expect(failedTest.filePath, contains('integration'));
    });

    test('should handle test with special characters in name', () {
      final failedTest = FailedTest(
        name: 'should handle "quotes", \'apostrophes\', and [brackets]',
        filePath: 'test/special_test.dart',
        testId: '1',
      );

      expect(failedTest.name, contains('"'));
      expect(failedTest.name, contains("'"));
      expect(failedTest.name, contains('['));
    });

    test('should handle test with Unicode in name', () {
      final failedTest = FailedTest(
        name: 'should handle café and 🚀 emoji',
        filePath: 'test/unicode_test.dart',
        testId: '1',
      );

      expect(failedTest.name, contains('café'));
      expect(failedTest.name, contains('🚀'));
    });

    test('should handle test with very long stack trace', () {
      final longStackTrace = List.generate(
        100,
        (i) => 'at file_$i.dart:$i:7',
      ).join('\n');

      final failedTest = FailedTest(
        name: 'should process data',
        filePath: 'test/data_test.dart',
        testId: '1',
        stackTrace: longStackTrace,
      );

      expect(failedTest.stackTrace!.split('\n').length, equals(100));
    });

    test('should handle test with zero runtime', () {
      final failedTest = FailedTest(
        name: 'should be instant',
        filePath: 'test/fast_test.dart',
        testId: '1',
        runtime: Duration.zero,
      );

      expect(failedTest.runtime, equals(Duration.zero));
    });

    test('should handle test with very long runtime', () {
      final failedTest = FailedTest(
        name: 'should take forever',
        filePath: 'test/slow_test.dart',
        testId: '1',
        runtime: const Duration(hours: 1),
      );

      expect(failedTest.runtime!.inHours, equals(1));
    });
  });

  group('Complex TestResults Scenarios', () {
    test('should handle results with all tests failed', () {
      final failedTests = List.generate(
        50,
        (i) => FailedTest(
          name: 'test $i',
          filePath: 'test/file_$i.dart',
          testId: '$i',
        ),
      );

      final results = TestResults(
        failedTests: failedTests,
        totalTests: 50,
        passedTests: 0,
        totalTime: const Duration(seconds: 100),
        timestamp: DateTime.now(),
      );

      expect(results.failedCount, equals(50));
      expect(results.successRate, equals(0.0));
    });

    test('should handle results with very large test count', () {
      final results = TestResults(
        failedTests: [],
        totalTests: 100000,
        passedTests: 99999,
        totalTime: const Duration(hours: 5),
        timestamp: DateTime.now(),
      );

      expect(results.totalTests, equals(100000));
      expect(results.successRate, closeTo(99.999, 0.001));
    });

    test('should handle results with fractional success rate', () {
      final results = TestResults(
        failedTests: [
          FailedTest(name: 'test1', filePath: 'test.dart', testId: '1'),
        ],
        totalTests: 3,
        passedTests: 2,
        totalTime: const Duration(seconds: 5),
        timestamp: DateTime.now(),
      );

      expect(results.successRate, closeTo(66.666, 0.01));
    });

    test('should handle results with zero total time', () {
      final results = TestResults(
        failedTests: [],
        totalTests: 10,
        passedTests: 10,
        totalTime: Duration.zero,
        timestamp: DateTime.now(),
      );

      expect(results.totalTime, equals(Duration.zero));
    });

    test('should handle results with very old timestamp', () {
      final oldDate = DateTime(2000, 1, 1);
      final results = TestResults(
        failedTests: [],
        totalTests: 5,
        passedTests: 5,
        totalTime: const Duration(seconds: 3),
        timestamp: oldDate,
      );

      expect(results.timestamp.year, equals(2000));
    });

    test('should handle results with future timestamp', () {
      final futureDate = DateTime(2030, 12, 31);
      final results = TestResults(
        failedTests: [],
        totalTests: 5,
        passedTests: 5,
        totalTime: const Duration(seconds: 3),
        timestamp: futureDate,
      );

      expect(results.timestamp.year, equals(2030));
    });
  });

  group('FailedTest Edge Cases', () {
    test('should handle empty test name', () {
      final failedTest = FailedTest(
        name: '',
        filePath: 'test/empty_test.dart',
        testId: '1',
      );

      expect(failedTest.name, equals(''));
      expect(failedTest.toString(), contains('test/empty_test.dart'));
    });

    test('should handle empty file path', () {
      final failedTest = FailedTest(
        name: 'should do something',
        filePath: '',
        testId: '1',
      );

      expect(failedTest.filePath, equals(''));
    });

    test('should handle numeric test ID', () {
      final failedTest = FailedTest(
        name: 'test',
        filePath: 'test.dart',
        testId: '999999',
      );

      expect(failedTest.testId, equals('999999'));
    });

    test('should handle alphanumeric test ID', () {
      final failedTest = FailedTest(
        name: 'test',
        filePath: 'test.dart',
        testId: 'test-123-abc',
      );

      expect(failedTest.testId, equals('test-123-abc'));
    });

    test('should handle empty group', () {
      final failedTest = FailedTest(
        name: 'test',
        filePath: 'test.dart',
        testId: '1',
        group: '',
      );

      expect(failedTest.group, equals(''));
    });

    test('should handle empty error message', () {
      final failedTest = FailedTest(
        name: 'test',
        filePath: 'test.dart',
        testId: '1',
        error: '',
      );

      expect(failedTest.error, equals(''));
    });

    test('should handle empty stack trace', () {
      final failedTest = FailedTest(
        name: 'test',
        filePath: 'test.dart',
        testId: '1',
        stackTrace: '',
      );

      expect(failedTest.stackTrace, equals(''));
    });
  });

  group('TestResults Edge Cases', () {
    test('should handle mismatched counts (more failures than total)', () {
      // This should not happen but testing resilience
      final failedTests = List.generate(
        10,
        (i) => FailedTest(name: 'test$i', filePath: 'test.dart', testId: '$i'),
      );

      final results = TestResults(
        failedTests: failedTests,
        totalTests: 5, // Less than failed count
        passedTests: 0,
        totalTime: const Duration(seconds: 5),
        timestamp: DateTime.now(),
      );

      expect(results.failedCount, equals(10));
      expect(results.totalTests, equals(5));
    });

    test('should handle passed tests greater than total', () {
      final results = TestResults(
        failedTests: [],
        totalTests: 5,
        passedTests: 10, // More than total
        totalTime: const Duration(seconds: 5),
        timestamp: DateTime.now(),
      );

      expect(results.passedTests, equals(10));
      expect(results.totalTests, equals(5));
    });

    test('should handle negative total tests', () {
      final results = TestResults(
        failedTests: [],
        totalTests: -5,
        passedTests: 0,
        totalTime: const Duration(seconds: 5),
        timestamp: DateTime.now(),
      );

      expect(results.totalTests, equals(-5));
      expect(results.successRate, equals(0.0)); // Avoid division by zero
    });

    test('should handle negative passed tests', () {
      final results = TestResults(
        failedTests: [],
        totalTests: 10,
        passedTests: -5,
        totalTime: const Duration(seconds: 5),
        timestamp: DateTime.now(),
      );

      expect(results.passedTests, equals(-5));
    });
  });

  group('Complex File Paths', () {
    test('should handle Windows absolute path', () {
      final failedTest = FailedTest(
        name: 'test',
        filePath: r'C:\Users\Developer\project\test\auth_test.dart',
        testId: '1',
      );

      expect(failedTest.filePath, contains(r'C:\'));
    });

    test('should handle Unix absolute path', () {
      final failedTest = FailedTest(
        name: 'test',
        filePath: '/home/developer/project/test/auth_test.dart',
        testId: '1',
      );

      expect(failedTest.filePath, startsWith('/'));
    });

    test('should handle relative path with parent references', () {
      final failedTest = FailedTest(
        name: 'test',
        filePath: '../../test/auth_test.dart',
        testId: '1',
      );

      expect(failedTest.filePath, contains('..'));
    });

    test('should handle path with spaces', () {
      final failedTest = FailedTest(
        name: 'test',
        filePath: 'test/my test folder/auth_test.dart',
        testId: '1',
      );

      expect(failedTest.filePath, contains(' '));
    });

    test('should handle path with special characters', () {
      final failedTest = FailedTest(
        name: 'test',
        filePath: r'test/@scope/package-v2.0/test_file.dart',
        testId: '1',
      );

      expect(failedTest.filePath, contains('@'));
      expect(failedTest.filePath, contains('-'));
    });

    test('should handle deeply nested path', () {
      final failedTest = FailedTest(
        name: 'test',
        filePath: 'test/a/b/c/d/e/f/g/h/i/j/test.dart',
        testId: '1',
      );

      expect(failedTest.filePath.split('/').length, greaterThan(10));
    });
  });

  group('Runtime Duration Edge Cases', () {
    test('should handle microsecond precision', () {
      final failedTest = FailedTest(
        name: 'test',
        filePath: 'test.dart',
        testId: '1',
        runtime: const Duration(microseconds: 123),
      );

      expect(failedTest.runtime!.inMicroseconds, equals(123));
    });

    test('should handle very long duration', () {
      final failedTest = FailedTest(
        name: 'test',
        filePath: 'test.dart',
        testId: '1',
        runtime: const Duration(days: 365),
      );

      expect(failedTest.runtime!.inDays, equals(365));
    });

    test('should handle fractional seconds', () {
      final failedTest = FailedTest(
        name: 'test',
        filePath: 'test.dart',
        testId: '1',
        runtime: const Duration(milliseconds: 1500),
      );

      expect(failedTest.runtime!.inMilliseconds, equals(1500));
    });
  });

  group('Error Message Patterns', () {
    test('should handle assertion error format', () {
      final error = "Expected: <42>\n  Actual: <43>";
      final failedTest = FailedTest(
        name: 'test',
        filePath: 'test.dart',
        testId: '1',
        error: error,
      );

      expect(failedTest.error, contains('Expected'));
      expect(failedTest.error, contains('Actual'));
    });

    test('should handle exception error format', () {
      final error = 'Unhandled exception:\nNullPointerException: null';
      final failedTest = FailedTest(
        name: 'test',
        filePath: 'test.dart',
        testId: '1',
        error: error,
      );

      expect(failedTest.error, contains('exception'));
    });

    test('should handle timeout error', () {
      final error = 'Test timed out after 30 seconds';
      final failedTest = FailedTest(
        name: 'test',
        filePath: 'test.dart',
        testId: '1',
        error: error,
      );

      expect(failedTest.error, contains('timed out'));
    });

    test('should handle very long error message', () {
      final error = 'Error: ' + ('x' * 10000);
      final failedTest = FailedTest(
        name: 'test',
        filePath: 'test.dart',
        testId: '1',
        error: error,
      );

      expect(failedTest.error!.length, greaterThan(10000));
    });
  });

  group('Stack Trace Patterns', () {
    test('should handle single-line stack trace', () {
      final failedTest = FailedTest(
        name: 'test',
        filePath: 'test.dart',
        testId: '1',
        stackTrace: 'at test.dart:15:7',
      );

      expect(failedTest.stackTrace, contains(':15:'));
    });

    test('should handle multi-file stack trace', () {
      final stackTrace = '''
at test_file.dart:15:7
at helper.dart:42:3
at main.dart:10:5
''';
      final failedTest = FailedTest(
        name: 'test',
        filePath: 'test.dart',
        testId: '1',
        stackTrace: stackTrace,
      );

      expect(failedTest.stackTrace!.split('\n').length, greaterThan(2));
    });

    test('should handle stack trace with package references', () {
      final stackTrace = 'at package:test_reporter/src/helper.dart:42:3';
      final failedTest = FailedTest(
        name: 'test',
        filePath: 'test.dart',
        testId: '1',
        stackTrace: stackTrace,
      );

      expect(failedTest.stackTrace, contains('package:'));
    });
  });

  group('Success Rate Calculations', () {
    test('should calculate exact percentages', () {
      final results = TestResults(
        failedTests: [
          FailedTest(name: 'test', filePath: 'test.dart', testId: '1'),
        ],
        totalTests: 4,
        passedTests: 3,
        totalTime: const Duration(seconds: 5),
        timestamp: DateTime.now(),
      );

      expect(results.successRate, equals(75.0));
    });

    test('should handle one-third success rate', () {
      final results = TestResults(
        failedTests: [
          FailedTest(name: 'test1', filePath: 'test.dart', testId: '1'),
          FailedTest(name: 'test2', filePath: 'test.dart', testId: '2'),
        ],
        totalTests: 3,
        passedTests: 1,
        totalTime: const Duration(seconds: 5),
        timestamp: DateTime.now(),
      );

      expect(results.successRate, closeTo(33.333, 0.01));
    });

    test('should handle very small success rate', () {
      final results = TestResults(
        failedTests: List.generate(
          99,
          (i) =>
              FailedTest(name: 'test$i', filePath: 'test.dart', testId: '$i'),
        ),
        totalTests: 100,
        passedTests: 1,
        totalTime: const Duration(seconds: 50),
        timestamp: DateTime.now(),
      );

      expect(results.successRate, equals(1.0));
    });
  });

  group('Watch Mode Configuration', () {
    test('should create extractor for watch mode operations', () {
      final extractor = FailedTestExtractor();
      expect(extractor, isNotNull);
    });

    test('should support watch mode with auto-rerun', () {
      // Watch mode is tested through integration tests
      // This test verifies the extractor can be instantiated
      // which is required for watch mode functionality
      final extractor = FailedTestExtractor();
      expect(extractor, isA<FailedTestExtractor>());
    });
  });
}
