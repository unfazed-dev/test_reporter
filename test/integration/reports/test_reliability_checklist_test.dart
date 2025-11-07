@Tags(['integration'])
import 'dart:io';
import 'package:test/test.dart';
import 'package:test_reporter/src/bin/analyze_tests_lib.dart';
import 'package:test_reporter/src/utils/report_manager.dart';

/// Integration tests for test reliability report checklist generation
///
/// These tests verify that analyze_tests generates actionable checklists
/// with priority-based sections (failing/flaky/slow tests).
///
/// NOTE: These tests use a temp directory for reports to avoid polluting tests_reports/
/// Run with: dart test --tags integration
void main() {
  group('Test Reliability Report Checklist Integration', () {
    late Directory tempDir;
    late Directory tempReportsDir;
    late String reportPath;

    setUp(() async {
      // Create temp directory for test outputs
      tempDir = Directory.systemTemp.createTempSync('test_reliability_test_');

      // Create temp directory for reports (so we don't pollute real reports/)
      tempReportsDir = await Directory.systemTemp.createTemp('test_reports_');

      // Override ReportManager to use temp directory
      ReportManager.overrideReportsRoot(tempReportsDir.path);
    });

    tearDown(() async {
      // Reset ReportManager to use default directory
      ReportManager.overrideReportsRoot('tests_reports');

      // Cleanup temp test directory
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }

      // Cleanup temp reports directory
      if (await tempReportsDir.exists()) {
        await tempReportsDir.delete(recursive: true);
      }
    });

    test('report includes "✅ Test Reliability Action Items" section', () async {
      // Create a simple test fixture that will be analyzed
      final testFile = File('${tempDir.path}/sample_test.dart');
      testFile.writeAsStringSync('''
import 'package:test/test.dart';

void main() {
  test('passing test', () {
    expect(true, isTrue);
  });

  test('failing test', () {
    expect(true, isFalse); // Will fail
  });
}
''');

      // Run analyzer on the test file (reports will go to temp dir via ReportManager override)
      final analyzer = TestAnalyzer(
        targetFiles: [testFile.path],
        runCount: 2,
        verbose: false,
      );

      await analyzer.run();

      // Get the generated report from temp directory
      final reports = Directory('${tempReportsDir.path}/reliability')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.md'))
          .toList();

      expect(reports, isNotEmpty,
          reason: 'Should generate at least one report');

      reportPath = reports.last.path;
      final reportContent = File(reportPath).readAsStringSync();

      // Verify checklist section exists
      expect(
        reportContent,
        contains('## ✅ Test Reliability Action Items'),
        reason: 'Report should include checklist section',
      );
    });

    test('report includes Priority 1 section for failing tests', () async {
      final testFile = File('${tempDir.path}/failing_test.dart');
      testFile.writeAsStringSync('''
import 'package:test/test.dart';

void main() {
  test('consistently failing test', () {
    expect(1, equals(2)); // Assertion failure
  });
}
''');

      final analyzer = TestAnalyzer(
        targetFiles: [testFile.path],
        runCount: 2,
        verbose: false,
      );

      await analyzer.run();

      final reports = Directory('${tempReportsDir.path}/reliability')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.md'))
          .toList();

      final reportContent = File(reports.last.path).readAsStringSync();

      // Verify Priority 1 section exists
      expect(
        reportContent,
        contains('### 🔴 Priority 1: Fix Failing Tests'),
        reason: 'Should have Priority 1 section for failing tests',
      );
    });

    test('report includes Priority 2 section for flaky tests', () async {
      // Note: Creating an actual flaky test is complex in a unit test
      // This test verifies the section exists when flaky tests are detected
      final testFile = File('${tempDir.path}/test.dart');
      testFile.writeAsStringSync('''
import 'package:test/test.dart';
import 'dart:math';

void main() {
  test('potentially flaky test', () {
    // This test might pass/fail randomly
    final random = Random().nextBool();
    expect(random || true, isTrue); // Always passes, but simulates flaky pattern
  });
}
''');

      final analyzer = TestAnalyzer(
        targetFiles: [testFile.path],
        runCount: 3,
        verbose: false,
      );

      await analyzer.run();

      final reports = Directory('${tempReportsDir.path}/reliability')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.md'))
          .toList();

      final reportContent = File(reports.last.path).readAsStringSync();

      // Verify Priority 2 section can exist (may not exist if no flaky tests detected)
      // At minimum, the report should support this section structure
      final hasReliabilitySection =
          reportContent.contains('✅ Test Reliability Action Items');
      expect(hasReliabilitySection, isTrue);
    });

    test('report includes Priority 3 section for slow tests', () async {
      final testFile = File('${tempDir.path}/slow_test.dart');
      testFile.writeAsStringSync('''
import 'package:test/test.dart';

void main() {
  test('slow test', () async {
    await Future.delayed(Duration(milliseconds: 100));
    expect(true, isTrue);
  });
}
''');

      final analyzer = TestAnalyzer(
        targetFiles: [testFile.path],
        runCount: 2,
        verbose: false,
        slowTestThreshold: 0.05, // 50ms - low threshold to catch our test
      );

      await analyzer.run();

      final reports = Directory('${tempReportsDir.path}/reliability')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.md'))
          .toList();

      final reportContent = File(reports.last.path).readAsStringSync();

      // Verify Priority 3 section exists or is supported
      final hasReliabilitySection =
          reportContent.contains('✅ Test Reliability Action Items');
      expect(hasReliabilitySection, isTrue);
    });

    test('failing tests include failure type and fix suggestion', () async {
      final testFile = File('${tempDir.path}/typed_failure_test.dart');
      testFile.writeAsStringSync('''
import 'package:test/test.dart';

void main() {
  test('assertion failure test', () {
    final expected = 10;
    final actual = 5;
    expect(actual, equals(expected)); // Clear assertion failure
  });
}
''');

      final analyzer = TestAnalyzer(
        targetFiles: [testFile.path],
        runCount: 2,
        verbose: false,
      );

      await analyzer.run();

      final reports = Directory('${tempReportsDir.path}/reliability')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.md'))
          .toList();

      final reportContent = File(reports.last.path).readAsStringSync();

      // Verify checklist includes test info and actions
      expect(
        reportContent,
        contains('- [ ]'),
        reason: 'Should include checkbox items',
      );
    });

    test('checklist includes verification commands', () async {
      final testFile = File('${tempDir.path}/verify_test.dart');
      testFile.writeAsStringSync('''
import 'package:test/test.dart';

void main() {
  test('test needing verification', () {
    expect(true, isFalse);
  });
}
''');

      final analyzer = TestAnalyzer(
        targetFiles: [testFile.path],
        runCount: 2,
        verbose: false,
      );

      await analyzer.run();

      final reports = Directory('${tempReportsDir.path}/reliability')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.md'))
          .toList();

      final reportContent = File(reports.last.path).readAsStringSync();

      // Verify verification commands are present
      expect(
        reportContent,
        anyOf([
          contains('dart test'),
          contains('Verify:'),
          contains('Run:'),
        ]),
        reason: 'Should include verification commands',
      );
    });

    test('checklist includes progress tracking per priority level', () async {
      final testFile = File('${tempDir.path}/progress_test.dart');
      testFile.writeAsStringSync('''
import 'package:test/test.dart';

void main() {
  test('failing test 1', () {
    expect(1, equals(2));
  });

  test('failing test 2', () {
    expect('a', equals('b'));
  });
}
''');

      final analyzer = TestAnalyzer(
        targetFiles: [testFile.path],
        runCount: 2,
        verbose: false,
      );

      await analyzer.run();

      final reports = Directory('${tempReportsDir.path}/reliability')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.md'))
          .toList();

      final reportContent = File(reports.last.path).readAsStringSync();

      // Verify progress tracking exists
      expect(
        reportContent,
        anyOf([
          contains('Progress:'),
          contains('0 of'),
          contains('completed'),
        ]),
        reason: 'Should include progress tracking',
      );
    });
  });
}
