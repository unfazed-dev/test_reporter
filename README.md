# Test Analyzer

Comprehensive Flutter/Dart test analysis toolkit with coverage analysis, flaky test detection, unified reporting, and modern Dart 3.x patterns.

## Features

- ✅ **Unified Orchestrator** - Run all analysis tools with a single command
- ✅ **Coverage Analysis** - Line & branch coverage with incremental git diff support
- ✅ **Test Analysis** - Flaky test detection, performance profiling, pattern recognition
- ✅ **Failed Test Extraction** - Smart extraction and batch rerun commands
- ✅ **Modern Dart Patterns** - Sealed classes, records, and pattern matching
- ✅ **Unified Reports** - Single file format with markdown + embedded JSON
- ✅ **Beautiful CLI** - Colored output, progress indicators, tables

## Installation

### From Git Repository
```yaml
dev_dependencies:
  test_analyzer:
    git:
      url: https://github.com/unfazed-dev/test_analyzer.git
      ref: main  # or specific tag like v2.0.0
```

### Local Development
```yaml
dev_dependencies:
  test_analyzer:
    path: /Users/your-username/Developer/packages/test_analyzer
```

After adding to `pubspec.yaml`, run:
```bash
dart pub get
```

## Quick Start

### Unified Orchestrator (Recommended)

The **unified orchestrator** runs coverage analysis and test analysis sequentially, then generates a combined report with smart insights:

```bash
# Basic usage - analyzes a specific path
dart run test_analyzer:run_all lib/ui/widgets

# With all options
dart run test_analyzer:run_all lib/ui/widgets \
  --runs=5 \
  --performance \
  --verbose \
  --parallel
```

**What it does:**
1. Runs `coverage_tool` on the specified path
2. Runs `test_analyzer` on the corresponding test path
3. Extracts JSON data from both reports
4. Generates a unified report with combined insights
5. Provides actionable recommendations

**Output:**
- Individual reports in `test_analyzer_reports/`
- Unified report: `test_analyzer_reports/{module}_unified_report@{timestamp}.md`

### Individual Tools

#### Coverage Analysis

Analyzes code coverage for a specific path:

```bash
# Basic coverage analysis
dart run test_analyzer:coverage_tool lib/src/features

# With minimum coverage threshold
dart run test_analyzer:coverage_tool lib/src/features --min-coverage 95

# Verbose output
dart run test_analyzer:coverage_tool lib/src/features --verbose
```

**Options:**
- `--min-coverage` - Minimum coverage threshold (default: 80%)
- `--verbose` - Show detailed output
- `--help` - Show help message

**Output:**
- Report: `test_analyzer_reports/{module}_test_report@{timestamp}.md`
- Contains: Coverage metrics, file analysis, uncovered lines, recommendations

#### Test Analysis

Analyzes test reliability and detects flaky tests:

```bash
# Basic test analysis
dart run test_analyzer:test_analyzer test/features

# Multiple test runs to detect flaky tests
dart run test_analyzer:test_analyzer test/features --runs=5

# With performance profiling
dart run test_analyzer:test_analyzer test/features --runs=5 --performance

# Run tests in parallel
dart run test_analyzer:test_analyzer test/features --parallel
```

**Options:**
- `--runs` - Number of test runs (default: 3, min: 2, max: 10)
- `--performance` - Enable performance profiling
- `--parallel` - Run tests in parallel
- `--verbose` - Show detailed output
- `--help` - Show help message

**Output:**
- Report: `test_analyzer_reports/{module}_test_report@{timestamp}.md`
- Contains: Pass rate, flaky tests, consistent failures, performance metrics, recommendations

#### Failed Test Extractor

Extracts failed test paths from test output and generates batch rerun commands:

```bash
dart run test_analyzer:failed_test_extractor
```

**Interactive:**
- Prompts for test output (paste and press Ctrl+D)
- Detects file paths from test failures
- Generates `flutter test` commands for batch rerun

## Report Format

All reports use a unified format:
- **Human-readable markdown** for easy review
- **Embedded JSON data** for machine parsing
- **Automatic directory creation** (`test_analyzer_reports/`)
- **Timestamp-based naming** for version history

### Report Structure

```markdown
# Module Name Test Report

## Executive Summary
- Key metrics and overview

## Detailed Analysis
- Coverage/test-specific analysis

## Recommendations
- Actionable next steps

---

## 📊 Machine-Readable Data

```json
{
  "metadata": { ... },
  "summary": { ... },
  "detailed_data": { ... }
}
```
```

### Extracting JSON from Reports

```dart
import 'package:test_analyzer/test_analyzer.dart';

// Read report file
final reportContent = File('test_analyzer_reports/module_report@1234.md').readAsStringSync();

// Extract JSON
final jsonData = ReportUtils.extractJsonFromReport(reportContent);

if (jsonData != null) {
  final metadata = jsonData['metadata'];
  final summary = jsonData['summary'];
  // Process data...
}
```

## Modern Dart Patterns

### Sealed Failure Types

The package uses sealed classes for type-safe failure pattern matching:

```dart
import 'package:test_analyzer/test_analyzer.dart';

final failure = detectFailureType(errorMessage, stackTrace);

switch (failure) {
  case AssertionFailure(:final message, :final expectedValue, :final actualValue):
    print('Assertion failed: expected $expectedValue, got $actualValue');

  case NullError(:final variableName):
    print('Null error on variable: $variableName');

  case TimeoutFailure(:final duration):
    print('Test timed out after $duration');

  case RangeError(:final index, :final validRange):
    print('Index $index out of range: $validRange');

  case TypeError(:final expectedType, :final actualType):
    print('Type error: expected $expectedType, got $actualType');

  case IOError(:final operation, :final path):
    print('IO error during $operation on $path');

  case NetworkError(:final endpoint, :final statusCode):
    print('Network error on $endpoint: $statusCode');

  case UnknownFailure(:final message):
    print('Unknown failure: $message');
}
```

**Available failure types:**
- `AssertionFailure` - Test assertion failures
- `NullError` - Null reference errors
- `TimeoutFailure` - Test timeouts
- `RangeError` - Index out of bounds
- `TypeError` - Type casting errors
- `IOError` - File/IO operations
- `NetworkError` - Network call failures
- `UnknownFailure` - Unclassified errors

### Record Types

Lightweight data structures for results:

```dart
import 'package:test_analyzer/test_analyzer.dart';

// Create analysis result
final result = successfulAnalysis(
  totalTests: 100,
  passedTests: 95,
  failedTests: 5,
);

// Destructure record
final (:totalTests, :passedTests, :failedTests) = result;

// Pattern match with helper
final message = handleAnalysisResult(
  result,
  onSuccess: (total, passed, failed) => 'Passed: $passed/$total',
  onError: (error) => 'Analysis failed: $error',
);
```

**Available record types:**
- `AnalysisResult` - Test analysis results
- `CoverageResult` - Coverage analysis results
- `TestFileResult` - Test file load results
- `TestRunResult` - Individual test run results
- `PerformanceMetrics` - Performance profiling data
- `CoverageSummary` - Coverage summary data
- `ReliabilityMetrics` - Test reliability metrics
- `FileCoverage` - Per-file coverage data

## CI/CD Integration

### GitHub Actions

Add to your workflow:

```yaml
name: Test Analysis

on: [push, pull_request]

jobs:
  analyze:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: dart-lang/setup-dart@v1
        with:
          sdk: stable

      - name: Install dependencies
        run: dart pub get

      - name: Run unified analysis
        run: dart run test_analyzer:run_all lib/src --runs=3

      - name: Upload reports
        uses: actions/upload-artifact@v3
        with:
          name: test-reports
          path: test_analyzer_reports/
```

### GitLab CI

```yaml
test_analysis:
  stage: test
  script:
    - dart pub get
    - dart run test_analyzer:run_all lib/src --runs=3
  artifacts:
    paths:
      - test_analyzer_reports/
    expire_in: 1 week
```

### Version Control

Add to `.gitignore` if you don't want to commit reports:
```gitignore
# Test analyzer reports (optional - can commit for history)
test_analyzer_reports/
```

## Troubleshooting

### Common Issues

**Q: Command not found**
```bash
# Solution: Ensure pub get has been run
dart pub get
```

**Q: Reports not being generated**
```bash
# Solution: Check write permissions in project directory
ls -la test_analyzer_reports/

# Directory is auto-created, but check parent permissions
ls -ld .
```

**Q: Coverage showing 0%**
```bash
# Solution: Ensure tests exist for the analyzed path
# If analyzing lib/src/features, tests should be in test/src/features

# Check test files exist
find test -name "*_test.dart"
```

**Q: Flaky test not detected**
```bash
# Solution: Increase number of runs
dart run test_analyzer:test_analyzer test/features --runs=10

# Minimum 2 runs required to detect flaky tests
```

**Q: Performance metrics not showing**
```bash
# Solution: Enable performance profiling
dart run test_analyzer:test_analyzer test/features --performance
```

**Q: Parallel execution slower**
```bash
# Solution: Parallel execution overhead may not benefit small test suites
# Use parallel only for large test suites (50+ tests)
dart run test_analyzer:test_analyzer test/features  # without --parallel
```

### Debugging

Enable verbose output for detailed information:

```bash
dart run test_analyzer:run_all lib/src --verbose
```

Check analyzer status:
```bash
dart analyze
```

Run package tests:
```bash
cd path/to/test_analyzer
dart test
```

## Performance Tips

1. **Use Unified Orchestrator** - More efficient than running tools separately
2. **Parallel Execution** - Use `--parallel` for large test suites (50+ tests)
3. **Optimize Run Count** - Balance flaky test detection (3-5 runs) vs speed
4. **Target Specific Paths** - Analyze specific modules instead of entire codebase
5. **Clean Old Reports** - Reports are auto-cleaned, but manual cleanup available:
   ```bash
   rm -rf test_analyzer_reports/*_old_*.md
   ```

## Examples

### Comprehensive Analysis

```bash
# Full analysis with all features
dart run test_analyzer:run_all lib/ui/widgets \
  --runs=5 \
  --performance \
  --verbose
```

### Quick Coverage Check

```bash
# Fast coverage analysis with threshold
dart run test_analyzer:coverage_tool lib/ui --min-coverage 90
```

### Detect Flaky Tests

```bash
# Run tests multiple times to detect flakiness
dart run test_analyzer:test_analyzer test/integration --runs=10
```

### CI Pipeline

```bash
# Recommended CI command - balance speed and reliability
dart run test_analyzer:run_all lib/src --runs=3 --parallel
```

## API Documentation

### Utilities

**FormattingUtils**
- `formatTimestamp()` - Format timestamp as HHMM_DDMMYY
- `formatDuration()` - Human-readable duration formatting
- `formatPercentage()` - Percentage formatting with precision
- `truncate()` - String truncation with ellipsis
- `generateBar()` - Progress bar generation

**PathUtils**
- `extractPathName()` - Extract module name from path
- `getRelativePath()` - Convert absolute to relative path
- `normalizePath()` - Normalize path separators

**ReportUtils**
- `getReportDirectory()` - Get/create report directory
- `cleanOldReports()` - Clean old reports by pattern
- `ensureDirectoryExists()` - Ensure directory exists
- `getReportPath()` - Generate full report path
- `writeUnifiedReport()` - Write markdown + JSON report
- `extractJsonFromReport()` - Extract JSON from report

**Constants**
- Performance thresholds
- Coverage thresholds
- ANSI color codes
- Default settings

**Extensions**
- `DurationFormatting` - Duration extension methods
- `DoubleFormatting` - Double extension methods
- `ListChunking` - List chunking utilities
- `ListUtils` - List utility methods

### Models

**Failure Types** (`lib/src/models/failure_types.dart`)
- 8 sealed failure types with pattern matching
- `detectFailureType()` - Detect failure from error message
- Context-specific detail extraction

**Result Types** (`lib/src/models/result_types.dart`)
- 8 record type aliases for results
- 21 helper functions for result handling
- Pattern matching support

## Development

### Setup

```bash
# Clone repository
git clone https://github.com/unfazed-dev/test_analyzer.git
cd test_analyzer

# Install dependencies
dart pub get

# Run tests
dart test

# Check coverage
dart test --coverage=coverage
dart pub global activate coverage
dart pub global run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info --report-on=lib
```

### Running Tests

```bash
# All tests
dart test

# Specific test file
dart test test/test_analyzer_test.dart

# With coverage
dart test --coverage
```

### Code Quality

```bash
# Format code
dart format .

# Analyze
dart analyze --fatal-infos

# Verify formatting
dart format --output=none --set-exit-if-changed .
```

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Follow code style (dart format)
4. Add tests for new features
5. Ensure all tests pass
6. Submit a pull request

## License

MIT License - see [LICENSE](LICENSE) file

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and release notes.

## Support

- **Issues**: https://github.com/unfazed-dev/test_analyzer/issues
- **Documentation**: https://github.com/unfazed-dev/test_analyzer
- **Examples**: See `example/` directory

---

**Version:** 2.0.0
**Dart SDK:** >=3.0.0 <4.0.0
**Maintainer:** unfazed-dev
