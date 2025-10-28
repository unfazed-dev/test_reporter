/// Constants used across analyzer tools
class AnalyzerConstants {
  // Performance thresholds
  static const Duration defaultSlowTestThreshold = Duration(seconds: 1);
  static const Duration testDelayBetweenRuns = Duration(milliseconds: 500);
  static const Duration watchModeDebounce = Duration(seconds: 1);

  // Parallel execution
  static const int defaultMaxWorkers = 4;
  static const int defaultChunkSize = 10;

  // Report settings
  static const String reportDirectory =
      'test_analyzer_reports'; // In project root
  static const String reportSuffix = 'test_report';

  // Coverage thresholds
  static const double defaultMinimumCoverage = 80;
  static const double defaultWarningCoverage = 90;
  static const double goodCoverageThreshold = 90;
  static const double acceptableCoverageThreshold = 60;

  // Colors (ANSI)
  static const String reset = '\x1B[0m';
  static const String bold = '\x1B[1m';
  static const String red = '\x1B[31m';
  static const String green = '\x1B[32m';
  static const String yellow = '\x1B[33m';
  static const String blue = '\x1B[34m';
  static const String cyan = '\x1B[36m';
  static const String gray = '\x1B[90m';
}
