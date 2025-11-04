import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_reporter/src/utils/report_utils.dart';

void main() {
  late Directory tempDir;
  late Directory reportsDir;

  setUp(() async {
    // Create temp test directory
    tempDir = await Directory.systemTemp.createTemp('report_utils_test_');
    reportsDir = Directory(p.join(tempDir.path, 'tests_reports'));
    await reportsDir.create(recursive: true);
  });

  tearDown(() async {
    // Clean up temp directory
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('ReportUtils.cleanOldReports - Cleanup Behavior', () {
    test('🔴 should delete old reports with same module name', () async {
      // Create reliability subdirectory
      final reliabilityDir = Directory(p.join(reportsDir.path, 'reliability'));
      await reliabilityDir.create(recursive: true);

      // Create 2 reports with same module, different timestamps
      final oldReport = File(
          p.join(reliabilityDir.path, 'flaky-fi_report_tests@2153_041125.md'));
      final newReport = File(
          p.join(reliabilityDir.path, 'flaky-fi_report_tests@2154_041125.md'));

      await oldReport.writeAsString('Old report content');
      await newReport.writeAsString('New report content');

      // Verify both exist before cleanup
      expect(await oldReport.exists(), isTrue,
          reason: 'Old report should exist before cleanup');
      expect(await newReport.exists(), isTrue,
          reason: 'New report should exist before cleanup');

      // Run cleanup with baseDir for test isolation
      await ReportUtils.cleanOldReports(
        pathName: 'flaky-fi',
        prefixPatterns: ['report_tests'],
        subdirectory: 'reliability',
        verbose: false,
        baseDir: reportsDir.path,
      );

      // Verify only new report remains (old one deleted)
      expect(await oldReport.exists(), isFalse,
          reason: 'Old report should be deleted by cleanup');
      expect(await newReport.exists(), isTrue,
          reason: 'New report should remain after cleanup');
    });

    test('🔴 should preserve reports with different module names', () async {
      final reliabilityDir = Directory(p.join(reportsDir.path, 'reliability'));
      await reliabilityDir.create(recursive: true);

      // Create reports for different modules
      final flakyReport = File(
          p.join(reliabilityDir.path, 'flaky-fi_report_tests@2153_041125.md'));
      final authReport = File(
          p.join(reliabilityDir.path, 'auth-fo_report_tests@2153_041125.md'));

      await flakyReport.writeAsString('Flaky report');
      await authReport.writeAsString('Auth report');

      // Run cleanup for flaky module only
      await ReportUtils.cleanOldReports(
        pathName: 'flaky-fi',
        prefixPatterns: ['report_tests'],
        subdirectory: 'reliability',
        verbose: false,
        baseDir: reportsDir.path,
      );

      // Verify both remain (different modules should not affect each other)
      expect(await flakyReport.exists(), isTrue,
          reason: 'Flaky report should remain');
      expect(await authReport.exists(), isTrue,
          reason: 'Auth report should remain (different module)');
    });

    test('🔴 should only match specified pattern prefix', () async {
      final reliabilityDir = Directory(p.join(reportsDir.path, 'reliability'));
      await reliabilityDir.create(recursive: true);

      // Create reports with different patterns
      final testsReport = File(
          p.join(reliabilityDir.path, 'flaky-fi_report_tests@2153_041125.md'));
      final coverageReport = File(p.join(
          reliabilityDir.path, 'flaky-fi_report_coverage@2153_041125.md'));

      await testsReport.writeAsString('Tests report');
      await coverageReport.writeAsString('Coverage report');

      // Run cleanup for tests pattern only
      await ReportUtils.cleanOldReports(
        pathName: 'flaky-fi',
        prefixPatterns: ['report_tests'],
        subdirectory: 'reliability',
        verbose: false,
        baseDir: reportsDir.path,
      );

      // Verify only tests report affected (coverage has different pattern)
      expect(await testsReport.exists(), isTrue,
          reason: 'Tests report should remain');
      expect(await coverageReport.exists(), isTrue,
          reason: 'Coverage report should remain (different pattern)');
    });

    test('🔴 should respect subdirectory filter', () async {
      // Create multiple subdirectories
      final reliabilityDir = Directory(p.join(reportsDir.path, 'reliability'));
      final qualityDir = Directory(p.join(reportsDir.path, 'quality'));
      await reliabilityDir.create(recursive: true);
      await qualityDir.create(recursive: true);

      // Create reports in different subdirs with same module name
      final reliabilityReport = File(
          p.join(reliabilityDir.path, 'flaky-fi_report_tests@2153_041125.md'));
      final qualityReport = File(
          p.join(qualityDir.path, 'flaky-fi_report_coverage@2153_041125.md'));

      await reliabilityReport.writeAsString('Reliability report');
      await qualityReport.writeAsString('Quality report');

      // Run cleanup on reliability subdirectory only
      await ReportUtils.cleanOldReports(
        pathName: 'flaky-fi',
        prefixPatterns: ['report_tests'],
        subdirectory: 'reliability',
        verbose: false,
        baseDir: reportsDir.path,
      );

      // Verify quality report unaffected (different subdir)
      expect(await reliabilityReport.exists(), isTrue,
          reason: 'Reliability report should remain');
      expect(await qualityReport.exists(), isTrue,
          reason: 'Quality report should remain (different subdirectory)');
    });

    test('🔴 should handle multiple old reports and keep only latest',
        () async {
      final reliabilityDir = Directory(p.join(reportsDir.path, 'reliability'));
      await reliabilityDir.create(recursive: true);

      // Create 3 reports with same module, different timestamps
      final oldest = File(
          p.join(reliabilityDir.path, 'flaky-fi_report_tests@2151_041125.md'));
      final middle = File(
          p.join(reliabilityDir.path, 'flaky-fi_report_tests@2152_041125.md'));
      final newest = File(
          p.join(reliabilityDir.path, 'flaky-fi_report_tests@2153_041125.md'));

      await oldest.writeAsString('Oldest report');
      await middle.writeAsString('Middle report');
      await newest.writeAsString('Newest report');

      // Verify all exist
      expect(await oldest.exists(), isTrue);
      expect(await middle.exists(), isTrue);
      expect(await newest.exists(), isTrue);

      // Run cleanup
      await ReportUtils.cleanOldReports(
        pathName: 'flaky-fi',
        prefixPatterns: ['report_tests'],
        subdirectory: 'reliability',
        verbose: false,
        baseDir: reportsDir.path,
      );

      // Verify only newest remains
      expect(await oldest.exists(), isFalse,
          reason: 'Oldest report should be deleted');
      expect(await middle.exists(), isFalse,
          reason: 'Middle report should be deleted');
      expect(await newest.exists(), isTrue,
          reason: 'Newest report should remain');
    });

    test('🔴 should handle both .md and .json files with same timestamp',
        () async {
      final reliabilityDir = Directory(p.join(reportsDir.path, 'reliability'));
      await reliabilityDir.create(recursive: true);

      // Create old report pair (md + json)
      final oldMd = File(
          p.join(reliabilityDir.path, 'flaky-fi_report_tests@2153_041125.md'));
      final oldJson = File(p.join(
          reliabilityDir.path, 'flaky-fi_report_tests@2153_041125.json'));

      // Create new report pair (md + json)
      final newMd = File(
          p.join(reliabilityDir.path, 'flaky-fi_report_tests@2154_041125.md'));
      final newJson = File(p.join(
          reliabilityDir.path, 'flaky-fi_report_tests@2154_041125.json'));

      await oldMd.writeAsString('Old markdown');
      await oldJson.writeAsString('{"old": true}');
      await newMd.writeAsString('New markdown');
      await newJson.writeAsString('{"new": true}');

      // Run cleanup
      await ReportUtils.cleanOldReports(
        pathName: 'flaky-fi',
        prefixPatterns: ['report_tests'],
        subdirectory: 'reliability',
        verbose: false,
        baseDir: reportsDir.path,
      );

      // Verify only new pair remains
      expect(await oldMd.exists(), isFalse,
          reason: 'Old .md should be deleted');
      expect(await oldJson.exists(), isFalse,
          reason: 'Old .json should be deleted');
      expect(await newMd.exists(), isTrue, reason: 'New .md should remain');
      expect(await newJson.exists(), isTrue, reason: 'New .json should remain');
    });
  });

  group('ReportUtils.cleanOldReports - Pattern Matching', () {
    test('🔴 should NOT match legacy pattern with double underscores',
        () async {
      final reliabilityDir = Directory(p.join(reportsDir.path, 'reliability'));
      await reliabilityDir.create(recursive: true);

      // Create report with current naming convention
      final currentFormat = File(
          p.join(reliabilityDir.path, 'flaky-fi_report_tests@2153_041125.md'));

      // Create hypothetical legacy format file (if it existed)
      // Legacy format: {pathName without underscores}_{pattern}__{timestamp}
      final legacyFormat = File(
          p.join(reliabilityDir.path, 'flakyfi_report_tests__2153_041125.md'));

      await currentFormat.writeAsString('Current format');
      await legacyFormat.writeAsString('Legacy format');

      // Run cleanup
      await ReportUtils.cleanOldReports(
        pathName: 'flaky-fi',
        prefixPatterns: ['report_tests'],
        subdirectory: 'reliability',
        verbose: false,
        baseDir: reportsDir.path,
      );

      // Current format should be recognized and kept (latest)
      expect(await currentFormat.exists(), isTrue,
          reason: 'Current format should be recognized');

      // Legacy format should NOT be matched by cleanup (different pattern)
      expect(await legacyFormat.exists(), isTrue,
          reason: 'Legacy format should NOT match (different pattern)');
    });

    test('🔴 should correctly parse module names with dashes and underscores',
        () async {
      final reliabilityDir = Directory(p.join(reportsDir.path, 'reliability'));
      await reliabilityDir.create(recursive: true);

      // Test various module name formats
      final dashReport = File(p.join(
          reliabilityDir.path, 'my-module-fi_report_tests@2153_041125.md'));
      final underscoreReport = File(p.join(reliabilityDir.path,
          'my_module_name-fo_report_tests@2153_041125.md'));

      await dashReport.writeAsString('Dash module');
      await underscoreReport.writeAsString('Underscore module');

      // Cleanup dash module
      await ReportUtils.cleanOldReports(
        pathName: 'my-module-fi',
        prefixPatterns: ['report_tests'],
        subdirectory: 'reliability',
        verbose: false,
        baseDir: reportsDir.path,
      );

      // Dash report should be affected, underscore should not
      expect(await dashReport.exists(), isTrue,
          reason: 'Dash module report should be recognized');
      expect(await underscoreReport.exists(), isTrue,
          reason: 'Different module should not be affected');
    });
  });
}
