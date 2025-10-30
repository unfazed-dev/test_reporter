import 'package:test/test.dart';
import 'package:test_reporter/src/models/result_types.dart';

void main() {
  group('successfulAnalysis', () {
    test('should create successful analysis result', () {
      final result = successfulAnalysis(
        totalTests: 10,
        passedTests: 8,
        failedTests: 2,
      );

      expect(result.success, isTrue);
      expect(result.totalTests, 10);
      expect(result.passedTests, 8);
      expect(result.failedTests, 2);
      expect(result.error, isNull);
    });
  });

  group('failedAnalysis', () {
    test('should create failed analysis result', () {
      final result = failedAnalysis('Analysis crashed');

      expect(result.success, isFalse);
      expect(result.totalTests, 0);
      expect(result.passedTests, 0);
      expect(result.failedTests, 0);
      expect(result.error, 'Analysis crashed');
    });
  });

  group('successfulCoverage', () {
    test('should create successful coverage result', () {
      final result = successfulCoverage(
        coverage: 85.5,
        totalLines: 100,
        coveredLines: 85,
      );

      expect(result.success, isTrue);
      expect(result.coverage, 85.5);
      expect(result.totalLines, 100);
      expect(result.coveredLines, 85);
      expect(result.error, isNull);
    });
  });

  group('failedCoverage', () {
    test('should create failed coverage result', () {
      final result = failedCoverage('Coverage tool not found');

      expect(result.success, isFalse);
      expect(result.coverage, 0.0);
      expect(result.totalLines, 0);
      expect(result.coveredLines, 0);
      expect(result.error, 'Coverage tool not found');
    });
  });

  group('successfulLoad', () {
    test('should create successful test file load result', () {
      final result = successfulLoad('test/my_test.dart', 150);

      expect(result.success, isTrue);
      expect(result.filePath, 'test/my_test.dart');
      expect(result.loadTimeMs, 150);
      expect(result.error, isNull);
    });
  });

  group('failedLoad', () {
    test('should create failed test file load result', () {
      final result = failedLoad('test/missing.dart', 'File not found');

      expect(result.success, isFalse);
      expect(result.filePath, 'test/missing.dart');
      expect(result.loadTimeMs, 0);
      expect(result.error, 'File not found');
    });
  });

  group('passingTest', () {
    test('should create passing test run result', () {
      final result = passingTest('should pass', 50);

      expect(result.passed, isTrue);
      expect(result.testName, 'should pass');
      expect(result.durationMs, 50);
      expect(result.errorMessage, isNull);
      expect(result.stackTrace, isNull);
    });
  });

  group('failingTest', () {
    test('should create failing test run result', () {
      final result = failingTest(
        'should fail',
        75,
        'Expected true, got false',
        'test.dart:10:5',
      );

      expect(result.passed, isFalse);
      expect(result.testName, 'should fail');
      expect(result.durationMs, 75);
      expect(result.errorMessage, 'Expected true, got false');
      expect(result.stackTrace, 'test.dart:10:5');
    });
  });

  group('calculatePerformanceMetrics', () {
    test('should calculate metrics from durations', () {
      final durations = [10.0, 20.0, 30.0, 40.0, 50.0];
      final metrics = calculatePerformanceMetrics(durations);

      expect(metrics.averageDuration, 30.0);
      expect(metrics.maxDuration, 50.0);
      expect(metrics.minDuration, 10.0);
      expect(metrics.sampleSize, 5);
    });

    test('should handle single duration', () {
      final durations = [25.0];
      final metrics = calculatePerformanceMetrics(durations);

      expect(metrics.averageDuration, 25.0);
      expect(metrics.maxDuration, 25.0);
      expect(metrics.minDuration, 25.0);
      expect(metrics.sampleSize, 1);
    });

    test('should handle empty list', () {
      final durations = <double>[];
      final metrics = calculatePerformanceMetrics(durations);

      expect(metrics.averageDuration, 0.0);
      expect(metrics.maxDuration, 0.0);
      expect(metrics.minDuration, 0.0);
      expect(metrics.sampleSize, 0);
    });
  });

  group('createCoverageSummary', () {
    test('should create coverage summary with calculated uncovered lines', () {
      final summary = createCoverageSummary(
        overallCoverage: 75.0,
        filesAnalyzed: 10,
        totalLines: 200,
        coveredLines: 150,
      );

      expect(summary.overallCoverage, 75.0);
      expect(summary.filesAnalyzed, 10);
      expect(summary.totalLines, 200);
      expect(summary.coveredLines, 150);
      expect(summary.uncoveredLines, 50);
    });

    test('should handle 100% coverage', () {
      final summary = createCoverageSummary(
        overallCoverage: 100.0,
        filesAnalyzed: 5,
        totalLines: 100,
        coveredLines: 100,
      );

      expect(summary.uncoveredLines, 0);
    });
  });

  group('createReliabilityMetrics', () {
    test('should calculate pass rate and stability score', () {
      final metrics = createReliabilityMetrics(
        totalTests: 100,
        consistentPasses: 80,
        consistentFailures: 10,
        flakyTests: 10,
      );

      expect(metrics.passRate, 80.0);
      expect(metrics.totalTests, 100);
      expect(metrics.consistentPasses, 80);
      expect(metrics.consistentFailures, 10);
      expect(metrics.flakyTests, 10);
      // Stability: (100 - 10 - 10*0.5) / 100 * 100 = 85%
      expect(metrics.stabilityScore, 85.0);
    });

    test('should handle perfect reliability', () {
      final metrics = createReliabilityMetrics(
        totalTests: 50,
        consistentPasses: 50,
        consistentFailures: 0,
        flakyTests: 0,
      );

      expect(metrics.passRate, 100.0);
      expect(metrics.stabilityScore, 100.0);
    });

    test('should handle zero tests', () {
      final metrics = createReliabilityMetrics(
        totalTests: 0,
        consistentPasses: 0,
        consistentFailures: 0,
        flakyTests: 0,
      );

      expect(metrics.passRate, 100.0);
      expect(metrics.stabilityScore, 100.0);
    });
  });

  group('onAnalysisSuccess', () {
    test('should call onSuccess for successful result', () {
      final result = successfulAnalysis(
        totalTests: 10,
        passedTests: 8,
        failedTests: 2,
      );

      final output = onAnalysisSuccess(result, (total, passed, failed) {
        return 'Passed: $passed/$total';
      });

      expect(output, 'Passed: 8/10');
    });

    test('should return null for failed result', () {
      final result = failedAnalysis('Error occurred');

      final output = onAnalysisSuccess(result, (total, passed, failed) {
        return 'Passed: $passed/$total';
      });

      expect(output, isNull);
    });
  });

  group('onCoverageSuccess', () {
    test('should call onSuccess for successful result', () {
      final result = successfulCoverage(
        coverage: 85.5,
        totalLines: 100,
        coveredLines: 85,
      );

      final output = onCoverageSuccess(result, (coverage, total, covered) {
        return 'Coverage: $coverage%';
      });

      expect(output, 'Coverage: 85.5%');
    });

    test('should return null for failed result', () {
      final result = failedCoverage('Coverage failed');

      final output = onCoverageSuccess(result, (coverage, total, covered) {
        return 'Coverage: $coverage%';
      });

      expect(output, isNull);
    });
  });

  group('handleAnalysisResult', () {
    test('should call onSuccess for successful result', () {
      final result = successfulAnalysis(
        totalTests: 10,
        passedTests: 8,
        failedTests: 2,
      );

      final output = handleAnalysisResult(
        result,
        onSuccess: (total, passed, failed) => 'Success: $passed/$total',
        onError: (error) => 'Error: $error',
      );

      expect(output, 'Success: 8/10');
    });

    test('should call onError for failed result', () {
      final result = failedAnalysis('Analysis crashed');

      final output = handleAnalysisResult(
        result,
        onSuccess: (total, passed, failed) => 'Success: $passed/$total',
        onError: (error) => 'Error: $error',
      );

      expect(output, 'Error: Analysis crashed');
    });
  });

  group('handleCoverageResult', () {
    test('should call onSuccess for successful result', () {
      final result = successfulCoverage(
        coverage: 85.5,
        totalLines: 100,
        coveredLines: 85,
      );

      final output = handleCoverageResult(
        result,
        onSuccess: (coverage, total, covered) => 'Coverage: $coverage%',
        onError: (error) => 'Error: $error',
      );

      expect(output, 'Coverage: 85.5%');
    });

    test('should call onError for failed result', () {
      final result = failedCoverage('Tool not found');

      final output = handleCoverageResult(
        result,
        onSuccess: (coverage, total, covered) => 'Coverage: $coverage%',
        onError: (error) => 'Error: $error',
      );

      expect(output, 'Error: Tool not found');
    });
  });
}
