import 'package:test/test.dart';
import 'package:test_reporter/src/models/result_types.dart';

void main() {
  group('Record Types - Basic Creation and Access', () {
    group('AnalysisResult', () {
      test('should create successful analysis result with all fields', () {
        final result = successfulAnalysis(
          totalTests: 100,
          passedTests: 95,
          failedTests: 5,
        );

        expect(result.success, isTrue);
        expect(result.totalTests, equals(100));
        expect(result.passedTests, equals(95));
        expect(result.failedTests, equals(5));
        expect(result.error, isNull);
      });

      test('should create failed analysis result with error', () {
        final result = failedAnalysis('Test execution failed');

        expect(result.success, isFalse);
        expect(result.totalTests, equals(0));
        expect(result.passedTests, equals(0));
        expect(result.failedTests, equals(0));
        expect(result.error, equals('Test execution failed'));
      });

      test('should allow direct record creation', () {
        final result = (
          success: true,
          totalTests: 50,
          passedTests: 48,
          failedTests: 2,
          error: null,
        );

        expect(result, isA<AnalysisResult>());
        expect(result.totalTests, equals(50));
      });
    });

    group('CoverageResult', () {
      test('should create successful coverage result with all fields', () {
        final result = successfulCoverage(
          coverage: 85.5,
          totalLines: 1000,
          coveredLines: 855,
        );

        expect(result.success, isTrue);
        expect(result.coverage, equals(85.5));
        expect(result.totalLines, equals(1000));
        expect(result.coveredLines, equals(855));
        expect(result.error, isNull);
      });

      test('should create failed coverage result with error', () {
        final result = failedCoverage('Coverage analysis failed');

        expect(result.success, isFalse);
        expect(result.coverage, equals(0.0));
        expect(result.totalLines, equals(0));
        expect(result.coveredLines, equals(0));
        expect(result.error, equals('Coverage analysis failed'));
      });

      test('should handle 100% coverage', () {
        final result = successfulCoverage(
          coverage: 100.0,
          totalLines: 500,
          coveredLines: 500,
        );

        expect(result.coverage, equals(100.0));
        expect(result.totalLines, equals(result.coveredLines));
      });

      test('should handle 0% coverage', () {
        final result = successfulCoverage(
          coverage: 0.0,
          totalLines: 500,
          coveredLines: 0,
        );

        expect(result.coverage, equals(0.0));
        expect(result.coveredLines, equals(0));
      });
    });

    group('TestFileResult', () {
      test('should create successful file load result', () {
        final result = successfulLoad('test/my_test.dart', 150);

        expect(result.success, isTrue);
        expect(result.filePath, equals('test/my_test.dart'));
        expect(result.loadTimeMs, equals(150));
        expect(result.error, isNull);
      });

      test('should create failed file load result', () {
        final result = failedLoad('test/missing.dart', 'File not found');

        expect(result.success, isFalse);
        expect(result.filePath, equals('test/missing.dart'));
        expect(result.loadTimeMs, equals(0));
        expect(result.error, equals('File not found'));
      });

      test('should handle zero load time', () {
        final result = successfulLoad('test/empty.dart', 0);

        expect(result.success, isTrue);
        expect(result.loadTimeMs, equals(0));
      });
    });

    group('TestRunResult', () {
      test('should create passing test result', () {
        final result = passingTest('user authentication works', 250);

        expect(result.passed, isTrue);
        expect(result.testName, equals('user authentication works'));
        expect(result.durationMs, equals(250));
        expect(result.errorMessage, isNull);
        expect(result.stackTrace, isNull);
      });

      test('should create failing test result with error and stack trace', () {
        final result = failingTest(
          'user login fails',
          300,
          'Expected: true, Actual: false',
          'at test/auth_test.dart:42\nat test/auth_test.dart:10',
        );

        expect(result.passed, isFalse);
        expect(result.testName, equals('user login fails'));
        expect(result.durationMs, equals(300));
        expect(result.errorMessage, equals('Expected: true, Actual: false'));
        expect(result.stackTrace, contains('test/auth_test.dart:42'));
      });

      test('should handle empty error message', () {
        final result = failingTest('test', 100, '', '');

        expect(result.passed, isFalse);
        expect(result.errorMessage, isEmpty);
        expect(result.stackTrace, isEmpty);
      });
    });

    group('PerformanceMetrics', () {
      test('should create performance metrics with all fields', () {
        final metrics = (
          averageDuration: 250.5,
          maxDuration: 500.0,
          minDuration: 100.0,
          sampleSize: 50,
        );

        expect(metrics, isA<PerformanceMetrics>());
        expect(metrics.averageDuration, equals(250.5));
        expect(metrics.maxDuration, equals(500.0));
        expect(metrics.minDuration, equals(100.0));
        expect(metrics.sampleSize, equals(50));
      });
    });

    group('CoverageSummary', () {
      test('should create coverage summary with calculated uncovered lines',
          () {
        final summary = createCoverageSummary(
          overallCoverage: 75.0,
          filesAnalyzed: 10,
          totalLines: 1000,
          coveredLines: 750,
        );

        expect(summary.overallCoverage, equals(75.0));
        expect(summary.filesAnalyzed, equals(10));
        expect(summary.totalLines, equals(1000));
        expect(summary.coveredLines, equals(750));
        expect(summary.uncoveredLines, equals(250));
      });

      test('should handle complete coverage', () {
        final summary = createCoverageSummary(
          overallCoverage: 100.0,
          filesAnalyzed: 5,
          totalLines: 500,
          coveredLines: 500,
        );

        expect(summary.uncoveredLines, equals(0));
      });
    });

    group('ReliabilityMetrics', () {
      test('should create reliability metrics with calculated scores', () {
        final metrics = createReliabilityMetrics(
          totalTests: 100,
          consistentPasses: 90,
          consistentFailures: 5,
          flakyTests: 5,
        );

        expect(metrics.totalTests, equals(100));
        expect(metrics.consistentPasses, equals(90));
        expect(metrics.consistentFailures, equals(5));
        expect(metrics.flakyTests, equals(5));
        expect(metrics.passRate, equals(90.0)); // 90/100 * 100
        expect(
            metrics.stabilityScore, equals(92.5)); // (100 - 5 - 5*0.5)/100*100
      });

      test('should handle zero total tests', () {
        final metrics = createReliabilityMetrics(
          totalTests: 0,
          consistentPasses: 0,
          consistentFailures: 0,
          flakyTests: 0,
        );

        expect(metrics.passRate, equals(100.0));
        expect(metrics.stabilityScore, equals(100.0));
      });

      test('should calculate correct pass rate', () {
        final metrics = createReliabilityMetrics(
          totalTests: 50,
          consistentPasses: 40,
          consistentFailures: 10,
          flakyTests: 0,
        );

        expect(metrics.passRate, equals(80.0)); // 40/50 * 100
      });

      test('should penalize flaky tests in stability score', () {
        final metrics = createReliabilityMetrics(
          totalTests: 100,
          consistentPasses: 80,
          consistentFailures: 0,
          flakyTests: 20,
        );

        // (100 - 0 - 20*0.5)/100*100 = 90
        expect(metrics.stabilityScore, equals(90.0));
      });
    });

    group('FileCoverage', () {
      test('should create file coverage with uncovered line numbers', () {
        final coverage = (
          filePath: 'lib/src/my_file.dart',
          coverage: 80.0,
          totalLines: 100,
          coveredLines: 80,
          uncoveredLines: [5, 12, 23, 45, 67, 89, 90, 91, 92, 93],
        );

        expect(coverage, isA<FileCoverage>());
        expect(coverage.filePath, equals('lib/src/my_file.dart'));
        expect(coverage.coverage, equals(80.0));
        expect(coverage.uncoveredLines.length, equals(10));
        expect(coverage.uncoveredLines, contains(5));
      });

      test('should handle fully covered file', () {
        final coverage = (
          filePath: 'lib/src/covered.dart',
          coverage: 100.0,
          totalLines: 50,
          coveredLines: 50,
          uncoveredLines: <int>[],
        );

        expect(coverage.uncoveredLines, isEmpty);
      });
    });

    group('TestTiming', () {
      test('should create test timing data', () {
        final timestamp = DateTime(2025, 11, 4, 10, 30, 45);
        final timing = (
          testId: 'auth_test_001',
          duration: const Duration(milliseconds: 250),
          timestamp: timestamp,
          passed: true,
        );

        expect(timing, isA<TestTiming>());
        expect(timing.testId, equals('auth_test_001'));
        expect(timing.duration, equals(const Duration(milliseconds: 250)));
        expect(timing.timestamp, equals(timestamp));
        expect(timing.passed, isTrue);
      });

      test('should handle failed test timing', () {
        final timing = (
          testId: 'failed_test',
          duration: const Duration(milliseconds: 100),
          timestamp: DateTime.now(),
          passed: false,
        );

        expect(timing.passed, isFalse);
      });
    });
  });

  group('Calculation Functions', () {
    group('calculatePerformanceMetrics', () {
      test('should calculate correct metrics from durations', () {
        final durations = [100.0, 200.0, 300.0, 400.0, 500.0];
        final metrics = calculatePerformanceMetrics(durations);

        expect(metrics.averageDuration, equals(300.0));
        expect(metrics.maxDuration, equals(500.0));
        expect(metrics.minDuration, equals(100.0));
        expect(metrics.sampleSize, equals(5));
      });

      test('should handle empty list', () {
        final metrics = calculatePerformanceMetrics([]);

        expect(metrics.averageDuration, equals(0.0));
        expect(metrics.maxDuration, equals(0.0));
        expect(metrics.minDuration, equals(0.0));
        expect(metrics.sampleSize, equals(0));
      });

      test('should handle single duration', () {
        final metrics = calculatePerformanceMetrics([250.0]);

        expect(metrics.averageDuration, equals(250.0));
        expect(metrics.maxDuration, equals(250.0));
        expect(metrics.minDuration, equals(250.0));
        expect(metrics.sampleSize, equals(1));
      });

      test('should handle identical durations', () {
        final metrics = calculatePerformanceMetrics([100.0, 100.0, 100.0]);

        expect(metrics.averageDuration, equals(100.0));
        expect(metrics.maxDuration, equals(100.0));
        expect(metrics.minDuration, equals(100.0));
      });

      test('should handle floating point durations', () {
        final durations = [123.45, 234.56, 345.67];
        final metrics = calculatePerformanceMetrics(durations);

        expect(metrics.averageDuration, closeTo(234.56, 0.01));
        expect(metrics.maxDuration, equals(345.67));
        expect(metrics.minDuration, equals(123.45));
      });
    });

    group('createCoverageSummary', () {
      test('should calculate uncovered lines correctly', () {
        final summary = createCoverageSummary(
          overallCoverage: 60.0,
          filesAnalyzed: 8,
          totalLines: 500,
          coveredLines: 300,
        );

        expect(summary.uncoveredLines, equals(200));
      });

      test('should handle zero coverage', () {
        final summary = createCoverageSummary(
          overallCoverage: 0.0,
          filesAnalyzed: 1,
          totalLines: 100,
          coveredLines: 0,
        );

        expect(summary.uncoveredLines, equals(100));
      });
    });

    group('createReliabilityMetrics', () {
      test('should calculate pass rate correctly', () {
        final metrics = createReliabilityMetrics(
          totalTests: 200,
          consistentPasses: 150,
          consistentFailures: 30,
          flakyTests: 20,
        );

        expect(metrics.passRate, equals(75.0)); // 150/200 * 100
      });

      test('should calculate stability score with flaky penalty', () {
        final metrics = createReliabilityMetrics(
          totalTests: 100,
          consistentPasses: 70,
          consistentFailures: 10,
          flakyTests: 20,
        );

        // (100 - 10 - 20*0.5)/100*100 = 80
        expect(metrics.stabilityScore, equals(80.0));
      });

      test('should handle all passing tests', () {
        final metrics = createReliabilityMetrics(
          totalTests: 50,
          consistentPasses: 50,
          consistentFailures: 0,
          flakyTests: 0,
        );

        expect(metrics.passRate, equals(100.0));
        expect(metrics.stabilityScore, equals(100.0));
      });

      test('should handle all flaky tests', () {
        final metrics = createReliabilityMetrics(
          totalTests: 10,
          consistentPasses: 0,
          consistentFailures: 0,
          flakyTests: 10,
        );

        expect(metrics.passRate, equals(0.0));
        expect(
            metrics.stabilityScore, equals(50.0)); // flaky tests count as 0.5
      });
    });
  });

  group('Pattern Matching Helpers', () {
    group('onAnalysisSuccess', () {
      test('should execute callback on successful analysis', () {
        final result = successfulAnalysis(
          totalTests: 100,
          passedTests: 95,
          failedTests: 5,
        );

        final message = onAnalysisSuccess(
          result,
          (total, passed, failed) =>
              'Analyzed $total tests: $passed passed, $failed failed',
        );

        expect(message, equals('Analyzed 100 tests: 95 passed, 5 failed'));
      });

      test('should return null on failed analysis', () {
        final result = failedAnalysis('Error occurred');

        final message = onAnalysisSuccess(
          result,
          (total, passed, failed) => 'Success: $total',
        );

        expect(message, isNull);
      });

      test('should allow complex transformations', () {
        final result = successfulAnalysis(
          totalTests: 50,
          passedTests: 48,
          failedTests: 2,
        );

        final passRate = onAnalysisSuccess(
          result,
          (total, passed, failed) => (passed / total * 100).toStringAsFixed(1),
        );

        expect(passRate, equals('96.0'));
      });
    });

    group('onCoverageSuccess', () {
      test('should execute callback on successful coverage', () {
        final result = successfulCoverage(
          coverage: 85.5,
          totalLines: 1000,
          coveredLines: 855,
        );

        final message = onCoverageSuccess(
          result,
          (coverage, total, covered) =>
              'Coverage: ${coverage.toStringAsFixed(1)}%',
        );

        expect(message, equals('Coverage: 85.5%'));
      });

      test('should return null on failed coverage', () {
        final result = failedCoverage('Analysis failed');

        final message = onCoverageSuccess(
          result,
          (coverage, total, covered) => 'Coverage: $coverage%',
        );

        expect(message, isNull);
      });
    });

    group('handleAnalysisResult', () {
      test('should call onSuccess for successful result', () {
        final result = successfulAnalysis(
          totalTests: 100,
          passedTests: 100,
          failedTests: 0,
        );

        final message = handleAnalysisResult(
          result,
          onSuccess: (total, passed, failed) => 'All $total tests passed!',
          onError: (error) => 'Error: $error',
        );

        expect(message, equals('All 100 tests passed!'));
      });

      test('should call onError for failed result', () {
        final result = failedAnalysis('Test execution crashed');

        final message = handleAnalysisResult(
          result,
          onSuccess: (total, passed, failed) => 'Success',
          onError: (error) => 'Error: $error',
        );

        expect(message, equals('Error: Test execution crashed'));
      });

      test('should allow different return types', () {
        final result = successfulAnalysis(
          totalTests: 50,
          passedTests: 45,
          failedTests: 5,
        );

        final exitCode = handleAnalysisResult(
          result,
          onSuccess: (total, passed, failed) => failed == 0 ? 0 : 1,
          onError: (error) => 2,
        );

        expect(exitCode, equals(1)); // Has failures
      });
    });

    group('handleCoverageResult', () {
      test('should call onSuccess for successful coverage', () {
        final result = successfulCoverage(
          coverage: 90.0,
          totalLines: 1000,
          coveredLines: 900,
        );

        final message = handleCoverageResult(
          result,
          onSuccess: (coverage, total, covered) =>
              'Coverage: ${coverage.toStringAsFixed(0)}%',
          onError: (error) => 'Error: $error',
        );

        expect(message, equals('Coverage: 90%'));
      });

      test('should call onError for failed coverage', () {
        final result = failedCoverage('Unable to parse coverage data');

        final message = handleCoverageResult(
          result,
          onSuccess: (coverage, total, covered) => 'Success',
          onError: (error) => 'Error: $error',
        );

        expect(message, equals('Error: Unable to parse coverage data'));
      });

      test('should allow threshold checking', () {
        final result = successfulCoverage(
          coverage: 75.0,
          totalLines: 400,
          coveredLines: 300,
        );

        final meetsThreshold = handleCoverageResult(
          result,
          onSuccess: (coverage, total, covered) => coverage >= 80.0,
          onError: (error) => false,
        );

        expect(meetsThreshold, isFalse);
      });
    });
  });

  group('Record Destructuring', () {
    test('should support AnalysisResult destructuring - full destructure', () {
      final result = successfulAnalysis(
        totalTests: 100,
        passedTests: 95,
        failedTests: 5,
      );

      final (
        success: ok,
        totalTests: total,
        passedTests: passed,
        failedTests: failed,
        error: err,
      ) = result;

      expect(ok, isTrue);
      expect(total, equals(100));
      expect(passed, equals(95));
      expect(failed, equals(5));
      expect(err, isNull);
    });

    test('should support CoverageResult destructuring - full destructure', () {
      final result = successfulCoverage(
        coverage: 85.0,
        totalLines: 1000,
        coveredLines: 850,
      );

      final (
        success: ok,
        coverage: cov,
        totalLines: lines,
        coveredLines: covered,
        error: err,
      ) = result;

      expect(ok, isTrue);
      expect(cov, equals(85.0));
      expect(lines, equals(1000));
      expect(covered, equals(850));
      expect(err, isNull);
    });

    test('should support pattern matching in switch - all fields matched', () {
      final result = successfulAnalysis(
        totalTests: 50,
        passedTests: 50,
        failedTests: 0,
      );

      final message = switch (result) {
        (
          success: true,
          failedTests: 0,
          totalTests: _,
          passedTests: _,
          error: _
        ) =>
          'All tests passed!',
        (
          success: true,
          failedTests: final f,
          totalTests: _,
          passedTests: _,
          error: _
        ) =>
          '$f tests failed',
        (
          success: false,
          error: final e,
          totalTests: _,
          passedTests: _,
          failedTests: _
        ) =>
          'Error: $e',
      };

      expect(message, equals('All tests passed!'));
    });

    test('should support accessing fields by name', () {
      final result = successfulAnalysis(
        totalTests: 75,
        passedTests: 70,
        failedTests: 5,
      );

      // Access fields directly by name
      expect(result.success, isTrue);
      expect(result.totalTests, equals(75));
      expect(result.passedTests, equals(70));
      expect(result.failedTests, equals(5));
      expect(result.error, isNull);
    });

    test('should support TestRunResult destructuring', () {
      final result = passingTest('my test', 250);

      final (
        passed: p,
        testName: name,
        durationMs: duration,
        errorMessage: errMsg,
        stackTrace: stack,
      ) = result;

      expect(p, isTrue);
      expect(name, equals('my test'));
      expect(duration, equals(250));
      expect(errMsg, isNull);
      expect(stack, isNull);
    });
  });

  group('Edge Cases and Validation', () {
    test('should handle very large numbers in metrics', () {
      final metrics = createReliabilityMetrics(
        totalTests: 1000000,
        consistentPasses: 999999,
        consistentFailures: 1,
        flakyTests: 0,
      );

      expect(metrics.passRate, closeTo(99.9999, 0.0001));
    });

    test('should handle very small coverage values', () {
      final result = successfulCoverage(
        coverage: 0.01,
        totalLines: 10000,
        coveredLines: 1,
      );

      expect(result.coverage, equals(0.01));
    });

    test('should handle very long file paths in FileCoverage', () {
      final longPath =
          'lib/src/very/deeply/nested/directory/structure/my_file.dart';
      final coverage = (
        filePath: longPath,
        coverage: 75.0,
        totalLines: 100,
        coveredLines: 75,
        uncoveredLines: <int>[],
      );

      expect(coverage.filePath, equals(longPath));
    });

    test('should handle empty test name in TestRunResult', () {
      final result = passingTest('', 100);

      expect(result.testName, isEmpty);
      expect(result.passed, isTrue);
    });

    test('should handle negative durations gracefully in calculations', () {
      // Edge case: should this be handled? Let's test current behavior
      final durations = [100.0, 200.0, -50.0];
      final metrics = calculatePerformanceMetrics(durations);

      expect(metrics.minDuration, equals(-50.0));
      expect(metrics.averageDuration, closeTo(83.33, 0.01));
    });
  });

  group('Type Safety and Immutability', () {
    test('record types should be immutable', () {
      final result = successfulAnalysis(
        totalTests: 100,
        passedTests: 95,
        failedTests: 5,
      );

      // Records are immutable - these assignments should fail at compile time
      // This test documents the immutability
      expect(() => result, returnsNormally);
    });

    test('should maintain type information', () {
      final analysisResult = successfulAnalysis(
        totalTests: 100,
        passedTests: 95,
        failedTests: 5,
      );

      final coverageResult = successfulCoverage(
        coverage: 85.0,
        totalLines: 1000,
        coveredLines: 850,
      );

      expect(analysisResult, isA<AnalysisResult>());
      expect(coverageResult, isA<CoverageResult>());
      expect(analysisResult, isNot(isA<CoverageResult>()));
    });
  });
}
