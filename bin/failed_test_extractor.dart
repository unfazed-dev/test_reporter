#!/usr/bin/env dart

/// # Failed Test Extractor - Entry Point
///
/// Command-line entry point for the Failed Test Extractor tool.
/// All business logic is in lib/src/bin/failed_test_extractor_lib.dart

import 'package:test_analyzer/src/bin/failed_test_extractor_lib.dart';

/// Main entry point for the failed test extractor
void main(List<String> arguments) async {
  final extractor = FailedTestExtractor();
  await extractor.run(arguments);
}
