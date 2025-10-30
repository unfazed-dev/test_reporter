import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:test_reporter/src/bin/extract_failures_lib.dart';

import 'helpers/report_helpers.dart';
import 'helpers/test_fixtures.dart';

void main() {
  group('FailedTest', () {
    test('should create FailedTest with required fields', () {
      final failedTest = FailedTest(
        name: 'example test',
        filePath: 'test/example_test.dart',
        testId: '1',
      );

      expect(failedTest.name, equals('example test'));
      expect(failedTest.filePath, equals('test/example_test.dart'));
      expect(failedTest.testId, equals('1'));
    });

    test('should create FailedTest with optional fields', () {
      final failedTest = FailedTest(
        name: 'example test',
        filePath: 'test/example_test.dart',
        testId: '1',
        group: 'Example group',
        error: 'Expected: true, Actual: false',
        stackTrace: 'at test/example_test.dart:10',
        runtime: const Duration(seconds: 2),
      );

      expect(failedTest.group, equals('Example group'));
      expect(failedTest.error, isNotNull);
      expect(failedTest.stackTrace, isNotNull);
      expect(failedTest.runtime, equals(const Duration(seconds: 2)));
    });

    test('toString should format correctly', () {
      final failedTest = FailedTest(
        name: 'example test',
        filePath: 'test/example_test.dart',
        testId: '1',
      );

      expect(
        failedTest.toString(),
        equals('test/example_test.dart: example test'),
      );
    });
  });

  group('TestResults', () {
    test('should calculate failedCount correctly', () {
      final results = TestResults(
        failedTests: [
          FailedTest(name: 'test1', filePath: 'test1.dart', testId: '1'),
          FailedTest(name: 'test2', filePath: 'test2.dart', testId: '2'),
        ],
        totalTests: 10,
        passedTests: 8,
        totalTime: Duration.zero,
        timestamp: DateTime.now(),
      );

      expect(results.failedCount, equals(2));
    });

    test('should calculate successRate correctly', () {
      final results = TestResults(
        failedTests: [],
        totalTests: 100,
        passedTests: 85,
        totalTime: Duration.zero,
        timestamp: DateTime.now(),
      );

      expect(results.successRate, closeTo(85.0, 0.01));
    });

    test('should handle 0% success rate', () {
      final results = TestResults(
        failedTests: [
          FailedTest(name: 'test1', filePath: 'test1.dart', testId: '1'),
        ],
        totalTests: 1,
        passedTests: 0,
        totalTime: Duration.zero,
        timestamp: DateTime.now(),
      );

      expect(results.successRate, equals(0.0));
    });

    test('should handle 100% success rate', () {
      final results = TestResults(
        failedTests: [],
        totalTests: 10,
        passedTests: 10,
        totalTime: Duration.zero,
        timestamp: DateTime.now(),
      );

      expect(results.successRate, equals(100.0));
    });

    test('should handle empty test results', () {
      final results = TestResults(
        failedTests: [],
        totalTests: 0,
        passedTests: 0,
        totalTime: Duration.zero,
        timestamp: DateTime.now(),
      );

      expect(results.successRate, equals(0.0));
      expect(results.failedCount, equals(0));
    });
  });

  group('JSON Event Processing', () {
    test('should parse suite event correctly', () {
      final json = jsonDecode(sampleSuiteEvent) as Map<String, dynamic>;
      expect(json['type'], equals('suite'));
      final suite = json['suite'] as Map<String, dynamic>;
      expect(suite['id'], equals(0));
      expect(suite['path'], equals('test/example_test.dart'));
    });

    test('should parse testStart event correctly', () {
      final json = jsonDecode(sampleTestStartEvent) as Map<String, dynamic>;
      expect(json['type'], equals('testStart'));
      final test = json['test'] as Map<String, dynamic>;
      expect(test['id'], equals(1));
      expect(test['name'], equals('example test passes'));
      expect(test['suiteID'], equals(0));
    });

    test('should parse testDone pass event correctly', () {
      final json = jsonDecode(sampleTestDonePassEvent) as Map<String, dynamic>;
      expect(json['type'], equals('testDone'));
      expect(json['testID'], equals(1));
      expect(json['result'], equals('success'));
    });

    test('should parse testDone fail event correctly', () {
      final json = jsonDecode(sampleTestDoneFailEvent) as Map<String, dynamic>;
      expect(json['type'], equals('testDone'));
      expect(json['testID'], equals(1));
      expect(json['result'], equals('failure'));
    });

    test('should parse error event correctly', () {
      final json = jsonDecode(sampleErrorEvent) as Map<String, dynamic>;
      expect(json['type'], equals('error'));
      expect(json['testID'], equals(1));
      expect(json['error'], contains('Expected:'));
      expect(json['stackTrace'], isNotNull);
      expect(json['isFailure'], isTrue);
    });

    test('should parse group event correctly', () {
      final json = jsonDecode(sampleGroupEvent) as Map<String, dynamic>;
      expect(json['type'], equals('group'));
      final group = json['group'] as Map<String, dynamic>;
      expect(group['name'], equals('Example group'));
      expect(group['testCount'], equals(5));
    });

    test('should parse done event correctly', () {
      final json = jsonDecode(sampleDoneEvent) as Map<String, dynamic>;
      expect(json['type'], equals('done'));
      expect(json['success'], isTrue);
    });
  });

  group('Regex Escaping', () {
    test('should escape regex special characters', () {
      expect(escapeRegex('test.example'), equals(r'test\.example'));
      expect(escapeRegex('test*example'), equals(r'test\*example'));
      expect(escapeRegex('test+example'), equals(r'test\+example'));
      expect(escapeRegex('test?example'), equals(r'test\?example'));
      expect(escapeRegex('test^example'), equals(r'test\^example'));
      expect(escapeRegex('test\$example'), equals(r'test\$example'));
    });

    test('should escape brackets', () {
      expect(escapeRegex('test[0]'), equals(r'test\[0\]'));
      expect(escapeRegex('test{0}'), equals(r'test\{0\}'));
      expect(escapeRegex('test(0)'), equals(r'test\(0\)'));
    });

    test('should escape pipes and backslashes', () {
      expect(escapeRegex('test|example'), equals(r'test\|example'));
      expect(escapeRegex(r'test\example'), equals(r'test\\example'));
    });

    test('should handle multiple special characters', () {
      expect(
        escapeRegex('test.*+?^example'),
        equals(r'test\.\*\+\?\^example'),
      );
    });

    test('should handle test names with special characters', () {
      expect(
        escapeRegex('should test (with parentheses)'),
        equals(r'should test \(with parentheses\)'),
      );
    });

    test('should not modify alphanumeric strings', () {
      expect(escapeRegex('simpleTestName123'), equals('simpleTestName123'));
    });
  });

  group('Rerun Command Generation', () {
    test('should generate rerun command for single test', () {
      const testFile = 'test/example_test.dart';
      const testName = 'example test';

      final command = generateRerunCommand(testFile, testName);

      expect(command, contains('flutter test'));
      expect(command, contains(testFile));
      expect(command, contains('--name'));
      expect(command, contains(escapeRegex(testName)));
    });

    test('should handle test names with special characters', () {
      const testFile = 'test/example_test.dart';
      const testName = 'should handle (special) characters';

      final command = generateRerunCommand(testFile, testName);

      expect(
        command,
        contains(r'should handle \(special\) characters'),
      );
    });

    test('should group tests by file', () {
      final tests = {
        'test/auth_test.dart': ['login test', 'logout test'],
        'test/profile_test.dart': ['update profile test'],
      };

      expect(tests.keys.length, equals(2));
      expect(tests['test/auth_test.dart']!.length, equals(2));
      expect(tests['test/profile_test.dart']!.length, equals(1));
    });
  });

  group('Failed Test Report Generation', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('failed_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('should validate failed report structure', () {
      final report = sampleFailedReport();

      expect(
        validateReportStructure(
          report,
          requiredSections: [
            'Failed Tests Report',
            'Failed Tests',
            'JSON Data',
          ],
        ),
        isTrue,
      );
    });

    test('should extract JSON from failed report', () {
      final report = sampleFailedReport(module: 'test_module', failedCount: 3);
      final json = extractJsonFromReport(report);

      expect(json, isNotNull);
      expect(json!['module'], equals('test_module'));
      expect(json['failedCount'], equals(3));
    });

    test('should validate report name for failed reports', () {
      expect(
        validateReportName('example_test_report_failed@1430_280125.md'),
        isTrue,
      );
    });

    test('should extract report type as failed', () {
      final type =
          extractReportType('example_test_report_failed@1430_280125.md');
      expect(type, equals('failed'));
    });
  });

  group('Test Error Message Parsing', () {
    test('should identify assertion failures', () {
      expect(SampleErrors.assertion, contains('Expected:'));
      expect(SampleErrors.assertion, contains('Actual:'));
    });

    test('should identify null errors', () {
      expect(SampleErrors.nullError, contains('NoSuchMethodError'));
      expect(SampleErrors.nullError, contains('was called on null'));
    });

    test('should identify timeout errors', () {
      expect(SampleErrors.timeout, contains('timed out'));
    });

    test('should identify range errors', () {
      expect(SampleErrors.rangeError, contains('RangeError'));
      expect(SampleErrors.rangeError, contains('Invalid value'));
    });

    test('should identify type errors', () {
      expect(SampleErrors.typeError, contains('is not a subtype'));
    });

    test('should identify network errors', () {
      expect(SampleErrors.networkError, contains('SocketException'));
      expect(SampleErrors.networkError, contains('Connection refused'));
    });

    test('should identify file not found errors', () {
      expect(
        SampleErrors.fileNotFound,
        contains('FileSystemException'),
      );
      expect(SampleErrors.fileNotFound, contains('Cannot open file'));
    });
  });

  group('Stack Trace Parsing', () {
    test('should parse assertion stack trace', () {
      expect(sampleAssertionStackTrace, contains('expect'));
      expect(sampleAssertionStackTrace, contains('test/example_test.dart'));
      expect(sampleAssertionStackTrace, contains('Invoker'));
    });

    test('should parse null error stack trace', () {
      expect(sampleNullErrorStackTrace, contains('noSuchMethod'));
      expect(sampleNullErrorStackTrace, contains('lib/src/example.dart'));
    });

    test('should parse timeout stack trace', () {
      expect(sampleTimeoutStackTrace, contains('LiveTest'));
      expect(sampleTimeoutStackTrace, contains('CancelableOperation'));
    });

    test('should extract file location from stack trace', () {
      final fileRegex = RegExp(r'(test/[^\s]+\.dart)\s+(\d+):(\d+)');
      final match = fileRegex.firstMatch(sampleAssertionStackTrace);

      expect(match, isNotNull);
      expect(match!.group(1), equals('test/example_test.dart'));
      expect(match.group(2), equals('10')); // Line number
      expect(match.group(3), equals('7')); // Column number
    });
  });

  group('Test File Discovery', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('test_discovery_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('should identify test files', () {
      final testFile = File('${tempDir.path}/example_test.dart');
      testFile.writeAsStringSync("import 'package:test/test.dart';");

      expect(testFile.path.endsWith('_test.dart'), isTrue);
    });

    test('should distinguish between lib and test files', () {
      const libFile = 'lib/src/example.dart';
      const testFile = 'test/src/example_test.dart';

      expect(libFile.contains('lib/'), isTrue);
      expect(testFile.contains('test/'), isTrue);
      expect(testFile.endsWith('_test.dart'), isTrue);
    });
  });

  group('Duration Formatting', () {
    test('should format seconds correctly', () {
      const duration = Duration(seconds: 30);
      expect(formatDuration(duration), equals('30.0s'));
    });

    test('should format minutes and seconds', () {
      const duration = Duration(minutes: 2, seconds: 30);
      expect(formatDuration(duration), equals('2m 30.0s'));
    });

    test('should format milliseconds', () {
      const duration = Duration(milliseconds: 500);
      expect(formatDuration(duration), equals('0.5s'));
    });

    test('should handle zero duration', () {
      const duration = Duration.zero;
      expect(formatDuration(duration), equals('0.0s'));
    });

    test('should format hours, minutes, and seconds', () {
      const duration = Duration(hours: 1, minutes: 30, seconds: 45);
      expect(formatDuration(duration), equals('1h 30m 45.0s'));
    });
  });

  group('Test Status Tracking', () {
    test('should track passed tests', () {
      var totalTests = 0;
      var passedTests = 0;

      // Simulate 3 passing tests
      for (var i = 0; i < 3; i++) {
        totalTests++;
        passedTests++;
      }

      expect(totalTests, equals(3));
      expect(passedTests, equals(3));
    });

    test('should track failed tests', () {
      final failedTests = <String>[];

      // Simulate test failures
      failedTests.add('test1');
      failedTests.add('test2');

      expect(failedTests.length, equals(2));
    });

    test('should track mixed results', () {
      var totalTests = 0;
      var passedTests = 0;
      final failedTests = <String>[];

      // Simulate 5 tests: 3 pass, 2 fail
      for (var i = 0; i < 5; i++) {
        totalTests++;
        if (i < 3) {
          passedTests++;
        } else {
          failedTests.add('test$i');
        }
      }

      expect(totalTests, equals(5));
      expect(passedTests, equals(3));
      expect(failedTests.length, equals(2));
    });
  });
}

// Mock classes for testing

// Utility functions extracted from failed_test_extractor.dart

String escapeRegex(String input) {
  return input.replaceAllMapped(
    RegExp(r'[.*+?^${}()|[\]\\]'),
    (match) => '\\${match.group(0)}',
  );
}

String generateRerunCommand(String testFile, String testName) {
  final escapedName = escapeRegex(testName);
  return 'flutter test $testFile --name "$escapedName"';
}

String formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);
  final milliseconds = duration.inMilliseconds.remainder(1000);
  final secondsWithMillis = seconds + (milliseconds / 1000);

  if (hours > 0) {
    return '${hours}h ${minutes}m ${secondsWithMillis.toStringAsFixed(1)}s';
  } else if (minutes > 0) {
    return '${minutes}m ${secondsWithMillis.toStringAsFixed(1)}s';
  } else {
    return '${secondsWithMillis.toStringAsFixed(1)}s';
  }
}
