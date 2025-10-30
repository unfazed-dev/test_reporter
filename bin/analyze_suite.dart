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

  final orchestrator = TestOrchestrator(
    testPath: testPath,
    runs: int.parse(args['runs'] as String),
    performance: args['performance'] as bool,
    verbose: args['verbose'] as bool,
    parallel: args['parallel'] as bool,
  );

  try {
    await orchestrator.runAll();
    exit(0);
  } catch (e) {
    print('\n❌ Orchestrator failed: $e');
    exit(2);
  }
}
