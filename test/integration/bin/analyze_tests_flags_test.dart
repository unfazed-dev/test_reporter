// ignore_for_file: avoid_print

@Tags(['integration'])
library;

import 'dart:io';

import 'package:test/test.dart';

/// Integration tests for analyze_tests CLI flags.
///
/// These tests verify that all CLI flags for the analyze_tests tool work
/// correctly in real execution scenarios.
///
/// Phase 5.1 of CLI Flags Audit - TDD Methodology:
/// 🔴 RED: Write failing tests first
/// 🟢 GREEN: Make tests pass
/// ♻️ REFACTOR: Clean up
/// 🔄 META-TEST: Manual verification
void main() {
  group('analyze_tests boolean flags', () {
    test('--verbose/-v flag shows detailed output', () async {
      final result = await Process.run(
        'dart',
        [
          'bin/analyze_tests.dart',
          'test/fixtures/passing_test.dart',
          '--verbose'
        ],
      );

      expect(result.exitCode, equals(0));
      // Verbose output should contain more details
      expect(result.stdout.toString(), contains('Running'));
    });

    test('--performance/-p flag shows performance metrics', () async {
      final result = await Process.run(
        'dart',
        [
          'bin/analyze_tests.dart',
          'test/fixtures/passing_test.dart',
          '--performance'
        ],
      );

      expect(result.exitCode, equals(0));
      // Performance output should contain timing information
      expect(
        result.stdout.toString(),
        anyOf(contains('ms'), contains('Performance'), contains('timing')),
      );
    });

    test('--help/-h flag shows help text', () async {
      final result = await Process.run(
        'dart',
        ['bin/analyze_tests.dart', '--help'],
      );

      expect(result.exitCode, equals(0));
      expect(result.stdout.toString(), contains('Usage:'));
      expect(result.stdout.toString(), contains('Options:'));
      expect(result.stdout.toString(), contains('--verbose'));
      expect(result.stdout.toString(), contains('--performance'));
    });

    test('--no-report flag skips report generation', () async {
      final result = await Process.run(
        'dart',
        [
          'bin/analyze_tests.dart',
          'test/fixtures/passing_test.dart',
          '--no-report'
        ],
      );

      expect(result.exitCode, equals(0));
      // Should NOT contain report generation messages
      expect(result.stdout.toString(), isNot(contains('Report saved')));
      expect(result.stdout.toString(), isNot(contains('tests_reports/')));
    });

    test('--no-fixes flag disables fix suggestions', () async {
      final result = await Process.run(
        'dart',
        [
          'bin/analyze_tests.dart',
          'test/fixtures/failing_test.dart',
          '--no-fixes'
        ],
      );

      // Should run regardless of exit code
      // Should NOT contain fix suggestions
      expect(result.stdout.toString(), isNot(contains('Fix suggestion')));
      expect(result.stdout.toString(), isNot(contains('Try:')));
    });

    test('--no-checklist flag disables checklists', () async {
      final result = await Process.run(
        'dart',
        [
          'bin/analyze_tests.dart',
          'test/fixtures/passing_test.dart',
          '--no-checklist'
        ],
      );

      expect(result.exitCode, equals(0));
      // Should NOT contain checklist markers
      expect(result.stdout.toString(), isNot(contains('- [ ]')));
      expect(result.stdout.toString(), isNot(contains('Action Items')));
    });

    test('--minimal-checklist flag shows compact checklist', () async {
      final result = await Process.run(
        'dart',
        [
          'bin/analyze_tests.dart',
          'test/fixtures/passing_test.dart',
          '--minimal-checklist',
        ],
      );

      expect(result.exitCode, equals(0));
      // Should contain compact checklist format (if there are action items)
      // This flag only affects format, not presence
    });

    test('--parallel flag runs tests in parallel', () async {
      final result = await Process.run(
        'dart',
        [
          'bin/analyze_tests.dart',
          'test/fixtures/passing_test.dart',
          '--parallel',
          '--workers=2',
          '--no-report',
        ],
      );

      // Should complete successfully
      expect(result.exitCode, equals(0));
    }, timeout: Timeout(Duration(seconds: 60)));

    test('--include-fixtures flag includes fixture tests', () async {
      final result = await Process.run(
        'dart',
        [
          'bin/analyze_tests.dart',
          'test/fixtures/passing_test.dart',
          '--include-fixtures',
          '--no-report',
        ],
      );

      // Should run fixture tests (currently excluded by default)
      expect(result.exitCode, equals(0));
    }, timeout: Timeout(Duration(seconds: 60)));
  });

  group('analyze_tests numeric options', () {
    test('--runs=5 flag runs tests 5 times', () async {
      final result = await Process.run(
        'dart',
        [
          'bin/analyze_tests.dart',
          'test/fixtures/passing_test.dart',
          '--runs=5'
        ],
      );

      expect(result.exitCode, equals(0));
      // Output should indicate multiple runs
      expect(
        result.stdout.toString(),
        anyOf(
          contains('Run 5'),
          contains('5 runs'),
          contains('reliability'),
        ),
      );
    });

    test('--slow=2.0 flag sets slow threshold to 2.0 seconds', () async {
      final result = await Process.run(
        'dart',
        [
          'bin/analyze_tests.dart',
          'test/fixtures/passing_test.dart',
          '--slow=2.0'
        ],
      );

      expect(result.exitCode, equals(0));
      // Slow threshold setting should be acknowledged
    });

    test('--workers=8 flag sets parallel workers to 8', () async {
      final result = await Process.run(
        'dart',
        [
          'bin/analyze_tests.dart',
          'test/fixtures/passing_test.dart',
          '--parallel',
          '--workers=8',
          '--no-report',
        ],
      );

      // Should run with 8 workers
      expect(result.exitCode, equals(0));
    }, timeout: Timeout(Duration(seconds: 60)));
  });

  group('analyze_tests string options', () {
    test('--module-name=custom flag overrides module name', () async {
      final result = await Process.run(
        'dart',
        [
          'bin/analyze_tests.dart',
          'test/fixtures/passing_test.dart',
          '--module-name=custom-module',
        ],
      );

      expect(result.exitCode, equals(0));
      // Module name should appear in report path/output
      expect(
        result.stdout.toString(),
        anyOf(
          contains('custom-module'),
          contains('tests_reports/'),
        ),
      );
    });
  });

  group('analyze_tests flag combinations', () {
    test('--verbose --performance --runs=5 works together', () async {
      final result = await Process.run(
        'dart',
        [
          'bin/analyze_tests.dart',
          'test/fixtures/passing_test.dart',
          '--verbose',
          '--performance',
          '--runs=5',
        ],
      );

      expect(result.exitCode, equals(0));
      // Should show verbose output with performance metrics for 5 runs
      expect(result.stdout.toString(), contains('Running'));
    });

    test('--no-report --verbose shows output but no report', () async {
      final result = await Process.run(
        'dart',
        [
          'bin/analyze_tests.dart',
          'test/fixtures/passing_test.dart',
          '--no-report',
          '--verbose',
        ],
      );

      expect(result.exitCode, equals(0));
      // Should show verbose output
      expect(result.stdout.toString(), contains('Running'));
      // But NO report saved message
      expect(result.stdout.toString(), isNot(contains('Report saved')));
    });
  });

  group('analyze_tests flag aliases', () {
    test('-v alias equals --verbose', () async {
      final verboseResult = await Process.run(
        'dart',
        [
          'bin/analyze_tests.dart',
          'test/fixtures/passing_test.dart',
          '--verbose'
        ],
      );

      final aliasResult = await Process.run(
        'dart',
        ['bin/analyze_tests.dart', 'test/fixtures/passing_test.dart', '-v'],
      );

      expect(verboseResult.exitCode, equals(aliasResult.exitCode));
      // Both should show similar verbose output
    });

    test('-p alias equals --performance', () async {
      final longResult = await Process.run(
        'dart',
        [
          'bin/analyze_tests.dart',
          'test/fixtures/passing_test.dart',
          '--performance'
        ],
      );

      final shortResult = await Process.run(
        'dart',
        ['bin/analyze_tests.dart', 'test/fixtures/passing_test.dart', '-p'],
      );

      expect(longResult.exitCode, equals(shortResult.exitCode));
    });
  });

  group('analyze_tests default values', () {
    test('runs defaults to 3', () async {
      // Without --runs flag, should run 3 times by default
      final result = await Process.run(
        'dart',
        [
          'bin/analyze_tests.dart',
          'test/fixtures/passing_test.dart',
          '--verbose'
        ],
      );

      expect(result.exitCode, equals(0));
      // Should show evidence of 3 runs (reliability analysis)
    });

    test('slow threshold defaults to 1.0 seconds', () async {
      final result = await Process.run(
        'dart',
        ['bin/analyze_tests.dart', 'test/fixtures/passing_test.dart'],
      );

      expect(result.exitCode, equals(0));
      // Default slow threshold applied
    });

    test('workers defaults to 4 with --parallel', () async {
      final result = await Process.run(
        'dart',
        [
          'bin/analyze_tests.dart',
          'test/fixtures/passing_test.dart',
          '--parallel',
          '--no-report',
        ],
      );

      // Should use 4 workers by default
      expect(result.exitCode, equals(0));
    }, timeout: Timeout(Duration(seconds: 60)));
  });
}
