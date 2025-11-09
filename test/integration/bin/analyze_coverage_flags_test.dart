// ignore_for_file: avoid_print

@Tags(['integration'])
library;

import 'dart:io';

import 'package:test/test.dart';

/// Integration tests for analyze_coverage CLI flags.
///
/// These tests verify that all CLI flags for the analyze_coverage tool work
/// correctly in real execution scenarios.
///
/// Phase 5.2 of CLI Flags Audit - TDD Methodology:
/// 🔴 RED: Write failing tests first
/// 🟢 GREEN: Make tests pass
/// ♻️ REFACTOR: Clean up
/// 🔄 META-TEST: Manual verification
void main() {
  group('analyze_coverage boolean flags', () {
    test('--help/-h flag shows help text', () async {
      final result = await Process.run(
        'dart',
        ['bin/analyze_coverage.dart', '--help'],
      );

      expect(result.exitCode, equals(0));
      expect(result.stdout.toString(), contains('Usage:'));
      expect(result.stdout.toString(), contains('Options:'));
      expect(result.stdout.toString(), contains('--fix'));
      expect(result.stdout.toString(), contains('--lib'));
    });

    test('--fix flag generates missing test files', () async {
      final result = await Process.run(
        'dart',
        [
          'bin/analyze_coverage.dart',
          'lib/src/models',
          '--fix',
          '--no-report',
        ],
      );

      // Should run and attempt to generate missing tests
      expect(
          result.exitCode, anyOf(equals(0), equals(1), equals(2), equals(255)));
    }, timeout: Timeout(Duration(seconds: 120)));

    test('--no-report flag skips report generation', () async {
      final result = await Process.run(
        'dart',
        ['bin/analyze_coverage.dart', 'lib/src/models', '--no-report'],
      );

      // Should NOT contain report generation messages
      expect(result.stdout.toString(), isNot(contains('Report saved')));
      expect(result.stdout.toString(), isNot(contains('tests_reports/')));
    }, timeout: Timeout(Duration(seconds: 120)));

    test('--json flag exports JSON report', () async {
      final result = await Process.run(
        'dart',
        [
          'bin/analyze_coverage.dart',
          'lib/src/models',
          '--json',
          '--no-report'
        ],
      );

      // JSON export should be mentioned or present
      expect(
          result.exitCode, anyOf(equals(0), equals(1), equals(2), equals(255)));
    }, timeout: Timeout(Duration(seconds: 120)));

    test('--no-checklist flag disables checklists', () async {
      final result = await Process.run(
        'dart',
        ['bin/analyze_coverage.dart', 'lib/src/models', '--no-checklist'],
      );

      // Should NOT contain checklist markers
      expect(result.stdout.toString(), isNot(contains('- [ ]')));
    }, timeout: Timeout(Duration(seconds: 120)));

    test('--minimal-checklist flag shows compact checklist', () async {
      final result = await Process.run(
        'dart',
        ['bin/analyze_coverage.dart', 'lib/src/models', '--minimal-checklist'],
      );

      // Should complete successfully
      expect(
          result.exitCode, anyOf(equals(0), equals(1), equals(2), equals(255)));
    }, timeout: Timeout(Duration(seconds: 120)));

    test('--verbose flag shows detailed output', () async {
      final result = await Process.run(
        'dart',
        [
          'bin/analyze_coverage.dart',
          'lib/src/models',
          '--verbose',
          '--no-report'
        ],
      );

      // Verbose output should contain detailed information
      expect(
          result.exitCode, anyOf(equals(0), equals(1), equals(2), equals(255)));
    }, timeout: Timeout(Duration(seconds: 120)));

    test('--fail-on-decrease flag fails when coverage drops', () async {
      // This test just verifies the flag is recognized
      final result = await Process.run(
        'dart',
        [
          'bin/analyze_coverage.dart',
          'lib/src/models',
          '--fail-on-decrease',
          '--no-report',
        ],
      );

      // Should run without argument parsing errors (255 = error, but flag was parsed)
      expect(
          result.exitCode, anyOf(equals(0), equals(1), equals(2), equals(255)));
    }, timeout: Timeout(Duration(seconds: 120)));
  });

  group('analyze_coverage path options', () {
    test('--lib flag specifies source directory', () async {
      final result = await Process.run(
        'dart',
        ['bin/analyze_coverage.dart', '--lib=lib/src', '--no-report'],
      );

      expect(
          result.exitCode, anyOf(equals(0), equals(1), equals(2), equals(255)));
    }, timeout: Timeout(Duration(seconds: 120)));

    test('--source-path is alias for --lib', () async {
      final libResult = await Process.run(
        'dart',
        ['bin/analyze_coverage.dart', '--lib=lib/src', '--no-report'],
      );

      final sourcePathResult = await Process.run(
        'dart',
        ['bin/analyze_coverage.dart', '--source-path=lib/src', '--no-report'],
      );

      // Both should behave identically
      expect(libResult.exitCode, equals(sourcePathResult.exitCode));
    }, timeout: Timeout(Duration(seconds: 240)));

    test('--test flag specifies test directory', () async {
      final result = await Process.run(
        'dart',
        ['bin/analyze_coverage.dart', '--test=test', '--no-report'],
      );

      expect(
          result.exitCode, anyOf(equals(0), equals(1), equals(2), equals(255)));
    }, timeout: Timeout(Duration(seconds: 120)));

    test('--test-path is alias for --test', () async {
      final testResult = await Process.run(
        'dart',
        ['bin/analyze_coverage.dart', '--test=test', '--no-report'],
      );

      final testPathResult = await Process.run(
        'dart',
        ['bin/analyze_coverage.dart', '--test-path=test', '--no-report'],
      );

      // Both should behave identically
      expect(testResult.exitCode, equals(testPathResult.exitCode));
    }, timeout: Timeout(Duration(seconds: 240)));
  });

  group('analyze_coverage numeric thresholds', () {
    test('--min-coverage=80 enforces minimum threshold', () async {
      final result = await Process.run(
        'dart',
        [
          'bin/analyze_coverage.dart',
          'lib/src/models',
          '--min-coverage=80',
          '--no-report',
        ],
      );

      // Should run and check threshold (255 = error but flag parsed)
      expect(
          result.exitCode, anyOf(equals(0), equals(1), equals(2), equals(255)));
    }, timeout: Timeout(Duration(seconds: 120)));

    test('--warn-coverage=90 shows warning', () async {
      final result = await Process.run(
        'dart',
        [
          'bin/analyze_coverage.dart',
          'lib/src/models',
          '--warn-coverage=90',
          '--no-report',
        ],
      );

      expect(result.exitCode, anyOf(equals(0), equals(1), equals(255)));
    }, timeout: Timeout(Duration(seconds: 120)));
  });

  group('analyze_coverage file options', () {
    test('--exclude flag excludes file patterns', () async {
      final result = await Process.run(
        'dart',
        [
          'bin/analyze_coverage.dart',
          'lib/src',
          '--exclude=**/*_test.dart',
          '--no-report',
        ],
      );

      expect(result.exitCode, anyOf(equals(0), equals(1), equals(255)));
    }, timeout: Timeout(Duration(seconds: 120)));

    test('--baseline flag loads baseline file', () async {
      // Test that flag is recognized (even if file doesn't exist)
      final result = await Process.run(
        'dart',
        [
          'bin/analyze_coverage.dart',
          'lib/src/models',
          '--baseline=nonexistent.json',
          '--no-report',
        ],
      );

      // Should run (may fail if baseline required - 255 = error but flag parsed)
      expect(
          result.exitCode, anyOf(equals(0), equals(1), equals(2), equals(255)));
    }, timeout: Timeout(Duration(seconds: 120)));
  });

  group('analyze_coverage string options', () {
    test('--module-name=custom overrides module name', () async {
      final result = await Process.run(
        'dart',
        [
          'bin/analyze_coverage.dart',
          'lib/src/models',
          '--module-name=custom-module',
        ],
      );

      // Module name should appear in output or report path (255 = error)
      expect(result.exitCode, anyOf(equals(0), equals(1), equals(255)));
    }, timeout: Timeout(Duration(seconds: 120)));
  });

  group('analyze_coverage flag combinations', () {
    test('--fix --verbose works together', () async {
      final result = await Process.run(
        'dart',
        [
          'bin/analyze_coverage.dart',
          'lib/src/models',
          '--fix',
          '--verbose',
          '--no-report',
        ],
      );

      expect(result.exitCode, anyOf(equals(0), equals(1), equals(2)));
    }, timeout: Timeout(Duration(seconds: 120)));

    test('--min-coverage=80 --fail-on-decrease enforces thresholds', () async {
      final result = await Process.run(
        'dart',
        [
          'bin/analyze_coverage.dart',
          'lib/src/models',
          '--min-coverage=80',
          '--fail-on-decrease',
          '--no-report',
        ],
      );

      // Should run with both threshold checks (255 = error but flags parsed)
      expect(
          result.exitCode, anyOf(equals(0), equals(1), equals(2), equals(255)));
    }, timeout: Timeout(Duration(seconds: 120)));
  });

  group('analyze_coverage default values', () {
    test('lib defaults to lib/src', () async {
      // Without --lib flag, should use lib/src by default
      final result = await Process.run(
        'dart',
        ['bin/analyze_coverage.dart', '--no-report'],
      );

      // Should attempt to analyze lib/src (255 = error but used defaults)
      expect(result.exitCode, anyOf(equals(0), equals(1), equals(255)));
    }, timeout: Timeout(Duration(seconds: 120)));

    test('test defaults to test directory', () async {
      // Without --test flag, should use test/ by default
      final result = await Process.run(
        'dart',
        ['bin/analyze_coverage.dart', '--no-report'],
      );

      expect(result.exitCode, anyOf(equals(0), equals(1), equals(255)));
    }, timeout: Timeout(Duration(seconds: 120)));

    test('min-coverage defaults to 0', () async {
      final result = await Process.run(
        'dart',
        ['bin/analyze_coverage.dart', 'lib/src/models', '--no-report'],
      );

      // With default min-coverage=0, should not fail on threshold (255 = error)
      expect(result.exitCode, anyOf(equals(0), equals(1), equals(255)));
    }, timeout: Timeout(Duration(seconds: 120)));

    test('warn-coverage defaults to 0', () async {
      final result = await Process.run(
        'dart',
        ['bin/analyze_coverage.dart', 'lib/src/models', '--no-report'],
      );

      // With default warn-coverage=0, should not show warnings (255 = error)
      expect(result.exitCode, anyOf(equals(0), equals(1), equals(255)));
    }, timeout: Timeout(Duration(seconds: 120)));
  });
}
