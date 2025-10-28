import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_analyzer/src/utils/report_utils.dart';

/// Clean up test-created files and directories
Future<void> _cleanupTestArtifacts(String reportDir) async {
  try {
    final reportDirectory = Directory(reportDir);
    if (!await reportDirectory.exists()) return;

    // Clean up test files and directories
    await for (final entity in reportDirectory.list(recursive: true)) {
      try {
        if (entity is File) {
          final path = entity.path;
          // Delete test files (those with test-fo, module-fo, etc. in the name)
          if (path.contains('test-fo') ||
              path.contains('module-fo') ||
              path.contains('module-fi') ||
              path.contains('other-fo') ||
              path.contains('src-fo')) {
            // Only delete if it's a test artifact (has specific test timestamps)
            if (path.contains('@1234_010125') ||
                path.contains('@5678') ||
                path.contains('test_report_coverage@5678')) {
              await entity.delete();
            }
          }
        } else if (entity is Directory) {
          final dirName = p.basename(entity.path);
          // Delete test subdirectories
          if (dirName == 'subdir' ||
              dirName == 'new_directory' ||
              dirName == 'existing_directory' ||
              dirName.startsWith('level')) {
            await entity.delete(recursive: true);
          }
        }
      } catch (e) {
        // Ignore cleanup errors
      }
    }
  } catch (e) {
    // Ignore cleanup errors
  }
}

void main() {
  late Directory tempDir;
  late String reportDir;

  setUp(() async {
    // Create temp directory for testing
    tempDir = await Directory.systemTemp.createTemp('test_analyzer_test_');

    // Get report directory for cleanup tracking
    reportDir = await ReportUtils.getReportDirectory();
  });

  tearDown(() async {
    // Clean up temp directory
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }

    // Clean up any test artifacts in report directory
    await _cleanupTestArtifacts(reportDir);
  });

  group('getReportDirectory', () {
    test('should create report directory if it does not exist', () async {
      final reportDir = await ReportUtils.getReportDirectory();

      expect(await Directory(reportDir).exists(), isTrue);
      expect(reportDir, endsWith('test_analyzer_reports'));
    });

    test('should return existing report directory', () async {
      // Call twice
      final reportDir1 = await ReportUtils.getReportDirectory();
      final reportDir2 = await ReportUtils.getReportDirectory();

      expect(reportDir1, reportDir2);
      expect(await Directory(reportDir1).exists(), isTrue);
    });
  });

  group('ensureDirectoryExists', () {
    test('should create directory if it does not exist', () async {
      final testPath = p.join(tempDir.path, 'new_directory');
      expect(await Directory(testPath).exists(), isFalse);

      await ReportUtils.ensureDirectoryExists(testPath);

      expect(await Directory(testPath).exists(), isTrue);
    });

    test('should handle existing directory', () async {
      final testPath = p.join(tempDir.path, 'existing_directory');
      await Directory(testPath).create();

      await ReportUtils.ensureDirectoryExists(testPath);

      expect(await Directory(testPath).exists(), isTrue);
    });

    test('should create nested directories recursively', () async {
      final testPath = p.join(tempDir.path, 'level1', 'level2', 'level3');
      expect(await Directory(testPath).exists(), isFalse);

      await ReportUtils.ensureDirectoryExists(testPath);

      expect(await Directory(testPath).exists(), isTrue);
    });
  });

  group('getReportPath', () {
    test('should generate path in coverage subdirectory for coverage suffix', () async {
      final path = await ReportUtils.getReportPath(
        'module-fo',
        '1234_010125',
        suffix: 'coverage',
      );

      expect(path, contains('test_analyzer_reports'));
      expect(path, contains('coverage'));
      expect(path, endsWith('module-fo_test_report_coverage@1234_010125.md'));

      // Verify subdirectory was created
      final subdirPath = p.dirname(path);
      expect(await Directory(subdirPath).exists(), isTrue);
    });

    test('should generate path in analyzer subdirectory for analyzer suffix', () async {
      final path = await ReportUtils.getReportPath(
        'test-fo',
        '1234_010125',
        suffix: 'analyzer',
      );

      expect(path, contains('analyzer'));
      expect(path, endsWith('test-fo_test_report_analyzer@1234_010125.md'));
    });

    test('should generate path in failed subdirectory for failed suffix', () async {
      final path = await ReportUtils.getReportPath(
        'module-fi',
        '1234_010125',
        suffix: 'failed',
      );

      expect(path, contains('failed'));
      expect(path, endsWith('module-fi_test_report_failed@1234_010125.md'));
    });

    test('should generate path in unified subdirectory for empty suffix', () async {
      final path = await ReportUtils.getReportPath(
        'src-fo',
        '1234_010125',
      );

      expect(path, contains('unified'));
      expect(path, endsWith('src-fo_test_report@1234_010125.md'));
    });

    test('should generate path in unified subdirectory for unknown suffix', () async {
      final path = await ReportUtils.getReportPath(
        'module-fo',
        '1234_010125',
        suffix: 'unknown',
      );

      expect(path, contains('unified'));
    });
  });

  group('writeUnifiedReport', () {
    test('should create report file with markdown and JSON', () async {
      final reportPath = await ReportUtils.writeUnifiedReport(
        moduleName: 'test-fo',
        timestamp: '1234_010125',
        markdownContent: '# Test Report\n\nSome content',
        jsonData: {'metric': 'value', 'count': 42},
        suffix: 'coverage',
      );

      expect(await File(reportPath).exists(), isTrue);

      final content = await File(reportPath).readAsString();
      expect(content, contains('# Test Report'));
      expect(content, contains('Some content'));
      expect(content, contains('## 📊 Machine-Readable Data'));
      expect(content, contains('```json'));
      expect(content, contains('"metric": "value"'));
      expect(content, contains('"count": 42'));
    });

    test('should handle verbose output', () async {
      // Just verify it doesn't throw with verbose=true
      await ReportUtils.writeUnifiedReport(
        moduleName: 'test-fo',
        timestamp: '1234_010125',
        markdownContent: '# Report',
        jsonData: {},
        verbose: true,
      );
    });

    test('should format JSON with indentation', () async {
      final reportPath = await ReportUtils.writeUnifiedReport(
        moduleName: 'test-fo',
        timestamp: '1234_010125',
        markdownContent: '# Report',
        jsonData: {
          'nested': {'key': 'value'},
          'list': [1, 2, 3]
        },
      );

      final content = await File(reportPath).readAsString();
      expect(content, contains('  "nested": {'));
      expect(content, contains('    "key": "value"'));
    });

    test('should return the report path', () async {
      final reportPath = await ReportUtils.writeUnifiedReport(
        moduleName: 'test-fo',
        timestamp: '1234_010125',
        markdownContent: '# Report',
        jsonData: {},
      );

      expect(reportPath, isNotEmpty);
      expect(await File(reportPath).exists(), isTrue);
    });
  });

  group('extractJsonFromReport', () {
    test('should extract JSON from report file', () async {
      final reportPath = await ReportUtils.writeUnifiedReport(
        moduleName: 'test-fo',
        timestamp: '1234_010125',
        markdownContent: '# Report',
        jsonData: {'key': 'value', 'number': 123},
      );

      final extracted = await ReportUtils.extractJsonFromReport(reportPath);

      expect(extracted, isNotNull);
      expect(extracted!['key'], 'value');
      expect(extracted['number'], 123);
    });

    test('should return null for non-existent file', () async {
      final extracted = await ReportUtils.extractJsonFromReport(
        '/nonexistent/file.md',
      );

      expect(extracted, isNull);
    });

    test('should return null for file without JSON section', () async {
      final reportPath = p.join(tempDir.path, 'no_json.md');
      await File(reportPath).writeAsString('# Report\n\nNo JSON here');

      final extracted = await ReportUtils.extractJsonFromReport(reportPath);

      expect(extracted, isNull);
    });

    test('should return null for invalid JSON', () async {
      final reportPath = p.join(tempDir.path, 'invalid_json.md');
      await File(reportPath).writeAsString(
        '# Report\n\n```json\n{invalid json}\n```',
      );

      final extracted = await ReportUtils.extractJsonFromReport(reportPath);

      expect(extracted, isNull);
    });

    test('should find LAST occurrence of json marker', () async {
      // Create report with code example containing ```json
      const content = '''
# Report

Here's an example:

```json
{"example": "code"}
```

---

## 📊 Machine-Readable Data

```json
{"actual": "data", "value": 42}
```
''';

      final reportPath = p.join(tempDir.path, 'multi_json.md');
      await File(reportPath).writeAsString(content);

      final extracted = await ReportUtils.extractJsonFromReport(reportPath);

      expect(extracted, isNotNull);
      expect(extracted!['actual'], 'data');
      expect(extracted['value'], 42);
      expect(extracted.containsKey('example'), isFalse);
    });

    test('should handle complex nested JSON', () async {
      final complexData = {
        'metadata': {
          'tool': 'coverage',
          'version': '2.0',
        },
        'results': [
          {'file': 'test.dart', 'coverage': 85.5},
          {'file': 'main.dart', 'coverage': 92.3},
        ],
        'summary': {
          'total': 100,
          'covered': 88,
        },
      };

      final reportPath = await ReportUtils.writeUnifiedReport(
        moduleName: 'test-fo',
        timestamp: '1234_010125',
        markdownContent: '# Complex Report',
        jsonData: complexData,
      );

      final extracted = await ReportUtils.extractJsonFromReport(reportPath);

      expect(extracted, isNotNull);
      final metadata = extracted!['metadata'] as Map<String, dynamic>;
      expect(metadata['tool'], 'coverage');
      final results = extracted['results'] as List<dynamic>;
      expect(results, isList);
      final firstResult = results[0] as Map<String, dynamic>;
      expect(firstResult['file'], 'test.dart');
      final summary = extracted['summary'] as Map<String, dynamic>;
      expect(summary['total'], 100);
    });
  });

  group('cleanOldReports', () {
    test('should keep latest and delete old reports', () async {
      final reportDir = await ReportUtils.getReportDirectory();

      // Create subdirectories
      await Directory(p.join(reportDir, 'coverage')).create(recursive: true);
      await Directory(p.join(reportDir, 'analyzer')).create(recursive: true);

      // Create multiple test report files (older and newer)
      await File(
              p.join(reportDir, 'coverage', 'module-fo_test_report_coverage@1234_010125.md'))
          .create();
      await File(
              p.join(reportDir, 'coverage', 'module-fo_test_report_coverage@5678_010125.md'))
          .create();
      await File(
              p.join(reportDir, 'analyzer', 'module-fo_test_report_analyzer@1234_010125.md'))
          .create();
      await File(
              p.join(reportDir, 'analyzer', 'module-fo_test_report_analyzer@5678_010125.md'))
          .create();
      await File(
              p.join(reportDir, 'coverage', 'other-fo_test_report_coverage@1234_010125.md'))
          .create();

      await ReportUtils.cleanOldReports(
        pathName: 'module-fo',
        prefixPatterns: ['test_report_coverage', 'test_report_analyzer'],
      );

      // Check that old module-fo reports were deleted
      expect(
        await File(
                p.join(reportDir, 'coverage', 'module-fo_test_report_coverage@1234_010125.md'))
            .exists(),
        isFalse,
      );
      expect(
        await File(
                p.join(reportDir, 'analyzer', 'module-fo_test_report_analyzer@1234_010125.md'))
            .exists(),
        isFalse,
      );

      // Check that latest module-fo reports still exist
      expect(
        await File(
                p.join(reportDir, 'coverage', 'module-fo_test_report_coverage@5678_010125.md'))
            .exists(),
        isTrue,
      );
      expect(
        await File(
                p.join(reportDir, 'analyzer', 'module-fo_test_report_analyzer@5678_010125.md'))
            .exists(),
        isTrue,
      );

      // Check that other reports still exist
      expect(
        await File(
                p.join(reportDir, 'coverage', 'other-fo_test_report_coverage@1234_010125.md'))
            .exists(),
        isTrue,
      );
    });

    test('should handle non-existent report directory', () async {
      // NOTE: This test is skipped to prevent deleting real reports during test_analyzer runs
      // It can be run in isolation if needed for testing cleanup functionality
    }, skip: 'Disabled to prevent deleting reports during test_analyzer workflow');

    test('should handle verbose output', () async {
      final reportDir = await ReportUtils.getReportDirectory();

      // Create coverage subdirectory
      await Directory(p.join(reportDir, 'coverage')).create(recursive: true);

      await File(
              p.join(reportDir, 'coverage', 'test-fo_test_report_coverage@1234.md'))
          .create();

      // Should not throw with verbose=true
      await ReportUtils.cleanOldReports(
        pathName: 'test-fo',
        prefixPatterns: ['test_report_coverage'],
        subdirectory: 'coverage',
        verbose: true,
      );
    });

    test('should skip non-file entries', () async {
      final reportDir = await ReportUtils.getReportDirectory();

      // Create a subdirectory
      await Directory(p.join(reportDir, 'subdir')).create();

      // Should not throw when encountering directory
      await ReportUtils.cleanOldReports(
        pathName: 'module-fo',
        prefixPatterns: ['test_report'],
      );
    });

    test('should handle file deletion errors with verbose output', () async {
      final reportDir = await ReportUtils.getReportDirectory();

      // Create coverage subdirectory
      await Directory(p.join(reportDir, 'coverage')).create(recursive: true);

      // Create a test report file in coverage subdirectory
      final testFile = File(
          p.join(reportDir, 'coverage', 'test-fo_test_report_coverage@1234.md'));
      await testFile.create();

      // Create an immutable file to trigger deletion error
      final immutableFile = File(
          p.join(reportDir, 'coverage', 'test-fo_test_report_coverage@5678.md'));
      await immutableFile.create();

      // Try to make file immutable (Unix/Mac only with chflags)
      bool errorTestPossible = false;
      try {
        // On macOS, use chflags to make file immutable
        final chflagsResult =
            await Process.run('chflags', ['uchg', immutableFile.path]);
        errorTestPossible = chflagsResult.exitCode == 0;
      } catch (e) {
        // chflags not available or failed
      }

      // This should log an error for immutable file but not throw
      await ReportUtils.cleanOldReports(
        pathName: 'test-fo',
        prefixPatterns: ['test_report_coverage'],
        subdirectory: 'coverage',
        verbose: true,
      );

      // Clean up immutable flag if it was set
      if (errorTestPossible) {
        try {
          await Process.run('chflags', ['nouchg', immutableFile.path]);
        } catch (e) {
          // Cleanup failed, but test continues
        }
      }

      // Normal file should always be deleted
      expect(await testFile.exists(), isFalse);
    });
  });
}
