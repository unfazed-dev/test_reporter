# test_reporter Examples

This directory contains working examples for all 4 CLI tools included in the test_reporter package.

## Available Examples

| Example File | Tool | Description |
|-------------|------|-------------|
| [`analyze_tests_example.dart`](analyze_tests_example.dart) | analyze_tests | Detect flaky tests by running tests multiple times |
| [`analyze_coverage_example.dart`](analyze_coverage_example.dart) | analyze_coverage | Analyze test coverage and generate missing tests |
| [`extract_failures_example.dart`](extract_failures_example.dart) | extract_failures | Extract failed tests and generate rerun commands |
| [`analyze_suite_example.dart`](analyze_suite_example.dart) | analyze_suite | Run complete test suite analysis |

## Running Examples

Each example can be run directly from the command line:

```bash
# Run individual examples
dart run example/analyze_tests_example.dart
dart run example/analyze_coverage_example.dart
dart run example/extract_failures_example.dart
dart run example/analyze_suite_example.dart
```

## What You'll Learn

### analyze_tests_example.dart
- How to detect flaky tests
- Running tests multiple times
- Generating reliability reports
- Performance profiling

### analyze_coverage_example.dart
- Analyzing test coverage
- Finding uncovered code
- Auto-generating test stubs
- Setting coverage thresholds

### extract_failures_example.dart
- Extracting failed tests from test runs
- Generating targeted rerun commands
- Grouping failures by file
- Watch mode for continuous testing

### analyze_suite_example.dart
- Running unified test suite analysis
- Combining coverage and reliability data
- Generating comprehensive reports
- Module-based analysis

## Integration with Your Project

All examples use `package:` imports to demonstrate real-world usage:

```dart
import 'package:test_reporter/test_reporter.dart';
```

This is exactly how you would import test_reporter in your own projects.

## More Information

For complete documentation, see the main [README.md](../README.md) in the package root.
