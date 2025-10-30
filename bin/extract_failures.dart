#!/usr/bin/env dart

/// # Failed Test Extractor - Entry Point
///
/// Command-line entry point for the Failed Test Extractor tool.
/// All business logic is in lib/src/bin/extract_failures_lib.dart

import 'package:test_reporter/src/bin/extract_failures_lib.dart';

/// Main entry point for the failed test extractor
void main(List<String> arguments) async {
  final extractor = FailedTestExtractor();
  await extractor.run(arguments);
}
