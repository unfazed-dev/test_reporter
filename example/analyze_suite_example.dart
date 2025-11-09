/// Example: Using analyze_suite for unified test analysis
///
/// This demonstrates the suite orchestrator which:
/// - Runs both coverage and reliability analysis
/// - Combines results into a unified report
/// - Provides comprehensive test quality metrics
/// - Generates actionable insights
/// - Perfect for CI/CD and pre-commit checks
///
/// Run this example:
/// ```bash
/// dart run example/analyze_suite_example.dart
/// ```

// ignore_for_file: avoid_print

import 'dart:io';

Future<void> main() async {
  print('🎯 Test Suite Analyzer Example\n');
  print('=' * 60);

  // Introduction
  print('\nThe suite analyzer orchestrates multiple analysis tools:');
  print('  1. analyze_coverage - Test coverage analysis');
  print('  2. analyze_tests - Test reliability analysis');
  print('  3. Combined reporting - Unified insights');

  // Example 1: Basic suite analysis
  print('\n' + '=' * 60);
  print('\n📌 Example 1: Analyze entire test suite\n');
  print('Command equivalent:');
  print('  dart run test_reporter:analyze_suite test/');
  print('\nRuns both coverage and reliability analysis, then generates:');
  print('  • Coverage metrics');
  print('  • Flaky test detection');
  print('  • Combined quality score');
  print('  • Unified recommendations');

  // Example 2: Quick analysis with minimal runs
  print('\n' + '=' * 60);
  print('\n📌 Example 2: Quick suite check (2 runs)\n');
  print('Command equivalent:');
  print('  dart run test_reporter:analyze_suite test/ --runs=2');
  print('\nFaster analysis with 2 test runs instead of default 3.');
  print('Good for pre-commit checks!');

  // Example 3: Comprehensive analysis
  print('\n' + '=' * 60);
  print('\n📌 Example 3: Thorough analysis with performance profiling\n');
  print('Command equivalent:');
  print('  dart run test_reporter:analyze_suite test/ --runs=5 --performance');
  print('\nPerforms 5 runs and includes performance metrics.');
  print('Detects flaky tests with higher confidence.');

  // Example 4: Verbose output for debugging
  print('\n' + '=' * 60);
  print('\n📌 Example 4: Verbose analysis with detailed logs\n');
  print('Command equivalent:');
  print('  dart run test_reporter:analyze_suite test/ --verbose');
  print('\nProvides detailed output from all sub-tools.');
  print('Useful for troubleshooting issues.');

  // Example 5: Parallel execution
  print('\n' + '=' * 60);
  print('\n📌 Example 5: Faster analysis with parallel execution\n');
  print('Command equivalent:');
  print('  dart run test_reporter:analyze_suite test/ --parallel');
  print('\nRuns tests in parallel for faster execution.');
  print('Great for large test suites!');

  // Example 6: Specific directory or file
  print('\n' + '=' * 60);
  print('\n📌 Example 6: Analyze specific test directory\n');
  print('Command equivalent:');
  print('  dart run test_reporter:analyze_suite test/unit');
  print('\nFocuses analysis on unit tests only.');

  // Real-world example
  print('\n' + '=' * 60);
  print('\n🚀 Running Real Suite Analysis (if tests exist)...\n');

  if (await Directory('test').exists()) {
    print(
        'Executing: dart run test_reporter:analyze_suite test/unit --runs=2\n');
    print('(This may take a minute...)\n');

    final stopwatch = Stopwatch()..start();

    final result = await Process.run(
      'dart',
      [
        'run',
        'test_reporter:analyze_suite',
        'test/unit',
        '--runs=2',
      ],
    );

    stopwatch.stop();

    if (result.exitCode == 0) {
      print('✅ Suite analysis completed in ${stopwatch.elapsed.inSeconds}s!');
      print('\nSample output:');
      final lines = result.stdout.toString().split('\n');
      print(lines.take(30).join('\n'));
    } else {
      print(
          '⚠️ Analysis completed with issues (exit code: ${result.exitCode})');
      print('Time: ${stopwatch.elapsed.inSeconds}s');
      print(result.stderr);
    }
  } else {
    print('⚠️ No test/ directory found.');
    print('Run this example from a Dart package root directory.');
  }

  print('\n' + '=' * 60);
  print('\n📚 Report Output');
  print('\nThe suite analyzer generates reports in:');
  print('  tests_reports/suite/{module}_suite@timestamp.md (unified report)');
  print('\nUnified report includes:');
  print('  • Executive summary');
  print('  • Coverage analysis results');
  print('  • Reliability analysis results');
  print('  • Combined quality score');
  print('  • Prioritized action items');
  print('  • Recommendations for improvement');

  print('\n' + '=' * 60);
  print('\n💡 CI/CD Integration');
  print('\nPerfect for continuous integration:');
  print('\n# .github/workflows/test.yml');
  print('- name: Analyze Test Suite');
  print('  run: dart run test_reporter:analyze_suite test/');
  print('\nThe suite analyzer:');
  print('  ✅ Returns exit code 0 if all quality checks pass');
  print('  ❌ Returns exit code 1 if tests fail or coverage is low');
  print('  📊 Generates reports for team review');

  print('\n' + '=' * 60);
  print('\n🎯 Best Practices');
  print('\n1. Pre-commit: Quick check with --runs=2');
  print('2. CI/CD: Full analysis with --runs=3 (default)');
  print('3. Weekly: Thorough analysis with --runs=5 --performance');
  print('4. Debug: Use --verbose to understand what each tool does');

  print('\n' + '=' * 60);
  print('\n⚙️ What Happens Behind the Scenes');
  print('\nThe suite analyzer orchestrates:');
  print('  1. analyze_coverage lib/src → Coverage metrics');
  print('  2. analyze_tests test/ → Reliability metrics');
  print('  3. Report aggregation → Unified insights');
  print('  4. Quality scoring → Overall assessment');

  print('\n' + '=' * 60);
  print('\n✨ Learn More');
  print('\nFor complete documentation, visit:');
  print('  https://pub.dev/packages/test_reporter');
  print('\nOr run: dart run test_reporter:analyze_suite --help\n');
}
