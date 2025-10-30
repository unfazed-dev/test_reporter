/// Cross-tool integration tests
///
/// Tests interactions between multiple test_reporter binaries,
/// report interoperability, and orchestration.

import 'dart:io';

import 'package:test/test.dart';

import 'helpers/assertion_helpers.dart';
import 'helpers/real_execution_helper.dart';
import 'helpers/temp_directory_helper.dart';

void main() {
  late BinaryExecutor executor;
  late TempTestDirectory tempDir;

  setUp(() async {
    executor = BinaryExecutor();
    tempDir = TempTestDirectory();
    await tempDir.create();
  });

  tearDown(() async {
    await tempDir.cleanup();
  });

  group('Cross-Tool Integration', () {
    test('analyze_suite should orchestrate coverage and tests', () async {
      await tempDir.setupFixture('sample_dart_project');

      final result =
          await executor.analyzeSuite('test', extraArgs: ['--runs=2']);

      expect(result, succeeds);

      // Check all report types were generated
      expect(Directory('tests_reports/coverage').existsSync(), isTrue);
      expect(Directory('tests_reports/tests').existsSync(), isTrue);
      expect(Directory('tests_reports/suite').existsSync(), isTrue);
    });

    test('reports should have correct naming convention', () async {
      await tempDir.setupFixture('sample_dart_project');

      await executor.analyzeCoverage('lib');

      final reports = Directory('tests_reports/coverage')
          .listSync()
          .whereType<File>()
          .map((f) => f.path)
          .toList();

      expect(reports, isNotEmpty);
      expect(reports.first, matches(RegExp(r'.*_report_coverage@.*\.md')));
    });

    test('concurrent runs should create unique reports', () async {
      await tempDir.setupFixture('sample_dart_project');

      // Run two analyses concurrently
      final results = await Future.wait([
        executor.analyzeCoverage('lib'),
        executor.analyzeCoverage('lib'),
      ]);

      expect(results[0], succeeds);
      expect(results[1], succeeds);

      final reports = Directory('tests_reports/coverage')
          .listSync()
          .whereType<File>()
          .toList();

      // Should have 2 separate report files
      expect(reports.length, greaterThanOrEqualTo(2));
    });
  });
}
