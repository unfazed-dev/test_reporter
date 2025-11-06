#!/usr/bin/env dart

/// # Run All - Entry Point
///
/// Command-line entry point for the Unified Test Analysis Orchestrator.
/// All business logic is in lib/src/bin/analyze_suite_lib.dart

import 'dart:io';

import 'package:args/args.dart';
import 'package:test_reporter/src/bin/analyze_suite_lib.dart';

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      'path',
      abbr: 'p',
      help: 'Test path to analyze (default: test/)',
      defaultsTo: 'test',
    )
    ..addOption(
      'runs',
      abbr: 'r',
      help: 'Number of test runs for flaky detection',
      defaultsTo: '3',
    )
    ..addOption(
      'test-path',
      help: 'Explicit test path override (v3.0)',
    )
    ..addOption(
      'source-path',
      help: 'Explicit source path override (v3.0)',
    )
    ..addOption(
      'module-name',
      help: 'Override module name for reports (v3.0)',
    )
    ..addFlag(
      'performance',
      help: 'Enable performance profiling',
      negatable: false,
    )
    ..addFlag(
      'verbose',
      abbr: 'v',
      help: 'Verbose output',
      negatable: false,
    )
    ..addFlag(
      'parallel',
      help: 'Run tests in parallel',
      negatable: false,
    )
    ..addFlag(
      'checklist',
      help: 'Include actionable checklists in reports (default: enabled)',
      defaultsTo: true,
    )
    ..addFlag(
      'minimal-checklist',
      help: 'Generate compact checklist format',
      negatable: false,
    )
    ..addFlag(
      'help',
      abbr: 'h',
      help: 'Show this help message',
      negatable: false,
    );

  ArgResults args;
  try {
    args = parser.parse(arguments);
  } catch (e) {
    print('Error: $e\n');
    print(parser.usage);
    exit(2);
  }

  if (args['help'] as bool) {
    print('Unified Test Analysis Orchestrator');
    print('\nUsage: dart run_all.dart [test_path] [options]\n');
    print(parser.usage);
    exit(0);
  }

  // Get test path from positional argument or --path option
  String testPath;
  if (args.rest.isNotEmpty) {
    testPath = args.rest.first;
  } else {
    testPath = args['path'] as String;
  }

  // Validate test path exists (handle both files and directories)
  final pathExists = testPath.endsWith('.dart')
      ? File(testPath).existsSync()
      : Directory(testPath).existsSync();

  if (!pathExists) {
    print('❌ Error: Test path does not exist\n');
    print('Specified path: $testPath');
    print('  Status: ❌ does not exist');
    print('');
    print('💡 Usage Examples:');
    print('  # Analyze all tests');
    print('  dart run test_reporter:analyze_suite test/');
    print('');
    print('  # Analyze specific test directory');
    print('  dart run test_reporter:analyze_suite test/integration/');
    print('');
    print('  # Analyze specific test file');
    print(
        '  dart run test_reporter:analyze_suite test/unit/models/failure_types_test.dart');
    print('');
    print('  # With explicit overrides');
    print(
        '  dart run test_reporter:analyze_suite test/ --test-path=test/ --source-path=lib/src/');
    print('');
    print('  # With module name override');
    print(
        '  dart run test_reporter:analyze_suite test/ --module-name=my-suite');
    exit(2);
  }

  final orchestrator = TestOrchestrator(
    testPath: testPath,
    runs: int.parse(args['runs'] as String),
    performance: args['performance'] as bool,
    verbose: args['verbose'] as bool,
    parallel: args['parallel'] as bool,
    enableChecklist: args['checklist'] as bool,
    minimalChecklist: args['minimal-checklist'] as bool,
    explicitModuleName: args['module-name'] as String?,
    testPathOverride: args['test-path'] as String?,
    sourcePathOverride: args['source-path'] as String?,
  );

  try {
    await orchestrator.runAll();
    exit(0);
  } catch (e) {
    print('\n❌ Orchestrator failed: $e');
    exit(2);
  }
}
