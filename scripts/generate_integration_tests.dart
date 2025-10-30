/// Master script for generating integration tests
///
/// This script orchestrates the generation of comprehensive integration tests
/// for all test_reporter binaries using the template system.
///
/// Usage:
///   dart run scripts/generate_integration_tests.dart
///
/// Generated tests will be placed in test/integration/

// ignore_for_file: avoid_print

import 'dart:io';
import 'package:path/path.dart' as p;
import 'test_templates.dart';

/// Configuration for a binary's integration tests
class BinaryTestConfig {
  const BinaryTestConfig({
    required this.binaryName,
    required this.className,
    required this.reportType,
    required this.flags,
    required this.description,
  });

  final String binaryName;
  final String className;
  final String reportType;
  final List<String> flags;
  final String description;
}

/// All binary configurations
const binaryConfigs = [
  BinaryTestConfig(
    binaryName: 'analyzeCoverage',
    className: 'AnalyzeCoverage',
    reportType: 'coverage',
    description: 'Code coverage analysis',
    flags: [
      '--exclude',
      '--include-imports',
      '--baseline',
      '--output',
      '--format',
      '--verbose',
      '--min-coverage',
      '--fail-on-decrease',
    ],
  ),
  BinaryTestConfig(
    binaryName: 'analyzeTests',
    className: 'AnalyzeTests',
    reportType: 'tests',
    description: 'Test analysis and flaky test detection',
    flags: [
      '--runs',
      '--verbose',
      '--performance',
      '--slow-test-threshold',
      '--parallel',
      '--max-workers',
      '--target',
      '--watch',
      '--interactive',
      '--dependency-analysis',
      '--mutation-testing',
      '--impact-analysis',
      '--generate-report',
      '--generate-fixes',
    ],
  ),
  BinaryTestConfig(
    binaryName: 'extractFailures',
    className: 'ExtractFailures',
    reportType: 'failures',
    description: 'Failed test extraction',
    flags: [
      '--output',
      '--format',
      '--verbose',
      '--watch',
    ],
  ),
  BinaryTestConfig(
    binaryName: 'analyzeSuite',
    className: 'AnalyzeSuite',
    reportType: 'suite',
    description: 'Full test suite analysis',
    flags: [
      '--runs',
      '--verbose',
      '--parallel',
      '--max-workers',
      '--skip-coverage',
      '--skip-tests',
      '--skip-failures',
    ],
  ),
];

void main() async {
  print('🚀 Generating integration tests for test_reporter...\n');

  final integrationDir = Directory('test/integration');
  if (!await integrationDir.exists()) {
    await integrationDir.create(recursive: true);
    print('✓ Created test/integration directory');
  }

  // Generate tests for each binary
  for (final config in binaryConfigs) {
    await _generateBinaryTests(config);
  }

  // Generate cross-tool integration tests
  await _generateCrossToolTests();

  print('\n✅ Integration test generation complete!');
  print('\nGenerated test files:');
  print('  - test/integration/analyze_coverage_integration_test.dart');
  print('  - test/integration/analyze_tests_integration_test.dart');
  print('  - test/integration/extract_failures_integration_test.dart');
  print('  - test/integration/analyze_suite_integration_test.dart');
  print('  - test/integration/cross_tool_integration_test.dart');
  print('\nTotal: 5 test files');
  print('\nNext steps:');
  print('  1. Run: dart run scripts/fixture_generator.dart');
  print('  2. Run: dart test test/integration/');
  print('  3. Check coverage with analyze_coverage');
}

/// Generate integration tests for a specific binary
Future<void> _generateBinaryTests(BinaryTestConfig config) async {
  print('📝 Generating tests for ${config.binaryName}...');

  final testContent = generateTestFile(
    config.binaryName,
    config.className,
    config.reportType,
    config.flags,
  );

  final testFile = File(
    p.join(
      'test',
      'integration',
      '${_camelToSnake(config.binaryName)}_integration_test.dart',
    ),
  );

  await testFile.writeAsString(testContent);
  print('  ✓ Created ${testFile.path}');

  // Count tests
  final testCount = _countTests(testContent);
  print('    → Generated $testCount tests');
}

/// Generate cross-tool integration tests
Future<void> _generateCrossToolTests() async {
  print('📝 Generating cross-tool integration tests...');

  final testContent = generateCrossToolTestFile();

  final testFile = File(
    p.join('test', 'integration', 'cross_tool_integration_test.dart'),
  );

  await testFile.writeAsString(testContent);
  print('  ✓ Created ${testFile.path}');

  // Count tests
  final testCount = _countTests(testContent);
  print('    → Generated $testCount tests');
}

/// Convert camelCase to snake_case
String _camelToSnake(String input) {
  return input.replaceAllMapped(
    RegExp('([a-z])([A-Z])'),
    (match) => '${match.group(1)}_${match.group(2)}'.toLowerCase(),
  );
}

/// Count test() calls in generated content
int _countTests(String content) {
  return 'test('.allMatches(content).length;
}
