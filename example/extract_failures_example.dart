/// Example: Using extract_failures to extract and rerun failed tests
///
/// This demonstrates the failure extractor which:
/// - Parses test output to identify failures
/// - Generates targeted rerun commands
/// - Groups failures by file for batch execution
/// - Provides watch mode for continuous testing
/// - Auto-reruns failed tests on detection
///
/// Run this example:
/// ```bash
/// dart run example/extract_failures_example.dart
/// ```

// ignore_for_file: avoid_print

import 'dart:io';

Future<void> main() async {
  print('🔍 Failed Test Extractor Example\n');
  print('=' * 60);

  // Example 1: Basic failure extraction
  print('\n📌 Example 1: Extract failures from test run\n');
  print('Command equivalent:');
  print('  dart run test_reporter:extract_failures test/');
  print('\nRuns tests and extracts all failures with:');
  print('  • Test names');
  print('  • Error messages');
  print('  • Stack traces');
  print('  • Runtime durations');

  // Example 2: Group failures by file
  print('\n' + '=' * 60);
  print('\n📌 Example 2: Group failures by test file\n');
  print('Command equivalent:');
  print('  dart run test_reporter:extract_failures test/ --group-by-file');
  print('\nGroups failures by file and generates:');
  print('  • One rerun command per file');
  print('  • Easier batch execution');
  print('  • Better organization for large test suites');

  // Example 3: Auto-rerun failed tests
  print('\n' + '=' * 60);
  print('\n📌 Example 3: Automatically rerun failed tests\n');
  print('Command equivalent:');
  print('  dart run test_reporter:extract_failures test/ --auto-rerun');
  print('\nAfter extracting failures, automatically reruns them!');
  print('Useful for confirming intermittent failures.');

  // Example 4: Watch mode for continuous testing
  print('\n' + '=' * 60);
  print('\n📌 Example 4: Watch mode - rerun on file changes\n');
  print('Command equivalent:');
  print('  dart run test_reporter:extract_failures test/ --watch');
  print('\nContinuously monitors test files for changes.');
  print('Automatically reruns tests when files are modified.');

  // Example 5: Save results for later analysis
  print('\n' + '=' * 60);
  print('\n📌 Example 5: Save failure details to report\n');
  print('Command equivalent:');
  print('  dart run test_reporter:extract_failures test/ --save');
  print('\nGenerates detailed failure reports in tests_reports/failures/');

  // Example 6: Specific test file or directory
  print('\n' + '=' * 60);
  print('\n📌 Example 6: Extract failures from specific file\n');
  print('Command equivalent:');
  print('  dart run test_reporter:extract_failures test/unit/models/');
  print('\nAnalyzes failures in a specific directory only.');

  // Real-world example
  print('\n' + '=' * 60);
  print('\n🚀 Running Real Analysis (if tests exist)...\n');

  if (await Directory('test').exists()) {
    print(
        'Executing: dart run test_reporter:extract_failures test/unit --no-report\n');
    print('(Running on test/unit to keep execution time short)\n');

    final result = await Process.run(
      'dart',
      [
        'run',
        'test_reporter:extract_failures',
        'test/unit',
        '--no-report',
      ],
    );

    if (result.exitCode == 0) {
      print('✅ All tests passed - no failures to extract!');
    } else if (result.exitCode == 1) {
      print('⚠️ Found test failures. See output above for rerun commands.');
      print('\nSample output:');
      final lines = result.stdout.toString().split('\n');
      print(lines.take(25).join('\n'));
    } else {
      print('❌ Extraction failed (exit code: ${result.exitCode})');
      print(result.stderr);
    }
  } else {
    print('⚠️ No test/ directory found.');
    print('Run this example from a Dart package root directory.');
  }

  print('\n' + '=' * 60);
  print('\n📚 Report Output');
  print('\nWhen --save is enabled, you\'ll find:');
  print('  - Markdown: tests_reports/failures/{module}_failures@timestamp.md');
  print('  - JSON: tests_reports/failures/{module}_failures@timestamp.json');
  print('\nReports include:');
  print('  • List of all failed tests');
  print('  • Complete error messages and stack traces');
  print('  • Copy-pasteable rerun commands');
  print('  • Failure statistics and patterns');

  print('\n' + '=' * 60);
  print('\n💡 Common Use Cases');
  print('\n1. CI/CD Pipeline:');
  print('   dart run test_reporter:extract_failures test/');
  print('   Extract failures for investigation');
  print('\n2. Local Development:');
  print('   dart run test_reporter:extract_failures test/ --watch');
  print('   Get instant feedback on failures as you code');
  print('\n3. Flaky Test Investigation:');
  print('   dart run test_reporter:extract_failures test/ --auto-rerun');
  print('   Verify if failures are consistent or intermittent');
  print('\n4. Targeted Debugging:');
  print(
      '   dart run test_reporter:extract_failures test/unit/specific_test.dart');
  print('   Focus on a problematic test file');

  print('\n' + '=' * 60);
  print('\n✨ Learn More');
  print('\nFor complete documentation, visit:');
  print('  https://pub.dev/packages/test_reporter');
  print('\nOr run: dart run test_reporter:extract_failures --help\n');
}
