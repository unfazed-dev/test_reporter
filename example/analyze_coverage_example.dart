/// Example: Using analyze_coverage to analyze test coverage
///
/// This demonstrates the coverage analyzer which:
/// - Analyzes line and branch coverage
/// - Identifies uncovered code
/// - Auto-generates missing test stubs (with --fix)
/// - Validates coverage against thresholds
/// - Generates detailed coverage reports
///
/// Run this example:
/// ```bash
/// dart run example/analyze_coverage_example.dart
/// ```

// ignore_for_file: avoid_print

import 'dart:io';

Future<void> main() async {
  print('📊 Coverage Analyzer Example\n');
  print('=' * 60);

  // Example 1: Basic coverage analysis
  print('\n📌 Example 1: Analyze coverage for entire lib/ directory\n');
  print('Command equivalent:');
  print('  dart run test_reporter:analyze_coverage lib/src');
  print(
      '\nAnalyzes all source files in lib/src and their corresponding tests.');

  // Example 2: Auto-fix mode - generate missing tests
  print('\n' + '=' * 60);
  print('\n📌 Example 2: Generate test stubs for uncovered files\n');
  print('Command equivalent:');
  print('  dart run test_reporter:analyze_coverage lib/src --fix');
  print('\nAutomatically creates test files for source files without tests!');
  print('Generated tests include:');
  print('  • Basic test structure');
  print('  • Correct import statements');
  print('  • TODO placeholders for implementation');

  // Example 3: Set coverage thresholds
  print('\n' + '=' * 60);
  print('\n📌 Example 3: Validate coverage meets 80% threshold\n');
  print('Command equivalent:');
  print('  dart run test_reporter:analyze_coverage lib/src --min-coverage=80');
  print('\nFails (exit code 1) if coverage is below 80%.');
  print('Perfect for CI/CD quality gates!');

  // Example 4: Specific file or directory
  print('\n' + '=' * 60);
  print('\n📌 Example 4: Analyze specific file\n');
  print('Command equivalent:');
  print(
      '  dart run test_reporter:analyze_coverage lib/src/utils/report_utils.dart');
  print('\nFocuses analysis on a single source file.');

  // Real-world example
  print('\n' + '=' * 60);
  print('\n🚀 Running Real Analysis (if lib/src exists)...\n');

  if (await Directory('lib/src').exists()) {
    print(
        'Executing: dart run test_reporter:analyze_coverage lib/src --no-report\n');

    final result = await Process.run(
      'dart',
      [
        'run',
        'test_reporter:analyze_coverage',
        'lib/src',
        '--no-report',
      ],
    );

    if (result.exitCode == 0) {
      print('✅ Coverage analysis completed successfully!');
      print('\nSummary output:');
      final lines = result.stdout.toString().split('\n');
      print(lines.take(20).join('\n'));
    } else {
      print(
          '⚠️ Coverage below threshold or analysis failed (exit code: ${result.exitCode})');
      print(result.stderr);
    }
  } else {
    print('⚠️ No lib/src directory found.');
    print('Run this example from a Dart package root directory.');
  }

  print('\n' + '=' * 60);
  print('\n📚 Report Output');
  print('\nWhen reports are enabled (default), you\'ll find:');
  print('  - Markdown: tests_reports/quality/{module}_coverage@timestamp.md');
  print('  - JSON: tests_reports/quality/{module}_coverage@timestamp.json');
  print('\nReports include:');
  print('  • Overall coverage percentage');
  print('  • Coverage by file with uncovered lines');
  print('  • List of files without tests');
  print('  • Coverage trend analysis');
  print('  • Threshold validation results');

  print('\n' + '=' * 60);
  print('\n💡 Pro Tips');
  print('\n1. Use --fix to bootstrap test files for new features');
  print('2. Set --min-coverage in CI/CD to enforce coverage standards');
  print('3. Analyze specific files or directories to focus on problem areas');

  print('\n' + '=' * 60);
  print('\n✨ Learn More');
  print('\nFor complete documentation, visit:');
  print('  https://pub.dev/packages/test_reporter');
  print('\nOr run: dart run test_reporter:analyze_coverage --help\n');
}
