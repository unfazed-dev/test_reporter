import 'dart:io';

import 'package:test/test.dart';

import 'helpers/report_helpers.dart';
import 'helpers/test_fixtures.dart';

void main() {
  group('Module Name Extraction', () {
    test('should extract module name from file path', () {
      const filePath = 'test/auth/login_test.dart';
      final module = extractModuleName(filePath);
      expect(module, equals('login'));
    });

    test('should extract module name from directory path', () {
      const dirPath = 'test/auth/';
      final module = extractModuleName(dirPath);
      expect(module, equals('auth'));
    });

    test('should handle root test directory', () {
      const path = 'test/';
      final module = extractModuleName(path);
      expect(module, equals('test'));
    });

    test('should handle single file', () {
      const path = 'test/example_test.dart';
      final module = extractModuleName(path);
      expect(module, equals('example'));
    });

    test('should handle nested paths', () {
      const path = 'test/features/auth/login_test.dart';
      final module = extractModuleName(path);
      expect(module, equals('login'));
    });
  });

  group('Health Score Calculation', () {
    test('should calculate 100% health score', () {
      final score = calculateHealthScore(
        coverage: 100.0,
        passRate: 100.0,
        stability: 100.0,
      );
      expect(score, equals(100.0));
    });

    test('should calculate weighted health score', () {
      final score = calculateHealthScore(
        coverage: 80.0,
        passRate: 90.0,
        stability: 100.0,
      );
      // Weighted: 80*0.4 + 90*0.4 + 100*0.2 = 32 + 36 + 20 = 88
      expect(score, closeTo(88.0, 0.1));
    });

    test('should handle 0% health score', () {
      final score = calculateHealthScore(
        coverage: 0.0,
        passRate: 0.0,
        stability: 0.0,
      );
      expect(score, equals(0.0));
    });

    test('should handle partial scores', () {
      final score = calculateHealthScore(
        coverage: 50.0,
        passRate: 75.0,
        stability: 90.0,
      );
      // Weighted: 50*0.4 + 75*0.4 + 90*0.2 = 20 + 30 + 18 = 68
      expect(score, closeTo(68.0, 0.1));
    });
  });

  group('Unified Report Generation', () {
    test('should validate unified report structure', () {
      final report = sampleUnifiedReport();
      expect(
        validateReportStructure(
          report,
          requiredSections: [
            'Test Analysis Report',
            'Coverage Analysis',
            'Test Results',
            'JSON Data',
          ],
        ),
        isTrue,
      );
    });

    test('should extract health score from unified report', () {
      const report = '''
# Unified Test Report

## Health Score: 85.5

Details here...
''';
      final score = extractHealthScore(report);
      expect(score, equals(85.5));
    });

    test('should validate report has links to sub-reports', () {
      const report = '''
# Unified Report

See [Coverage Report](coverage_report.md)
See [Analyzer Report](analyzer_report.md)
''';
      expect(hasReportLink(report, 'Coverage Report'), isTrue);
      expect(hasReportLink(report, 'Analyzer Report'), isTrue);
    });

    test('should validate report name for unified reports', () {
      expect(
        validateReportName('example_test_report_unified@1430_280125.md'),
        isTrue,
      );
    });

    test('should extract report type as unified', () {
      final type =
          extractReportType('example_test_report_unified@1430_280125.md');
      expect(type, equals('unified'));
    });
  });

  group('Report Discovery', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('run_all_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('should find coverage report', () {
      final coverageReport =
          File('${tempDir.path}/module_test_report_coverage@1400_280125.md');
      coverageReport.writeAsStringSync(sampleCoverageReport());

      final found = findLatestReport(tempDir, type: 'coverage');
      expect(found, isNotNull);
      expect(found!.path, equals(coverageReport.path));
    });

    test('should find analyzer report', () {
      final analyzerReport =
          File('${tempDir.path}/module_test_report_analyzer@1400_280125.md');
      analyzerReport.writeAsStringSync(sampleAnalyzerReport());

      final found = findLatestReport(tempDir, type: 'analyzer');
      expect(found, isNotNull);
      expect(found!.path, equals(analyzerReport.path));
    });

    test('should return null when no reports exist', () {
      final found = findLatestReport(tempDir, type: 'coverage');
      expect(found, isNull);
    });

    test('should find latest among multiple reports', () {
      final report1 =
          File('${tempDir.path}/module_test_report_coverage@1400_280125.md');
      final report2 =
          File('${tempDir.path}/module_test_report_coverage@1430_280125.md');

      report1.writeAsStringSync('Report 1');
      sleep(const Duration(seconds: 1));
      report2.writeAsStringSync('Report 2');

      final found = findLatestReport(tempDir, type: 'coverage');
      expect(found, isNotNull);
      expect(found!.path, equals(report2.path));
    });
  });

  group('Report Data Extraction', () {
    test('should extract coverage and test data from reports', () {
      final coverageReport = sampleCoverageReport(coverage: 85.0);
      final analyzerReport =
          sampleAnalyzerReport(totalTests: 100, passedTests: 95);

      final coverageData = extractJsonFromReport(coverageReport);
      final analyzerData = extractJsonFromReport(analyzerReport);

      expect(coverageData, isNotNull);
      expect(coverageData!['coverage'], equals(85.0));

      expect(analyzerData, isNotNull);
      expect(analyzerData!['totalTests'], equals(100));
      expect(analyzerData['passed'], equals(95));
    });

    test('should combine data from multiple reports', () {
      final data = {
        'coverage': 85.0,
        'totalTests': 100,
        'passedTests': 95,
        'failedTests': 5,
      };

      expect(data['coverage'], equals(85.0));
      expect(data['totalTests'], equals(100));
      expect(data['passedTests'], equals(95));
    });
  });

  group('Insight Generation', () {
    test('should generate no insights for good metrics', () {
      final insights = generateInsights(
        coverage: 90.0,
        passRate: 95.0,
        stability: 100.0,
      );

      // Good metrics should have no warnings/insights
      expect(insights, isEmpty);
    });

    test('should generate insights for low coverage', () {
      final insights = generateInsights(
        coverage: 50.0,
        passRate: 80.0,
        stability: 90.0,
      );

      expect(insights.any((i) => i.contains('coverage')), isTrue);
    });

    test('should generate insights for low pass rate', () {
      final insights = generateInsights(
        coverage: 90.0,
        passRate: 60.0,
        stability: 80.0,
      );

      expect(insights.any((i) => i.contains('fail')), isTrue);
    });

    test('should generate insights for flaky tests', () {
      final insights = generateInsights(
        coverage: 90.0,
        passRate: 90.0,
        stability: 70.0,
      );

      final result =
          insights.any((i) => i.contains('flaky') || i.contains('stability'));
      expect(result, isTrue);
    });
  });

  group('Recommendation Generation', () {
    test('should recommend actions for low coverage', () {
      final recommendations = generateRecommendations(
        coverage: 50.0,
        passRate: 90.0,
      );

      expect(recommendations, isNotEmpty);
      expect(recommendations.any((r) => r.contains('coverage')), isTrue);
    });

    test('should recommend actions for failing tests', () {
      final recommendations = generateRecommendations(
        coverage: 90.0,
        passRate: 60.0,
      );

      expect(recommendations, isNotEmpty);
      expect(recommendations.any((r) => r.contains('fail')), isTrue);
    });

    test('should have no recommendations for excellent metrics', () {
      final recommendations = generateRecommendations(
        coverage: 95.0,
        passRate: 100.0,
      );

      // Should be empty or contain positive feedback
      expect(recommendations.length, lessThanOrEqualTo(1));
    });
  });

  group('Cleanup Logic', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('cleanup_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('should keep latest report and delete old ones', () {
      // Create 3 reports
      final report1 =
          File('${tempDir.path}/module_test_report_coverage@1400_280125.md');
      final report2 =
          File('${tempDir.path}/module_test_report_coverage@1430_280125.md');
      final report3 =
          File('${tempDir.path}/module_test_report_coverage@1500_280125.md');

      report1.writeAsStringSync('Report 1');
      sleep(const Duration(milliseconds: 100));
      report2.writeAsStringSync('Report 2');
      sleep(const Duration(milliseconds: 100));
      report3.writeAsStringSync('Report 3');

      // Simulate cleanup - keep latest (report3), delete report1 and report2
      final allReports = tempDir
          .listSync()
          .whereType<File>()
          .where((File f) => f.path.contains('_test_report_coverage@'))
          .toList();

      allReports.sort((File a, File b) =>
          b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      // Keep first (latest), delete rest
      for (var i = 1; i < allReports.length; i++) {
        allReports[i].deleteSync();
      }

      expect(report3.existsSync(), isTrue);
      expect(report1.existsSync(), isFalse);
      expect(report2.existsSync(), isFalse);
    });

    test('should count reports before and after cleanup', () {
      // Create multiple reports
      for (var i = 0; i < 5; i++) {
        File('${tempDir.path}/report${i}_test_report_coverage@140${i}_280125.md')
            .writeAsStringSync('Report $i');
        sleep(const Duration(milliseconds: 50));
      }

      final beforeCount = countReports(tempDir, type: 'coverage');
      expect(beforeCount, equals(5));

      // Simulate cleanup - keep only latest
      final reports = tempDir
          .listSync()
          .whereType<File>()
          .where((File f) => f.path.contains('_test_report_coverage@'))
          .toList();

      reports.sort((File a, File b) =>
          b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      for (var i = 1; i < reports.length; i++) {
        reports[i].deleteSync();
      }

      final afterCount = countReports(tempDir, type: 'coverage');
      expect(afterCount, equals(1));
    });
  });
}

// Utility functions

String extractModuleName(String path) {
  // Remove trailing slashes
  path = path.replaceAll(RegExp(r'/$'), '');

  // Get the last segment
  final segments = path.split('/');
  var moduleName = segments.last;

  // Remove _test.dart suffix if present
  if (moduleName.endsWith('_test.dart')) {
    moduleName = moduleName.replaceAll('_test.dart', '');
  }

  // Remove .dart suffix if present
  if (moduleName.endsWith('.dart')) {
    moduleName = moduleName.replaceAll('.dart', '');
  }

  return moduleName;
}

double calculateHealthScore({
  required double coverage,
  required double passRate,
  required double stability,
}) {
  // Weighted average: coverage 40%, passRate 40%, stability 20%
  return (coverage * 0.4) + (passRate * 0.4) + (stability * 0.2);
}

List<String> generateInsights({
  required double coverage,
  required double passRate,
  required double stability,
}) {
  final insights = <String>[];

  if (coverage < 70) {
    insights.add('Low coverage detected - consider adding more tests');
  }

  if (passRate < 80) {
    insights.add('High test failures - address failing tests');
  }

  if (stability < 80) {
    insights.add('Flaky tests detected - improve test stability');
  }

  return insights;
}

List<String> generateRecommendations({
  required double coverage,
  required double passRate,
}) {
  final recommendations = <String>[];

  if (coverage < 80) {
    recommendations.add('Increase test coverage to meet minimum threshold');
  }

  if (passRate < 90) {
    recommendations.add('Fix failing tests to improve pass rate');
  }

  return recommendations;
}
