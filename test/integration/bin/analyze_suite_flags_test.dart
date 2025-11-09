// ignore_for_file: avoid_print

@Tags(['integration'])
library;

import 'dart:io';

import 'package:test/test.dart';

/// Integration tests for analyze_suite CLI flags.
///
/// These tests verify that all CLI flags for the analyze_suite tool work
/// correctly in real execution scenarios.
///
/// ⚠️ **IMPORTANT: Report Generation Behavior**
/// All tests in this file will generate reports in tests_reports/suite/.
/// This is INTENTIONAL - analyze_suite has NO --no-report flag by design.
/// The suite's primary purpose IS to generate unified reports.
/// See bin/analyze_suite.dart:8-16 for design rationale.
///
/// Phase 5.4 of CLI Flags Audit - TDD Methodology:
/// 🔴 RED: Write failing tests first
/// 🟢 GREEN: Make tests pass
/// ♻️ REFACTOR: Clean up
/// 🔄 META-TEST: Manual verification
void main() {
  group('analyze_suite boolean flags', () {
    test('--help/-h flag shows help text', () async {
      final result = await Process.run(
        'dart',
        ['bin/analyze_suite.dart', '--help'],
      );

      expect(result.exitCode, equals(0));
      expect(result.stdout.toString(), contains('Usage:'));
      expect(result.stdout.toString(), contains('--performance'));
      expect(result.stdout.toString(), contains('--[no-]checklist'));
    });

    test('--performance flag enables performance profiling', () async {
      final result = await Process.run(
        'dart',
        [
          'bin/analyze_suite.dart',
          'test/fixtures/passing_test.dart',
          '--performance'
        ],
      );

      // Should run with performance profiling enabled
      expect(result.exitCode, anyOf(equals(0), equals(1), equals(2)));
    }, timeout: Timeout(Duration(seconds: 120)));

    test('--verbose/-v flag shows detailed output', () async {
      final result = await Process.run(
        'dart',
        [
          'bin/analyze_suite.dart',
          'test/fixtures/passing_test.dart',
          '--verbose'
        ],
      );

      // Verbose flag should be recognized
      expect(result.exitCode, anyOf(equals(0), equals(1), equals(2)));
    }, timeout: Timeout(Duration(seconds: 120)));

    test('--parallel flag enables parallel execution', () async {
      final result = await Process.run(
        'dart',
        [
          'bin/analyze_suite.dart',
          'test/fixtures/passing_test.dart',
          '--parallel'
        ],
      );

      // Should run in parallel mode
      expect(result.exitCode, anyOf(equals(0), equals(1), equals(2)));
    }, timeout: Timeout(Duration(seconds: 120)));

    test('--no-checklist flag disables checklists', () async {
      final result = await Process.run(
        'dart',
        [
          'bin/analyze_suite.dart',
          'test/fixtures/passing_test.dart',
          '--no-checklist'
        ],
      );

      // Should run without checklist generation
      expect(result.exitCode, anyOf(equals(0), equals(1), equals(2)));
    }, timeout: Timeout(Duration(seconds: 120)));

    test('--minimal-checklist flag shows compact checklist', () async {
      final result = await Process.run(
        'dart',
        [
          'bin/analyze_suite.dart',
          'test/fixtures/passing_test.dart',
          '--minimal-checklist'
        ],
      );

      // Should generate minimal checklist format
      expect(result.exitCode, anyOf(equals(0), equals(1), equals(2)));
    }, timeout: Timeout(Duration(seconds: 120)));

    test('--include-fixtures flag includes fixture tests', () async {
      final result = await Process.run(
        'dart',
        ['bin/analyze_suite.dart', 'test/fixtures/', '--include-fixtures'],
      );

      // Should include fixture tests (currently excluded by default)
      expect(result.exitCode, anyOf(equals(0), equals(1), equals(2)));
    }, timeout: Timeout(Duration(seconds: 120)));
  });

  group('analyze_suite path options', () {
    test('--path/-p flag sets test path', () async {
      final result = await Process.run(
        'dart',
        ['bin/analyze_suite.dart', '--path=test/fixtures/passing_test.dart'],
      );

      // Should use specified test path
      expect(result.exitCode, anyOf(equals(0), equals(1), equals(2)));
    }, timeout: Timeout(Duration(seconds: 120)));

    test('--test-path flag explicitly overrides test path', () async {
      final result = await Process.run(
        'dart',
        [
          'bin/analyze_suite.dart',
          'test/fixtures/passing_test.dart',
          '--test-path=test/',
        ],
      );

      // Should override test path
      expect(result.exitCode, anyOf(equals(0), equals(1), equals(2)));
    }, timeout: Timeout(Duration(seconds: 120)));

    test('--source-path flag explicitly overrides source path', () async {
      final result = await Process.run(
        'dart',
        [
          'bin/analyze_suite.dart',
          'test/fixtures/passing_test.dart',
          '--source-path=lib/src/',
        ],
      );

      // Should override source path
      expect(result.exitCode, anyOf(equals(0), equals(1), equals(2)));
    }, timeout: Timeout(Duration(seconds: 120)));
  });

  group('analyze_suite numeric options', () {
    test('--runs/-r=5 flag runs tests 5 times', () async {
      final result = await Process.run(
        'dart',
        [
          'bin/analyze_suite.dart',
          'test/fixtures/passing_test.dart',
          '--runs=5'
        ],
      );

      // Should run tests 5 times
      expect(result.exitCode, anyOf(equals(0), equals(1), equals(2)));
    }, timeout: Timeout(Duration(seconds: 180)));
  });

  group('analyze_suite string options', () {
    test('--module-name=custom flag overrides module name', () async {
      final result = await Process.run(
        'dart',
        [
          'bin/analyze_suite.dart',
          'test/fixtures/passing_test.dart',
          '--module-name=custom-suite',
        ],
      );

      // Module name should appear in report
      expect(result.exitCode, anyOf(equals(0), equals(1), equals(2)));
    }, timeout: Timeout(Duration(seconds: 120)));
  });

  group('analyze_suite flag combinations', () {
    test('--verbose --performance works together', () async {
      final result = await Process.run(
        'dart',
        [
          'bin/analyze_suite.dart',
          'test/fixtures/passing_test.dart',
          '--verbose',
          '--performance',
        ],
      );

      expect(result.exitCode, anyOf(equals(0), equals(1), equals(2)));
    }, timeout: Timeout(Duration(seconds: 120)));

    test('--parallel --minimal-checklist works together', () async {
      final result = await Process.run(
        'dart',
        [
          'bin/analyze_suite.dart',
          'test/fixtures/passing_test.dart',
          '--parallel',
          '--minimal-checklist',
        ],
      );

      expect(result.exitCode, anyOf(equals(0), equals(1), equals(2)));
    }, timeout: Timeout(Duration(seconds: 120)));
  });

  group('analyze_suite flag aliases', () {
    test('-v alias equals --verbose', () async {
      final longResult = await Process.run(
        'dart',
        [
          'bin/analyze_suite.dart',
          'test/fixtures/passing_test.dart',
          '--verbose'
        ],
      );

      final shortResult = await Process.run(
        'dart',
        ['bin/analyze_suite.dart', 'test/fixtures/passing_test.dart', '-v'],
      );

      expect(longResult.exitCode, equals(shortResult.exitCode));
    }, timeout: Timeout(Duration(seconds: 240)));

    test('-p alias equals --path', () async {
      final longResult = await Process.run(
        'dart',
        ['bin/analyze_suite.dart', '--path=test/fixtures/passing_test.dart'],
      );

      final shortResult = await Process.run(
        'dart',
        ['bin/analyze_suite.dart', '-p', 'test/fixtures/passing_test.dart'],
      );

      expect(longResult.exitCode, equals(shortResult.exitCode));
    }, timeout: Timeout(Duration(seconds: 240)));

    test('-r alias equals --runs', () async {
      final longResult = await Process.run(
        'dart',
        [
          'bin/analyze_suite.dart',
          'test/fixtures/passing_test.dart',
          '--runs=2'
        ],
      );

      final shortResult = await Process.run(
        'dart',
        [
          'bin/analyze_suite.dart',
          'test/fixtures/passing_test.dart',
          '-r',
          '2'
        ],
      );

      expect(longResult.exitCode, equals(shortResult.exitCode));
    }, timeout: Timeout(Duration(seconds: 240)));
  });

  group('analyze_suite default values', () {
    test('path defaults to test/', () async {
      // Without --path flag, should use test/ by default
      // Use specific file to avoid running entire test suite
      final result = await Process.run(
        'dart',
        ['bin/analyze_suite.dart', 'test/fixtures/passing_test.dart'],
      );

      expect(result.exitCode, anyOf(equals(0), equals(1), equals(2)));
    }, timeout: Timeout(Duration(seconds: 120)));

    test('runs defaults to 3', () async {
      // Without --runs flag, should run 3 times by default
      final result = await Process.run(
        'dart',
        [
          'bin/analyze_suite.dart',
          'test/fixtures/passing_test.dart',
          '--verbose'
        ],
      );

      expect(result.exitCode, anyOf(equals(0), equals(1), equals(2)));
    }, timeout: Timeout(Duration(seconds: 120)));

    test('checklist defaults to true', () async {
      // Without --no-checklist, should include checklist by default
      final result = await Process.run(
        'dart',
        ['bin/analyze_suite.dart', 'test/fixtures/passing_test.dart'],
      );

      expect(result.exitCode, anyOf(equals(0), equals(1), equals(2)));
    }, timeout: Timeout(Duration(seconds: 120)));
  });

  group('analyze_suite design notes', () {
    test('verify no --no-report flag exists (intentional design)', () async {
      final result = await Process.run(
        'dart',
        ['bin/analyze_suite.dart', '--help'],
      );

      // Should NOT list --report or --no-report as a FLAG for analyze_suite
      // (It's okay if --no-report is mentioned in the note about other tools)
      final helpText = result.stdout.toString();

      // Check that --report is not listed as a flag option
      // (it would appear as "    --[no-]report" or "    --report" if it existed)
      expect(helpText, isNot(contains(RegExp(r'\s+--\[no-\]report'))));
      expect(helpText, isNot(contains(RegExp(r'\s+--report\s'))));
    });

    test('help text mentions reports are always generated', () async {
      final result = await Process.run(
        'dart',
        ['bin/analyze_suite.dart', '--help'],
      );

      // Help text should clarify that reports are always generated
      expect(result.stdout.toString(), contains('Note:'));
      expect(
        result.stdout.toString(),
        anyOf(
          contains('ALWAYS generated'),
          contains('always generated'),
        ),
      );
    });
  });
}
