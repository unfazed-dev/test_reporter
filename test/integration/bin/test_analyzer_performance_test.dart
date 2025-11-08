// test/integration/bin/test_analyzer_performance_test.dart
import 'package:test/test.dart';
import 'package:test_reporter/src/bin/analyze_tests_lib.dart';

/// Phase 3.3: Performance Profiling Tests (Simplified for TDD)
///
/// Tests verify performance tracking and profiling capabilities.
/// Similar to Phase 3.1 and 3.2, we test core logic directly without full mocks.
///
/// Test Coverage:
/// - Suite 1: Performance Tracking (8 tests) - duration tracking, statistics, slow test detection
/// - Suite 2: Performance Mode (4 tests) - timing breakdown, bottleneck identification
/// Total: 12 tests
///
/// Methodology: 🔴🟢♻️🔄 TDD (Red-Green-Refactor-MetaTest)
void main() {
  group('Suite 1: Performance Tracking Tests', () {
    test('should track test duration across multiple runs', () {
      final perf = TestPerformance(testId: 'test1', testName: 'Test 1');

      perf.addDuration(1.5);
      perf.addDuration(2.0);
      perf.addDuration(1.8);

      expect(perf.durations, hasLength(3));
      expect(perf.durations, contains(1.5));
      expect(perf.durations, contains(2.0));
      expect(perf.durations, contains(1.8));
    });

    test('should calculate average duration correctly', () {
      final perf = TestPerformance(testId: 'test1', testName: 'Test 1');

      perf.addDuration(2.0);
      perf.addDuration(4.0);
      perf.addDuration(6.0);

      expect(perf.averageDuration, equals(4.0));
    });

    test('should calculate max duration correctly', () {
      final perf = TestPerformance(testId: 'test1', testName: 'Test 1');

      perf.addDuration(1.0);
      perf.addDuration(5.0);
      perf.addDuration(3.0);

      expect(perf.maxDuration, equals(5.0));
    });

    test('should calculate min duration correctly', () {
      final perf = TestPerformance(testId: 'test1', testName: 'Test 1');

      perf.addDuration(3.0);
      perf.addDuration(1.0);
      perf.addDuration(5.0);

      expect(perf.minDuration, equals(1.0));
    });

    test('should calculate standard deviation of durations', () {
      final perf = TestPerformance(testId: 'test1', testName: 'Test 1');

      // Durations: [2, 4, 4, 4, 5, 5, 7, 9]
      // Mean = 5.0
      // Variance = 4.0
      // StdDev = 2.0
      perf.addDuration(2.0);
      perf.addDuration(4.0);
      perf.addDuration(4.0);
      perf.addDuration(4.0);
      perf.addDuration(5.0);
      perf.addDuration(5.0);
      perf.addDuration(7.0);
      perf.addDuration(9.0);

      // This will fail until we implement standardDeviation
      expect(perf.standardDeviation, closeTo(2.0, 0.01));
    });

    test('should detect slow tests above threshold', () {
      final analyzer = TestAnalyzer(slowTestThreshold: 2.0);

      final perf1 = TestPerformance(testId: 'test1', testName: 'Fast Test');
      perf1.addDuration(0.5);
      perf1.addDuration(0.6);
      perf1.addDuration(0.7);

      final perf2 = TestPerformance(testId: 'test2', testName: 'Slow Test');
      perf2.addDuration(3.0);
      perf2.addDuration(3.5);
      perf2.addDuration(4.0);

      // Add performance data to analyzer
      analyzer.performance['test1'] = perf1;
      analyzer.performance['test2'] = perf2;

      // This will fail until we implement getSlowTests()
      final slowTests = analyzer.getSlowTests();

      expect(slowTests, hasLength(1));
      expect(slowTests.first.testName, equals('Slow Test'));
    });

    test('should detect performance regressions between runs', () {
      final perf = TestPerformance(testId: 'test1', testName: 'Test 1');

      // First 3 runs: fast
      perf.addDuration(1.0);
      perf.addDuration(1.1);
      perf.addDuration(1.2);

      // Last run: significant regression
      perf.addDuration(5.0);

      // This will fail until we implement hasPerformanceRegression
      final hasRegression = perf.hasPerformanceRegression(threshold: 2.0);

      expect(hasRegression, isTrue);
    });

    test('should generate performance report with timing breakdown', () {
      final analyzer = TestAnalyzer(performanceMode: true);

      final perf1 = TestPerformance(testId: 'test1', testName: 'Test 1');
      perf1.addDuration(1.5);
      perf1.addDuration(1.6);

      final perf2 = TestPerformance(testId: 'test2', testName: 'Test 2');
      perf2.addDuration(3.0);
      perf2.addDuration(3.2);

      analyzer.performance['test1'] = perf1;
      analyzer.performance['test2'] = perf2;

      // This will fail until we implement generatePerformanceReport
      final report = analyzer.generatePerformanceReport();

      expect(report, isNotNull);
      expect(report, contains('Test 1'));
      expect(report, contains('Test 2'));
      expect(report, contains('1.5')); // Duration info
    });
  });

  group('Suite 2: Performance Mode Tests', () {
    test('should enable performance mode with --performance flag', () {
      final analyzer = TestAnalyzer(performanceMode: true);

      expect(analyzer.performanceMode, isTrue);
    });

    test('should generate detailed timing breakdown in performance mode', () {
      final analyzer = TestAnalyzer(performanceMode: true);

      final perf = TestPerformance(testId: 'test1', testName: 'Test 1');
      perf.addDuration(2.5);
      perf.addDuration(3.0);
      perf.addDuration(2.8);

      analyzer.performance['test1'] = perf;

      // This will fail until we implement getTimingBreakdown
      final breakdown = analyzer.getTimingBreakdown('test1');

      expect(breakdown, isNotNull);
      expect(breakdown, containsPair('average', closeTo(2.77, 0.01)));
      expect(breakdown, containsPair('min', 2.5));
      expect(breakdown, containsPair('max', 3.0));
    });

    test('should profile test setup and teardown time', () {
      final perf = TestPerformance(testId: 'test1', testName: 'Test 1');

      // This will fail until we add setup/teardown tracking
      perf.recordSetupTime(0.5);
      perf.recordTeardownTime(0.3);
      perf.recordExecutionTime(2.0);

      expect(perf.setupTime, equals(0.5));
      expect(perf.teardownTime, equals(0.3));
      expect(perf.executionTime, equals(2.0));
      expect(perf.totalTime, equals(2.8));
    });

    test('should identify performance bottlenecks', () {
      final analyzer = TestAnalyzer(performanceMode: true);

      final perf1 = TestPerformance(testId: 'test1', testName: 'Fast Test');
      perf1.addDuration(0.5);

      final perf2 = TestPerformance(testId: 'test2', testName: 'Medium Test');
      perf2.addDuration(2.0);

      final perf3 = TestPerformance(testId: 'test3', testName: 'Slow Test');
      perf3.addDuration(10.0);

      analyzer.performance['test1'] = perf1;
      analyzer.performance['test2'] = perf2;
      analyzer.performance['test3'] = perf3;

      // This will fail until we implement identifyBottlenecks
      final bottlenecks = analyzer.identifyBottlenecks(percentile: 90);

      expect(bottlenecks, hasLength(1));
      expect(bottlenecks.first.testName, equals('Slow Test'));
      expect(bottlenecks.first.averageDuration, greaterThan(5.0));
    });
  });
}
