#!/usr/bin/env dart

/// # Coverage Tool - Entry Point
///
/// Command-line entry point for the Coverage Analysis Tool.
/// All business logic is in lib/src/bin/analyze_coverage_lib.dart

import 'package:test_reporter/src/bin/analyze_coverage_lib.dart'
    as coverage_lib;

void main(List<String> args) {
  coverage_lib.main(args);
}
