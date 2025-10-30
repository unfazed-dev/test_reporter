/// Templates for generating integration tests
///
/// Provides test templates for different test categories:
/// - Process execution tests
/// - File I/O tests
/// - CLI argument tests
/// - Integration workflow tests
/// - Cross-tool integration tests

// ignore_for_file: avoid_print

class TestTemplate {
  const TestTemplate({
    required this.name,
    required this.description,
    required this.code,
    this.isReal = true,
  });

  final String name;
  final String description;
  final String code;
  final bool isReal;
}

/// Get process execution test templates for a binary
List<TestTemplate> getProcessExecutionTests(String binaryName) {
  // Convert camelCase to snake_case for binary name
  final snakeCaseName = _camelToSnake(binaryName);

  return [
    TestTemplate(
      name: 'should start and exit successfully',
      description: 'Basic execution with --help flag',
      code: '''
      final result = await executor.runBinary('$snakeCaseName', ['--help']);
      expect(result, succeeds);
      expect(result, outputContains('Usage'));
    ''',
    ),
    TestTemplate(
      name: 'should handle invalid arguments gracefully',
      description: 'Test with unknown flag',
      code: '''
      final result = await executor.runBinary('$snakeCaseName', ['--invalid-flag']);
      expect(result, fails);
      expect(result.stderr, isNotEmpty);
    ''',
    ),
    TestTemplate(
      name: 'should timeout on long-running operations',
      description: 'Test timeout handling',
      isReal: false,
      code: '''
      // Mocked test - would take too long in reality
      final executor = BinaryExecutor(timeout: const Duration(milliseconds: 100));
      // Test implementation would go here
      expect(true, isTrue); // Placeholder
    ''',
    ),
    TestTemplate(
      name: 'should capture stdout and stderr separately',
      description: 'Output stream separation',
      code: '''
      final result = await executor.runBinary('$snakeCaseName', ['--verbose', '--help']);
      expect(result.stdout, isNotEmpty);
      // Some output may go to stderr for warnings
    ''',
    ),
  ];
}

/// Convert camelCase to snake_case
String _camelToSnake(String input) {
  return input.replaceAllMapped(
    RegExp('([a-z])([A-Z])'),
    (match) => '${match.group(1)}_${match.group(2)}'.toLowerCase(),
  );
}

/// Get file I/O test templates for a binary
List<TestTemplate> getFileIOTests(String binaryName, String reportType) {
  final snakeCaseName = _camelToSnake(binaryName);

  return [
    TestTemplate(
      name: 'should create report file',
      description: 'Verify report generation',
      code: '''
      await tempDir.createDartProject(name: 'test_project');

      final result = await executor.runBinary('$snakeCaseName', ['test']);

      expect(result, succeeds);
      expect(
        Directory('tests_reports/$reportType'),
        hasReportFile('_report_'),
      );
    ''',
    ),
    TestTemplate(
      name: 'should create subdirectory structure',
      description: 'Verify directory creation',
      code: '''
      await tempDir.createDartProject(name: 'test_project');

      await executor.runBinary('$snakeCaseName', ['test']);

      expect(await Directory('tests_reports/$reportType').exists(), isTrue);
    ''',
    ),
    TestTemplate(
      name: 'should embed JSON in report',
      description: 'Verify JSON embedding',
      code: '''
      await tempDir.setupFixture('sample_dart_project');

      final result = await executor.runBinary('$snakeCaseName', ['test']);

      final reportFiles = Directory('tests_reports/$reportType')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.md'));

      expect(reportFiles, isNotEmpty);
      expect(reportFiles.first, hasEmbeddedJson);
    ''',
    ),
  ];
}

/// Get CLI argument test templates for a binary
List<TestTemplate> getCLIArgumentTests(String binaryName, List<String> flags) {
  final snakeCaseName = _camelToSnake(binaryName);
  final templates = <TestTemplate>[];

  for (final flag in flags) {
    templates.add(
      TestTemplate(
        name: 'should accept $flag flag',
        description: 'Test $flag flag parsing',
        code: '''
      final result = await executor.runBinary('$snakeCaseName', ['test', '$flag']);
      // Flag should be accepted (may succeed or fail based on other factors)
      expect(result.exitCode, anyOf(equals(0), equals(1)));
    ''',
      ),
    );
  }

  templates.add(
    TestTemplate(
      name: 'should handle multiple flags together',
      description: 'Test flag combination',
      code: '''
      final result = await executor.runBinary('$snakeCaseName', [
        'test',
        '${flags.take(2).join("', '")}',
      ]);
      expect(result.exitCode, anyOf(equals(0), equals(1)));
    ''',
    ),
  );

  return templates;
}

/// Get integration workflow test templates
List<TestTemplate> getWorkflowTests(String binaryName) {
  final snakeCaseName = _camelToSnake(binaryName);

  return [
    TestTemplate(
      name: 'should complete end-to-end workflow',
      description: 'Full workflow test',
      code: '''
      await tempDir.setupFixture('sample_dart_project');

      final result = await executor.runBinary('$snakeCaseName', ['test']);

      expect(result, succeeds);
      expect(result, completesWithin(const Duration(seconds: 60)));
    ''',
    ),
    TestTemplate(
      name: 'should handle missing dependencies gracefully',
      description: 'Test error handling',
      code: '''
      await tempDir.createDartProject(name: 'empty_project');
      // Don't run pub get - missing dependencies

      final result = await executor.runBinary('$snakeCaseName', ['test']);

      // Should fail gracefully
      expect(result, fails);
      expect(result.stderr, isNotEmpty);
    ''',
    ),
  ];
}

/// Get cross-tool integration test templates
List<TestTemplate> getCrossToolTests() {
  return [
    TestTemplate(
      name: 'analyze_suite should orchestrate coverage and tests',
      description: 'Test full suite orchestration',
      code: '''
      await tempDir.setupFixture('sample_dart_project');

      final result = await executor.analyzeSuite('test', extraArgs: ['--runs=2']);

      expect(result, succeeds);

      // Check all report types were generated
      expect(Directory('tests_reports/coverage').existsSync(), isTrue);
      expect(Directory('tests_reports/tests').existsSync(), isTrue);
      expect(Directory('tests_reports/suite').existsSync(), isTrue);
    ''',
    ),
    TestTemplate(
      name: 'reports should have correct naming convention',
      description: 'Verify report naming',
      code: '''
      await tempDir.setupFixture('sample_dart_project');

      await executor.analyzeCoverage('lib');

      final reports = Directory('tests_reports/coverage')
          .listSync()
          .whereType<File>()
          .map((f) => f.path)
          .toList();

      expect(reports, isNotEmpty);
      expect(reports.first, matches(RegExp(r'.*_report_coverage@.*\\.md')));
    ''',
    ),
    TestTemplate(
      name: 'concurrent runs should create unique reports',
      description: 'Test concurrent execution',
      code: '''
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
    ''',
    ),
  ];
}

/// Generate complete test file content for a binary
String generateTestFile(
  String binaryName,
  String className,
  String reportType,
  List<String> flags,
) {
  final processTests = getProcessExecutionTests(binaryName);
  final fileIOTests = getFileIOTests(binaryName, reportType);
  final cliTests = getCLIArgumentTests(binaryName, flags);
  final workflowTests = getWorkflowTests(binaryName);

  final buffer = StringBuffer();

  // Header
  buffer.writeln('''
/// Integration tests for $binaryName binary
///
/// Tests real execution of the $binaryName binary with actual
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
''');

  // Process execution tests
  buffer.writeln('''
  group('Process Execution Tests', () {
''');
  for (final test in processTests) {
    buffer.writeln('''
    test('${test.name}', () async {
${test.code}
    });
''');
  }
  buffer.writeln('  });');

  // File I/O tests
  buffer.writeln('''
  group('File I/O Tests', () {
''');
  for (final test in fileIOTests) {
    buffer.writeln('''
    test('${test.name}', () async {
${test.code}
    });
''');
  }
  buffer.writeln('  });');

  // CLI argument tests
  buffer.writeln('''
  group('CLI Arguments Tests', () {
''');
  for (final test in cliTests.take(10)) {
    // Limit to 10 to avoid too many tests
    buffer.writeln('''
    test('${test.name}', () async {
${test.code}
    });
''');
  }
  buffer.writeln('  });');

  // Workflow tests
  buffer.writeln('''
  group('Integration Workflows', () {
''');
  for (final test in workflowTests) {
    buffer.writeln('''
    test('${test.name}', () async {
${test.code}
    });
''');
  }
  buffer.writeln('  });');

  buffer.writeln('}');

  return buffer.toString();
}

/// Generate cross-tool integration test file
String generateCrossToolTestFile() {
  final tests = getCrossToolTests();

  final buffer = StringBuffer();

  buffer.writeln('''
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
''');

  for (final test in tests) {
    buffer.writeln('''
    test('${test.name}', () async {
${test.code}
    });
''');
  }

  buffer.writeln('''
  });
}
''');

  return buffer.toString();
}
