/// Modern result types using Dart records
///
/// Records provide a lightweight way to return multiple values without
/// defining full classes. They're immutable, have built-in equality, and
/// support destructuring.
///
/// Example usage:
/// ```dart
/// final result = await runTestAnalysis();
/// switch (result) {
///   case (success: true, :final data):
///     print('Analysis succeeded: $data');
///   case (success: false, :final error):
///     print('Analysis failed: $error');
/// }
///
/// // Or destructure directly
/// final (success: ok, data: analysisData) = await runTestAnalysis();
/// ```
library;

/// Result of a test analysis operation
///
/// Returns both success status and relevant data/error
typedef AnalysisResult = ({
  bool success,
  int totalTests,
  int passedTests,
  int failedTests,
  String? error,
});

/// Result of a coverage analysis operation
typedef CoverageResult = ({
  bool success,
  double coverage,
  int totalLines,
  int coveredLines,
  String? error,
});

/// Result of loading a test file
typedef TestFileResult = ({
  bool success,
  String filePath,
  int loadTimeMs,
  String? error,
});

/// Result of running a single test
typedef TestRunResult = ({
  bool passed,
  String testName,
  int durationMs,
  String? errorMessage,
  String? stackTrace,
});

/// Performance metrics as a record
typedef PerformanceMetrics = ({
  double averageDuration,
  double maxDuration,
  double minDuration,
  int sampleSize,
});

/// Coverage summary as a record
typedef CoverageSummary = ({
  double overallCoverage,
  int filesAnalyzed,
  int totalLines,
  int coveredLines,
  int uncoveredLines,
});

/// Test reliability metrics as a record
typedef ReliabilityMetrics = ({
  double passRate,
  double stabilityScore,
  int totalTests,
  int consistentPasses,
  int consistentFailures,
  int flakyTests,
});

/// File coverage data as a record
typedef FileCoverage = ({
  String filePath,
  double coverage,
  int totalLines,
  int coveredLines,
  List<int> uncoveredLines,
});

/// Test timing data as a record
typedef TestTiming = ({
  String testId,
  Duration duration,
  DateTime timestamp,
  bool passed,
});

/// Helper functions for creating common result patterns

/// Create a successful analysis result
AnalysisResult successfulAnalysis({
  required int totalTests,
  required int passedTests,
  required int failedTests,
}) =>
    (
      success: true,
      totalTests: totalTests,
      passedTests: passedTests,
      failedTests: failedTests,
      error: null,
    );

/// Create a failed analysis result
AnalysisResult failedAnalysis(String error) => (
      success: false,
      totalTests: 0,
      passedTests: 0,
      failedTests: 0,
      error: error,
    );

/// Create a successful coverage result
CoverageResult successfulCoverage({
  required double coverage,
  required int totalLines,
  required int coveredLines,
}) =>
    (
      success: true,
      coverage: coverage,
      totalLines: totalLines,
      coveredLines: coveredLines,
      error: null,
    );

/// Create a failed coverage result
CoverageResult failedCoverage(String error) => (
      success: false,
      coverage: 0.0,
      totalLines: 0,
      coveredLines: 0,
      error: error,
    );

/// Create a successful test file load result
TestFileResult successfulLoad(String filePath, int loadTimeMs) => (
      success: true,
      filePath: filePath,
      loadTimeMs: loadTimeMs,
      error: null,
    );

/// Create a failed test file load result
TestFileResult failedLoad(String filePath, String error) => (
      success: false,
      filePath: filePath,
      loadTimeMs: 0,
      error: error,
    );

/// Create a passing test run result
TestRunResult passingTest(String testName, int durationMs) => (
      passed: true,
      testName: testName,
      durationMs: durationMs,
      errorMessage: null,
      stackTrace: null,
    );

/// Create a failing test run result
TestRunResult failingTest(
  String testName,
  int durationMs,
  String errorMessage,
  String stackTrace,
) =>
    (
      passed: false,
      testName: testName,
      durationMs: durationMs,
      errorMessage: errorMessage,
      stackTrace: stackTrace,
    );

/// Calculate performance metrics from a list of durations
PerformanceMetrics calculatePerformanceMetrics(List<double> durations) {
  if (durations.isEmpty) {
    return (
      averageDuration: 0.0,
      maxDuration: 0.0,
      minDuration: 0.0,
      sampleSize: 0,
    );
  }

  final sum = durations.reduce((a, b) => a + b);
  final avg = sum / durations.length;
  final max = durations.reduce((a, b) => a > b ? a : b);
  final min = durations.reduce((a, b) => a < b ? a : b);

  return (
    averageDuration: avg,
    maxDuration: max,
    minDuration: min,
    sampleSize: durations.length,
  );
}

/// Create coverage summary from analysis data
CoverageSummary createCoverageSummary({
  required double overallCoverage,
  required int filesAnalyzed,
  required int totalLines,
  required int coveredLines,
}) =>
    (
      overallCoverage: overallCoverage,
      filesAnalyzed: filesAnalyzed,
      totalLines: totalLines,
      coveredLines: coveredLines,
      uncoveredLines: totalLines - coveredLines,
    );

/// Create reliability metrics from test results
ReliabilityMetrics createReliabilityMetrics({
  required int totalTests,
  required int consistentPasses,
  required int consistentFailures,
  required int flakyTests,
}) {
  final passRate =
      totalTests > 0 ? (consistentPasses / totalTests * 100) : 100.0;
  final stabilityScore = totalTests > 0
      ? ((totalTests - consistentFailures - flakyTests * 0.5) /
          totalTests *
          100)
      : 100.0;

  return (
    passRate: passRate,
    stabilityScore: stabilityScore,
    totalTests: totalTests,
    consistentPasses: consistentPasses,
    consistentFailures: consistentFailures,
    flakyTests: flakyTests,
  );
}

/// Pattern matching helpers for results

/// Check if analysis was successful and extract data
T? onAnalysisSuccess<T>(
  AnalysisResult result,
  T Function(int totalTests, int passedTests, int failedTests) onSuccess,
) {
  if (result.success) {
    return onSuccess(result.totalTests, result.passedTests, result.failedTests);
  }
  return null;
}

/// Check if coverage was successful and extract data
T? onCoverageSuccess<T>(
  CoverageResult result,
  T Function(double coverage, int totalLines, int coveredLines) onSuccess,
) {
  if (result.success) {
    return onSuccess(result.coverage, result.totalLines, result.coveredLines);
  }
  return null;
}

/// Handle result with success and error cases
T handleAnalysisResult<T>(
  AnalysisResult result, {
  required T Function(int totalTests, int passedTests, int failedTests)
      onSuccess,
  required T Function(String error) onError,
}) {
  if (result.success) {
    return onSuccess(result.totalTests, result.passedTests, result.failedTests);
  }
  return onError(result.error!);
}

/// Handle coverage result with success and error cases
T handleCoverageResult<T>(
  CoverageResult result, {
  required T Function(double coverage, int totalLines, int coveredLines)
      onSuccess,
  required T Function(String error) onError,
}) {
  if (result.success) {
    return onSuccess(result.coverage, result.totalLines, result.coveredLines);
  }
  return onError(result.error!);
}
