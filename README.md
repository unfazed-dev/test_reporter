# test_reporter

[![License: BSD-3-Clause](https://img.shields.io/badge/License-BSD_3--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)

Comprehensive Flutter/Dart test reporting toolkit providing coverage analysis, flaky test detection, failure extraction, and unified reporting. Built for developers who want deep insights into their test suites.

## What's New in v3.1

**Interactive Actionable Checklists** in all reports!

### ✅ Actionable Checklists
- **GitHub-flavored markdown checklists** in all 4 analyzer reports
- **Interactive checkboxes** for tracking progress in VS Code and GitHub issues/PRs
- **3-tier priority system** for test reliability (🔴 critical, 🟠 important, 🟡 optional)
- **Copy-pasteable commands** for each action item
- **Progress tracking** with completion percentages
- **CLI flags**: `--no-checklist` (disable) or `--minimal-checklist` (compact format)

### ChecklistUtils Library
- New utility classes for creating interactive checklists
- Exported in `package:test_reporter/test_reporter.dart`
- 31 comprehensive unit tests (100% passing)

See examples below in each tool section and [CHANGELOG.md](CHANGELOG.md) for details.

---

## What's New in v3.0

**Major architectural improvements and enhanced features:**

### Foundation Utilities
- **PathResolver**: Automatic bidirectional path inference (test ↔ source)
- **ModuleIdentifier**: Consistent qualified module naming (`module-fo/fi/pr`)
- **ReportManager**: Unified report generation with automatic cleanup
- **170 lines** of duplicate code removed across all tools

### Enhanced CLI Experience
- **Smart Path Detection**: Provide test OR source path - the other is automatically inferred
- **Explicit Overrides**: `--test-path` and `--source-path` flags for manual control
- **Module Naming**: `--module-name` flag to customize report names
- **Input Validation**: Clear error messages with existence checks and helpful examples

### Cross-Tool Features
- **ReportRegistry**: Track and query reports across all tools
- **Consistent Naming**: All reports follow `{module}-{fo|fi|pr}_{tool}_{type}@{timestamp}.{md|json}`
- **Automatic Cleanup**: Old reports removed, keeping only latest per pattern

### Breaking Changes
- Report names now include qualifiers: `-fo` (folder), `-fi` (file), `-pr` (project)
- Path inference uses new PathResolver (may differ in edge cases)

See [CHANGELOG.md](CHANGELOG.md) for complete details.

---

## Features

### 🧪 Test Analyzer (`analyze_tests`)
- **Flaky Test Detection** - Runs tests multiple times to identify intermittent failures
- **Pattern Recognition** - Detects null errors, timeouts, assertions, type errors, etc.
- **Performance Profiling** - Identifies slow tests and performance bottlenecks
- **Interactive Debugging** - Deep dive into specific test failures with source viewing
- **Parallel Execution** - Run tests in parallel with configurable worker pool
- **Watch Mode** - Continuous testing with auto re-run on file changes
- **Actionable Checklists** - 3-tier priority checklists (🔴 failing, 🟠 flaky, 🟡 slow)

### 📊 Coverage Analyzer (`analyze_coverage`)
- **Line Coverage** - Comprehensive line-by-line coverage analysis
- **Auto-Fix Generation** - Automatically generate missing test cases with `--fix`
- **Coverage Thresholds** - Set minimum/warning thresholds with failure on decrease
- **JSON Export** - Machine-readable coverage reports
- **Actionable Checklists** - File-by-file test coverage action items

### 📋 Failure Extractor (`extract_failures`)
- **Failed Test Detection** - Parses JSON reporter output to identify failures
- **Smart Rerun Commands** - Generates optimized commands to rerun only failed tests
- **Batch Processing** - Groups failed tests by file for efficient re-execution
- **Watch Mode** - Continuously monitor and rerun failed tests on file changes
- **Detailed Reporting** - Comprehensive failure analysis and statistics
- **Actionable Checklists** - 3-step triage workflow per failing test

### 🚀 Suite Analyzer (`analyze_suite`)
- **Unified Orchestrator** - Runs all analysis tools in sequence
- **Combined Reports** - Single comprehensive report with all insights
- **Configurable Runs** - Set number of test runs for flaky detection
- **Performance Profiling** - Enable performance analysis across all tools
- **Actionable Checklists** - Master 3-phase workflow combining all action items
- **Verbose Output** - Detailed logging for debugging

## Installation

### Global Activation

Install globally to use across all projects:

```bash
dart pub global activate test_reporter
```

Then run commands directly:

```bash
analyze_tests --runs=5
analyze_coverage --fix
extract_failures test/
analyze_suite --performance
```

### Project Dependency

Add to your `pubspec.yaml`:

```yaml
dev_dependencies:
  test_reporter: ^3.1.0
```

Then run:

```bash
dart pub get
```

Use with `dart run`:

```bash
dart run test_reporter:analyze_tests --runs=5
dart run test_reporter:analyze_coverage --fix
dart run test_reporter:extract_failures test/
dart run test_reporter:analyze_suite --performance
```

## Quick Start

### Analyze Test Reliability

```bash
# Basic analysis - run tests 3 times to detect flaky tests
dart run test_reporter:analyze_tests

# Run 5 times with performance profiling
dart run test_reporter:analyze_tests --runs=5 --performance

# Analyze specific test file
dart run test_reporter:analyze_tests test/my_test.dart --verbose

# Parallel execution with 8 workers
dart run test_reporter:analyze_tests --parallel --workers=8

# Watch mode for continuous testing
dart run test_reporter:analyze_tests --watch

# Custom module name for reports
dart run test_reporter:analyze_tests --module-name my-feature
```

### Analyze Test Coverage

```bash
# Basic coverage analysis - provide test path, source auto-inferred
dart run test_reporter:analyze_coverage test/

# Or provide source path, test path auto-inferred
dart run test_reporter:analyze_coverage lib/src/

# With auto-fix generation for missing tests
dart run test_reporter:analyze_coverage --fix

# Analyze specific module with explicit paths
dart run test_reporter:analyze_coverage test/auth --source-path lib/src/auth

# Set coverage thresholds
dart run test_reporter:analyze_coverage --min-coverage=80 --warn-coverage=90

# Exclude generated files
dart run test_reporter:analyze_coverage --exclude "*.g.dart" --exclude "*.freezed.dart"

# JSON export with thresholds
dart run test_reporter:analyze_coverage --json --min-coverage=80

# Custom module name
dart run test_reporter:analyze_coverage --module-name auth-service
```

### Extract Failed Tests

```bash
# Extract and rerun failed tests
dart run test_reporter:extract_failures test/

# List failures without rerunning
dart run test_reporter:extract_failures test/ --list-only

# Watch mode with saved results
dart run test_reporter:extract_failures test/ --watch --save-results

# With verbose output
dart run test_reporter:extract_failures test/ --verbose
```

### Run Complete Suite

```bash
# Run all tools with defaults
dart run test_reporter:analyze_suite

# Specific test path with 5 runs
dart run test_reporter:analyze_suite test/integration --runs=5

# Enable performance profiling and parallel execution
dart run test_reporter:analyze_suite --performance --parallel

# Verbose output for debugging
dart run test_reporter:analyze_suite --verbose
```

## Detailed Usage

### Test Analyzer Options

```bash
Usage: dart test_analyzer.dart [options] [test_files...]

Options:
  --verbose, -v        Show detailed output and stack traces
  --interactive, -i    Enter interactive debug mode for failed tests
  --performance, -p    Track and report test performance metrics
  --watch, -w          Watch for changes and re-run analysis
  --parallel           Run tests in parallel for faster execution
  --runs=N             Number of test runs (default: 3)
  --slow=N             Slow test threshold in seconds (default: 1.0)
  --workers=N          Max parallel workers (default: 4)
  --no-fixes           Disable fix suggestions
  --module-name        Custom module name for reports
  --test-path          Override test path (for path resolution)
  --help, -h           Show this help message
```

### Coverage Analyzer Options

```bash
Usage: analyze_coverage [options] [module_path]

Basic Options:
  --lib <path>          Path to source files (default: lib/src, alias: --source-path)
  --test <path>         Path to test files (default: test, alias: --test-path)
  --source-path         Alias for --lib (explicit source path override)
  --test-path           Explicit test path override
  --module-name         Custom module name for reports
  --fix                 Generate missing test cases automatically
  --verbose, -v         Enable verbose output for detailed debugging
  --no-report           Skip generating coverage report
  --help, -h            Show this help message

Advanced Options:
  --json                Export JSON report
  --exclude <pattern>   Exclude files matching pattern (repeatable)
  --baseline <file>     Compare against baseline coverage
  --min-coverage <n>    Minimum coverage threshold (0-100)
  --warn-coverage <n>   Warning coverage threshold (0-100)
  --fail-on-decrease    Fail if coverage decreases from baseline
```

### Failure Extractor Options

```bash
Usage: flutter pub run analyzer/failed_test_extractor.dart [options] <test_path>

Options:
  -h, --help               Show usage information
  -l, --list-only          List failed tests without rerunning them
  -r, --[no-]auto-rerun    Automatically rerun failed tests after extraction
  -w, --watch              Watch mode: continuously monitor and rerun
  -s, --save-results       Save detailed failure report to file
  -v, --verbose            Enable verbose output
  -g, --group-by-file      Group failed tests by file for batch rerun
  -t, --timeout            Test timeout in seconds (default: 120)
  -p, --parallel           Run tests in parallel
      --max-failures       Maximum failures to extract (0 = unlimited)
```

### Suite Analyzer Options

```bash
Usage: dart run_all.dart [test_path] [options]

Options:
  -p, --path           Test path to analyze (default: test/)
  -r, --runs           Number of test runs for flaky detection (default: 3)
      --performance    Enable performance profiling
  -v, --verbose        Verbose output
      --parallel       Run tests in parallel
      --module-name    Custom module name for reports
      --test-path      Override test path (for path resolution)
      --source-path    Override source path (for path resolution)
  -h, --help           Show this help message
```

## Report Output

All tools generate reports in the `tests_reports/` directory:

```
tests_reports/
├──  tests/         # Test reliability reports (analyze_tests)
├──  coverage/      # Coverage analysis reports (analyze_coverage)
├──  failures/      # Failed test extraction reports (extract_failures)
└──  suite/         # Unified suite reports (analyze_suite)
```

### Report Naming Convention

Reports follow this pattern:
```
{module_name}-{qualifier}_report_{type}@HHMM_DDMMYY.{md|json}
```

**Qualifiers**:
- `-fo`: Folder analysis (e.g., `test/auth/` → `auth-fo`)
- `-fi`: File analysis (e.g., `test/auth_test.dart` → `auth-fi`)

**Examples**:
- `auth-fo_report_coverage@1435_041125.md` (folder coverage analysis)
- `auth-service-fi_report_tests@0920_041125.json` (file test analysis)
- `test-fo_report_suite@1000_041125.md` (project-wide suite report)

**Module Name Generation**:
- Automatically extracted from input path using ModuleIdentifier
- Underscores converted to hyphens for consistency
- Override with `--module-name` flag if needed

### Report Formats

- **Markdown (`.md`)** - Human-readable with formatting, colors, tables
- **JSON (`.json`)** - Machine-parseable for CI/CD integration

### Report Management

- **Automatic cleanup** - Old reports are automatically removed, keeping only the latest per pattern
- **Subdirectories** - Reports organized by tool type for easy navigation
- **Timestamped** - Each report includes generation timestamp

## Architecture

### v3.0 Foundation Utilities

All tools now use centralized utilities for consistency:

**PathResolver** (`lib/src/utils/path_resolver.dart`):
- Automatic bidirectional path inference (test ↔ source)
- Validates path existence
- Handles edge cases (Windows vs Unix paths, nested directories)

**ModuleIdentifier** (`lib/src/utils/module_identifier.dart`):
- Consistent qualified module naming
- Generates `-fo` (folder) and `-fi` (file) suffixes
- Parses qualified names back to components

**ReportManager** (`lib/src/utils/report_manager.dart`):
- Unified report generation (markdown + JSON)
- Automatic cleanup of old reports
- Configurable keep count (default: keep latest 1)

**ReportRegistry** (`lib/src/utils/report_registry.dart`):
- Cross-tool report discovery
- Query reports by toolName, reportType, or moduleName
- Session-wide report tracking

**ChecklistUtils** (`lib/src/utils/checklist_utils.dart`):
- Interactive GitHub-flavored markdown checklists
- 3-tier priority system (critical, important, optional)
- Reusable components for all 4 analyzers

### Entry Point Pattern

All executables follow a consistent separation pattern:
- **bin/*.dart** - Minimal entry points that delegate to library implementations
- **lib/src/bin/*_lib.dart** - Actual business logic and implementation

This keeps bin/ clean and allows logic to be tested and reused as a library.

### Modern Dart Features

Built with Dart 3+ features:

**Sealed Classes** - Type-safe failure categorization with exhaustive pattern matching:
```dart
sealed class FailureType {
  const FailureType();
}

final class AssertionFailure extends FailureType { ... }
final class NullError extends FailureType { ... }
final class TimeoutFailure extends FailureType { ... }
```

**Records** - Lightweight multi-value returns:
```dart
typedef AnalysisResult = ({
  bool success,
  int totalTests,
  int passedTests,
  int failedTests,
  String? error,
});

// Usage with destructuring
final (success: ok, totalTests: count) = await runAnalysis();
```

## Contributing

Contributions are welcome!


### Development Setup

```bash
# Clone repository
git clone https://github.com/unfazed-dev/test_reporter.git
cd test_reporter

# Install dependencies
dart pub get

# Run analyzer
dart analyze

# Format code
dart format .
```

## License

BSD 3 License - see [LICENSE](LICENSE) file for details.

## Links

- **Repository**: https://github.com/unfazed-dev/test_reporter
- **Issues**: https://github.com/unfazed-dev/test_reporter/issues
- **Pub.dev**: https://pub.dev/packages/test_reporter

## Support

For bugs, feature requests, or questions:
1. Check existing [issues](https://github.com/unfazed-dev/test_reporter/issues)
2. Create a new issue with detailed information

---

Made with ❤️ for the Flutter/Dart community

---

Authored and orchestrated by **Evan Pierre Louis - (unfazed-dev)**, with pair programming powered by [Claude Code](https://claude.com/claude-code) from Anthropic.
