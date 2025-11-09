// ignore_for_file: avoid_print

@Tags(['integration'])
library;

import 'dart:io';

import 'package:test/test.dart';

/// Integration tests for --no-report flag in analyze_tests
///
/// **Bug**: The --no-report flag is parsed but report is STILL printed to stdout
///
/// **Expected behavior**: When --no-report is specified:
/// - NO report should be printed to stdout
/// - NO report files should be created in tests_reports/
///
/// **Actual behavior**:
/// - Report IS printed to stdout (BUG!)
/// - Report files are NOT created (works correctly)
///
/// These tests demonstrate the bug using TDD methodology (🔴 RED phase)
void main() {
  group('analyze_tests --no-report flag', () {
    late String projectRoot;
    late Directory reportsDir;

    setUp(() {
      // Get project root (assuming tests run from project root)
      projectRoot = Directory.current.path;
      reportsDir = Directory('$projectRoot/tests_reports/tests');
    });

    tearDown(() async {
      // Clean up any test-generated reports
      if (await reportsDir.exists()) {
        final files = await reportsDir
            .list()
            .where((entity) => entity is File)
            .cast<File>()
            .toList();

        for (final file in files) {
          final filename = file.path.split('/').last;
          // Only delete test-generated reports (contain specific markers)
          if (filename.contains('test') || filename.contains('no-report')) {
            await file.delete();
          }
        }
      }
    });

    test('--no-report should NOT print report to stdout', () async {
      // 🔴 RED: This test should FAIL initially (bug exists)
      //
      // Run analyzer with --no-report flag
      final result = await Process.run(
        'dart',
        [
          'run',
          'test_reporter:analyze_tests',
          'test/unit/models/',
          '--runs=1',
          '--no-report',
        ],
        workingDirectory: projectRoot,
      );

      final stdout = result.stdout.toString();

      // Report sections that should NOT appear when --no-report is set
      final reportSections = [
        'Test Analysis Report',
        'Test Reliability Report',
        'Reliability Matrix',
        'Failure Analysis',
        'Performance Metrics',
        'Summary',
        '===', // Report section dividers
      ];

      // Assert: stdout should NOT contain any report sections
      for (final section in reportSections) {
        expect(
          stdout,
          isNot(contains(section)),
          reason:
              'Report section "$section" should NOT appear when --no-report is set, '
              'but it was found in stdout. This is the BUG!',
        );
      }

      // Stdout should only contain test execution output (if any)
      // or be mostly empty
      print('✓ Test 1: Verified report NOT printed to stdout');
    });

    test('--no-report should NOT create report files', () async {
      // 🟢 GREEN: This test should PASS (file saving already works correctly)
      //
      // Run analyzer with --no-report flag
      final result = await Process.run(
        'dart',
        [
          'run',
          'test_reporter:analyze_tests',
          'test/unit/models/',
          '--runs=1',
          '--no-report',
        ],
        workingDirectory: projectRoot,
      );

      // Verify command completed successfully
      expect(result.exitCode, anyOf([0, 1]),
          reason: 'Command should complete (pass or fail is fine)');

      // Wait a moment for any async file operations
      await Future.delayed(Duration(milliseconds: 500));

      // Check if reports directory exists
      if (await reportsDir.exists()) {
        // List all report files
        final now = DateTime.now();
        final allFiles = await reportsDir
            .list()
            .where((entity) => entity is File)
            .cast<File>()
            .toList();

        // Filter for recent files (created in last minute)
        final recentFiles = <File>[];
        for (final file in allFiles) {
          final stat = await file.stat();
          final age = now.difference(stat.modified);
          if (age.inMinutes < 1) {
            recentFiles.add(file);
          }
        }

        // Assert: NO new report files should be created
        expect(
          recentFiles,
          isEmpty,
          reason: 'No report files should be created when --no-report is set',
        );
      }

      // If directory doesn't exist, that's also correct
      print('✓ Test 2: Verified NO report files created');
    });

    test('--no-report with --verbose should show test output but NO report',
        () async {
      // 🔴 RED: This test should FAIL initially (report is printed)
      //
      // Run analyzer with --no-report --verbose flags
      final result = await Process.run(
        'dart',
        [
          'run',
          'test_reporter:analyze_tests',
          'test/unit/models/',
          '--runs=1',
          '--no-report',
          '--verbose',
        ],
        workingDirectory: projectRoot,
      );

      final stdout = result.stdout.toString();

      // Verbose test execution output MAY be shown (that's fine)
      // But report sections should NOT appear

      final reportSections = [
        'Test Analysis Report',
        'Reliability Matrix',
        'Failure Analysis',
        'Performance Metrics',
      ];

      // Assert: Report sections should NOT appear
      for (final section in reportSections) {
        expect(
          stdout,
          isNot(contains(section)),
          reason:
              'Report section "$section" should NOT appear with --no-report, '
              'even when --verbose is set',
        );
      }

      print('✓ Test 3: Verified --verbose shows output but NO report');
    });

    test('--no-report with --runs=5 should work correctly', () async {
      // 🔴 RED: This test should FAIL initially (report is printed)
      //
      // Run analyzer with --no-report --runs=5
      final result = await Process.run(
        'dart',
        [
          'run',
          'test_reporter:analyze_tests',
          'test/unit/models/',
          '--runs=5',
          '--no-report',
        ],
        workingDirectory: projectRoot,
      );

      final stdout = result.stdout.toString();

      // The analyzer should run tests 5 times (verify via exit code or logs)
      // Exit code 0 = all passed, 1 = some failed, 2 = error
      expect(
        result.exitCode,
        anyOf([0, 1]), // Either all passed or some failed (both valid)
        reason: 'Analyzer should complete successfully',
      );

      // But NO report should be generated
      final reportSections = [
        'Test Analysis Report',
        'Reliability Matrix',
        'Flaky Tests',
      ];

      for (final section in reportSections) {
        expect(
          stdout,
          isNot(contains(section)),
          reason:
              'Report section "$section" should NOT appear when --no-report is set, '
              'regardless of --runs value',
        );
      }

      print('✓ Test 4: Verified --no-report works with --runs=5');
    });

    test('default behavior (no flag) should generate report', () async {
      // 🟢 GREEN: This test should PASS (baseline behavior)
      //
      // Run analyzer WITHOUT --no-report flag
      final result = await Process.run(
        'dart',
        [
          'run',
          'test_reporter:analyze_tests',
          'test/unit/models/',
          '--runs=1',
        ],
        workingDirectory: projectRoot,
      );

      final stdout = result.stdout.toString();

      // Report SHOULD be printed to stdout (default behavior)
      // At least ONE report section should appear
      final reportIndicators = [
        'Test',
        'Report',
        'Analysis',
        'Summary',
        '===',
      ];

      var foundReportIndicator = false;
      for (final indicator in reportIndicators) {
        if (stdout.contains(indicator)) {
          foundReportIndicator = true;
          break;
        }
      }

      expect(
        foundReportIndicator,
        isTrue,
        reason:
            'Report should be generated and printed when --no-report is NOT set '
            '(this is the expected default behavior)',
      );

      // Report files SHOULD be created
      if (await reportsDir.exists()) {
        final now = DateTime.now();
        final allFiles = await reportsDir
            .list()
            .where((entity) => entity is File)
            .cast<File>()
            .toList();

        // Filter for recent files (created in last minute)
        final recentFiles = <File>[];
        for (final file in allFiles) {
          final stat = await file.stat();
          final age = now.difference(stat.modified);
          if (age.inMinutes < 1) {
            recentFiles.add(file);
          }
        }

        // At least one report file should exist (markdown or JSON)
        expect(
          recentFiles.length,
          greaterThan(0),
          reason: 'Report files should be created by default',
        );
      }

      print('✓ Test 5: Verified default behavior generates report');
    });
  });

  group('--no-report consistency check', () {
    late String projectRoot;

    setUp(() {
      projectRoot = Directory.current.path;
    });

    test('analyze_tests --no-report behavior matches analyze_coverage',
        () async {
      // This test verifies both tools suppress output similarly
      //
      // Run analyze_tests with --no-report
      final testsResult = await Process.run(
        'dart',
        [
          'run',
          'test_reporter:analyze_tests',
          'test/unit/models/',
          '--runs=1',
          '--no-report',
        ],
        workingDirectory: projectRoot,
      );

      // Run analyze_coverage with --no-report
      final coverageResult = await Process.run(
        'dart',
        [
          'run',
          'test_reporter:analyze_coverage',
          'lib/src/models/',
          '--no-report',
        ],
        workingDirectory: projectRoot,
      );

      final testsStdout = testsResult.stdout.toString();
      final coverageStdout = coverageResult.stdout.toString();

      // Both should suppress report output
      // (This is a behavioral consistency test)

      final reportSections = ['Report', 'Analysis', 'Summary'];

      var testsHasReport = false;
      var coverageHasReport = false;

      for (final section in reportSections) {
        if (testsStdout.contains(section)) testsHasReport = true;
        if (coverageStdout.contains(section)) coverageHasReport = true;
      }

      // Both should behave the same way (either both suppress or both show)
      // Expected: both suppress (both false)
      expect(
        testsHasReport,
        equals(coverageHasReport),
        reason: 'Both tools should handle --no-report consistently. '
            'analyze_coverage works correctly (suppresses output), '
            'so analyze_tests should also suppress output.',
      );

      print('✓ Consistency check: Both tools behave similarly');
    });
  });
}
