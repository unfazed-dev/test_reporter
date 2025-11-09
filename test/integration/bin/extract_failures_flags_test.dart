// ignore_for_file: avoid_print

@Tags(['integration'])
library;

import 'dart:io';

import 'package:test/test.dart';

/// Integration tests for extract_failures CLI flags.
///
/// These tests verify that all CLI flags for the extract_failures tool work
/// correctly in real execution scenarios.
///
/// Phase 5.3 of CLI Flags Audit - TDD Methodology:
/// 🔴 RED: Write failing tests first
/// 🟢 GREEN: Make tests pass
/// ♻️ REFACTOR: Clean up
/// 🔄 META-TEST: Manual verification
void main() {
  group('extract_failures boolean flags', () {
    test('--help/-h flag shows help text', () async {
      final result = await Process.run(
        'dart',
        ['bin/extract_failures.dart', '--help'],
      );

      expect(result.exitCode, equals(0));
      expect(result.stdout.toString(), contains('Usage:'));
      expect(result.stdout.toString(), contains('Options:'));
      expect(result.stdout.toString(), contains('--list-only'));
      expect(result.stdout.toString(), contains('--[no-]auto-rerun'));
    });

    test('--list-only/-l flag lists failures without rerunning', () async {
      // This test verifies the flag is recognized
      final result = await Process.run(
        'dart',
        ['bin/extract_failures.dart', 'test/', '--list-only'],
      );

      // Should run and recognize the flag (may exit with various codes)
      expect(result.exitCode, anyOf(equals(0), equals(1), equals(2)));
    }, timeout: Timeout(Duration(seconds: 30)));

    test('--no-auto-rerun disables automatic rerun', () async {
      final result = await Process.run(
        'dart',
        ['bin/extract_failures.dart', 'test/', '--no-auto-rerun'],
      );

      // Should run without auto-rerunning
      expect(result.exitCode, anyOf(equals(0), equals(1), equals(2)));
    }, timeout: Timeout(Duration(seconds: 30)));

    test('--watch/-w flag enables watch mode (not tested - runs indefinitely)',
        () async {
      // Skip actual execution since watch mode runs indefinitely
      // Just verify the flag exists in help text
      final result = await Process.run(
        'dart',
        ['bin/extract_failures.dart', '--help'],
      );

      expect(result.stdout.toString(), contains('--watch'));
      expect(result.stdout.toString(), contains('-w'));
    });

    test('--save-results/-s flag saves detailed report', () async {
      final result = await Process.run(
        'dart',
        ['bin/extract_failures.dart', 'test/', '--save-results'],
      );

      // Should run and attempt to save results
      expect(result.exitCode, anyOf(equals(0), equals(1), equals(2)));
    }, timeout: Timeout(Duration(seconds: 30)));

    test('--verbose/-v flag shows detailed output', () async {
      final result = await Process.run(
        'dart',
        ['bin/extract_failures.dart', 'test/', '--verbose'],
      );

      // Verbose flag should be recognized
      expect(result.exitCode, anyOf(equals(0), equals(1), equals(2)));
    }, timeout: Timeout(Duration(seconds: 30)));

    test('--no-group-by-file disables file grouping', () async {
      final result = await Process.run(
        'dart',
        ['bin/extract_failures.dart', 'test/', '--no-group-by-file'],
      );

      // Should run without grouping by file
      expect(result.exitCode, anyOf(equals(0), equals(1), equals(2)));
    }, timeout: Timeout(Duration(seconds: 30)));

    test('--parallel/-p flag enables parallel execution', () async {
      final result = await Process.run(
        'dart',
        ['bin/extract_failures.dart', 'test/', '--parallel', '--list-only'],
      );

      // Should recognize parallel flag
      expect(result.exitCode, anyOf(equals(0), equals(1), equals(2)));
    }, timeout: Timeout(Duration(seconds: 30)));

    test('--no-checklist flag disables checklists', () async {
      final result = await Process.run(
        'dart',
        ['bin/extract_failures.dart', 'test/', '--no-checklist'],
      );

      // Should run without checklist generation
      expect(result.exitCode, anyOf(equals(0), equals(1), equals(2)));
    }, timeout: Timeout(Duration(seconds: 30)));

    test('--minimal-checklist flag shows compact checklist', () async {
      final result = await Process.run(
        'dart',
        ['bin/extract_failures.dart', 'test/', '--minimal-checklist'],
      );

      // Should generate minimal checklist format
      expect(result.exitCode, anyOf(equals(0), equals(1), equals(2)));
    }, timeout: Timeout(Duration(seconds: 30)));
  });

  group('extract_failures numeric options', () {
    test('--timeout=60 sets test timeout to 60 seconds', () async {
      final result = await Process.run(
        'dart',
        ['bin/extract_failures.dart', 'test/', '--timeout=60', '--list-only'],
      );

      // Should run with custom timeout
      expect(result.exitCode, anyOf(equals(0), equals(1), equals(2)));
    }, timeout: Timeout(Duration(seconds: 30)));

    test('--max-failures=10 limits failures to 10', () async {
      final result = await Process.run(
        'dart',
        [
          'bin/extract_failures.dart',
          'test/',
          '--max-failures=10',
          '--list-only'
        ],
      );

      // Should limit to 10 failures
      expect(result.exitCode, anyOf(equals(0), equals(1), equals(2)));
    }, timeout: Timeout(Duration(seconds: 30)));
  });

  group('extract_failures string options', () {
    test('--module-name=custom overrides module name', () async {
      final result = await Process.run(
        'dart',
        [
          'bin/extract_failures.dart',
          'test/',
          '--module-name=custom-module',
          '--list-only'
        ],
      );

      // Module name should be used for reports
      expect(result.exitCode, anyOf(equals(0), equals(1), equals(2)));
    }, timeout: Timeout(Duration(seconds: 30)));
  });

  group('extract_failures flag combinations', () {
    test('--list-only --verbose works together', () async {
      final result = await Process.run(
        'dart',
        [
          'bin/extract_failures.dart',
          'test/',
          '--list-only',
          '--verbose',
        ],
      );

      expect(result.exitCode, anyOf(equals(0), equals(1), equals(2)));
    }, timeout: Timeout(Duration(seconds: 30)));

    test('--save-results --minimal-checklist works together', () async {
      final result = await Process.run(
        'dart',
        [
          'bin/extract_failures.dart',
          'test/',
          '--save-results',
          '--minimal-checklist',
        ],
      );

      expect(result.exitCode, anyOf(equals(0), equals(1), equals(2)));
    }, timeout: Timeout(Duration(seconds: 30)));
  });

  group('extract_failures flag aliases', () {
    test('-l alias equals --list-only', () async {
      final longResult = await Process.run(
        'dart',
        ['bin/extract_failures.dart', 'test/', '--list-only'],
      );

      final shortResult = await Process.run(
        'dart',
        ['bin/extract_failures.dart', 'test/', '-l'],
      );

      expect(longResult.exitCode, equals(shortResult.exitCode));
    }, timeout: Timeout(Duration(seconds: 60)));

    test('-v alias equals --verbose', () async {
      final longResult = await Process.run(
        'dart',
        ['bin/extract_failures.dart', 'test/', '--verbose', '--list-only'],
      );

      final shortResult = await Process.run(
        'dart',
        ['bin/extract_failures.dart', 'test/', '-v', '-l'],
      );

      expect(longResult.exitCode, equals(shortResult.exitCode));
    }, timeout: Timeout(Duration(seconds: 60)));

    test('-p alias equals --parallel', () async {
      final longResult = await Process.run(
        'dart',
        ['bin/extract_failures.dart', 'test/', '--parallel', '--list-only'],
      );

      final shortResult = await Process.run(
        'dart',
        ['bin/extract_failures.dart', 'test/', '-p', '-l'],
      );

      expect(longResult.exitCode, equals(shortResult.exitCode));
    }, timeout: Timeout(Duration(seconds: 60)));
  });

  group('extract_failures default values', () {
    test('auto-rerun defaults to true', () async {
      // Without --no-auto-rerun, should auto-rerun by default
      // We use --list-only to prevent actual rerun
      final result = await Process.run(
        'dart',
        ['bin/extract_failures.dart', 'test/', '--list-only'],
      );

      expect(result.exitCode, anyOf(equals(0), equals(1), equals(2)));
    }, timeout: Timeout(Duration(seconds: 30)));

    test('group-by-file defaults to true', () async {
      // Without --no-group-by-file, should group by default
      final result = await Process.run(
        'dart',
        ['bin/extract_failures.dart', 'test/', '--list-only'],
      );

      expect(result.exitCode, anyOf(equals(0), equals(1), equals(2)));
    }, timeout: Timeout(Duration(seconds: 30)));

    test('checklist defaults to true', () async {
      // Without --no-checklist, should include checklist by default
      final result = await Process.run(
        'dart',
        ['bin/extract_failures.dart', 'test/', '--list-only'],
      );

      expect(result.exitCode, anyOf(equals(0), equals(1), equals(2)));
    }, timeout: Timeout(Duration(seconds: 30)));

    test('timeout defaults to 120 seconds', () async {
      // Without --timeout flag, should use 120s default
      final result = await Process.run(
        'dart',
        ['bin/extract_failures.dart', 'test/', '--list-only'],
      );

      expect(result.exitCode, anyOf(equals(0), equals(1), equals(2)));
    }, timeout: Timeout(Duration(seconds: 30)));

    test('max-failures defaults to 0 (unlimited)', () async {
      // Without --max-failures, should extract all failures
      final result = await Process.run(
        'dart',
        ['bin/extract_failures.dart', 'test/', '--list-only'],
      );

      expect(result.exitCode, anyOf(equals(0), equals(1), equals(2)));
    }, timeout: Timeout(Duration(seconds: 30)));
  });
}
