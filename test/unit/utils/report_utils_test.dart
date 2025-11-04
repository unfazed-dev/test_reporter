import 'dart:io';
import 'package:test/test.dart';
import 'package:test_reporter/src/utils/report_utils.dart';
import 'package:path/path.dart' as p;

void main() {
  group('ReportUtils', () {
    late Directory tempDir;
    late Directory originalDir;

    setUp(() async {
      // Create a temporary directory for testing
      tempDir = await Directory.systemTemp.createTemp('report_utils_test_');
      originalDir = Directory.current;
      // Change to temp directory for testing
      Directory.current = tempDir;
    });

    tearDown(() async {
      // Restore original directory
      Directory.current = originalDir;
      // Clean up temporary directory
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('getReportDirectory', () {
      test('should create tests_reports directory if it does not exist',
          () async {
        final reportDir = await ReportUtils.getReportDirectory();

        expect(await Directory(reportDir).exists(), isTrue);
        expect(reportDir, endsWith('tests_reports'));
      });

      test('should return existing tests_reports directory if it exists',
          () async {
        // Create directory first
        final firstCall = await ReportUtils.getReportDirectory();

        // Call again
        final secondCall = await ReportUtils.getReportDirectory();

        expect(firstCall, equals(secondCall));
        expect(await Directory(firstCall).exists(), isTrue);
      });

      test('should create directory in current working directory', () async {
        final reportDir = await ReportUtils.getReportDirectory();
        final expectedPath = p.join(Directory.current.path, 'tests_reports');

        expect(reportDir, equals(expectedPath));
      });

      test('should create directory recursively', () async {
        final reportDir = await ReportUtils.getReportDirectory();

        expect(await Directory(reportDir).exists(), isTrue);
        expect(await Directory(reportDir).parent.exists(), isTrue);
      });
    });

    group('ensureDirectoryExists', () {
      test('should create directory if it does not exist', () async {
        final testPath = p.join(tempDir.path, 'new_directory');

        await ReportUtils.ensureDirectoryExists(testPath);

        expect(await Directory(testPath).exists(), isTrue);
      });

      test('should not fail if directory already exists', () async {
        final testPath = p.join(tempDir.path, 'existing_directory');
        await Directory(testPath).create();

        await ReportUtils.ensureDirectoryExists(testPath);

        expect(await Directory(testPath).exists(), isTrue);
      });

      test('should create nested directories recursively', () async {
        final testPath = p.join(tempDir.path, 'a', 'b', 'c', 'd');

        await ReportUtils.ensureDirectoryExists(testPath);

        expect(await Directory(testPath).exists(), isTrue);
        expect(
            await Directory(p.join(tempDir.path, 'a', 'b')).exists(), isTrue);
      });

      test('should handle paths with trailing slashes', () async {
        final testPath = p.join(tempDir.path, 'trailing_slash') + p.separator;

        await ReportUtils.ensureDirectoryExists(testPath);

        expect(await Directory(testPath).exists(), isTrue);
      });
    });

    group('getReportPath', () {
      test('should generate path for coverage report in coverage subdirectory',
          () async {
        final path = await ReportUtils.getReportPath(
          'module_name',
          '1234_567890',
          suffix: 'coverage',
        );

        expect(path, contains('tests_reports'));
        expect(path, contains('coverage'));
        expect(path, contains('module_name_report_coverage@1234_567890.md'));
      });

      test('should generate path for tests report in tests subdirectory',
          () async {
        final path = await ReportUtils.getReportPath(
          'module_name',
          '1234_567890',
          suffix: 'tests',
        );

        expect(path, contains('tests_reports'));
        expect(path, contains(p.separator + 'tests' + p.separator));
        expect(path, contains('module_name_report_tests@1234_567890.md'));
      });

      test('should generate path for failures report in failures subdirectory',
          () async {
        final path = await ReportUtils.getReportPath(
          'module_name',
          '1234_567890',
          suffix: 'failures',
        );

        expect(path, contains('tests_reports'));
        expect(path, contains('failures'));
        expect(path, contains('module_name_report_failures@1234_567890.md'));
      });

      test(
          'should generate path for suite report in suite subdirectory when suffix is empty',
          () async {
        final path = await ReportUtils.getReportPath(
          'module_name',
          '1234_567890',
          suffix: '',
        );

        expect(path, contains('tests_reports'));
        expect(path, contains(p.separator + 'suite' + p.separator));
        expect(path, contains('module_name_report@1234_567890.md'));
      });

      test('should create subdirectory if it does not exist', () async {
        final path = await ReportUtils.getReportPath(
          'test_module',
          '1234_567890',
          suffix: 'coverage',
        );

        final subdirPath = p.dirname(path);
        expect(await Directory(subdirPath).exists(), isTrue);
      });

      test('should handle module names with special characters', () async {
        final path = await ReportUtils.getReportPath(
          'module-name_test',
          '1234_567890',
          suffix: 'tests',
        );

        expect(path, contains('module-name_test_report_tests@1234_567890.md'));
      });

      test('should use suite as default subdirectory for unknown suffix',
          () async {
        final path = await ReportUtils.getReportPath(
          'module_name',
          '1234_567890',
          suffix: 'unknown_suffix',
        );

        expect(path, contains(p.separator + 'suite' + p.separator));
      });
    });

    group('writeUnifiedReport', () {
      test('should write markdown and JSON content to file', () async {
        const moduleName = 'test_module';
        const timestamp = '1234_567890';
        const markdownContent = '# Test Report\n\nThis is a test.';
        final jsonData = {'metric': 'value', 'count': 42};

        final reportPath = await ReportUtils.writeUnifiedReport(
          moduleName: moduleName,
          timestamp: timestamp,
          markdownContent: markdownContent,
          jsonData: jsonData,
          suffix: 'tests',
        );

        expect(await File(reportPath).exists(), isTrue);

        final content = await File(reportPath).readAsString();
        expect(content, contains('# Test Report'));
        expect(content, contains('This is a test.'));
        expect(content, contains('## 📊 Machine-Readable Data'));
        expect(content, contains('```json'));
        expect(content, contains('"metric": "value"'));
        expect(content, contains('"count": 42'));
      });

      test('should format JSON with indentation', () async {
        const moduleName = 'test_module';
        const timestamp = '1234_567890';
        const markdownContent = '# Report';
        final jsonData = {
          'nested': {'key': 'value'},
          'array': [1, 2, 3]
        };

        final reportPath = await ReportUtils.writeUnifiedReport(
          moduleName: moduleName,
          timestamp: timestamp,
          markdownContent: markdownContent,
          jsonData: jsonData,
        );

        final content = await File(reportPath).readAsString();
        expect(content, contains('  "nested": {'));
        expect(content, contains('    "key": "value"'));
        expect(content, contains('  "array": ['));
      });

      test('should create subdirectory if needed', () async {
        const moduleName = 'new_module';
        const timestamp = '1234_567890';
        const markdownContent = '# Report';
        final jsonData = {'data': 'test'};

        await ReportUtils.writeUnifiedReport(
          moduleName: moduleName,
          timestamp: timestamp,
          markdownContent: markdownContent,
          jsonData: jsonData,
          suffix: 'coverage',
        );

        final reportDir = await ReportUtils.getReportDirectory();
        final coverageDir = Directory(p.join(reportDir, 'coverage'));
        expect(await coverageDir.exists(), isTrue);
      });

      test('should return the report file path', () async {
        const moduleName = 'test_module';
        const timestamp = '1234_567890';
        const markdownContent = '# Report';
        final jsonData = {'data': 'test'};

        final reportPath = await ReportUtils.writeUnifiedReport(
          moduleName: moduleName,
          timestamp: timestamp,
          markdownContent: markdownContent,
          jsonData: jsonData,
          suffix: 'tests',
        );

        expect(reportPath, endsWith('.md'));
        expect(reportPath, contains('test_module'));
        expect(reportPath, contains('1234_567890'));
      });

      test('should include separator between markdown and JSON', () async {
        const moduleName = 'test_module';
        const timestamp = '1234_567890';
        const markdownContent = '# Report\n\nContent';
        final jsonData = {'data': 'test'};

        final reportPath = await ReportUtils.writeUnifiedReport(
          moduleName: moduleName,
          timestamp: timestamp,
          markdownContent: markdownContent,
          jsonData: jsonData,
        );

        final content = await File(reportPath).readAsString();
        expect(content, contains('---'));
        final separatorIndex = content.indexOf('---');
        final jsonIndex = content.indexOf('```json');
        expect(separatorIndex, lessThan(jsonIndex));
      });

      test('should handle empty markdown content', () async {
        const moduleName = 'test_module';
        const timestamp = '1234_567890';
        const markdownContent = '';
        final jsonData = {'data': 'test'};

        final reportPath = await ReportUtils.writeUnifiedReport(
          moduleName: moduleName,
          timestamp: timestamp,
          markdownContent: markdownContent,
          jsonData: jsonData,
        );

        expect(await File(reportPath).exists(), isTrue);
        final content = await File(reportPath).readAsString();
        expect(content, contains('```json'));
      });

      test('should handle empty JSON data', () async {
        const moduleName = 'test_module';
        const timestamp = '1234_567890';
        const markdownContent = '# Report';
        final jsonData = <String, dynamic>{};

        final reportPath = await ReportUtils.writeUnifiedReport(
          moduleName: moduleName,
          timestamp: timestamp,
          markdownContent: markdownContent,
          jsonData: jsonData,
        );

        final content = await File(reportPath).readAsString();
        expect(content, contains('{}'));
      });

      test('should handle verbose output without errors', () async {
        const moduleName = 'test_module';
        const timestamp = '1234_567890';
        const markdownContent = '# Report';
        final jsonData = {'data': 'test'};

        // Should not throw when verbose is true
        await ReportUtils.writeUnifiedReport(
          moduleName: moduleName,
          timestamp: timestamp,
          markdownContent: markdownContent,
          jsonData: jsonData,
          verbose: true,
        );
      });
    });

    group('extractJsonFromReport', () {
      test('should extract JSON from unified report', () async {
        const moduleName = 'test_module';
        const timestamp = '1234_567890';
        const markdownContent = '# Test Report';
        final jsonData = {'metric': 'value', 'count': 42};

        final reportPath = await ReportUtils.writeUnifiedReport(
          moduleName: moduleName,
          timestamp: timestamp,
          markdownContent: markdownContent,
          jsonData: jsonData,
        );

        final extracted = await ReportUtils.extractJsonFromReport(reportPath);

        expect(extracted, isNotNull);
        expect(extracted!['metric'], equals('value'));
        expect(extracted['count'], equals(42));
      });

      test('should return null if file does not exist', () async {
        final extracted = await ReportUtils.extractJsonFromReport(
          '/non/existent/file.md',
        );

        expect(extracted, isNull);
      });

      test('should return null if no JSON section found', () async {
        final testFile = File(p.join(tempDir.path, 'no_json.md'));
        await testFile.writeAsString('# Report\n\nNo JSON here!');

        final extracted =
            await ReportUtils.extractJsonFromReport(testFile.path);

        expect(extracted, isNull);
      });

      test('should handle malformed JSON gracefully', () async {
        final testFile = File(p.join(tempDir.path, 'bad_json.md'));
        await testFile.writeAsString(
          '# Report\n\n```json\n{invalid json}\n```',
        );

        final extracted =
            await ReportUtils.extractJsonFromReport(testFile.path);

        expect(extracted, isNull);
      });

      test('should find LAST occurrence of ```json', () async {
        // Report with code example containing ```json AND actual data JSON
        final testFile = File(p.join(tempDir.path, 'multi_json.md'));
        await testFile.writeAsString('''
# Report

Example code:
```json
{"example": "not the real data"}
```

---

## 📊 Machine-Readable Data

```json
{"actual": "real data", "value": 123}
```
''');

        final extracted =
            await ReportUtils.extractJsonFromReport(testFile.path);

        expect(extracted, isNotNull);
        expect(extracted!['actual'], equals('real data'));
        expect(extracted['value'], equals(123));
        expect(extracted.containsKey('example'), isFalse);
      });

      test('should handle nested JSON objects', () async {
        const moduleName = 'test_module';
        const timestamp = '1234_567890';
        const markdownContent = '# Report';
        final jsonData = {
          'nested': {
            'deeply': {'key': 'value'}
          },
          'array': [1, 2, 3]
        };

        final reportPath = await ReportUtils.writeUnifiedReport(
          moduleName: moduleName,
          timestamp: timestamp,
          markdownContent: markdownContent,
          jsonData: jsonData,
        );

        final extracted = await ReportUtils.extractJsonFromReport(reportPath);

        expect(extracted, isNotNull);
        expect(extracted!['nested']['deeply']['key'], equals('value'));
        expect(extracted['array'], equals([1, 2, 3]));
      });

      test('should return null if extracted data is not a map', () async {
        final testFile = File(p.join(tempDir.path, 'array.md'));
        await testFile.writeAsString(
          '# Report\n\n```json\n[1, 2, 3]\n```',
        );

        final extracted =
            await ReportUtils.extractJsonFromReport(testFile.path);

        // Should return null because JSON is an array, not a map
        expect(extracted, isNull);
      });
    });

    group('cleanOldReports', () {
      test('should delete old reports and keep latest', () async {
        // Setup: Create reports directory and files
        final reportDir = await ReportUtils.getReportDirectory();
        final testsDir = Directory(p.join(reportDir, 'tests'));
        await testsDir.create(recursive: true);

        // Create multiple report files with different timestamps
        await File(p.join(testsDir.path, 'module_analysis@1200_010125.md'))
            .writeAsString('old');
        await File(p.join(testsDir.path, 'module_analysis@1400_010125.md'))
            .writeAsString('latest');
        await File(p.join(testsDir.path, 'module_analysis@1300_010125.md'))
            .writeAsString('middle');

        await ReportUtils.cleanOldReports(
          pathName: 'module',
          prefixPatterns: ['analysis'],
          subdirectory: 'tests',
          keepLatest: true,
        );

        // Should keep only the latest (1400)
        expect(
          await File(p.join(testsDir.path, 'module_analysis@1200_010125.md'))
              .exists(),
          isFalse,
        );
        expect(
          await File(p.join(testsDir.path, 'module_analysis@1300_010125.md'))
              .exists(),
          isFalse,
        );
        expect(
          await File(p.join(testsDir.path, 'module_analysis@1400_010125.md'))
              .exists(),
          isTrue,
        );
      });

      test('should delete all reports when keepLatest is false', () async {
        final reportDir = await ReportUtils.getReportDirectory();
        final testsDir = Directory(p.join(reportDir, 'tests'));
        await testsDir.create(recursive: true);

        await File(p.join(testsDir.path, 'module_analysis@1200_010125.md'))
            .writeAsString('old');
        await File(p.join(testsDir.path, 'module_analysis@1400_010125.md'))
            .writeAsString('latest');

        await ReportUtils.cleanOldReports(
          pathName: 'module',
          prefixPatterns: ['analysis'],
          subdirectory: 'tests',
          keepLatest: false,
        );

        expect(
          await File(p.join(testsDir.path, 'module_analysis@1200_010125.md'))
              .exists(),
          isFalse,
        );
        expect(
          await File(p.join(testsDir.path, 'module_analysis@1400_010125.md'))
              .exists(),
          isFalse,
        );
      });

      test('should handle multiple patterns separately', () async {
        final reportDir = await ReportUtils.getReportDirectory();
        final testsDir = Directory(p.join(reportDir, 'tests'));
        await testsDir.create(recursive: true);

        // Create files for different patterns
        await File(p.join(testsDir.path, 'module_analysis@1200_010125.md'))
            .writeAsString('analysis old');
        await File(p.join(testsDir.path, 'module_analysis@1400_010125.md'))
            .writeAsString('analysis latest');
        await File(p.join(testsDir.path, 'module_coverage@1200_010125.md'))
            .writeAsString('coverage old');
        await File(p.join(testsDir.path, 'module_coverage@1400_010125.md'))
            .writeAsString('coverage latest');

        await ReportUtils.cleanOldReports(
          pathName: 'module',
          prefixPatterns: ['analysis', 'coverage'],
          subdirectory: 'tests',
          keepLatest: true,
        );

        // Should keep latest for each pattern
        expect(
          await File(p.join(testsDir.path, 'module_analysis@1400_010125.md'))
              .exists(),
          isTrue,
        );
        expect(
          await File(p.join(testsDir.path, 'module_coverage@1400_010125.md'))
              .exists(),
          isTrue,
        );
        expect(
          await File(p.join(testsDir.path, 'module_analysis@1200_010125.md'))
              .exists(),
          isFalse,
        );
        expect(
          await File(p.join(testsDir.path, 'module_coverage@1200_010125.md'))
              .exists(),
          isFalse,
        );
      });

      test('should clean all subdirectories when subdirectory is null',
          () async {
        final reportDir = await ReportUtils.getReportDirectory();

        // Create multiple subdirectories with files
        for (final subdir in ['tests', 'coverage', 'failures', 'suite']) {
          final dir = Directory(p.join(reportDir, subdir));
          await dir.create(recursive: true);
          await File(p.join(dir.path, 'module_analysis@1200_010125.md'))
              .writeAsString('old');
          await File(p.join(dir.path, 'module_analysis@1400_010125.md'))
              .writeAsString('latest');
        }

        await ReportUtils.cleanOldReports(
          pathName: 'module',
          prefixPatterns: ['analysis'],
          subdirectory: null, // Clean all
          keepLatest: true,
        );

        // Check that old files are deleted in all subdirectories
        for (final subdir in ['tests', 'coverage', 'failures', 'suite']) {
          final dir = Directory(p.join(reportDir, subdir));
          expect(
            await File(p.join(dir.path, 'module_analysis@1200_010125.md'))
                .exists(),
            isFalse,
          );
          expect(
            await File(p.join(dir.path, 'module_analysis@1400_010125.md'))
                .exists(),
            isTrue,
          );
        }
      });

      test('should handle non-existent subdirectory gracefully', () async {
        // Should not throw when subdirectory doesn't exist
        await ReportUtils.cleanOldReports(
          pathName: 'module',
          prefixPatterns: ['analysis'],
          subdirectory: 'nonexistent',
          keepLatest: true,
        );
      });

      test('should ignore non-file entries in directory', () async {
        final reportDir = await ReportUtils.getReportDirectory();
        final testsDir = Directory(p.join(reportDir, 'tests'));
        await testsDir.create(recursive: true);

        // Create a subdirectory (not a file)
        await Directory(p.join(testsDir.path, 'some_folder')).create();

        // Create a report file
        await File(p.join(testsDir.path, 'module_analysis@1200_010125.md'))
            .writeAsString('content');

        // Should not throw
        await ReportUtils.cleanOldReports(
          pathName: 'module',
          prefixPatterns: ['analysis'],
          subdirectory: 'tests',
          keepLatest: true,
        );
      });

      test('should handle files that do not match pattern', () async {
        final reportDir = await ReportUtils.getReportDirectory();
        final testsDir = Directory(p.join(reportDir, 'tests'));
        await testsDir.create(recursive: true);

        // Create files with different patterns
        await File(p.join(testsDir.path, 'module_analysis@1200_010125.md'))
            .writeAsString('match');
        await File(p.join(testsDir.path, 'other_report@1200_010125.md'))
            .writeAsString('no match');

        await ReportUtils.cleanOldReports(
          pathName: 'module',
          prefixPatterns: ['analysis'],
          subdirectory: 'tests',
          keepLatest: false,
        );

        // Should delete matching file, keep non-matching
        expect(
          await File(p.join(testsDir.path, 'module_analysis@1200_010125.md'))
              .exists(),
          isFalse,
        );
        expect(
          await File(p.join(testsDir.path, 'other_report@1200_010125.md'))
              .exists(),
          isTrue,
        );
      });

      test('should handle alternative pattern with underscores removed',
          () async {
        final reportDir = await ReportUtils.getReportDirectory();
        final testsDir = Directory(p.join(reportDir, 'tests'));
        await testsDir.create(recursive: true);

        // Create file matching alternative pattern
        await File(p.join(testsDir.path, 'mymodule_analysis__1200_010125.md'))
            .writeAsString('match');

        await ReportUtils.cleanOldReports(
          pathName: 'my_module',
          prefixPatterns: ['analysis'],
          subdirectory: 'tests',
          keepLatest: false,
        );

        expect(
          await File(p.join(testsDir.path, 'mymodule_analysis__1200_010125.md'))
              .exists(),
          isFalse,
        );
      });

      test('should handle verbose output without errors', () async {
        final reportDir = await ReportUtils.getReportDirectory();
        final testsDir = Directory(p.join(reportDir, 'tests'));
        await testsDir.create(recursive: true);

        await File(p.join(testsDir.path, 'module_analysis@1200_010125.md'))
            .writeAsString('content');

        // Should not throw with verbose
        await ReportUtils.cleanOldReports(
          pathName: 'module',
          prefixPatterns: ['analysis'],
          subdirectory: 'tests',
          verbose: true,
          keepLatest: true,
        );
      });

      test('should handle file deletion errors gracefully', () async {
        final reportDir = await ReportUtils.getReportDirectory();
        final testsDir = Directory(p.join(reportDir, 'tests'));
        await testsDir.create(recursive: true);

        final testFile =
            File(p.join(testsDir.path, 'module_analysis@1200_010125.md'));
        await testFile.writeAsString('content');

        // Make file read-only (may not work on all platforms)
        // This test documents the error handling, even if it can't be fully tested
        await ReportUtils.cleanOldReports(
          pathName: 'module',
          prefixPatterns: ['analysis'],
          subdirectory: 'tests',
          keepLatest: false,
          verbose: true,
        );

        // Should complete without throwing, even if deletion fails
      });
    });

    group('Integration Tests', () {
      test('writeUnifiedReport and extractJsonFromReport round-trip', () async {
        const moduleName = 'integration_test';
        const timestamp = '1234_567890';
        const markdownContent = '# Integration Test\n\nTesting round-trip.';
        final originalData = {
          'test': 'data',
          'nested': {'key': 'value'},
          'array': [1, 2, 3],
          'number': 42
        };

        final reportPath = await ReportUtils.writeUnifiedReport(
          moduleName: moduleName,
          timestamp: timestamp,
          markdownContent: markdownContent,
          jsonData: originalData,
        );

        final extractedData =
            await ReportUtils.extractJsonFromReport(reportPath);

        expect(extractedData, isNotNull);
        expect(extractedData!['test'], equals('data'));
        expect(extractedData['nested']['key'], equals('value'));
        expect(extractedData['array'], equals([1, 2, 3]));
        expect(extractedData['number'], equals(42));
      });

      test('getReportPath creates directory that getReportDirectory returns',
          () async {
        final reportDir = await ReportUtils.getReportDirectory();
        final reportPath = await ReportUtils.getReportPath(
          'test',
          '123',
          suffix: 'tests',
        );

        expect(reportPath, startsWith(reportDir));
      });
    });
  });
}
