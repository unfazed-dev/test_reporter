import 'package:test/test.dart';
import 'package:test_reporter/src/utils/constants.dart';

void main() {
  group('AnalyzerConstants', () {
    group('Performance Thresholds', () {
      test('defaultSlowTestThreshold should be 1 second', () {
        expect(
          AnalyzerConstants.defaultSlowTestThreshold,
          equals(const Duration(seconds: 1)),
        );
        expect(
          AnalyzerConstants.defaultSlowTestThreshold.inMilliseconds,
          equals(1000),
        );
      });

      test('testDelayBetweenRuns should be 500 milliseconds', () {
        expect(
          AnalyzerConstants.testDelayBetweenRuns,
          equals(const Duration(milliseconds: 500)),
        );
        expect(
            AnalyzerConstants.testDelayBetweenRuns.inMilliseconds, equals(500));
      });

      test('watchModeDebounce should be 1 second', () {
        expect(
          AnalyzerConstants.watchModeDebounce,
          equals(const Duration(seconds: 1)),
        );
        expect(
            AnalyzerConstants.watchModeDebounce.inMilliseconds, equals(1000));
      });

      test('all performance durations should be positive', () {
        expect(
          AnalyzerConstants.defaultSlowTestThreshold.inMilliseconds,
          greaterThan(0),
        );
        expect(
          AnalyzerConstants.testDelayBetweenRuns.inMilliseconds,
          greaterThan(0),
        );
        expect(
          AnalyzerConstants.watchModeDebounce.inMilliseconds,
          greaterThan(0),
        );
      });

      test('performance durations should have proper ordering', () {
        // Test delay should be less than slow test threshold
        expect(
          AnalyzerConstants.testDelayBetweenRuns,
          lessThan(AnalyzerConstants.defaultSlowTestThreshold),
        );
      });
    });

    group('Parallel Execution Settings', () {
      test('defaultMaxWorkers should be 4', () {
        expect(AnalyzerConstants.defaultMaxWorkers, equals(4));
      });

      test('defaultChunkSize should be 10', () {
        expect(AnalyzerConstants.defaultChunkSize, equals(10));
      });

      test('parallel execution values should be positive', () {
        expect(AnalyzerConstants.defaultMaxWorkers, greaterThan(0));
        expect(AnalyzerConstants.defaultChunkSize, greaterThan(0));
      });

      test('defaultMaxWorkers should be reasonable for parallel execution', () {
        expect(AnalyzerConstants.defaultMaxWorkers, greaterThanOrEqualTo(1));
        expect(AnalyzerConstants.defaultMaxWorkers, lessThanOrEqualTo(32));
      });

      test('defaultChunkSize should be greater than defaultMaxWorkers', () {
        // Chunk size should be larger than worker count for efficiency
        expect(
          AnalyzerConstants.defaultChunkSize,
          greaterThan(AnalyzerConstants.defaultMaxWorkers),
        );
      });
    });

    group('Report Settings', () {
      test('reportDirectory should be tests_reports', () {
        expect(AnalyzerConstants.reportDirectory, equals('tests_reports'));
      });

      test('reportSuffix should be report', () {
        expect(AnalyzerConstants.reportSuffix, equals('report'));
      });

      test('report directory should not be empty', () {
        expect(AnalyzerConstants.reportDirectory, isNotEmpty);
      });

      test('report suffix should not be empty', () {
        expect(AnalyzerConstants.reportSuffix, isNotEmpty);
      });

      test('report directory should not start with slash', () {
        expect(AnalyzerConstants.reportDirectory.startsWith('/'), isFalse);
      });

      test('report directory should be a simple path', () {
        expect(AnalyzerConstants.reportDirectory.contains('..'), isFalse);
      });
    });

    group('Coverage Thresholds', () {
      test('defaultMinimumCoverage should be 80', () {
        expect(AnalyzerConstants.defaultMinimumCoverage, equals(80.0));
      });

      test('defaultWarningCoverage should be 90', () {
        expect(AnalyzerConstants.defaultWarningCoverage, equals(90.0));
      });

      test('goodCoverageThreshold should be 90', () {
        expect(AnalyzerConstants.goodCoverageThreshold, equals(90.0));
      });

      test('acceptableCoverageThreshold should be 60', () {
        expect(AnalyzerConstants.acceptableCoverageThreshold, equals(60.0));
      });

      test('all coverage thresholds should be between 0 and 100', () {
        expect(
            AnalyzerConstants.defaultMinimumCoverage, greaterThanOrEqualTo(0));
        expect(
            AnalyzerConstants.defaultMinimumCoverage, lessThanOrEqualTo(100));

        expect(
            AnalyzerConstants.defaultWarningCoverage, greaterThanOrEqualTo(0));
        expect(
            AnalyzerConstants.defaultWarningCoverage, lessThanOrEqualTo(100));

        expect(
            AnalyzerConstants.goodCoverageThreshold, greaterThanOrEqualTo(0));
        expect(AnalyzerConstants.goodCoverageThreshold, lessThanOrEqualTo(100));

        expect(
          AnalyzerConstants.acceptableCoverageThreshold,
          greaterThanOrEqualTo(0),
        );
        expect(
          AnalyzerConstants.acceptableCoverageThreshold,
          lessThanOrEqualTo(100),
        );
      });

      test('coverage thresholds should have proper ordering', () {
        // acceptable < minimum < warning/good
        expect(
          AnalyzerConstants.acceptableCoverageThreshold,
          lessThan(AnalyzerConstants.defaultMinimumCoverage),
        );
        expect(
          AnalyzerConstants.defaultMinimumCoverage,
          lessThanOrEqualTo(AnalyzerConstants.defaultWarningCoverage),
        );
        expect(
          AnalyzerConstants.defaultMinimumCoverage,
          lessThanOrEqualTo(AnalyzerConstants.goodCoverageThreshold),
        );
      });

      test('warning and good coverage thresholds should be equal', () {
        expect(
          AnalyzerConstants.defaultWarningCoverage,
          equals(AnalyzerConstants.goodCoverageThreshold),
        );
      });
    });

    group('ANSI Color Codes', () {
      test('reset should be ANSI reset code', () {
        expect(AnalyzerConstants.reset, equals('\x1B[0m'));
      });

      test('bold should be ANSI bold code', () {
        expect(AnalyzerConstants.bold, equals('\x1B[1m'));
      });

      test('red should be ANSI red code', () {
        expect(AnalyzerConstants.red, equals('\x1B[31m'));
      });

      test('green should be ANSI green code', () {
        expect(AnalyzerConstants.green, equals('\x1B[32m'));
      });

      test('yellow should be ANSI yellow code', () {
        expect(AnalyzerConstants.yellow, equals('\x1B[33m'));
      });

      test('blue should be ANSI blue code', () {
        expect(AnalyzerConstants.blue, equals('\x1B[34m'));
      });

      test('cyan should be ANSI cyan code', () {
        expect(AnalyzerConstants.cyan, equals('\x1B[36m'));
      });

      test('gray should be ANSI gray code', () {
        expect(AnalyzerConstants.gray, equals('\x1B[90m'));
      });

      test('all color codes should start with escape sequence', () {
        expect(AnalyzerConstants.reset.startsWith('\x1B['), isTrue);
        expect(AnalyzerConstants.bold.startsWith('\x1B['), isTrue);
        expect(AnalyzerConstants.red.startsWith('\x1B['), isTrue);
        expect(AnalyzerConstants.green.startsWith('\x1B['), isTrue);
        expect(AnalyzerConstants.yellow.startsWith('\x1B['), isTrue);
        expect(AnalyzerConstants.blue.startsWith('\x1B['), isTrue);
        expect(AnalyzerConstants.cyan.startsWith('\x1B['), isTrue);
        expect(AnalyzerConstants.gray.startsWith('\x1B['), isTrue);
      });

      test('all color codes should end with m', () {
        expect(AnalyzerConstants.reset.endsWith('m'), isTrue);
        expect(AnalyzerConstants.bold.endsWith('m'), isTrue);
        expect(AnalyzerConstants.red.endsWith('m'), isTrue);
        expect(AnalyzerConstants.green.endsWith('m'), isTrue);
        expect(AnalyzerConstants.yellow.endsWith('m'), isTrue);
        expect(AnalyzerConstants.blue.endsWith('m'), isTrue);
        expect(AnalyzerConstants.cyan.endsWith('m'), isTrue);
        expect(AnalyzerConstants.gray.endsWith('m'), isTrue);
      });

      test('color codes should have valid ANSI format', () {
        final validAnsiPattern = RegExp(r'^\x1B\[\d+m$');

        expect(AnalyzerConstants.reset, matches(validAnsiPattern));
        expect(AnalyzerConstants.bold, matches(validAnsiPattern));
        expect(AnalyzerConstants.red, matches(validAnsiPattern));
        expect(AnalyzerConstants.green, matches(validAnsiPattern));
        expect(AnalyzerConstants.yellow, matches(validAnsiPattern));
        expect(AnalyzerConstants.blue, matches(validAnsiPattern));
        expect(AnalyzerConstants.cyan, matches(validAnsiPattern));
        expect(AnalyzerConstants.gray, matches(validAnsiPattern));
      });

      test('color codes should not be empty', () {
        expect(AnalyzerConstants.reset, isNotEmpty);
        expect(AnalyzerConstants.bold, isNotEmpty);
        expect(AnalyzerConstants.red, isNotEmpty);
        expect(AnalyzerConstants.green, isNotEmpty);
        expect(AnalyzerConstants.yellow, isNotEmpty);
        expect(AnalyzerConstants.blue, isNotEmpty);
        expect(AnalyzerConstants.cyan, isNotEmpty);
        expect(AnalyzerConstants.gray, isNotEmpty);
      });
    });

    group('Type Safety', () {
      test('performance threshold constants should be Duration type', () {
        expect(AnalyzerConstants.defaultSlowTestThreshold, isA<Duration>());
        expect(AnalyzerConstants.testDelayBetweenRuns, isA<Duration>());
        expect(AnalyzerConstants.watchModeDebounce, isA<Duration>());
      });

      test('parallel execution constants should be int type', () {
        expect(AnalyzerConstants.defaultMaxWorkers, isA<int>());
        expect(AnalyzerConstants.defaultChunkSize, isA<int>());
      });

      test('report settings constants should be String type', () {
        expect(AnalyzerConstants.reportDirectory, isA<String>());
        expect(AnalyzerConstants.reportSuffix, isA<String>());
      });

      test('coverage threshold constants should be double type', () {
        expect(AnalyzerConstants.defaultMinimumCoverage, isA<double>());
        expect(AnalyzerConstants.defaultWarningCoverage, isA<double>());
        expect(AnalyzerConstants.goodCoverageThreshold, isA<double>());
        expect(AnalyzerConstants.acceptableCoverageThreshold, isA<double>());
      });

      test('color code constants should be String type', () {
        expect(AnalyzerConstants.reset, isA<String>());
        expect(AnalyzerConstants.bold, isA<String>());
        expect(AnalyzerConstants.red, isA<String>());
        expect(AnalyzerConstants.green, isA<String>());
        expect(AnalyzerConstants.yellow, isA<String>());
        expect(AnalyzerConstants.blue, isA<String>());
        expect(AnalyzerConstants.cyan, isA<String>());
        expect(AnalyzerConstants.gray, isA<String>());
      });
    });

    group('Constant Accessibility', () {
      test('all constants should be accessible without instantiation', () {
        // Performance thresholds
        expect(
            () => AnalyzerConstants.defaultSlowTestThreshold, returnsNormally);
        expect(() => AnalyzerConstants.testDelayBetweenRuns, returnsNormally);
        expect(() => AnalyzerConstants.watchModeDebounce, returnsNormally);

        // Parallel execution
        expect(() => AnalyzerConstants.defaultMaxWorkers, returnsNormally);
        expect(() => AnalyzerConstants.defaultChunkSize, returnsNormally);

        // Report settings
        expect(() => AnalyzerConstants.reportDirectory, returnsNormally);
        expect(() => AnalyzerConstants.reportSuffix, returnsNormally);

        // Coverage thresholds
        expect(() => AnalyzerConstants.defaultMinimumCoverage, returnsNormally);
        expect(() => AnalyzerConstants.defaultWarningCoverage, returnsNormally);
        expect(() => AnalyzerConstants.goodCoverageThreshold, returnsNormally);
        expect(() => AnalyzerConstants.acceptableCoverageThreshold,
            returnsNormally);

        // Colors
        expect(() => AnalyzerConstants.reset, returnsNormally);
        expect(() => AnalyzerConstants.bold, returnsNormally);
        expect(() => AnalyzerConstants.red, returnsNormally);
        expect(() => AnalyzerConstants.green, returnsNormally);
        expect(() => AnalyzerConstants.yellow, returnsNormally);
        expect(() => AnalyzerConstants.blue, returnsNormally);
        expect(() => AnalyzerConstants.cyan, returnsNormally);
        expect(() => AnalyzerConstants.gray, returnsNormally);
      });

      test('constants should be compile-time constants', () {
        // This test verifies that constants can be used in const contexts
        const slowTestThreshold = AnalyzerConstants.defaultSlowTestThreshold;
        const maxWorkers = AnalyzerConstants.defaultMaxWorkers;
        const reportDir = AnalyzerConstants.reportDirectory;
        const minCoverage = AnalyzerConstants.defaultMinimumCoverage;
        const redColor = AnalyzerConstants.red;

        expect(slowTestThreshold, isA<Duration>());
        expect(maxWorkers, isA<int>());
        expect(reportDir, isA<String>());
        expect(minCoverage, isA<double>());
        expect(redColor, isA<String>());
      });
    });

    group('Edge Cases and Integration', () {
      test('coverage thresholds work with percentage calculations', () {
        const totalLines = 100;

        final minLines =
            (totalLines * AnalyzerConstants.defaultMinimumCoverage / 100)
                .round();
        final acceptableLines =
            (totalLines * AnalyzerConstants.acceptableCoverageThreshold / 100)
                .round();

        expect(minLines, equals(80));
        expect(acceptableLines, equals(60));
      });

      test('slow test threshold can be used with Duration comparisons', () {
        const fastTest = Duration(milliseconds: 500);
        const slowTest = Duration(seconds: 2);

        expect(
          fastTest < AnalyzerConstants.defaultSlowTestThreshold,
          isTrue,
          reason: 'Fast test should be below threshold',
        );
        expect(
          slowTest > AnalyzerConstants.defaultSlowTestThreshold,
          isTrue,
          reason: 'Slow test should be above threshold',
        );
      });

      test('color codes can be concatenated for formatted output', () {
        final formattedText =
            '${AnalyzerConstants.bold}${AnalyzerConstants.red}Error${AnalyzerConstants.reset}';

        expect(formattedText, contains('\x1B[1m'));
        expect(formattedText, contains('\x1B[31m'));
        expect(formattedText, contains('Error'));
        expect(formattedText, contains('\x1B[0m'));
        expect(formattedText, equals('\x1B[1m\x1B[31mError\x1B[0m'));
      });

      test('parallel execution settings work with worker pools', () {
        final workers = AnalyzerConstants.defaultMaxWorkers;
        final chunkSize = AnalyzerConstants.defaultChunkSize;

        // Simulate distributing 50 tests across workers
        const totalTests = 50;
        final testsPerWorker = (totalTests / workers).ceil();

        expect(testsPerWorker, greaterThan(0));
        expect(testsPerWorker, greaterThanOrEqualTo(12));

        // Each chunk should be able to be processed by a worker
        final totalChunks = (totalTests / chunkSize).ceil();
        expect(totalChunks, equals(5));
      });

      test('report directory can be used for path construction', () {
        final reportPath =
            '${AnalyzerConstants.reportDirectory}/test_report.md';

        expect(reportPath, equals('tests_reports/test_report.md'));
        expect(
            reportPath.startsWith(AnalyzerConstants.reportDirectory), isTrue);
      });
    });
  });
}
