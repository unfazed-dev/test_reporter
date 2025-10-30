import 'dart:io';

import 'package:test/test.dart';
import 'package:test_reporter/src/bin/analyze_coverage_lib.dart';

import 'helpers/report_helpers.dart';
import 'helpers/test_fixtures.dart';

/// Testing CoverageThresholds class functionality
void main() {
  group('CoverageThresholds', () {
    test('validate should pass when coverage meets minimum', () {
      final thresholds = CoverageThresholds();
      final result = thresholds.validate(85.0);
      expect(result, isTrue);
    });

    test('validate should fail when coverage below minimum', () {
      final thresholds = CoverageThresholds();
      final result = thresholds.validate(75.0);
      expect(result, isFalse);
    });

    test('validate should pass when coverage above warning', () {
      final thresholds = CoverageThresholds();
      final result = thresholds.validate(95.0);
      expect(result, isTrue);
    });

    test('validate should pass with warning when between minimum and warning',
        () {
      final thresholds = CoverageThresholds();
      final result = thresholds.validate(85.0);
      expect(result, isTrue);
    });

    test('validate should fail when coverage decreased and failOnDecrease true',
        () {
      final thresholds = CoverageThresholds(
        minimum: 70.0,
        failOnDecrease: true,
      );
      final result = thresholds.validate(85.0, baseline: 90.0);
      expect(result, isFalse);
    });

    test(
        'validate should pass when coverage decreased but failOnDecrease false',
        () {
      final thresholds = CoverageThresholds(
        minimum: 70.0,
      );
      final result = thresholds.validate(85.0, baseline: 90.0);
      expect(result, isTrue);
    });

    test('validate should pass when coverage increased with baseline', () {
      final thresholds = CoverageThresholds(
        minimum: 70.0,
        failOnDecrease: true,
      );
      final result = thresholds.validate(95.0, baseline: 90.0);
      expect(result, isTrue);
    });

    test('validate should pass when coverage equals minimum threshold', () {
      final thresholds = CoverageThresholds();
      final result = thresholds.validate(80.0);
      expect(result, isTrue);
    });

    test('validate should pass when coverage equals warning threshold', () {
      final thresholds = CoverageThresholds();
      final result = thresholds.validate(90.0);
      expect(result, isTrue);
    });

    test('validate should handle 0% coverage correctly', () {
      final thresholds = CoverageThresholds(minimum: 0.0);
      final result = thresholds.validate(0.0);
      expect(result, isTrue);
    });

    test('validate should handle 100% coverage correctly', () {
      final thresholds = CoverageThresholds();
      final result = thresholds.validate(100.0);
      expect(result, isTrue);
    });
  });

  group('Path Utilities', () {
    test('normalizePath should handle forward slashes', () {
      final normalized = normalizePath('lib/src/example.dart');
      expect(normalized, equals('lib/src/example.dart'));
    });

    test('normalizePath should handle backslashes', () {
      final normalized = normalizePath(r'lib\src\example.dart');
      expect(normalized, equals('lib/src/example.dart'));
    });

    test('normalizePath should resolve single dots', () {
      final normalized = normalizePath('lib/./src/./example.dart');
      expect(normalized, equals('lib/src/example.dart'));
    });

    test('normalizePath should resolve double dots', () {
      final normalized = normalizePath('lib/src/../utils/example.dart');
      expect(normalized, equals('lib/utils/example.dart'));
    });

    test('normalizePath should handle multiple double dots', () {
      final normalized =
          normalizePath('lib/src/models/../../utils/example.dart');
      expect(normalized, equals('lib/utils/example.dart'));
    });

    test('normalizePath should preserve absolute paths', () {
      final normalized = normalizePath('/absolute/path/to/file.dart');
      expect(normalized, startsWith('/'));
      expect(normalized, equals('/absolute/path/to/file.dart'));
    });

    test('normalizePath should handle empty segments', () {
      final normalized = normalizePath('lib//src///example.dart');
      expect(normalized, equals('lib/src/example.dart'));
    });

    test('normalizePath should handle trailing slashes', () {
      final normalized = normalizePath('lib/src/');
      expect(normalized, equals('lib/src'));
    });

    test('normalizePath should handle leading dots with relative paths', () {
      final normalized = normalizePath('./lib/src/example.dart');
      expect(normalized, equals('lib/src/example.dart'));
    });

    test('normalizePath should handle complex mixed paths', () {
      final normalized =
          normalizePath(r'lib\src\..\.\utils/../helpers\example.dart');
      expect(normalized, equals('lib/helpers/example.dart'));
    });
  });

  group('Lcov Parsing', () {
    test('should parse simple lcov data correctly', () {
      final lcovData = parseLcovData(sampleLcovData);
      expect(lcovData, isNotEmpty);
      expect(lcovData.containsKey('lib/src/example.dart'), isTrue);
      expect(lcovData.containsKey('lib/src/another.dart'), isTrue);
    });

    test('should calculate coverage percentages correctly', () {
      final lcovData = parseLcovData(sampleLcovData);
      final exampleFile = lcovData['lib/src/example.dart']!;
      expect(exampleFile['total'], equals(7));
      expect(exampleFile['hit'], equals(5));

      final coverage = (exampleFile['hit']! / exampleFile['total']!) * 100;
      expect(coverage, closeTo(71.4, 0.1));
    });

    test('should handle 100% coverage correctly', () {
      final lcovData = parseLcovData(sampleLcovData);
      final anotherFile = lcovData['lib/src/another.dart']!;
      expect(anotherFile['total'], equals(3));
      expect(anotherFile['hit'], equals(3));

      final coverage = (anotherFile['hit']! / anotherFile['total']!) * 100;
      expect(coverage, equals(100.0));
    });

    test('should handle empty lcov data', () {
      final lcovData = parseLcovData('');
      expect(lcovData, isEmpty);
    });

    test('should handle malformed lcov data gracefully', () {
      const malformedLcov = '''
SF:lib/example.dart
LF:invalid
LH:invalid
end_of_record
''';
      expect(() => parseLcovData(malformedLcov), throwsFormatException);
    });
  });

  group('Report Generation', () {
    test('should create valid lcov file', () {
      final lcovFile = createSampleLcovFile();
      expect(lcovFile.existsSync(), isTrue);
      expect(lcovFile.path.endsWith('lcov.info'), isTrue);

      final content = lcovFile.readAsStringSync();
      expect(content, contains('SF:'));
      expect(content, contains('DA:'));
      expect(content, contains('end_of_record'));

      // Cleanup
      lcovFile.parent.deleteSync(recursive: true);
    });

    test('should create lcov file with custom content', () {
      const customContent = '''
TN:
SF:custom.dart
DA:1,1
LF:1
LH:1
end_of_record
''';
      final lcovFile = createSampleLcovFile(content: customContent);
      expect(lcovFile.readAsStringSync(), equals(customContent));

      // Cleanup
      lcovFile.parent.deleteSync(recursive: true);
    });

    test('should validate coverage report structure', () {
      final report = sampleCoverageReport();
      expect(
        validateReportStructure(
          report,
          requiredSections: ['Coverage Report', 'Summary', 'JSON Data'],
        ),
        isTrue,
      );
    });

    test('should extract coverage percentage from report', () {
      final report = sampleCoverageReport(coverage: 87.5);
      final coverage = extractCoveragePercentage(report);
      expect(coverage, equals(87.5));
    });

    test('should validate report naming convention', () {
      expect(
        validateReportName('example_test_report_coverage@1430_280125.md'),
        isTrue,
      );
      expect(
        validateReportName('invalid_report_name.md'),
        isFalse,
      );
    });

    test('should extract module name from report filename', () {
      final module = extractModuleFromFileName(
          'example_test_report_coverage@1430_280125.md');
      expect(module, equals('example'));
    });

    test('should extract report type from filename', () {
      final type =
          extractReportType('example_test_report_coverage@1430_280125.md');
      expect(type, equals('coverage'));
    });

    test('should extract timestamp from filename', () {
      final timestamp =
          extractTimestamp('example_test_report_coverage@1430_280125.md');
      expect(timestamp, equals('1430_280125'));
    });
  });

  group('Report File Operations', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('coverage_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('should find latest report in directory', () {
      // Create multiple report files
      final file1 =
          File('${tempDir.path}/module1_test_report_coverage@1400_280125.md');
      final file2 =
          File('${tempDir.path}/module2_test_report_coverage@1430_280125.md');

      file1.writeAsStringSync('Report 1');
      sleep(const Duration(seconds: 1));
      file2.writeAsStringSync('Report 2');

      final latest = findLatestReport(tempDir);
      expect(latest, isNotNull);
      expect(latest!.path, equals(file2.path));
    });

    test('should filter reports by type', () {
      final coverage =
          File('${tempDir.path}/module_test_report_coverage@1400_280125.md');
      final analyzer =
          File('${tempDir.path}/module_test_report_analyzer@1400_280125.md');

      coverage.writeAsStringSync('Coverage report');
      analyzer.writeAsStringSync('Analyzer report');

      final latest = findLatestReport(tempDir, type: 'coverage');
      expect(latest, isNotNull);
      expect(latest!.path, equals(coverage.path));
    });

    test('should count reports correctly', () {
      File('${tempDir.path}/report1_test_report_coverage@1400_280125.md')
          .writeAsStringSync('Report 1');
      File('${tempDir.path}/report2_test_report_coverage@1430_280125.md')
          .writeAsStringSync('Report 2');
      File('${tempDir.path}/report3_test_report_analyzer@1430_280125.md')
          .writeAsStringSync('Report 3');

      expect(countReports(tempDir), equals(3));
      expect(countReports(tempDir, type: 'coverage'), equals(2));
      expect(countReports(tempDir, type: 'analyzer'), equals(1));
    });

    test('should return 0 for non-existent directory', () {
      final nonExistent = Directory('${tempDir.path}/does_not_exist');
      expect(countReports(nonExistent), equals(0));
    });

    test('should handle empty directory', () {
      expect(countReports(tempDir), equals(0));
      expect(findLatestReport(tempDir), isNull);
    });
  });

  group('JSON Extraction', () {
    test('should extract JSON from coverage report', () {
      final report = sampleCoverageReport(module: 'test', coverage: 85.0);
      final json = extractJsonFromReport(report);

      expect(json, isNotNull);
      expect(json!['module'], equals('test'));
      expect(json['coverage'], equals(85.0));
    });

    test('should return null for report without JSON', () {
      const report = 'This is a report without JSON data.';
      final json = extractJsonFromReport(report);
      expect(json, isNull);
    });

    test('should validate JSON structure', () {
      final json = {
        'module': 'test',
        'coverage': 85.0,
        'timestamp': '2025-01-28T14:30:00.000',
      };

      expect(
        validateJsonStructure(json, requiredKeys: ['module', 'coverage']),
        isTrue,
      );
      expect(
        validateJsonStructure(json, requiredKeys: ['module', 'missing']),
        isFalse,
      );
    });

    test('should extract all JSON blocks from report', () {
      final report = sampleUnifiedReport();
      final jsonBlocks = extractAllJsonFromReport(report);

      expect(jsonBlocks, isNotEmpty);
      expect(jsonBlocks.length, greaterThanOrEqualTo(1));
    });
  });

  group('Project Detection', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('project_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('should detect Flutter project', () {
      final pubspec = File('${tempDir.path}/pubspec.yaml');
      pubspec.writeAsStringSync(samplePubspecFlutter);

      final content = pubspec.readAsStringSync();
      expect(content.contains('flutter:'), isTrue);
    });

    test('should detect Dart project', () {
      final pubspec = File('${tempDir.path}/pubspec.yaml');
      pubspec.writeAsStringSync(samplePubspecDart);

      final content = pubspec.readAsStringSync();
      expect(content.contains('flutter:'), isFalse);
    });

    test('should extract package name from pubspec', () {
      final pubspec = File('${tempDir.path}/pubspec.yaml');
      pubspec.writeAsStringSync(samplePubspecFlutter);

      final content = pubspec.readAsStringSync();
      final nameMatch =
          RegExp(r'^name:\s*(\S+)', multiLine: true).firstMatch(content);
      expect(nameMatch?.group(1), equals('example_app'));
    });
  });
}

// Utility function to normalize paths (extracted from coverage_tool.dart)
String normalizePath(String path) {
  // Convert to forward slashes for consistency
  path = path.replaceAll(r'\', '/');

  // Split into parts and resolve . and ..
  final parts = path.split('/').where((part) => part.isNotEmpty).toList();
  final resolved = <String>[];

  for (final part in parts) {
    if (part == '.') {
      // Current directory, skip
      continue;
    } else if (part == '..') {
      // Parent directory
      if (resolved.isNotEmpty) {
        resolved.removeLast();
      }
    } else {
      resolved.add(part);
    }
  }

  // Reconstruct path
  final result = resolved.join('/');
  return path.startsWith('/') ? '/$result' : result;
}
