import 'dart:io';
import 'package:test/test.dart';
import 'package:test_reporter/src/utils/report_manager.dart';

void main() {
  late Directory testReportDir;

  setUp(() async {
    // Create temporary report directory for tests
    testReportDir = await Directory.systemTemp.createTemp('test_reports_');
  });

  tearDown(() async {
    // Clean up temporary directory
    if (await testReportDir.exists()) {
      await testReportDir.delete(recursive: true);
    }
  });

  group('ReportContext', () {
    test('should store all required fields', () {
      final timestamp = DateTime(2025, 11, 4, 14, 35);
      final context = ReportContext(
        moduleName: 'auth-service-fo',
        type: ReportType.coverage,
        toolName: 'analyze-coverage',
        timestamp: timestamp,
        reportId: 'test-id',
      );

      expect(context.moduleName, equals('auth-service-fo'));
      expect(context.type, equals(ReportType.coverage));
      expect(context.toolName, equals('analyze-coverage'));
      expect(context.timestamp, equals(timestamp));
      expect(context.reportId, equals('test-id'));
    });

    test('should generate correct subdirectory for coverage type', () {
      final context = ReportContext(
        moduleName: 'auth-fo',
        type: ReportType.coverage,
        toolName: 'analyze-coverage',
        timestamp: DateTime.now(),
        reportId: 'test-id',
      );

      expect(context.subdirectory, equals('quality'));
    });

    test('should generate correct subdirectory for tests type', () {
      final context = ReportContext(
        moduleName: 'auth-fo',
        type: ReportType.tests,
        toolName: 'analyze-tests',
        timestamp: DateTime.now(),
        reportId: 'test-id',
      );

      expect(context.subdirectory, equals('reliability'));
    });

    test('should generate correct subdirectory for failures type', () {
      final context = ReportContext(
        moduleName: 'auth-fo',
        type: ReportType.failures,
        toolName: 'extract-failures',
        timestamp: DateTime.now(),
        reportId: 'test-id',
      );

      expect(context.subdirectory, equals('failures'));
    });

    test('should generate correct subdirectory for suite type', () {
      final context = ReportContext(
        moduleName: 'auth-fo',
        type: ReportType.suite,
        toolName: 'analyze-suite',
        timestamp: DateTime.now(),
        reportId: 'test-id',
      );

      expect(context.subdirectory, equals('suite'));
    });

    test('should generate correct base filename', () {
      final context = ReportContext(
        moduleName: 'auth-service-fo',
        type: ReportType.coverage,
        toolName: 'analyze-coverage',
        timestamp: DateTime(2025, 11, 4, 14, 35, 0),
        reportId: 'test-id',
      );

      expect(
        context.baseFilename,
        equals(
            'auth-service-fo_analyze-coverage_quality@20251104-143500-test-id'),
      );
    });
  });

  group('ReportManager.startReport', () {
    test('should create report context with auto-generated timestamp', () {
      final before = DateTime.now();
      final context = ReportManager.startReport(
        moduleName: 'auth-service-fo',
        type: ReportType.coverage,
        toolName: 'analyze-coverage',
      );
      final after = DateTime.now();

      expect(context.moduleName, equals('auth-service-fo'));
      expect(context.type, equals(ReportType.coverage));
      expect(context.toolName, equals('analyze-coverage'));
      expect(context.reportId, isNotEmpty);
      expect(
        context.timestamp.isAfter(before.subtract(Duration(seconds: 1))),
        isTrue,
      );
      expect(
          context.timestamp.isBefore(after.add(Duration(seconds: 1))), isTrue);
    });

    test('should generate unique report IDs', () {
      final context1 = ReportManager.startReport(
        moduleName: 'auth-fo',
        type: ReportType.tests,
        toolName: 'analyze-tests',
      );

      final context2 = ReportManager.startReport(
        moduleName: 'auth-fo',
        type: ReportType.tests,
        toolName: 'analyze-tests',
      );

      expect(context1.reportId, isNot(equals(context2.reportId)));
    });
  });

  group('ReportManager.getReportDirectory', () {
    test('should return quality for coverage type', () {
      expect(
        ReportManager.getReportDirectory(ReportType.coverage),
        endsWith('tests_reports/quality'),
      );
    });

    test('should return reliability for tests type', () {
      expect(
        ReportManager.getReportDirectory(ReportType.tests),
        endsWith('tests_reports/reliability'),
      );
    });

    test('should return failures for failures type', () {
      expect(
        ReportManager.getReportDirectory(ReportType.failures),
        endsWith('tests_reports/failures'),
      );
    });

    test('should return suite for suite type', () {
      expect(
        ReportManager.getReportDirectory(ReportType.suite),
        endsWith('tests_reports/suite'),
      );
    });
  });

  group('ReportManager.generateFilename', () {
    test('should generate correct markdown filename', () {
      final context = ReportContext(
        moduleName: 'auth-service-fo',
        type: ReportType.coverage,
        toolName: 'analyze-coverage',
        timestamp: DateTime(2025, 11, 4, 14, 35, 0),
        reportId: 'test-id',
      );

      expect(
        ReportManager.generateFilename(context, 'md'),
        equals(
            'auth-service-fo_analyze-coverage_quality@20251104-143500-test-id.md'),
      );
    });

    test('should generate correct JSON filename', () {
      final context = ReportContext(
        moduleName: 'auth-fo',
        type: ReportType.tests,
        toolName: 'analyze-tests',
        timestamp: DateTime(2025, 11, 4, 15, 45, 0),
        reportId: 'test-id',
      );

      expect(
        ReportManager.generateFilename(context, 'json'),
        equals(
            'auth-fo_analyze-tests_reliability@20251104-154500-test-id.json'),
      );
    });
  });

  group('ReportManager.writeReport', () {
    test('should write markdown file', () async {
      // Override report directory for testing
      ReportManager.overrideReportsRoot(testReportDir.path);

      final context = ReportManager.startReport(
        moduleName: 'auth-fo',
        type: ReportType.tests,
        toolName: 'analyze-tests',
      );

      final markdownContent = '# Test Report\n\nSample content';
      final jsonData = {'success': true, 'totalTests': 42};

      final reportPath = await ReportManager.writeReport(
        context,
        markdownContent: markdownContent,
        jsonData: jsonData,
      );

      expect(await File(reportPath).exists(), isTrue);
      expect(await File(reportPath).readAsString(), equals(markdownContent));
    });

    test('should write JSON file alongside markdown', () async {
      ReportManager.overrideReportsRoot(testReportDir.path);

      final context = ReportManager.startReport(
        moduleName: 'auth-fo',
        type: ReportType.coverage,
        toolName: 'analyze-coverage',
      );

      final reportPath = await ReportManager.writeReport(
        context,
        markdownContent: '# Coverage Report',
        jsonData: {'coverage': 85.5},
      );

      final jsonPath = reportPath.replaceAll('.md', '.json');
      expect(await File(jsonPath).exists(), isTrue);

      final jsonContent = await File(jsonPath).readAsString();
      expect(jsonContent, contains('"coverage"'));
      expect(jsonContent, contains('85.5'));
    });

    test('should create subdirectory if it does not exist', () async {
      ReportManager.overrideReportsRoot(testReportDir.path);

      final context = ReportManager.startReport(
        moduleName: 'test-fo',
        type: ReportType.suite,
        toolName: 'analyze-suite',
      );

      await ReportManager.writeReport(
        context,
        markdownContent: '# Suite Report',
        jsonData: {},
      );

      final suiteDir = Directory('${testReportDir.path}/suite');
      expect(await suiteDir.exists(), isTrue);
    });

    test('should cleanup old reports when keepCount is 1', () async {
      ReportManager.overrideReportsRoot(testReportDir.path);

      // Write first report
      final context1 = ReportManager.startReport(
        moduleName: 'auth-fo',
        type: ReportType.tests,
        toolName: 'analyze-tests',
      );
      await ReportManager.writeReport(
        context1,
        markdownContent: '# Report 1',
        jsonData: {},
      );

      // Wait a bit to ensure different timestamps
      await Future.delayed(Duration(milliseconds: 100));

      // Write second report with cleanup
      final context2 = ReportManager.startReport(
        moduleName: 'auth-fo',
        type: ReportType.tests,
        toolName: 'analyze-tests',
      );
      await ReportManager.writeReport(
        context2,
        markdownContent: '# Report 2',
        jsonData: {},
        keepCount: 1,
      );

      // Should only have 2 files (1 md + 1 json from latest report)
      final reliabilityDir = Directory('${testReportDir.path}/reliability');
      final files = reliabilityDir.listSync();
      expect(files.length, equals(2));
    });

    test('should keep multiple reports when keepCount > 1', () async {
      ReportManager.overrideReportsRoot(testReportDir.path);

      // Write 3 reports
      for (var i = 0; i < 3; i++) {
        final context = ReportManager.startReport(
          moduleName: 'auth-fo',
          type: ReportType.coverage,
          toolName: 'analyze-coverage',
        );
        await ReportManager.writeReport(
          context,
          markdownContent: '# Report $i',
          jsonData: {},
          keepCount: 2,
        );
        await Future.delayed(Duration(milliseconds: 100));
      }

      // Should keep 2 latest reports (4 files: 2 md + 2 json)
      final qualityDir = Directory('${testReportDir.path}/quality');
      final files = qualityDir.listSync();
      expect(files.length, equals(4));
    });
  });

  group('ReportManager.findLatestReport', () {
    test('should find latest report for module and type', () async {
      ReportManager.overrideReportsRoot(testReportDir.path);

      // Write 2 reports
      final context1 = ReportManager.startReport(
        moduleName: 'auth-fo',
        type: ReportType.tests,
        toolName: 'analyze-tests',
      );
      await ReportManager.writeReport(
        context1,
        markdownContent: '# Report 1',
        jsonData: {},
      );

      await Future.delayed(Duration(milliseconds: 100));

      final context2 = ReportManager.startReport(
        moduleName: 'auth-fo',
        type: ReportType.tests,
        toolName: 'analyze-tests',
      );
      final report2Path = await ReportManager.writeReport(
        context2,
        markdownContent: '# Report 2',
        jsonData: {},
      );

      // Find latest
      final latest = await ReportManager.findLatestReport(
        moduleName: 'auth-fo',
        type: ReportType.tests,
      );

      expect(latest, isNotNull);
      expect(latest, equals(report2Path));
    });

    test('should return null when no reports exist', () async {
      ReportManager.overrideReportsRoot(testReportDir.path);

      final latest = await ReportManager.findLatestReport(
        moduleName: 'nonexistent-fo',
        type: ReportType.coverage,
      );

      expect(latest, isNull);
    });

    test('should filter by tool name when provided', () async {
      ReportManager.overrideReportsRoot(testReportDir.path);

      // Write report from tool A
      final contextA = ReportManager.startReport(
        moduleName: 'auth-fo',
        type: ReportType.coverage,
        toolName: 'tool-a',
      );
      await ReportManager.writeReport(
        contextA,
        markdownContent: '# Tool A',
        jsonData: {},
      );

      await Future.delayed(Duration(milliseconds: 100));

      // Write report from tool B
      final contextB = ReportManager.startReport(
        moduleName: 'auth-fo',
        type: ReportType.coverage,
        toolName: 'tool-b',
      );
      final pathB = await ReportManager.writeReport(
        contextB,
        markdownContent: '# Tool B',
        jsonData: {},
      );

      // Find latest from tool B
      final latest = await ReportManager.findLatestReport(
        moduleName: 'auth-fo',
        type: ReportType.coverage,
        toolName: 'tool-b',
      );

      expect(latest, equals(pathB));
    });
  });

  group('ReportManager.cleanupReports', () {
    test('should cleanup old reports for module', () async {
      ReportManager.overrideReportsRoot(testReportDir.path);

      // Write 3 reports
      for (var i = 0; i < 3; i++) {
        final context = ReportManager.startReport(
          moduleName: 'cleanup-test-fo',
          type: ReportType.failures,
          toolName: 'extract-failures',
        );
        await ReportManager.writeReport(
          context,
          markdownContent: '# Report $i',
          jsonData: {},
          keepCount: 99, // Don't auto-cleanup
        );
        await Future.delayed(Duration(milliseconds: 100));
      }

      // Should have 6 files (3 md + 3 json)
      final failuresDir = Directory('${testReportDir.path}/failures');
      expect(failuresDir.listSync().length, equals(6));

      // Manual cleanup to keep 1
      await ReportManager.cleanupReports(
        moduleName: 'cleanup-test-fo',
        type: ReportType.failures,
        keepCount: 1,
      );

      // Should now have 2 files (1 md + 1 json)
      expect(failuresDir.listSync().length, equals(2));
    });

    test('should support dry-run mode', () async {
      ReportManager.overrideReportsRoot(testReportDir.path);

      // Write 2 reports
      for (var i = 0; i < 2; i++) {
        final context = ReportManager.startReport(
          moduleName: 'dryrun-test-fo',
          type: ReportType.suite,
          toolName: 'analyze-suite',
        );
        await ReportManager.writeReport(
          context,
          markdownContent: '# Report $i',
          jsonData: {},
          keepCount: 99,
        );
        await Future.delayed(Duration(milliseconds: 100));
      }

      // Dry run cleanup
      await ReportManager.cleanupReports(
        moduleName: 'dryrun-test-fo',
        type: ReportType.suite,
        keepCount: 1,
        dryRun: true,
      );

      // Should still have all 4 files (2 md + 2 json)
      final suiteDir = Directory('${testReportDir.path}/suite');
      expect(suiteDir.listSync().length, equals(4));
    });
  });

  group('ReportManager.extractJsonFromReport', () {
    test('should extract JSON data from report path', () async {
      ReportManager.overrideReportsRoot(testReportDir.path);

      final context = ReportManager.startReport(
        moduleName: 'extract-test-fo',
        type: ReportType.coverage,
        toolName: 'analyze-coverage',
      );

      final jsonData = {
        'coverage': 92.5,
        'totalLines': 1000,
        'coveredLines': 925,
      };

      final reportPath = await ReportManager.writeReport(
        context,
        markdownContent: '# Coverage Report',
        jsonData: jsonData,
      );

      final extracted = await ReportManager.extractJsonFromReport(reportPath);

      expect(extracted, isNotNull);
      expect(extracted!['coverage'], equals(92.5));
      expect(extracted['totalLines'], equals(1000));
      expect(extracted['coveredLines'], equals(925));
    });

    test('should return null for non-existent report', () async {
      final extracted = await ReportManager.extractJsonFromReport(
        '/path/to/nonexistent/report.md',
      );

      expect(extracted, isNull);
    });
  });
}
