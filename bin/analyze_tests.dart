#!/usr/bin/env dart

/// # Test Analyzer - Entry Point
///
/// Command-line entry point for the Test Analyzer Tool.
/// All business logic is in lib/src/bin/analyze_tests_lib.dart

import 'package:test_reporter/src/bin/analyze_tests_lib.dart' as analyzer_lib;

void main(List<String> args) {
  analyzer_lib.main(args);
}
