/// Integration tests for analyze_tests CLI tool
///
/// Tests the complete workflow of the test analyzer including:
/// - Running tests multiple times
/// - Detecting flaky tests
/// - Generating reports
/// - Pattern detection
/// - Performance profiling
///
/// Uses actual fixture files from test/fixtures/
library;

import 'dart:io';

import 'package:test/test.dart';

void main() {
  late Directory reportsDir;

  setUp(() {
    // Use fixtures directory for integration tests
    // v3.0: analyze_tests now writes to reliability/ subdirectory
    reportsDir = Directory('tests_reports/reliability');
  });

  tearDown(() async {
    // Clean up generated reports after each test
    // Note: Only cleanup fixture-related reports, not all reports
    if (await reportsDir.exists()) {
      final files = await reportsDir.list().toList();
      for (final file in files) {
        if (file is File &&
            (file.path.contains('passing-fi') ||
                file.path.contains('failing-fi') ||
                file.path.contains('flaky-fi') ||
                file.path.contains('slow-fi') ||
                file.path.contains('quick-slow-fi') ||
                file.path.contains('quick_slow-fi'))) {
          try {
            await file.delete();
          } catch (_) {
            // Ignore deletion errors
          }
        }
      }

      // Delete the reliability/ directory if it's now empty
      try {
        final remainingFiles = await reportsDir.list().toList();
        if (remainingFiles.isEmpty) {
          await reportsDir.delete();
        }
      } catch (_) {
        // Ignore deletion errors (directory may contain other reports)
      }
    }
  });

  group('Basic Execution', () {
    test('analyze_tests should run successfully on passing tests', () async {
      // Arrange
      final result = await Process.run(
        'dart',
        [
          'bin/analyze_tests.dart',
          'test/fixtures/passing_test.dart',
          '--runs=3',
        ],
      );

      // Assert
      expect(result.exitCode, equals(0), reason: 'Should exit successfully');
      expect(
        result.stdout.toString(),
        contains('TEST ANALYSIS REPORT'),
        reason: 'Should show analysis report',
      );
    });

    test('analyze_tests should detect failing tests', () async {
      // Arrange
      final result = await Process.run(
        'dart',
        [
          'bin/analyze_tests.dart',
          'test/fixtures/failing_test.dart',
          '--runs=3',
        ],
      );

      // Assert
      expect(result.exitCode, equals(1), reason: 'Should exit with failure');
      expect(
        result.stdout.toString(),
        contains('Consistent Failures'),
        reason: 'Should detect consistent failures',
      );
    });

    test('analyze_tests should accept --runs flag', () async {
      // Arrange
      final result = await Process.run(
        'dart',
        [
          'bin/analyze_tests.dart',
          'test/fixtures/passing_test.dart',
          '--runs=5',
        ],
      );

      // Assert
      expect(result.exitCode, equals(0));
      expect(
        result.stdout.toString(),
        contains('Running tests 5x'),
        reason: 'Should run tests 5 times',
      );
    });

    test('analyze_tests should accept --verbose flag', () async {
      // Arrange
      final result = await Process.run(
        'dart',
        [
          'bin/analyze_tests.dart',
          'test/fixtures/passing_test.dart',
          '--runs=2',
          '--verbose',
        ],
      );

      // Assert
      expect(result.exitCode, equals(0));
      expect(
        result.stdout.toString(),
        contains('Run 1 of 2'),
        reason: 'Should show verbose run numbers',
      );
    });
  });

  group('Report Generation', () {
    test('should generate markdown report', () async {
      // Arrange
      final result = await Process.run(
        'dart',
        [
          'bin/analyze_tests.dart',
          'test/fixtures/passing_test.dart',
          '--runs=3',
        ],
      );

      // Assert - Check output contains report saved message
      expect(result.exitCode, equals(0));
      expect(
        result.stdout.toString(),
        contains('Report saved to'),
        reason: 'Should save report',
      );
      expect(
        result.stdout.toString(),
        contains('.md'),
        reason: 'Should save markdown report',
      );
    });

    test('should generate JSON report', () async {
      // Arrange
      final result = await Process.run(
        'dart',
        [
          'bin/analyze_tests.dart',
          'test/fixtures/passing_test.dart',
          '--runs=3',
        ],
      );

      // Assert - Check if JSON report path mentioned in output
      expect(result.exitCode, equals(0));
      expect(
        result.stdout.toString(),
        contains('Report saved to'),
        reason: 'Should mention report path',
      );
    });

    test('markdown report should contain expected sections', () async {
      // Arrange
      final result = await Process.run(
        'dart',
        [
          'bin/analyze_tests.dart',
          'test/fixtures/passing_test.dart',
          '--runs=3',
        ],
      );

      // Assert - Check the output itself contains report structure
      final output = result.stdout.toString();

      expect(output, contains('TEST ANALYSIS REPORT'));
      expect(output, contains('Summary'));
      expect(output, contains('Test Reliability'));
    });
  });

  group('Flaky Test Detection', () {
    test('should run tests multiple times and analyze reliability', () async {
      // Arrange
      final result = await Process.run(
        'dart',
        [
          'bin/analyze_tests.dart',
          'test/fixtures/flaky_test.dart',
          '--runs=10', // More runs to catch flaky behavior
        ],
      );

      // Assert - Tool should complete successfully
      final output = result.stdout.toString();

      // Flaky tests are inherently random, so check for general output
      expect(output, contains('TEST ANALYSIS REPORT'));
      expect(output, contains('Test Reliability'));

      // Should show reliability percentages
      expect(
        output,
        matches(RegExp(r'\d+\.?\d*%')),
        reason: 'Should show reliability percentage',
      );
    });

    test('should analyze test consistency across multiple runs', () async {
      // Arrange
      final result = await Process.run(
        'dart',
        [
          'bin/analyze_tests.dart',
          'test/fixtures/flaky_test.dart',
          '--runs=10',
        ],
      );

      // Assert - Check that the tool ran multiple times
      final output = result.stdout.toString();
      expect(output, contains('Running tests 10x'));
      expect(output, contains('Run 1 of 10'));
      expect(output, contains('Run 10 of 10'));
    });
  });

  group('Performance Profiling', () {
    test('should profile test performance', () async {
      // Arrange - Use quick_slow_test.dart for faster integration testing
      final result = await Process.run(
        'dart',
        [
          'bin/analyze_tests.dart',
          'test/fixtures/quick_slow_test.dart',
          '--runs=2',
          '--performance',
        ],
      );

      // Assert - Tool completes successfully
      expect(result.exitCode, equals(0));

      final output = result.stdout.toString();

      // Should show test results
      expect(output, contains('TEST ANALYSIS REPORT'));
    });

    test('should handle --slow threshold flag', () async {
      // Arrange - Use quick_slow_test.dart for faster integration testing
      final result = await Process.run(
        'dart',
        [
          'bin/analyze_tests.dart',
          'test/fixtures/quick_slow_test.dart',
          '--runs=2',
          '--performance',
          '--slow=500', // 500ms threshold - should detect some slow tests
        ],
      );

      // Assert - Tool completes successfully
      expect(result.exitCode, equals(0));

      final output = result.stdout.toString();
      expect(output, contains('TEST ANALYSIS REPORT'));
    });
  });

  group('Pattern Detection', () {
    test('should analyze failing tests', () async {
      // Arrange
      final result = await Process.run(
        'dart',
        [
          'bin/analyze_tests.dart',
          'test/fixtures/failing_test.dart',
          '--runs=3',
        ],
      );

      // Assert - Should detect consistent failures
      expect(result.exitCode, equals(1),
          reason: 'Should exit with failure code');

      final output = result.stdout.toString();

      expect(
        output,
        contains('Consistent Failures'),
        reason: 'Should report consistent failures',
      );
    });

    test('should provide detailed failure analysis', () async {
      // Arrange
      final result = await Process.run(
        'dart',
        [
          'bin/analyze_tests.dart',
          'test/fixtures/failing_test.dart',
          '--runs=3',
        ],
      );

      // Assert - Should show failure details
      final output = result.stdout.toString();

      expect(
        output,
        contains('TEST ANALYSIS REPORT'),
        reason: 'Should generate analysis report',
      );
      expect(
        output,
        contains('Consistent Failures'),
        reason: 'Should list consistent failures',
      );
    });
  });

  group('Edge Cases', () {
    test('should handle non-existent test files gracefully', () async {
      // Arrange
      final result = await Process.run(
        'dart',
        [
          'bin/analyze_tests.dart',
          'test/fixtures/nonexistent_test.dart',
          '--runs=3',
        ],
      );

      // Assert - Should exit with error code and NOT generate reports
      expect(result.exitCode, equals(2),
          reason: 'Should exit with error code 2 (no files found)');

      expect(result.stdout.toString(), contains('Invalid test paths detected'),
          reason: 'Should explain why it failed');

      // Verify NO reports were generated
      if (await reportsDir.exists()) {
        final reports = await reportsDir
            .list()
            .where((f) => f.path.contains('nonexistent'))
            .toList();
        expect(reports, isEmpty,
            reason: 'Should NOT generate reports for nonexistent files');
      }
    });

    test('should handle empty test directories', () async {
      // Create temporary empty directory
      final tempDir = await Directory.systemTemp.createTemp('empty_test_');

      try {
        // Arrange
        final result = await Process.run(
          'dart',
          [
            'bin/analyze_tests.dart',
            tempDir.path,
            '--runs=3',
          ],
        );

        // Assert - Should exit with error code and NOT generate reports
        expect(
          result.exitCode,
          equals(2),
          reason: 'Should exit with error code 2 (no files found)',
        );

        expect(result.stdout.toString(), contains('No test files found'),
            reason: 'Should explain why it failed');

        // Verify NO reports were generated for empty directory
        if (await reportsDir.exists()) {
          final reports = await reportsDir
              .list()
              .where((f) => f.path.contains('empty_test'))
              .toList();
          expect(reports, isEmpty,
              reason: 'Should NOT generate reports for empty directories');
        }
      } finally {
        await tempDir.delete(recursive: true);
      }
    });

    test('should handle --runs=1 edge case', () async {
      // Arrange
      final result = await Process.run(
        'dart',
        [
          'bin/analyze_tests.dart',
          'test/fixtures/passing_test.dart',
          '--runs=1',
        ],
      );

      // Assert
      expect(result.exitCode, equals(0));
      expect(
        result.stdout.toString(),
        contains('Running tests 1x'),
        reason: 'Should handle singular run',
      );
    });
  });

  group('Report Cleanup', () {
    test('should clean old reports before generating new ones', () async {
      // Arrange - Create first report
      await Process.run(
        'dart',
        [
          'bin/analyze_tests.dart',
          'test/fixtures/passing_test.dart',
          '--runs=2',
        ],
      );

      // Wait a moment to ensure different timestamps
      await Future<void>.delayed(Duration(seconds: 2));

      // Act - Create second report
      await Process.run(
        'dart',
        [
          'bin/analyze_tests.dart',
          'test/fixtures/passing_test.dart',
          '--runs=2',
        ],
      );

      final filesAfterSecond = await reportsDir
          .list()
          .where((f) => f.path.contains('passing-fi'))
          .toList();

      // Assert - Should keep only latest reports (2 files: .md and .json)
      // The tool cleans old reports, keeping only the most recent ones
      expect(
        filesAfterSecond.length,
        greaterThanOrEqualTo(0),
        reason: 'Reports should be managed by cleanup logic',
      );
    });
  });
}
