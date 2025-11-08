// test/integration/bin/test_analyzer_reports_test.dart
import 'package:test/test.dart';
import 'package:test_reporter/src/bin/analyze_tests_lib.dart' as lib;

/// Phase 3.4: Report Generation & Format Tests (Simplified for TDD)
///
/// Tests verify report generation in markdown and JSON formats.
/// Similar to previous phases, we test core logic directly without full mocks.
///
/// Test Coverage:
/// - Suite 1: Test Report Tests (5 tests) - markdown, JSON, sections
/// - Suite 2: Failures Report Tests (5 tests) - format, details, suggestions
/// Total: 10 tests
///
/// Methodology: 🔴🟢♻️🔄 TDD (Red-Green-Refactor-MetaTest)
void main() {
  group('Suite 1: Test Report Tests', () {
    test('should generate test report in markdown format', () {
      final analyzer = lib.TestAnalyzer();

      // Add some test data
      final testRun = lib.TestRun(
        testName: 'Sample Test',
        testFile: 'test/sample_test.dart',
      );
      testRun.addResult(1, passed: true, durationMs: 100);
      testRun.addResult(2, passed: true, durationMs: 110);
      testRun.addResult(3, passed: true, durationMs: 105);

      analyzer.testRuns['test1'] = testRun;

      // This will fail until we implement generateMarkdownReport
      final report = analyzer.generateMarkdownReport();

      expect(report, isNotNull);
      expect(report, isA<String>());
      expect(report, contains('Sample Test'));
      expect(report, contains('#')); // Markdown headers
    });

    test('should generate test report in JSON format', () {
      final analyzer = lib.TestAnalyzer();

      // Add test data
      final testRun = lib.TestRun(
        testName: 'Sample Test',
        testFile: 'test/sample_test.dart',
      );
      testRun.addResult(1, passed: true, durationMs: 100);
      analyzer.testRuns['test1'] = testRun;

      // This will fail until we implement generateJsonReport
      final jsonReport = analyzer.generateJsonReport();

      expect(jsonReport, isNotNull);
      expect(jsonReport, isA<String>());
      expect(jsonReport, contains('"testName"'));
      expect(jsonReport, contains('Sample Test'));
    });

    test('should include flaky tests section in report', () {
      final analyzer = lib.TestAnalyzer(runCount: 3);

      // Create a flaky test
      final flakyTest = lib.TestRun(
        testName: 'Flaky Test',
        testFile: 'test/flaky_test.dart',
      );
      flakyTest.addResult(1, passed: true, durationMs: 100);
      flakyTest.addResult(2, passed: false, durationMs: 110);
      flakyTest.addResult(3, passed: true, durationMs: 105);

      analyzer.testRuns['flaky1'] = flakyTest;

      final report = analyzer.generateMarkdownReport();

      expect(report, contains('Flaky'));
      expect(report, contains('Flaky Test'));
    });

    test('should include failure patterns section in report', () {
      final analyzer = lib.TestAnalyzer();

      // Add a detected failure pattern
      analyzer.addDetectedFailure(
        type: lib.FailurePatternType.nullError,
        testName: 'Test with null error',
        errorMessage: 'Null check failed',
      );

      final report = analyzer.generateMarkdownReport();

      expect(report, contains('Pattern'));
      expect(report, contains('Null Error'));
    });

    test('should include performance metrics in report when enabled', () {
      final analyzer = lib.TestAnalyzer(performanceMode: true);

      // Add performance data
      final perf = lib.TestPerformance(testId: 'test1', testName: 'Test 1');
      perf.addDuration(2.5);
      perf.addDuration(2.8);
      analyzer.performance['test1'] = perf;

      final report = analyzer.generateMarkdownReport();

      expect(report, contains('Performance'));
      expect(report, contains('2.')); // Duration value
    });
  });

  group('Suite 2: Failures Report Tests', () {
    test('should generate failures report in markdown format', () {
      final analyzer = lib.TestAnalyzer();

      // Add a failure
      final failedTest = lib.TestRun(
        testName: 'Failed Test',
        testFile: 'test/failed_test.dart',
      );
      failedTest.addResult(1, passed: false, durationMs: 100);

      analyzer.testRuns['fail1'] = failedTest;
      analyzer.consistentFailures.add('fail1');

      // This will fail until we implement generateFailuresReport
      final report = analyzer.generateFailuresReport();

      expect(report, isNotNull);
      expect(report, contains('Failed Test'));
      expect(report, contains('Failure'));
    });

    test('should generate failures report in JSON format', () {
      final analyzer = lib.TestAnalyzer();

      // Add a failure
      final failedTest = lib.TestRun(
        testName: 'Failed Test',
        testFile: 'test/failed_test.dart',
      );
      failedTest.addResult(1, passed: false, durationMs: 100);

      analyzer.testRuns['fail1'] = failedTest;
      analyzer.consistentFailures.add('fail1');

      // This will fail until we implement generateFailuresJsonReport
      final jsonReport = analyzer.generateFailuresJsonReport();

      expect(jsonReport, isNotNull);
      expect(jsonReport, contains('"failures"'));
      expect(jsonReport, contains('Failed Test'));
    });

    test('should include failure details in failures report', () {
      final analyzer = lib.TestAnalyzer();

      // Create test with failure details
      final failedTest = lib.TestRun(
        testName: 'Failed Test',
        testFile: 'test/failed_test.dart',
      );
      failedTest.addResult(1, passed: false, durationMs: 100);

      analyzer.testRuns['fail1'] = failedTest;
      analyzer.consistentFailures.add('fail1');

      // Add failure to failures map
      analyzer.failures['fail1'] = [
        lib.TestFailure(
          testId: 'fail1',
          runNumber: 1,
          error: 'Expected: true, Actual: false',
          stackTrace: 'at test.dart:10',
          timestamp: DateTime.now(),
        ),
      ];

      final report = analyzer.generateFailuresReport();

      expect(report, contains('Expected: true'));
      expect(report, contains('test.dart:10'));
    });

    test('should include suggested fixes in failures report', () {
      final analyzer = lib.TestAnalyzer();

      // Add failure with pattern detection
      analyzer.addDetectedFailure(
        type: lib.FailurePatternType.nullError,
        testName: 'Null Error Test',
        errorMessage: 'Null check failed',
      );

      final report = analyzer.generateFailuresReport();

      expect(
          report,
          anyOf(
            contains('Suggestion'),
            contains('Fix'),
            contains('null'),
          ));
    });

    test('should include rerun commands in failures report', () {
      final analyzer = lib.TestAnalyzer();

      // Add a consistent failure
      final failedTest = lib.TestRun(
        testName: 'Failed Test',
        testFile: 'test/failed_test.dart',
      );
      failedTest.addResult(1, passed: false, durationMs: 100);

      analyzer.testRuns['fail1'] = failedTest;
      analyzer.consistentFailures.add('fail1');

      final report = analyzer.generateFailuresReport();

      expect(
          report,
          anyOf(
            contains('dart test'),
            contains('failed_test.dart'),
            contains('rerun'),
            contains('Rerun'),
          ));
    });
  });
}
