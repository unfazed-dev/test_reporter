import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_reporter/src/utils/report_manager.dart';
import 'package:test_reporter/src/utils/report_utils.dart';

void main() {
  late Directory tempDir;
  late Directory reportsDir;
  late String originalDir;

  setUp(() async {
    // Save original directory
    originalDir = Directory.current.path;

    // Create temp test directory
    tempDir = await Directory.systemTemp.createTemp('report_utils_test_');
    reportsDir = Directory(p.join(tempDir.path, 'tests_reports'));
    await reportsDir.create(recursive: true);

    // Change to temp directory for testing
    Directory.current = tempDir.path;

    // Override ReportManager for test isolation
    ReportManager.overrideReportsRoot(reportsDir.path);
  });

  tearDown(() async {
    // Restore original directory
    Directory.current = originalDir;

    // Clean up temp directory (also resets ReportManager override)
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

    test('🔴 should clean all subdirectories when subdirectory is null',
        () async {
      // Create all 4 subdirectories
      final reliabilityDir = Directory(p.join(reportsDir.path, 'reliability'));
      final qualityDir = Directory(p.join(reportsDir.path, 'quality'));
      final failuresDir = Directory(p.join(reportsDir.path, 'failures'));
      final suiteDir = Directory(p.join(reportsDir.path, 'suite'));

      await reliabilityDir.create(recursive: true);
      await qualityDir.create(recursive: true);
      await failuresDir.create(recursive: true);
      await suiteDir.create(recursive: true);

      // Create old and new reports in each subdirectory
      final oldReliability = File(p.join(
          reliabilityDir.path, 'all-subdirs-fi_report_tests@2153_041125.md'));
      final newReliability = File(p.join(
          reliabilityDir.path, 'all-subdirs-fi_report_tests@2154_041125.md'));

      final oldQuality = File(p.join(
          qualityDir.path, 'all-subdirs-fi_report_tests@2153_041125.md'));
      final newQuality = File(p.join(
          qualityDir.path, 'all-subdirs-fi_report_tests@2154_041125.md'));

      await oldReliability.writeAsString('Old reliability');
      await newReliability.writeAsString('New reliability');
      await oldQuality.writeAsString('Old quality');
      await newQuality.writeAsString('New quality');

      // Run cleanup WITHOUT subdirectory parameter (triggers line 67)
      await ReportUtils.cleanOldReports(
        pathName: 'all-subdirs-fi',
        prefixPatterns: ['report_tests'],
        // NO subdirectory parameter - cleans all 4 subdirs
        verbose: false,
        baseDir: reportsDir.path,
      );

      // Verify old reports deleted in ALL subdirectories
      expect(await oldReliability.exists(), isFalse,
          reason: 'Old reliability report should be deleted');
      expect(await newReliability.exists(), isTrue,
          reason: 'New reliability report should remain');
      expect(await oldQuality.exists(), isFalse,
          reason: 'Old quality report should be deleted');
      expect(await newQuality.exists(), isTrue,
          reason: 'New quality report should remain');
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

  group('ReportUtils.getReportDirectory', () {
    test('should return absolute path to tests_reports directory', () async {
      final reportDir = await ReportUtils.getReportDirectory();

      expect(reportDir, isNotNull);
      expect(reportDir, endsWith(p.join(tempDir.path, 'tests_reports')));
      expect(await Directory(reportDir).exists(), isTrue);
    });

    test('should create directory if it does not exist', () async {
      // Delete the reports directory
      if (await reportsDir.exists()) {
        await reportsDir.delete(recursive: true);
      }

      expect(await reportsDir.exists(), isFalse);

      // Call getReportDirectory
      final reportDir = await ReportUtils.getReportDirectory();

      // Verify directory was created
      expect(await Directory(reportDir).exists(), isTrue);
    });
  });

  group('ReportUtils.ensureDirectoryExists', () {
    test('should create directory if it does not exist', () async {
      final testDir = p.join(tempDir.path, 'new_test_dir');
      expect(await Directory(testDir).exists(), isFalse);

      await ReportUtils.ensureDirectoryExists(testDir);

      expect(await Directory(testDir).exists(), isTrue);
    });

    test('should handle existing directory without error', () async {
      final testDir = p.join(tempDir.path, 'existing_dir');
      await Directory(testDir).create(recursive: true);
      expect(await Directory(testDir).exists(), isTrue);

      // Should not throw
      await ReportUtils.ensureDirectoryExists(testDir);

      expect(await Directory(testDir).exists(), isTrue);
    });
  });

  group('ReportUtils.getReportPath', () {
    test('should generate path for coverage report in quality/ subdir',
        () async {
      final path = await ReportUtils.getReportPath(
        'my-module-fo',
        '1430_091125',
        suffix: 'coverage',
        baseDir: reportsDir.path,
      );

      expect(path, contains('quality'));
      expect(path, contains('my-module-fo_report_coverage@1430_091125.md'));
    });

    test('should generate path for tests report in reliability/ subdir',
        () async {
      final path = await ReportUtils.getReportPath(
        'my-module-fo',
        '1430_091125',
        suffix: 'tests',
        baseDir: reportsDir.path,
      );

      expect(path, contains('reliability'));
      expect(path, contains('my-module-fo_report_tests@1430_091125.md'));
    });

    test('should generate path for failures report in failures/ subdir',
        () async {
      final path = await ReportUtils.getReportPath(
        'my-module-fo',
        '1430_091125',
        suffix: 'failures',
        baseDir: reportsDir.path,
      );

      expect(path, contains('failures'));
      expect(path, contains('my-module-fo_report_failures@1430_091125.md'));
    });

    test('should generate path for suite report in suite/ subdir', () async {
      final path = await ReportUtils.getReportPath(
        'my-module-fo',
        '1430_091125',
        suffix: '',
        baseDir: reportsDir.path,
      );

      expect(path, contains('suite'));
      expect(path, contains('my-module-fo_report@1430_091125.md'));
    });

    test('should create subdirectory if it does not exist', () async {
      final qualityDir = Directory(p.join(reportsDir.path, 'quality'));
      if (await qualityDir.exists()) {
        await qualityDir.delete(recursive: true);
      }

      expect(await qualityDir.exists(), isFalse);

      await ReportUtils.getReportPath(
        'my-module-fo',
        '1430_091125',
        suffix: 'coverage',
        baseDir: reportsDir.path,
      );

      expect(await qualityDir.exists(), isTrue);
    });
  });

  group('ReportUtils.writeUnifiedReport', () {
    test('should write markdown content with embedded JSON', () async {
      final markdownContent = '# Test Report\n\nSome content here.';
      final jsonData = {'test': 'value', 'count': 42};

      final reportPath = await ReportUtils.writeUnifiedReport(
        moduleName: 'test-module-fo',
        timestamp: '1430_091125',
        markdownContent: markdownContent,
        jsonData: jsonData,
        suffix: 'coverage',
        baseDir: reportsDir.path,
      );

      expect(await File(reportPath).exists(), isTrue);

      final content = await File(reportPath).readAsString();
      expect(content, contains('# Test Report'));
      expect(content, contains('Some content here.'));
      expect(content, contains('## 📊 Machine-Readable Data'));
      expect(content, contains('```json'));
      expect(content, contains('"test": "value"'));
      expect(content, contains('"count": 42'));
    });

    test('should print verbose message when verbose=true', () async {
      final markdownContent = '# Test';
      final jsonData = {'test': 'value'};

      // Capture print output (note: this is tricky in Dart tests)
      // For now, just verify it doesn't throw
      final reportPath = await ReportUtils.writeUnifiedReport(
        moduleName: 'test-module-fo',
        timestamp: '1431_091125',
        markdownContent: markdownContent,
        jsonData: jsonData,
        suffix: 'tests',
        verbose: true,
        baseDir: reportsDir.path,
      );

      expect(await File(reportPath).exists(), isTrue);
    });
  });

  group('ReportUtils.extractJsonFromReport', () {
    test('should extract JSON from unified report', () async {
      final markdownContent = '# Test Report\n\nContent.';
      final jsonData = {'extracted': true, 'value': 123};

      final reportPath = await ReportUtils.writeUnifiedReport(
        moduleName: 'extract-test-fo',
        timestamp: '1432_091125',
        markdownContent: markdownContent,
        jsonData: jsonData,
        suffix: 'coverage',
        baseDir: reportsDir.path,
      );

      final extracted = await ReportUtils.extractJsonFromReport(reportPath);

      expect(extracted, isNotNull);
      expect(extracted!['extracted'], isTrue);
      expect(extracted['value'], equals(123));
    });

    test('should return null if file does not exist', () async {
      final nonExistentPath =
          p.join(reportsDir.path, 'quality', 'nonexistent.md');

      final result = await ReportUtils.extractJsonFromReport(nonExistentPath);

      expect(result, isNull);
    });

    test('should return null if no JSON section found', () async {
      final reportPath =
          p.join(reportsDir.path, 'quality', 'no-json_report@1433_091125.md');
      await Directory(p.join(reportsDir.path, 'quality'))
          .create(recursive: true);
      await File(reportPath).writeAsString('# Report\n\nNo JSON section here.');

      final result = await ReportUtils.extractJsonFromReport(reportPath);

      expect(result, isNull);
    });

    test('should handle malformed JSON gracefully', () async {
      final reportPath =
          p.join(reportsDir.path, 'quality', 'bad-json_report@1434_091125.md');
      await Directory(p.join(reportsDir.path, 'quality'))
          .create(recursive: true);
      await File(reportPath).writeAsString('''
# Report

Content here.

---

## 📊 Machine-Readable Data

```json
{malformed json here}
```
''');

      final result = await ReportUtils.extractJsonFromReport(reportPath);

      expect(result, isNull);
    });
  });

  group('ReportUtils.cleanOldReports - Verbose Logging', () {
    test('should print verbose output when verbose=true', () async {
      final reliabilityDir = Directory(p.join(reportsDir.path, 'reliability'));
      await reliabilityDir.create(recursive: true);

      final report = File(p.join(
          reliabilityDir.path, 'verbose-fi_report_tests@2153_041125.md'));
      await report.writeAsString('Test report');

      // Run with verbose=true (output goes to stdout, hard to capture in test)
      // Just verify it doesn't throw
      await ReportUtils.cleanOldReports(
        pathName: 'verbose-fi',
        prefixPatterns: ['report_tests'],
        subdirectory: 'reliability',
        verbose: true,
        baseDir: reportsDir.path,
      );

      expect(await report.exists(), isTrue);
    });

    test('should handle delete failure gracefully with verbose=true', () async {
      final reliabilityDir = Directory(p.join(reportsDir.path, 'reliability'));
      await reliabilityDir.create(recursive: true);

      final oldReport = File(
          p.join(reliabilityDir.path, 'delete-fi_report_tests@2153_041125.md'));
      final newReport = File(
          p.join(reliabilityDir.path, 'delete-fi_report_tests@2154_091125.md'));

      await oldReport.writeAsString('Old');
      await newReport.writeAsString('New');

      // Run with verbose=true
      // (We can't easily mock file deletion failure, but we can test the code path)
      await ReportUtils.cleanOldReports(
        pathName: 'delete-fi',
        prefixPatterns: ['report_tests'],
        subdirectory: 'reliability',
        verbose: true,
        baseDir: reportsDir.path,
      );

      expect(await newReport.exists(), isTrue);
    });

    test('should use default baseDir when not provided', () async {
      // Create reports in the actual reports directory (via ReportManager override)
      final reliabilityDir = Directory(p.join(reportsDir.path, 'reliability'));
      await reliabilityDir.create(recursive: true);

      final oldReport = File(p.join(
          reliabilityDir.path, 'default-dir-fi_report_tests@2153_041125.md'));
      final newReport = File(p.join(
          reliabilityDir.path, 'default-dir-fi_report_tests@2154_091125.md'));

      await oldReport.writeAsString('Old');
      await newReport.writeAsString('New');

      // Call WITHOUT baseDir parameter to trigger default path (line 62, 67)
      await ReportUtils.cleanOldReports(
        pathName: 'default-dir-fi',
        prefixPatterns: ['report_tests'],
        subdirectory: 'reliability',
        verbose: false,
        // NO baseDir parameter - uses getReportDirectory()
      );

      expect(await oldReport.exists(), isFalse);
      expect(await newReport.exists(), isTrue);
    });
  });

  group('ReportUtils.getReportPath - Default BaseDir', () {
    test('should use default baseDir when not provided', () async {
      // Call WITHOUT baseDir to trigger line 170
      final path = await ReportUtils.getReportPath(
        'default-path-fo',
        '1435_091125',
        suffix: 'coverage',
        // NO baseDir - uses getReportDirectory()
      );

      expect(path, contains('quality'));
      expect(path, contains('default-path-fo_report_coverage@1435_091125.md'));
    });
  });
}
