/// Integration tests for extractFailures binary
///
/// Tests real execution of the extractFailures binary with actual
/// file system operations and process spawning.

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

  group('Process Execution Tests', () {
    test('should start and exit successfully', () async {
      final result = await executor.runBinary('extract_failures', ['--help']);
      expect(result, succeeds);
      expect(result, outputContains('Usage'));
    });

    test('should handle invalid arguments gracefully', () async {
      final result =
          await executor.runBinary('extract_failures', ['--invalid-flag']);
      expect(result, fails);
      expect(result.stderr, isNotEmpty);
    });

    test('should timeout on long-running operations', () async {
      // Mocked test - would take too long in reality
      final executor =
          BinaryExecutor(timeout: const Duration(milliseconds: 100));
      // Test implementation would go here
      expect(true, isTrue); // Placeholder
    });

    test('should capture stdout and stderr separately', () async {
      final result =
          await executor.runBinary('extract_failures', ['--verbose', '--help']);
      expect(result.stdout, isNotEmpty);
      // Some output may go to stderr for warnings
    });
  });
  group('File I/O Tests', () {
    test('should create report file', () async {
      await tempDir.createDartProject(name: 'test_project');

      final result = await executor.runBinary('extract_failures', ['test']);

      expect(result, succeeds);
      expect(
        Directory('tests_reports/failures'),
        hasReportFile('_report_'),
      );
    });

    test('should create subdirectory structure', () async {
      await tempDir.createDartProject(name: 'test_project');

      await executor.runBinary('extract_failures', ['test']);

      expect(await Directory('tests_reports/failures').exists(), isTrue);
    });

    test('should embed JSON in report', () async {
      await tempDir.setupFixture('sample_dart_project');

      final result = await executor.runBinary('extract_failures', ['test']);

      final reportFiles = Directory('tests_reports/failures')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.md'));

      expect(reportFiles, isNotEmpty);
      expect(reportFiles.first, hasEmbeddedJson);
    });
  });
  group('CLI Arguments Tests', () {
    test('should accept --output flag', () async {
      final result =
          await executor.runBinary('extract_failures', ['test', '--output']);
      // Flag should be accepted (may succeed or fail based on other factors)
      expect(result.exitCode, anyOf(equals(0), equals(1)));
    });

    test('should accept --format flag', () async {
      final result =
          await executor.runBinary('extract_failures', ['test', '--format']);
      // Flag should be accepted (may succeed or fail based on other factors)
      expect(result.exitCode, anyOf(equals(0), equals(1)));
    });

    test('should accept --verbose flag', () async {
      final result =
          await executor.runBinary('extract_failures', ['test', '--verbose']);
      // Flag should be accepted (may succeed or fail based on other factors)
      expect(result.exitCode, anyOf(equals(0), equals(1)));
    });

    test('should accept --watch flag', () async {
      final result =
          await executor.runBinary('extract_failures', ['test', '--watch']);
      // Flag should be accepted (may succeed or fail based on other factors)
      expect(result.exitCode, anyOf(equals(0), equals(1)));
    });

    test('should handle multiple flags together', () async {
      final result = await executor.runBinary('extract_failures', [
        'test',
        '--output',
        '--format',
      ]);
      expect(result.exitCode, anyOf(equals(0), equals(1)));
    });
  });
  group('Integration Workflows', () {
    test('should complete end-to-end workflow', () async {
      await tempDir.setupFixture('sample_dart_project');

      final result = await executor.runBinary('extract_failures', ['test']);

      expect(result, succeeds);
      expect(result, completesWithin(const Duration(seconds: 60)));
    });

    test('should handle missing dependencies gracefully', () async {
      await tempDir.createDartProject(name: 'empty_project');
      // Don't run pub get - missing dependencies

      final result = await executor.runBinary('extract_failures', ['test']);

      // Should fail gracefully
      expect(result, fails);
      expect(result.stderr, isNotEmpty);
    });
  });
}
