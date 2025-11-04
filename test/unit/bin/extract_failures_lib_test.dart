/// Tests for extract_failures_lib.dart - Failed Test Extractor
///
/// Coverage Target: 100% (791/791 lines)
/// Test Strategy: Unit tests for data classes, integration tests for extractor
/// TDD Approach: 🔴 RED → 🟢 GREEN → ♻️ REFACTOR
///
/// NOTE: The FailedTestExtractor class has mostly private methods and relies on
/// Process.start() for execution, making it difficult to unit test without mocking.
/// Full coverage requires integration tests with actual test execution.
/// This file focuses on thoroughly testing the public data classes.

import 'package:test/test.dart';
import 'package:test_reporter/src/bin/extract_failures_lib.dart';

void main() {
  group('FailedTest', () {
    group('Construction and Properties', () {
      test('should create FailedTest with all required fields', () {
        final failedTest = FailedTest(
          name: 'should validate user input',
          filePath: 'test/auth_test.dart',
          testId: '1',
          group: 'Authentication',
          error: 'Expected: <true>\n  Actual: <false>',
          stackTrace: 'package:test_reporter/test/auth_test.dart 42:7',
          runtime: const Duration(milliseconds: 150),
        );

        expect(failedTest.name, equals('should validate user input'));
        expect(failedTest.filePath, equals('test/auth_test.dart'));
        expect(failedTest.testId, equals('1'));
        expect(failedTest.group, equals('Authentication'));
        expect(failedTest.error, contains('Expected: <true>'));
        expect(failedTest.stackTrace, contains('auth_test.dart 42:7'));
        expect(failedTest.runtime, equals(const Duration(milliseconds: 150)));
      });

      test('should create FailedTest with only required fields', () {
        final failedTest = FailedTest(
          name: 'basic test',
          filePath: 'test/simple_test.dart',
          testId: '2',
        );

        expect(failedTest.name, equals('basic test'));
        expect(failedTest.filePath, equals('test/simple_test.dart'));
        expect(failedTest.testId, equals('2'));
        expect(failedTest.group, isNull);
        expect(failedTest.error, isNull);
        expect(failedTest.stackTrace, isNull);
        expect(failedTest.runtime, isNull);
      });

      test('should create FailedTest with partial optional fields', () {
        final failedTest = FailedTest(
          name: 'test with error',
          filePath: 'test/file.dart',
          testId: '3',
          error: 'Something went wrong',
        );

        expect(failedTest.name, equals('test with error'));
        expect(failedTest.error, equals('Something went wrong'));
        expect(failedTest.group, isNull);
        expect(failedTest.stackTrace, isNull);
        expect(failedTest.runtime, isNull);
      });

      test('toString should return formatted string with file and name', () {
        final failedTest = FailedTest(
          name: 'test name',
          filePath: 'test/example_test.dart',
          testId: '3',
        );

        expect(
          failedTest.toString(),
          equals('test/example_test.dart: test name'),
        );
      });

      test('toString should work with long file paths', () {
        final failedTest = FailedTest(
          name: 'my test',
          filePath: 'test/integration/auth/user/login_test.dart',
          testId: '4',
        );

        expect(
          failedTest.toString(),
          equals('test/integration/auth/user/login_test.dart: my test'),
        );
      });

      test('should handle very long test names', () {
        final longName = 'should validate that user authentication works '
            'correctly when providing valid credentials and the database '
            'connection is stable and all services are running properly';

        final failedTest = FailedTest(
          name: longName,
          filePath: 'test/file.dart',
          testId: '5',
        );

        expect(failedTest.name, equals(longName));
        expect(failedTest.name.length, greaterThan(100));
      });

      test('should handle very long error messages', () {
        final longError = 'Expected: <${List.filled(100, 'a').join()}>\n'
            'Actual: <${List.filled(100, 'b').join()}>';

        final failedTest = FailedTest(
          name: 'test',
          filePath: 'test/file.dart',
          testId: '6',
          error: longError,
        );

        expect(failedTest.error, equals(longError));
        expect(failedTest.error!.length, greaterThan(200));
      });

      test('should handle multiline stack traces', () {
        const stackTrace = '''
package:test_reporter/test/auth_test.dart 42:7
package:test_reporter/src/utils/validator.dart 15:3
package:flutter_test/src/binding.dart 1234:5
dart:async/zone.dart 9999:1
''';

        final failedTest = FailedTest(
          name: 'test',
          filePath: 'test/file.dart',
          testId: '7',
          stackTrace: stackTrace,
        );

        expect(failedTest.stackTrace, contains('auth_test.dart 42:7'));
        expect(failedTest.stackTrace, contains('validator.dart 15:3'));
        expect(failedTest.stackTrace, contains('binding.dart 1234:5'));
        expect(failedTest.stackTrace, contains('dart:async'));
      });

      test('should handle special characters in test name', () {
        final failedTest = FailedTest(
          name: "should handle 'quotes' and escapes (with parens)",
          filePath: 'test/file.dart',
          testId: '8',
        );

        expect(failedTest.name, contains('quotes'));
        expect(failedTest.name, contains('escapes'));
        expect(failedTest.name, contains('parens'));
      });

      test('should handle special characters in file path', () {
        final failedTest = FailedTest(
          name: 'test',
          filePath: 'test/my-component/user_test.dart',
          testId: '9',
        );

        expect(failedTest.filePath, contains('my-component'));
        expect(failedTest.toString(), contains('my-component'));
      });

      test('should handle very short runtime', () {
        final failedTest = FailedTest(
          name: 'fast test',
          filePath: 'test/file.dart',
          testId: '10',
          runtime: const Duration(milliseconds: 1),
        );

        expect(failedTest.runtime, equals(const Duration(milliseconds: 1)));
      });

      test('should handle very long runtime', () {
        final failedTest = FailedTest(
          name: 'slow test',
          filePath: 'test/file.dart',
          testId: '11',
          runtime: const Duration(minutes: 5, seconds: 30),
        );

        expect(
          failedTest.runtime,
          equals(const Duration(minutes: 5, seconds: 30)),
        );
      });

      test('should handle zero runtime', () {
        final failedTest = FailedTest(
          name: 'instant test',
          filePath: 'test/file.dart',
          testId: '12',
          runtime: Duration.zero,
        );

        expect(failedTest.runtime, equals(Duration.zero));
      });

      test('should handle empty group name', () {
        final failedTest = FailedTest(
          name: 'test',
          filePath: 'test/file.dart',
          testId: '13',
          group: '',
        );

        expect(failedTest.group, equals(''));
        expect(failedTest.group, isNotNull);
        expect(failedTest.group, isEmpty);
      });

      test('should handle empty error message', () {
        final failedTest = FailedTest(
          name: 'test',
          filePath: 'test/file.dart',
          testId: '14',
          error: '',
        );

        expect(failedTest.error, equals(''));
        expect(failedTest.error, isNotNull);
        expect(failedTest.error, isEmpty);
      });

      test('should handle Unicode characters in test name', () {
        final failedTest = FailedTest(
          name: 'should handle 日本語 and émojis 🎉',
          filePath: 'test/file.dart',
          testId: '15',
        );

        expect(failedTest.name, contains('日本語'));
        expect(failedTest.name, contains('🎉'));
      });

      test('should handle numeric test IDs', () {
        final failedTest = FailedTest(
          name: 'test',
          filePath: 'test/file.dart',
          testId: '999999',
        );

        expect(failedTest.testId, equals('999999'));
      });

      test('should handle alphanumeric test IDs', () {
        final failedTest = FailedTest(
          name: 'test',
          filePath: 'test/file.dart',
          testId: 'test-id-abc-123',
        );

        expect(failedTest.testId, equals('test-id-abc-123'));
      });
    });
  });

  group('TestResults', () {
    group('Construction and Properties', () {
      test('should create TestResults with valid data', () {
        final failedTests = [
          FailedTest(
            name: 'test 1',
            filePath: 'test/a.dart',
            testId: '1',
          ),
          FailedTest(
            name: 'test 2',
            filePath: 'test/b.dart',
            testId: '2',
          ),
        ];

        final results = TestResults(
          failedTests: failedTests,
          totalTests: 10,
          passedTests: 8,
          totalTime: const Duration(seconds: 5),
          timestamp: DateTime(2025, 1, 1, 12, 0),
        );

        expect(results.failedTests, hasLength(2));
        expect(results.failedTests[0].name, equals('test 1'));
        expect(results.failedTests[1].name, equals('test 2'));
        expect(results.totalTests, equals(10));
        expect(results.passedTests, equals(8));
        expect(results.totalTime, equals(const Duration(seconds: 5)));
        expect(results.timestamp, equals(DateTime(2025, 1, 1, 12, 0)));
      });

      test('should create TestResults with empty failed tests list', () {
        final results = TestResults(
          failedTests: [],
          totalTests: 25,
          passedTests: 25,
          totalTime: const Duration(seconds: 3),
          timestamp: DateTime.now(),
        );

        expect(results.failedTests, isEmpty);
        expect(results.failedTests, hasLength(0));
        expect(results.totalTests, equals(25));
        expect(results.passedTests, equals(25));
      });

      test('should create TestResults with single failed test', () {
        final results = TestResults(
          failedTests: [
            FailedTest(name: 'test 1', filePath: 'test/a.dart', testId: '1'),
          ],
          totalTests: 1,
          passedTests: 0,
          totalTime: const Duration(milliseconds: 500),
          timestamp: DateTime.now(),
        );

        expect(results.failedTests, hasLength(1));
        expect(results.totalTests, equals(1));
        expect(results.passedTests, equals(0));
      });

      test('should create TestResults with many failed tests', () {
        final failedTests = List.generate(
          100,
          (i) => FailedTest(
            name: 'test $i',
            filePath: 'test/file_$i.dart',
            testId: '$i',
          ),
        );

        final results = TestResults(
          failedTests: failedTests,
          totalTests: 100,
          passedTests: 0,
          totalTime: const Duration(minutes: 2),
          timestamp: DateTime.now(),
        );

        expect(results.failedTests, hasLength(100));
        expect(results.totalTests, equals(100));
        expect(results.passedTests, equals(0));
      });
    });

    group('failedCount Getter', () {
      test('should return correct count for multiple failures', () {
        final results = TestResults(
          failedTests: [
            FailedTest(name: 'test 1', filePath: 'test/a.dart', testId: '1'),
            FailedTest(name: 'test 2', filePath: 'test/b.dart', testId: '2'),
            FailedTest(name: 'test 3', filePath: 'test/c.dart', testId: '3'),
          ],
          totalTests: 10,
          passedTests: 7,
          totalTime: Duration.zero,
          timestamp: DateTime.now(),
        );

        expect(results.failedCount, equals(3));
      });

      test('should return 0 when no failures', () {
        final results = TestResults(
          failedTests: [],
          totalTests: 50,
          passedTests: 50,
          totalTime: Duration.zero,
          timestamp: DateTime.now(),
        );

        expect(results.failedCount, equals(0));
      });

      test('should return 1 for single failure', () {
        final results = TestResults(
          failedTests: [
            FailedTest(name: 'test 1', filePath: 'test/a.dart', testId: '1'),
          ],
          totalTests: 10,
          passedTests: 9,
          totalTime: Duration.zero,
          timestamp: DateTime.now(),
        );

        expect(results.failedCount, equals(1));
      });

      test('should match length of failedTests list', () {
        final failedTests = List.generate(
          25,
          (i) => FailedTest(
            name: 'test $i',
            filePath: 'test/file.dart',
            testId: '$i',
          ),
        );

        final results = TestResults(
          failedTests: failedTests,
          totalTests: 25,
          passedTests: 0,
          totalTime: Duration.zero,
          timestamp: DateTime.now(),
        );

        expect(results.failedCount, equals(failedTests.length));
        expect(results.failedCount, equals(25));
      });
    });

    group('successRate Getter', () {
      test('should calculate 85% success rate correctly', () {
        final results = TestResults(
          failedTests: List.generate(
            15,
            (i) => FailedTest(
              name: 'test $i',
              filePath: 'test/file.dart',
              testId: '$i',
            ),
          ),
          totalTests: 100,
          passedTests: 85,
          totalTime: Duration.zero,
          timestamp: DateTime.now(),
        );

        expect(results.successRate, equals(85.0));
      });

      test('should calculate 100% success rate when all pass', () {
        final results = TestResults(
          failedTests: [],
          totalTests: 50,
          passedTests: 50,
          totalTime: Duration.zero,
          timestamp: DateTime.now(),
        );

        expect(results.successRate, equals(100.0));
      });

      test('should calculate 0% success rate when all fail', () {
        final failedTests = List.generate(
          10,
          (i) => FailedTest(
            name: 'test $i',
            filePath: 'test/file.dart',
            testId: '$i',
          ),
        );

        final results = TestResults(
          failedTests: failedTests,
          totalTests: 10,
          passedTests: 0,
          totalTime: Duration.zero,
          timestamp: DateTime.now(),
        );

        expect(results.successRate, equals(0.0));
        expect(results.failedCount, equals(10));
      });

      test('should return 0 when totalTests is 0', () {
        final results = TestResults(
          failedTests: [],
          totalTests: 0,
          passedTests: 0,
          totalTime: Duration.zero,
          timestamp: DateTime.now(),
        );

        expect(results.successRate, equals(0.0));
      });

      test('should calculate 50% success rate correctly', () {
        final results = TestResults(
          failedTests: List.generate(
            5,
            (i) => FailedTest(
              name: 'test $i',
              filePath: 'test/file.dart',
              testId: '$i',
            ),
          ),
          totalTests: 10,
          passedTests: 5,
          totalTime: Duration.zero,
          timestamp: DateTime.now(),
        );

        expect(results.successRate, equals(50.0));
      });

      test('should calculate fractional success rates', () {
        final results = TestResults(
          failedTests: [
            FailedTest(name: 'test 1', filePath: 'test/file.dart', testId: '1'),
          ],
          totalTests: 3,
          passedTests: 2,
          totalTime: Duration.zero,
          timestamp: DateTime.now(),
        );

        expect(results.successRate, closeTo(66.666, 0.001));
      });

      test('should handle very low success rates', () {
        final results = TestResults(
          failedTests: List.generate(
            99,
            (i) => FailedTest(
              name: 'test $i',
              filePath: 'test/file.dart',
              testId: '$i',
            ),
          ),
          totalTests: 100,
          passedTests: 1,
          totalTime: Duration.zero,
          timestamp: DateTime.now(),
        );

        expect(results.successRate, equals(1.0));
      });

      test('should handle very high success rates', () {
        final results = TestResults(
          failedTests: [
            FailedTest(name: 'test 1', filePath: 'test/file.dart', testId: '1'),
          ],
          totalTests: 100,
          passedTests: 99,
          totalTime: Duration.zero,
          timestamp: DateTime.now(),
        );

        expect(results.successRate, equals(99.0));
      });
    });

    group('Timestamp Handling', () {
      test('should preserve exact timestamp', () {
        final exactTime = DateTime(2025, 11, 4, 15, 30, 45, 123);
        final results = TestResults(
          failedTests: [],
          totalTests: 1,
          passedTests: 1,
          totalTime: Duration.zero,
          timestamp: exactTime,
        );

        expect(results.timestamp, equals(exactTime));
        expect(results.timestamp.year, equals(2025));
        expect(results.timestamp.month, equals(11));
        expect(results.timestamp.day, equals(4));
        expect(results.timestamp.hour, equals(15));
        expect(results.timestamp.minute, equals(30));
        expect(results.timestamp.second, equals(45));
      });

      test('should handle UTC timestamps', () {
        final utcTime = DateTime.utc(2025, 1, 1, 0, 0, 0);
        final results = TestResults(
          failedTests: [],
          totalTests: 1,
          passedTests: 1,
          totalTime: Duration.zero,
          timestamp: utcTime,
        );

        expect(results.timestamp.isUtc, isTrue);
        expect(results.timestamp, equals(utcTime));
      });

      test('should handle local timestamps', () {
        final localTime = DateTime(2025, 1, 1, 12, 0, 0);
        final results = TestResults(
          failedTests: [],
          totalTests: 1,
          passedTests: 1,
          totalTime: Duration.zero,
          timestamp: localTime,
        );

        expect(results.timestamp.isUtc, isFalse);
        expect(results.timestamp, equals(localTime));
      });
    });

    group('Total Time Handling', () {
      test('should handle short durations', () {
        final results = TestResults(
          failedTests: [],
          totalTests: 1,
          passedTests: 1,
          totalTime: const Duration(milliseconds: 100),
          timestamp: DateTime.now(),
        );

        expect(results.totalTime, equals(const Duration(milliseconds: 100)));
      });

      test('should handle long durations', () {
        final results = TestResults(
          failedTests: [],
          totalTests: 1,
          passedTests: 1,
          totalTime: const Duration(hours: 2, minutes: 30, seconds: 45),
          timestamp: DateTime.now(),
        );

        expect(
          results.totalTime,
          equals(const Duration(hours: 2, minutes: 30, seconds: 45)),
        );
      });

      test('should handle zero duration', () {
        final results = TestResults(
          failedTests: [],
          totalTests: 1,
          passedTests: 1,
          totalTime: Duration.zero,
          timestamp: DateTime.now(),
        );

        expect(results.totalTime, equals(Duration.zero));
        expect(results.totalTime.inMilliseconds, equals(0));
      });
    });

    group('Edge Cases and Invariants', () {
      test('passedTests + failedCount should equal or be less than totalTests',
          () {
        final results = TestResults(
          failedTests: [
            FailedTest(name: 'test 1', filePath: 'test/a.dart', testId: '1'),
            FailedTest(name: 'test 2', filePath: 'test/b.dart', testId: '2'),
          ],
          totalTests: 10,
          passedTests: 8,
          totalTime: Duration.zero,
          timestamp: DateTime.now(),
        );

        expect(results.passedTests + results.failedCount, equals(10));
        expect(
          results.passedTests + results.failedCount,
          lessThanOrEqualTo(results.totalTests),
        );
      });

      test('failedCount should never exceed totalTests', () {
        final results = TestResults(
          failedTests: List.generate(
            5,
            (i) => FailedTest(
              name: 'test $i',
              filePath: 'test/file.dart',
              testId: '$i',
            ),
          ),
          totalTests: 10,
          passedTests: 5,
          totalTime: Duration.zero,
          timestamp: DateTime.now(),
        );

        expect(results.failedCount, lessThanOrEqualTo(results.totalTests));
      });

      test('passedTests should never exceed totalTests', () {
        final results = TestResults(
          failedTests: [],
          totalTests: 10,
          passedTests: 10,
          totalTime: Duration.zero,
          timestamp: DateTime.now(),
        );

        expect(results.passedTests, lessThanOrEqualTo(results.totalTests));
      });
    });
  });

  group('FailedTestExtractor', () {
    group('Construction', () {
      test('should create FailedTestExtractor instance', () {
        final extractor = FailedTestExtractor();
        expect(extractor, isNotNull);
        expect(extractor, isA<FailedTestExtractor>());
      });

      test('should initialize argument parser in constructor', () {
        // Parser is private, but we can verify construction succeeds
        final extractor = FailedTestExtractor();
        expect(extractor, isNotNull);
      });

      test('should support creating multiple instances', () {
        final extractor1 = FailedTestExtractor();
        final extractor2 = FailedTestExtractor();

        expect(extractor1, isNotNull);
        expect(extractor2, isNotNull);
        expect(extractor1, isNot(same(extractor2)));
      });
    });

    // NOTE: Most FailedTestExtractor methods are private and interact with
    // Process.start(), making them unsuitable for unit testing without mocking.
    // The following tests document expected behavior but are skipped pending
    // integration test implementation.

    group('Integration Tests (Pending)', () {
      test('should parse help flag and show usage', () {},
          skip: 'Requires integration test with actual process execution');

      test('should parse list-only flag', () {},
          skip: 'Requires integration test with actual process execution');

      test('should parse auto-rerun flag with default true', () {},
          skip: 'Requires integration test with actual process execution');

      test('should parse watch flag', () {},
          skip: 'Requires integration test with actual process execution');

      test('should parse save-results flag', () {},
          skip: 'Requires integration test with actual process execution');

      test('should parse verbose flag', () {},
          skip: 'Requires integration test with actual process execution');

      test('should parse group-by-file flag with default true', () {},
          skip: 'Requires integration test with actual process execution');

      test('should parse timeout option with default 120', () {},
          skip: 'Requires integration test with actual process execution');

      test('should parse parallel flag', () {},
          skip: 'Requires integration test with actual process execution');

      test('should parse max-failures option with default 0', () {},
          skip: 'Requires integration test with actual process execution');

      test('should handle JSON suite events', () {},
          skip: 'Requires integration test with actual process execution');

      test('should handle JSON testStart events', () {},
          skip: 'Requires integration test with actual process execution');

      test('should handle JSON testDone events with success', () {},
          skip: 'Requires integration test with actual process execution');

      test('should handle JSON testDone events with failure', () {},
          skip: 'Requires integration test with actual process execution');

      test('should handle JSON done events', () {},
          skip: 'Requires integration test with actual process execution');

      test('should handle JSON error events', () {},
          skip: 'Requires integration test with actual process execution');

      test('should generate rerun commands grouped by file', () {},
          skip: 'Requires integration test with actual process execution');

      test('should generate individual rerun commands', () {},
          skip: 'Requires integration test with actual process execution');

      test('should escape regex special characters in test names', () {},
          skip: 'Requires integration test with actual process execution');

      test('should save markdown and JSON reports', () {},
          skip: 'Requires integration test with actual process execution');

      test('should handle watch mode', () {},
          skip: 'Requires integration test with actual process execution');

      test('should handle auto-rerun functionality', () {},
          skip: 'Requires integration test with actual process execution');
    });
  });
}
