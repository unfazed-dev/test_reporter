/// Example: Using analyze_tests to detect flaky tests
///
/// This demonstrates the test reliability analyzer which:
/// - Runs tests multiple times to detect flaky tests
/// - Identifies failure patterns (null errors, timeouts, assertions, etc.)
/// - Generates reliability scores for each test
/// - Provides fix suggestions based on failure types
/// - Profiles test performance
///
/// Run this example:
/// ```bash
/// dart run example/analyze_tests_example.dart
/// ```

// ignore_for_file: avoid_print

import 'dart:io';

Future<void> main() async {
  print('🔬 Test Reliability Analyzer Example\n');
  print('=' * 60);

  // Example 1: Basic usage - analyze all tests
  print('\n📌 Example 1: Analyze all tests in test/ directory\n');
  print('Command equivalent:');
  print('  dart run test_reporter:analyze_tests test/');
  print('\nThis runs all tests once and generates a reliability report.');

  // Example 2: Multi-run analysis to detect flaky tests
  print('\n' + '=' * 60);
  print('\n📌 Example 2: Run tests 5 times to detect flakiness\n');
  print('Command equivalent:');
  print('  dart run test_reporter:analyze_tests test/ --runs=5');
  print('\nFlaky tests are those that pass sometimes but fail other times.');
  print('Running multiple times helps identify these unreliable tests.');

  // Example 3: Performance profiling
  print('\n' + '=' * 60);
  print('\n📌 Example 3: Profile slow tests\n');
  print('Command equivalent:');
  print(
      '  dart run test_reporter:analyze_tests test/ --performance --slow=1.0');
  print('\nDetects tests that take longer than 1 second to run.');
  print('Helps identify performance bottlenecks in your test suite.');

  // Example 4: Analyze specific test file
  print('\n' + '=' * 60);
  print('\n📌 Example 4: Analyze a specific test file\n');
  print('Command equivalent:');
  print(
      '  dart run test_reporter:analyze_tests test/unit/models/failure_types_test.dart');
  print('\nFocuses analysis on a single test file.');

  // Example 5: Verbose output
  print('\n' + '=' * 60);
  print('\n📌 Example 5: Verbose analysis with detailed output\n');
  print('Command equivalent:');
  print('  dart run test_reporter:analyze_tests test/ --verbose --runs=3');
  print('\nProvides detailed information about each test run.');

  // Example 6: Skip report generation (for CI/CD)
  print('\n' + '=' * 60);
  print('\n📌 Example 6: Run without generating reports (CI/CD mode)\n');
  print('Command equivalent:');
  print('  dart run test_reporter:analyze_tests test/ --no-report');
  print('\nUseful in CI/CD pipelines where you only need exit codes.');

  // Real-world example: Run a quick analysis
  print('\n' + '=' * 60);
  print('\n🚀 Running Real Analysis (if tests exist)...\n');

  if (await Directory('test').exists()) {
    print(
        'Executing: dart run test_reporter:analyze_tests test/ --runs=2 --no-report\n');

    final result = await Process.run(
      'dart',
      [
        'run',
        'test_reporter:analyze_tests',
        'test/',
        '--runs=2',
        '--no-report',
      ],
    );

    if (result.exitCode == 0) {
      print('✅ Analysis completed successfully!');
      print('\nSummary output:');
      print(result.stdout.toString().split('\n').take(15).join('\n'));
    } else {
      print(
          '⚠️ Analysis completed with issues (exit code: ${result.exitCode})');
      print(result.stderr);
    }
  } else {
    print('⚠️ No test/ directory found in current location.');
    print('Run this example from a Dart package root directory.');
  }

  print('\n' + '=' * 60);
  print('\n📚 Report Output');
  print('\nWhen reports are enabled (default), you\'ll find:');
  print(
      '  - Markdown report: tests_reports/reliability/{module}_analysis@timestamp.md');
  print(
      '  - JSON report: tests_reports/reliability/{module}_analysis@timestamp.json');
  print('\nReports include:');
  print('  • Overall reliability statistics');
  print('  • List of flaky tests with reliability scores');
  print('  • Consistent failures with fix suggestions');
  print('  • Failure pattern distribution');
  print('  • Performance metrics for slow tests');

  print('\n' + '=' * 60);
  print('\n✨ Learn More');
  print('\nFor complete documentation, visit:');
  print('  https://pub.dev/packages/test_reporter');
  print('\nOr run: dart run test_reporter:analyze_tests --help\n');
}
