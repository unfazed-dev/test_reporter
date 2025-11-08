// test/integration/bin/test_analyzer_edge_cases_test.dart
import 'package:test/test.dart';
import 'package:test_reporter/src/bin/analyze_tests_lib.dart' as lib;

/// Phase 3.5: Edge Cases & Interactive Mode Tests (Simplified for TDD)
///
/// Tests verify edge case handling and watch mode functionality.
/// Similar to previous phases, we test core logic directly without full mocks.
///
/// Test Coverage:
/// - Suite 1: Edge Cases (6 tests) - no tests, all pass/fail, slow tests, no output, duplicates
/// - Suite 2: Watch Mode (4 tests) - enable, detect changes, rerun, interactive
/// Total: 10 tests
///
/// Methodology: 🔴🟢♻️🔄 TDD (Red-Green-Refactor-MetaTest)
void main() {
  group('Suite 1: Edge Cases Tests', () {
    test('should handle project with no tests gracefully', () {
      final analyzer = lib.TestAnalyzer();

      // Simulate scenario where no tests are found
      // This will fail until we add proper handling
      final isEmpty = analyzer.testRuns.isEmpty;

      expect(isEmpty, isTrue);
      // Should not throw when generating report with no tests
      final report = analyzer.generateMarkdownReport();
      expect(report, isNotNull);
      expect(report, contains('0'));
    });

    test('should handle all tests passing scenario', () {
      final analyzer = lib.TestAnalyzer(runCount: 3);

      // Add multiple passing tests
      final test1 = lib.TestRun(
        testName: 'Test 1',
        testFile: 'test/test1.dart',
      );
      test1.addResult(1, passed: true, durationMs: 100);
      test1.addResult(2, passed: true, durationMs: 105);
      test1.addResult(3, passed: true, durationMs: 102);

      final test2 = lib.TestRun(
        testName: 'Test 2',
        testFile: 'test/test2.dart',
      );
      test2.addResult(1, passed: true, durationMs: 200);
      test2.addResult(2, passed: true, durationMs: 210);
      test2.addResult(3, passed: true, durationMs: 205);

      analyzer.testRuns['test1'] = test1;
      analyzer.testRuns['test2'] = test2;

      // This will fail until we implement getAllPassingTests
      final allPassing = analyzer.getAllPassingTests();

      expect(allPassing, hasLength(2));
      expect(allPassing, contains(test1));
      expect(allPassing, contains(test2));
    });

    test('should handle all tests failing scenario', () {
      final analyzer = lib.TestAnalyzer(runCount: 3);

      // Add multiple failing tests
      final test1 = lib.TestRun(
        testName: 'Test 1',
        testFile: 'test/test1.dart',
      );
      test1.addResult(1, passed: false, durationMs: 100);
      test1.addResult(2, passed: false, durationMs: 105);
      test1.addResult(3, passed: false, durationMs: 102);

      final test2 = lib.TestRun(
        testName: 'Test 2',
        testFile: 'test/test2.dart',
      );
      test2.addResult(1, passed: false, durationMs: 200);
      test2.addResult(2, passed: false, durationMs: 210);
      test2.addResult(3, passed: false, durationMs: 205);

      analyzer.testRuns['test1'] = test1;
      analyzer.testRuns['test2'] = test2;
      analyzer.consistentFailures.add('test1');
      analyzer.consistentFailures.add('test2');

      // This will fail until we implement getAllFailingTests
      final allFailing = analyzer.getAllFailingTests();

      expect(allFailing, hasLength(2));
      expect(analyzer.consistentFailures, hasLength(2));
    });

    test('should handle very slow tests (>10s)', () {
      final analyzer = lib.TestAnalyzer(slowTestThreshold: 10.0);

      // Add very slow test
      final slowTest = lib.TestRun(
        testName: 'Very Slow Test',
        testFile: 'test/slow_test.dart',
      );
      // Convert to seconds: 15000ms = 15s
      slowTest.addResult(1, passed: true, durationMs: 15000);
      slowTest.addResult(2, passed: true, durationMs: 16000);

      analyzer.testRuns['slow1'] = slowTest;

      final perf = lib.TestPerformance(
        testId: 'slow1',
        testName: 'Very Slow Test',
      );
      perf.addDuration(15.0);
      perf.addDuration(16.0);
      analyzer.performance['slow1'] = perf;

      final slowTests = analyzer.getSlowTests();

      expect(slowTests, hasLength(1));
      expect(slowTests.first.averageDuration, greaterThan(10.0));
    });

    test('should handle tests with no output gracefully', () {
      final analyzer = lib.TestAnalyzer();

      // Create test with no failure details
      final test = lib.TestRun(
        testName: 'Silent Test',
        testFile: 'test/silent_test.dart',
      );
      test.addResult(1, passed: false, durationMs: 100);

      analyzer.testRuns['silent1'] = test;
      analyzer.consistentFailures.add('silent1');

      // Should handle missing failure details gracefully
      final report = analyzer.generateFailuresReport();

      expect(report, isNotNull);
      expect(report, contains('Silent Test'));
    });

    test('should handle duplicate test names', () {
      final analyzer = lib.TestAnalyzer();

      // Add tests with same name but different files
      final test1 = lib.TestRun(
        testName: 'Duplicate Test',
        testFile: 'test/file1_test.dart',
      );
      test1.addResult(1, passed: true, durationMs: 100);

      final test2 = lib.TestRun(
        testName: 'Duplicate Test',
        testFile: 'test/file2_test.dart',
      );
      test2.addResult(1, passed: true, durationMs: 200);

      analyzer.testRuns['test1'] = test1;
      analyzer.testRuns['test2'] = test2;

      // This will fail until we implement findDuplicateTestNames
      final duplicates = analyzer.findDuplicateTestNames();

      expect(duplicates, isNotEmpty);
      expect(duplicates, contains('Duplicate Test'));
    });
  });

  group('Suite 2: Watch & Interactive Mode Tests', () {
    test('should enable watch mode with flag', () {
      // This will fail until we add watchMode parameter
      final analyzer = lib.TestAnalyzer(watchMode: true);

      expect(analyzer.watchMode, isTrue);
    });

    test('should track file changes in watch mode', () {
      final analyzer = lib.TestAnalyzer(watchMode: true);

      // This will fail until we implement addFileChange
      analyzer.addFileChange('test/example_test.dart');
      analyzer.addFileChange('lib/src/example.dart');

      final changedFiles = analyzer.getChangedFiles();

      expect(changedFiles, hasLength(2));
      expect(changedFiles, contains('test/example_test.dart'));
      expect(changedFiles, contains('lib/src/example.dart'));
    });

    test('should determine which tests to rerun based on changes', () {
      final analyzer = lib.TestAnalyzer(watchMode: true);

      // Add some tests
      final test1 = lib.TestRun(
        testName: 'Test 1',
        testFile: 'test/example_test.dart',
      );
      final test2 = lib.TestRun(
        testName: 'Test 2',
        testFile: 'test/other_test.dart',
      );

      analyzer.testRuns['test1'] = test1;
      analyzer.testRuns['test2'] = test2;

      // Simulate file change
      analyzer.addFileChange('test/example_test.dart');

      // This will fail until we implement getTestsToRerun
      final testsToRerun = analyzer.getTestsToRerun();

      expect(testsToRerun, hasLength(1));
      expect(testsToRerun.first.testFile, equals('test/example_test.dart'));
    });

    test('should handle interactive prompts in watch mode', () {
      final analyzer = lib.TestAnalyzer(watchMode: true, interactive: true);

      expect(analyzer.interactive, isTrue);

      // This will fail until we implement handleUserInput
      final response = analyzer.handleUserInput('r'); // 'r' for rerun

      expect(response, isNotNull);
      expect(response, anyOf(equals('rerun'), equals('rerunAll')));
    });
  });
}
