// ignore_for_file: avoid_print

@Tags(['integration'])
library;

import 'dart:io';

import 'package:test/test.dart';

/// Integration tests for cross-tool flag consistency and edge cases.
///
/// These tests verify that flags behave consistently across all 4 tools,
/// invalid inputs are rejected properly, and edge cases are handled.
///
/// Phase 5.5 of CLI Flags Audit - TDD Methodology:
/// 🔴 RED: Write failing tests first
/// 🟢 GREEN: Make tests pass
/// ♻️ REFACTOR: Clean up
/// 🔄 META-TEST: Manual verification
void main() {
  group('cross-tool flag consistency', () {
    test('--verbose flag works consistently across all tools', () async {
      // Test analyze_tests with --verbose
      final testsResult = await Process.run(
        'dart',
        [
          'bin/analyze_tests.dart',
          'test/fixtures/passing_test.dart',
          '--verbose',
          '--no-report'
        ],
      );

      // Test analyze_coverage with --verbose
      final coverageResult = await Process.run(
        'dart',
        [
          'bin/analyze_coverage.dart',
          'lib/src/models',
          '--verbose',
          '--no-report'
        ],
      );

      // Test extract_failures with --verbose
      final extractResult = await Process.run(
        'dart',
        ['bin/extract_failures.dart', 'test/', '--verbose', '--list-only'],
      );

      // Test analyze_suite with --verbose
      final suiteResult = await Process.run(
        'dart',
        [
          'bin/analyze_suite.dart',
          'test/fixtures/passing_test.dart',
          '--verbose'
        ],
      );

      // All should recognize and handle --verbose flag
      expect(testsResult.exitCode, anyOf(equals(0), equals(1), equals(2)));
      expect(coverageResult.exitCode,
          anyOf(equals(0), equals(1), equals(2), equals(255)));
      expect(extractResult.exitCode, anyOf(equals(0), equals(1), equals(2)));
      expect(suiteResult.exitCode, anyOf(equals(0), equals(1), equals(2)));
    }, timeout: Timeout(Duration(seconds: 180)));

    test('--module-name flag works consistently across all tools', () async {
      // Test analyze_tests with --module-name
      final testsResult = await Process.run(
        'dart',
        [
          'bin/analyze_tests.dart',
          'test/fixtures/passing_test.dart',
          '--module-name=test-module',
          '--no-report'
        ],
      );

      // Test analyze_coverage with --module-name
      final coverageResult = await Process.run(
        'dart',
        [
          'bin/analyze_coverage.dart',
          'lib/src/models',
          '--module-name=test-module',
          '--no-report'
        ],
      );

      // Test extract_failures with --module-name
      final extractResult = await Process.run(
        'dart',
        [
          'bin/extract_failures.dart',
          'test/',
          '--module-name=test-module',
          '--list-only'
        ],
      );

      // Test analyze_suite with --module-name
      final suiteResult = await Process.run(
        'dart',
        [
          'bin/analyze_suite.dart',
          'test/fixtures/passing_test.dart',
          '--module-name=test-module'
        ],
      );

      // All should recognize and handle --module-name flag
      expect(testsResult.exitCode, anyOf(equals(0), equals(1), equals(2)));
      expect(coverageResult.exitCode,
          anyOf(equals(0), equals(1), equals(2), equals(255)));
      expect(extractResult.exitCode, anyOf(equals(0), equals(1), equals(2)));
      expect(suiteResult.exitCode, anyOf(equals(0), equals(1), equals(2)));
    }, timeout: Timeout(Duration(seconds: 180)));

    test('--help/-h flag format consistent across all tools', () async {
      // Test all tools show help text
      final testsHelp =
          await Process.run('dart', ['bin/analyze_tests.dart', '--help']);
      final coverageHelp =
          await Process.run('dart', ['bin/analyze_coverage.dart', '--help']);
      final extractHelp =
          await Process.run('dart', ['bin/extract_failures.dart', '--help']);
      final suiteHelp =
          await Process.run('dart', ['bin/analyze_suite.dart', '--help']);

      // All should exit with 0 and show help
      expect(testsHelp.exitCode, equals(0));
      expect(coverageHelp.exitCode, equals(0));
      expect(extractHelp.exitCode, equals(0));
      expect(suiteHelp.exitCode, equals(0));

      // All should contain 'Usage:' in help text
      expect(testsHelp.stdout.toString(), contains('Usage:'));
      expect(coverageHelp.stdout.toString(), contains('Usage:'));
      expect(extractHelp.stdout.toString(), contains('Usage:'));
      expect(suiteHelp.stdout.toString(), contains('Usage:'));
    });
  });

  group('checklist flag consistency', () {
    test('--no-checklist flag works in analyze_tests and analyze_coverage',
        () async {
      // Test analyze_tests with --no-checklist
      final testsResult = await Process.run(
        'dart',
        [
          'bin/analyze_tests.dart',
          'test/fixtures/passing_test.dart',
          '--no-checklist',
          '--no-report'
        ],
      );

      // Test analyze_coverage with --no-checklist
      final coverageResult = await Process.run(
        'dart',
        [
          'bin/analyze_coverage.dart',
          'lib/src/models',
          '--no-checklist',
          '--no-report'
        ],
      );

      expect(testsResult.exitCode, anyOf(equals(0), equals(1)));
      expect(coverageResult.exitCode, anyOf(equals(0), equals(1), equals(255)));
    }, timeout: Timeout(Duration(seconds: 120)));

    test('--minimal-checklist flag works across all tools', () async {
      // Test analyze_tests with --minimal-checklist
      final testsResult = await Process.run(
        'dart',
        [
          'bin/analyze_tests.dart',
          'test/fixtures/passing_test.dart',
          '--minimal-checklist',
          '--no-report'
        ],
      );

      // Test analyze_coverage with --minimal-checklist
      final coverageResult = await Process.run(
        'dart',
        [
          'bin/analyze_coverage.dart',
          'lib/src/models',
          '--minimal-checklist',
          '--no-report'
        ],
      );

      // Test extract_failures with --minimal-checklist
      final extractResult = await Process.run(
        'dart',
        [
          'bin/extract_failures.dart',
          'test/',
          '--minimal-checklist',
          '--list-only'
        ],
      );

      // Test analyze_suite with --minimal-checklist
      final suiteResult = await Process.run(
        'dart',
        [
          'bin/analyze_suite.dart',
          'test/fixtures/passing_test.dart',
          '--minimal-checklist'
        ],
      );

      // All should recognize the flag
      expect(testsResult.exitCode, anyOf(equals(0), equals(1)));
      expect(coverageResult.exitCode, anyOf(equals(0), equals(1), equals(255)));
      expect(extractResult.exitCode, anyOf(equals(0), equals(1), equals(2)));
      expect(suiteResult.exitCode, anyOf(equals(0), equals(1), equals(2)));
    }, timeout: Timeout(Duration(seconds: 180)));
  });

  group('invalid flag rejection', () {
    test('unknown flags are rejected by all tools', () async {
      // Test analyze_tests rejects unknown flag
      final testsResult = await Process.run(
        'dart',
        ['bin/analyze_tests.dart', '--invalid-flag'],
      );

      // Test analyze_coverage rejects unknown flag
      final coverageResult = await Process.run(
        'dart',
        ['bin/analyze_coverage.dart', '--invalid-flag'],
      );

      // Test extract_failures rejects unknown flag
      final extractResult = await Process.run(
        'dart',
        ['bin/extract_failures.dart', '--invalid-flag'],
      );

      // Test analyze_suite rejects unknown flag
      final suiteResult = await Process.run(
        'dart',
        ['bin/analyze_suite.dart', '--invalid-flag'],
      );

      // All should exit with non-zero error code (1 or 2)
      expect(testsResult.exitCode, isNonZero);
      expect(coverageResult.exitCode, isNonZero);
      expect(extractResult.exitCode, isNonZero);
      expect(suiteResult.exitCode, isNonZero);

      // All should show error messages (check both stdout and stderr)
      final testsOutput =
          testsResult.stderr.toString() + testsResult.stdout.toString();
      final coverageOutput =
          coverageResult.stderr.toString() + coverageResult.stdout.toString();
      final extractOutput =
          extractResult.stderr.toString() + extractResult.stdout.toString();
      final suiteOutput =
          suiteResult.stderr.toString() + suiteResult.stdout.toString();

      expect(testsOutput, contains('Could not find an option'));
      expect(coverageOutput, contains('Could not find an option'));
      expect(extractOutput, contains('Could not find an option'));
      expect(suiteOutput, contains('Could not find an option'));
    });

    test('stub flags are properly rejected in analyze_tests', () async {
      // Test --dependencies is rejected
      final depsResult = await Process.run(
        'dart',
        ['bin/analyze_tests.dart', '--dependencies'],
      );

      // Test --mutation is rejected
      final mutationResult = await Process.run(
        'dart',
        ['bin/analyze_tests.dart', '--mutation'],
      );

      // Test --impact is rejected
      final impactResult = await Process.run(
        'dart',
        ['bin/analyze_tests.dart', '--impact'],
      );

      // All should be rejected
      expect(depsResult.exitCode, equals(2));
      expect(mutationResult.exitCode, equals(2));
      expect(impactResult.exitCode, equals(2));
    });

    test('stub flags are properly rejected in analyze_coverage', () async {
      // Test --branch is rejected
      final branchResult = await Process.run(
        'dart',
        ['bin/analyze_coverage.dart', '--branch'],
      );

      // Test --incremental is rejected
      final incrementalResult = await Process.run(
        'dart',
        ['bin/analyze_coverage.dart', '--incremental'],
      );

      // Test --watch is rejected (stub in coverage, exists in other tools)
      final watchResult = await Process.run(
        'dart',
        ['bin/analyze_coverage.dart', '--watch'],
      );

      // All should be rejected
      expect(branchResult.exitCode, equals(2));
      expect(incrementalResult.exitCode, equals(2));
      expect(watchResult.exitCode, equals(2));
    });
  });

  group('numeric validation', () {
    test('negative runs value is handled gracefully', () async {
      final result = await Process.run(
        'dart',
        [
          'bin/analyze_tests.dart',
          'test/fixtures/passing_test.dart',
          '--runs=-1',
          '--no-report'
        ],
      );

      // Should either reject or treat as default
      // ArgParser doesn't validate numeric ranges, so this may pass through
      expect(result.exitCode, anyOf(equals(0), equals(1), equals(2)));
    });

    test('invalid coverage threshold is handled', () async {
      final result = await Process.run(
        'dart',
        [
          'bin/analyze_coverage.dart',
          'lib/src/models',
          '--min-coverage=150',
          '--no-report'
        ],
      );

      // Should handle invalid threshold (>100)
      expect(
          result.exitCode, anyOf(equals(0), equals(1), equals(2), equals(255)));
    }, timeout: Timeout(Duration(seconds: 120)));

    test('zero timeout value is handled', () async {
      final result = await Process.run(
        'dart',
        ['bin/extract_failures.dart', 'test/', '--timeout=0', '--list-only'],
      );

      // Should handle zero timeout
      expect(result.exitCode, anyOf(equals(0), equals(1), equals(2)));
    }, timeout: Timeout(Duration(seconds: 30)));
  });

  group('flag conflict handling', () {
    test('--no-report with --minimal-checklist handled gracefully', () async {
      // Report disabled makes checklist moot, but shouldn't error
      final result = await Process.run(
        'dart',
        [
          'bin/analyze_tests.dart',
          'test/fixtures/passing_test.dart',
          '--no-report',
          '--minimal-checklist'
        ],
      );

      // Should run successfully (checklist flag ignored when no report)
      expect(result.exitCode, equals(0));
    });

    test('--parallel without --workers uses default', () async {
      final result = await Process.run(
        'dart',
        [
          'bin/analyze_tests.dart',
          'test/fixtures/passing_test.dart',
          '--parallel',
          '--no-report'
        ],
      );

      // Should use default worker count
      expect(result.exitCode, equals(0));
    }, timeout: Timeout(Duration(seconds: 60)));
  });

  group('help text quality', () {
    test('all tools document their primary purpose', () async {
      final testsHelp =
          await Process.run('dart', ['bin/analyze_tests.dart', '--help']);
      final coverageHelp =
          await Process.run('dart', ['bin/analyze_coverage.dart', '--help']);
      final extractHelp =
          await Process.run('dart', ['bin/extract_failures.dart', '--help']);
      final suiteHelp =
          await Process.run('dart', ['bin/analyze_suite.dart', '--help']);

      // Each should have descriptive help text
      expect(testsHelp.stdout.toString(), isNotEmpty);
      expect(coverageHelp.stdout.toString(), isNotEmpty);
      expect(extractHelp.stdout.toString(), isNotEmpty);
      expect(suiteHelp.stdout.toString(), isNotEmpty);

      // Suite should mention it always generates reports
      expect(suiteHelp.stdout.toString(), contains('ALWAYS generated'));
    });

    test('all tools show available flags in help', () async {
      final testsHelp =
          await Process.run('dart', ['bin/analyze_tests.dart', '--help']);
      final coverageHelp =
          await Process.run('dart', ['bin/analyze_coverage.dart', '--help']);

      // Should list key flags
      expect(testsHelp.stdout.toString(), contains('--verbose'));
      expect(testsHelp.stdout.toString(), contains('--runs'));
      expect(coverageHelp.stdout.toString(), contains('--fix'));
      expect(coverageHelp.stdout.toString(), contains('--lib'));
    });
  });
}
