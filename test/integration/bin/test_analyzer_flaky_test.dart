import 'package:test/test.dart';
import 'package:test_reporter/src/bin/analyze_tests_lib.dart';

/// Phase 3.1: Multiple Run & Flaky Detection Tests (Simplified for TDD)
///
/// These tests verify the core flaky test detection functionality.
/// Note: TestAnalyzer will need mock support added in GREEN phase.
///
/// Methodology: 🔴🟢♻️🔄 TDD (Red-Green-Refactor-MetaTest)
void main() {
  group('Phase 3.1.1: Multiple Run Configuration', () {
    test('should support runCount parameter', () {
      final analyzer1 = TestAnalyzer(runCount: 1);
      final analyzer3 = TestAnalyzer(runCount: 3);
      final analyzer5 = TestAnalyzer(runCount: 5);

      expect(analyzer1.runCount, equals(1));
      expect(analyzer3.runCount, equals(3));
      expect(analyzer5.runCount, equals(5));
    });

    test('should default to 3 runs if not specified', () {
      final analyzer = TestAnalyzer();
      expect(analyzer.runCount, equals(3));
    });

    test('should have totalRuns property after execution', () async {
      final analyzer = TestAnalyzer(runCount: 3);

      // This will fail until we add totalRuns getter
      expect(() => analyzer.totalRuns, returnsNormally);
    });

    test('should track individual test runs', () {
      final analyzer = TestAnalyzer(runCount: 5);

      // Should have testRuns map
      expect(analyzer.testRuns, isA<Map>());
      expect(analyzer.testRuns, isEmpty); // Empty before running
    });
  });

  group('Phase 3.1.2: Test Run Tracking', () {
    test('should track test results across multiple runs', () {
      // TestRun should exist and track results
      final testRun = TestRun(
        testFile: 'test/my_test.dart',
        testName: 'my test',
      );

      expect(testRun.testFile, equals('test/my_test.dart'));
      expect(testRun.testName, equals('my test'));
      expect(testRun.results, isA<Map<int, bool>>());
      expect(testRun.durations, isA<Map<int, int>>());
    });

    test('should allow adding results to TestRun', () {
      final testRun = TestRun(
        testFile: 'test/my_test.dart',
        testName: 'my test',
      );

      // Add results for 3 runs
      testRun.addResult(1, passed: true, durationMs: 100);
      testRun.addResult(2, passed: false, durationMs: 150);
      testRun.addResult(3, passed: true, durationMs: 120);

      expect(testRun.results.length, equals(3));
      expect(testRun.results[1], isTrue);
      expect(testRun.results[2], isFalse);
      expect(testRun.results[3], isTrue);

      expect(testRun.durations[1], equals(100));
      expect(testRun.durations[2], equals(150));
      expect(testRun.durations[3], equals(120));
    });

    test('should calculate pass rate for TestRun', () {
      final testRun = TestRun(
        testFile: 'test/my_test.dart',
        testName: 'my test',
      );

      // 3 passes out of 5 = 60% pass rate
      testRun.addResult(1, passed: true, durationMs: 100);
      testRun.addResult(2, passed: true, durationMs: 100);
      testRun.addResult(3, passed: false, durationMs: 100);
      testRun.addResult(4, passed: true, durationMs: 100);
      testRun.addResult(5, passed: false, durationMs: 100);

      final passRate = testRun.passRate;
      expect(passRate, closeTo(0.6, 0.01)); // 60%
    });
  });

  group('Phase 3.1.3: Flaky Test Detection', () {
    test('should have flakyTests list', () {
      final analyzer = TestAnalyzer();
      expect(analyzer.flakyTests, isA<List<String>>());
    });

    test('should detect flaky test (passes then fails)', () {
      final testRun = TestRun(
        testFile: 'test/flaky_test.dart',
        testName: 'flaky test',
      );

      testRun.addResult(1, passed: true, durationMs: 100);
      testRun.addResult(2, passed: true, durationMs: 100);
      testRun.addResult(3, passed: false, durationMs: 100);

      expect(testRun.isFlaky, isTrue);
    });

    test('should detect flaky test (fails then passes)', () {
      final testRun = TestRun(
        testFile: 'test/flaky_test.dart',
        testName: 'flaky test',
      );

      testRun.addResult(1, passed: false, durationMs: 100);
      testRun.addResult(2, passed: true, durationMs: 100);
      testRun.addResult(3, passed: true, durationMs: 100);

      expect(testRun.isFlaky, isTrue);
    });

    test('should detect flaky test (intermittent failures)', () {
      final testRun = TestRun(
        testFile: 'test/very_flaky_test.dart',
        testName: 'very flaky test',
      );

      // Alternating pattern: P F P F P
      testRun.addResult(1, passed: true, durationMs: 100);
      testRun.addResult(2, passed: false, durationMs: 100);
      testRun.addResult(3, passed: true, durationMs: 100);
      testRun.addResult(4, passed: false, durationMs: 100);
      testRun.addResult(5, passed: true, durationMs: 100);

      expect(testRun.isFlaky, isTrue);
      expect(testRun.flakinessRate, closeTo(0.4, 0.01)); // 40% failure rate
    });

    test('should NOT mark consistently passing tests as flaky', () {
      final testRun = TestRun(
        testFile: 'test/stable_test.dart',
        testName: 'stable test',
      );

      for (var i = 1; i <= 5; i++) {
        testRun.addResult(i, passed: true, durationMs: 100);
      }

      expect(testRun.isFlaky, isFalse);
    });

    test('should have consistentFailures list for always-failing tests', () {
      final analyzer = TestAnalyzer();
      expect(analyzer.consistentFailures, isA<List<String>>());
    });

    test('should mark consistently failing test (not flaky)', () {
      final testRun = TestRun(
        testFile: 'test/broken_test.dart',
        testName: 'broken test',
      );

      for (var i = 1; i <= 5; i++) {
        testRun.addResult(i, passed: false, durationMs: 100);
      }

      expect(testRun.isFlaky, isFalse);
      expect(testRun.isConsistentFailure, isTrue);
    });
  });

  group('Phase 3.1.4: Flakiness Metrics', () {
    test('should calculate flakiness rate', () {
      final testRun = TestRun(
        testFile: 'test/my_test.dart',
        testName: 'my test',
      );

      // 2 failures out of 5 = 40% failure rate
      testRun.addResult(1, passed: true, durationMs: 100);
      testRun.addResult(2, passed: true, durationMs: 100);
      testRun.addResult(3, passed: true, durationMs: 100);
      testRun.addResult(4, passed: false, durationMs: 100);
      testRun.addResult(5, passed: false, durationMs: 100);

      expect(testRun.flakinessRate, closeTo(0.4, 0.01));
    });

    test('should rank flaky tests by severity', () {
      final analyzer = TestAnalyzer();

      // Add flaky tests with different severities
      analyzer.testRuns['test_a'] = TestRun(
        testFile: 'test/test_a.dart',
        testName: 'test A',
      )
        ..addResult(1, passed: false, durationMs: 100) // 20% flaky
        ..addResult(2, passed: true, durationMs: 100)
        ..addResult(3, passed: true, durationMs: 100)
        ..addResult(4, passed: true, durationMs: 100)
        ..addResult(5, passed: true, durationMs: 100);

      analyzer.testRuns['test_b'] = TestRun(
        testFile: 'test/test_b.dart',
        testName: 'test B',
      )
        ..addResult(1, passed: false, durationMs: 100) // 60% flaky
        ..addResult(2, passed: false, durationMs: 100)
        ..addResult(3, passed: false, durationMs: 100)
        ..addResult(4, passed: true, durationMs: 100)
        ..addResult(5, passed: true, durationMs: 100);

      final ranked = analyzer.getRankedFlakyTests();

      expect(ranked.length, greaterThanOrEqualTo(2));
      expect(ranked.first.testName, equals('test B')); // Most flaky first
      expect(ranked[1].testName, equals('test A'));
    });
  });

  group('Phase 3.1.5: Duration Tracking', () {
    test('should track test durations across runs', () {
      final testRun = TestRun(
        testFile: 'test/my_test.dart',
        testName: 'my test',
      );

      testRun.addResult(1, passed: true, durationMs: 100);
      testRun.addResult(2, passed: true, durationMs: 150);
      testRun.addResult(3, passed: true, durationMs: 200);

      expect(testRun.durations.values, containsAll([100, 150, 200]));
    });

    test('should calculate average duration', () {
      final testRun = TestRun(
        testFile: 'test/my_test.dart',
        testName: 'my test',
      );

      testRun.addResult(1, passed: true, durationMs: 100);
      testRun.addResult(2, passed: true, durationMs: 150);
      testRun.addResult(3, passed: true, durationMs: 200);

      final avgDuration = testRun.averageDuration;
      expect(avgDuration, closeTo(150.0, 1.0)); // (100+150+200)/3 = 150
    });

    test('should track min and max durations', () {
      final testRun = TestRun(
        testFile: 'test/my_test.dart',
        testName: 'my test',
      );

      testRun.addResult(1, passed: true, durationMs: 100);
      testRun.addResult(2, passed: true, durationMs: 300);
      testRun.addResult(3, passed: true, durationMs: 200);

      expect(testRun.minDuration, equals(100));
      expect(testRun.maxDuration, equals(300));
    });
  });

  group('Phase 3.1.6: Report Generation', () {
    test('should generate report with flaky tests section', () {
      final analyzer = TestAnalyzer(generateReport: true);

      // Add a flaky test
      analyzer.testRuns['flaky_test'] = TestRun(
        testFile: 'test/flaky_test.dart',
        testName: 'flaky test',
      )
        ..addResult(1, passed: true, durationMs: 100)
        ..addResult(2, passed: false, durationMs: 100)
        ..addResult(3, passed: true, durationMs: 100);

      final report = analyzer.generateFlakyTestReport();

      expect(report, contains('Flaky'));
      expect(report, contains('flaky test'));
    });

    test('should include flakiness percentage in report', () {
      final analyzer = TestAnalyzer();

      analyzer.testRuns['test'] = TestRun(
        testFile: 'test/my_test.dart',
        testName: 'my test',
      )
        ..addResult(1, passed: true, durationMs: 100)
        ..addResult(2, passed: false, durationMs: 100)
        ..addResult(3, passed: true, durationMs: 100)
        ..addResult(4, passed: false, durationMs: 100)
        ..addResult(5, passed: true, durationMs: 100);

      final report = analyzer.generateFlakyTestReport();

      expect(report, contains('40')); // 40% flakiness
    });
  });
}
