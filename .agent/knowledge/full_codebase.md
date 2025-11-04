# Full Codebase Context - test_reporter

**Last Updated**: January 2025
**Purpose**: Complete project overview for deep exploration and major refactoring tasks
**Token Estimate**: ~15-20K tokens

---

## Project Overview

**test_reporter** is a pure Dart package (NOT a Flutter app) providing comprehensive test reporting tools for Flutter/Dart projects.

- **Package Name**: test_reporter
- **Version**: 2.0.0
- **SDK**: Dart >=3.6.0 <4.0.0
- **Type**: CLI tool package
- **Repository**: https://github.com/unfazed-dev/test_reporter

---

## Package Executables

Defined in `pubspec.yaml`:

1. **analyze_coverage** → `bin/analyze_coverage.dart`
2. **analyze_tests** → `bin/analyze_tests.dart`
3. **extract_failures** → `bin/extract_failures.dart`
4. **analyze_suite** → `bin/analyze_suite.dart`

---

## Directory Structure with Line Counts

```
test_reporter/
├── bin/                                 # Entry points (4 files, ~60 lines total)
│   ├── analyze_coverage.dart           # 14 lines - Coverage tool entry
│   ├── analyze_suite.dart              # 90 lines - Suite orchestrator entry
│   ├── analyze_tests.dart              # 12 lines - Test analyzer entry
│   └── extract_failures.dart           # 15 lines - Failure extractor entry
│
├── lib/
│   ├── test_reporter.dart              # 23 lines - Main library export
│   └── src/
│       ├── bin/                         # CLI implementations (4 files, ~6,699 lines)
│       │   ├── analyze_coverage_lib.dart    # 2,199 lines - Coverage analyzer
│       │   ├── analyze_suite_lib.dart       # 1,046 lines - Suite orchestrator
│       │   ├── analyze_tests_lib.dart       # 2,663 lines - Test analyzer
│       │   └── extract_failures_lib.dart    # 791 lines - Failure extractor
│       │
│       ├── models/                      # Type definitions (2 files, ~400 lines)
│       │   ├── failure_types.dart      # ~250 lines - Sealed failure types
│       │   └── result_types.dart       # ~150 lines - Record type definitions
│       │
│       └── utils/                       # Shared utilities (5 files, ~800 lines)
│           ├── constants.dart          # Constants and defaults
│           ├── extensions.dart         # Extension methods
│           ├── formatting_utils.dart   # Output formatting
│           ├── path_utils.dart         # Path manipulation
│           └── report_utils.dart       # Report generation
│
├── scripts/                             # Development scripts (46 files)
│   ├── generate_integration_tests.dart
│   ├── fixture_generator.dart
│   └── ... (test generation & automation)
│
├── .agent/                              # AI documentation system
│   ├── README.md
│   ├── contexts/
│   ├── prompts/
│   ├── templates/
│   └── archives/
│
├── CHANGELOG.md                         # Version history
├── CLAUDE.md                            # AI session guide
├── LICENSE                              # MIT License
├── README.md                            # User documentation
└── pubspec.yaml                         # Package configuration
```

---

## Dependencies

### Production Dependencies (`pubspec.yaml`)

```yaml
dependencies:
  args: ^2.5.0              # CLI argument parsing
  cli_util: ^0.4.0          # CLI utilities
  collection: ^1.18.0       # Collection utilities
  glob: ^2.1.0              # File pattern matching
  io: ^1.0.4                # I/O utilities
  markdown: ^7.2.0          # Markdown generation
  mason_logger: ^0.3.0      # CLI logging/output
  path: ^1.9.0              # Path manipulation
```

### Development Dependencies

```yaml
dev_dependencies:
  coverage: ^1.9.0              # Coverage collection
  test: ^1.25.0                 # Testing framework
  very_good_analysis: ^6.0.0    # Linting rules
```

---

## Class & Type Hierarchy

### Sealed Classes (lib/src/models/failure_types.dart)

```
FailureType (sealed base class)
├── AssertionFailure
├── NullError
├── TimeoutFailure
├── TypeMismatch
├── AsyncError
├── StateError
├── NetworkError
├── FileSystemError
├── ParseError
├── InitializationError
├── DisposalError
├── ConfigurationError
└── UnknownFailure
```

Each failure type includes:
- `category`: String - Human-readable category name
- `suggestion`: String? - Fix suggestion
- Type-specific fields (message, location, variable names, etc.)

### Record Types (lib/src/models/result_types.dart)

```dart
typedef AnalysisResult = ({
  bool success,
  int totalTests,
  int passedTests,
  int failedTests,
  String? error,
});

typedef CoverageResult = ({
  bool success,
  double coverage,
  int totalLines,
  int coveredLines,
  String? error,
});

typedef TestFileResult = ({
  bool success,
  String filePath,
  int loadTimeMs,
  String? error,
});

// ... and more (see file for complete list)
```

### Main Analyzer Classes

#### TestAnalyzer (lib/src/bin/analyze_tests_lib.dart)

```dart
class TestAnalyzer {
  // Configuration
  final int runCount;
  final bool verbose;
  final bool interactive;
  final bool performanceMode;
  final bool watch;
  final bool parallel;

  // Key methods
  Future<int> run(List<String> targetFiles);
  Future<void> runTestsMultipleTimes();
  FailureType detectFailureType(String output);
  Future<void> generateReport();
}
```

**Purpose**: Detect flaky tests, analyze failure patterns, profile performance

**Key Features**:
- Multi-run testing (configurable runs, default: 3)
- Pattern recognition (13 failure types)
- Performance profiling (slow test detection)
- Interactive debugging mode
- Parallel execution
- Watch mode for continuous testing

#### CoverageAnalyzer (lib/src/bin/analyze_coverage_lib.dart)

```dart
class CoverageAnalyzer {
  // Configuration
  final String libPath;
  final String testPath;
  final bool autoFix;
  final bool branchCoverage;
  final bool incremental;
  final CoverageThresholds thresholds;

  // Key methods
  Future<void> analyze();
  Future<void> generateMissingTests();
  Future<void> generateReport();
}
```

**Purpose**: Analyze test coverage and auto-generate missing tests

**Key Features**:
- Line and branch coverage
- Auto-fix mode (generates test stubs)
- Incremental analysis (git diff)
- Coverage thresholds with validation
- Mutation testing support
- JSON export

#### FailedTestExtractor (lib/src/bin/extract_failures_lib.dart)

```dart
class FailedTestExtractor {
  // Configuration
  final bool autoRerun;
  final bool watch;
  final bool saveResults;
  final bool groupByFile;

  // Key methods
  Future<void> run(List<String> arguments);
  Future<TestResults> extractFailures(String testPath);
  Future<void> rerunFailedTests(List<FailedTest> tests);
  Future<void> generateReport(TestResults results);
}
```

**Purpose**: Extract and rerun only failing tests

**Key Features**:
- JSON reporter parsing
- Smart rerun command generation
- Batch processing by file
- Watch mode
- Detailed failure reports

#### TestOrchestrator (lib/src/bin/analyze_suite_lib.dart)

```dart
class TestOrchestrator {
  // Configuration
  final String testPath;
  final int runs;
  final bool performance;
  final bool verbose;
  final bool parallel;

  // Key methods
  Future<void> runAll();
  Future<bool> runCoverageTool();
  Future<bool> runTestAnalyzer();
  Future<void> generateUnifiedReport();
  String extractModuleName();
}
```

**Purpose**: Unified orchestration of all analysis tools

**Key Features**:
- Sequential execution of all tools
- Combined report generation
- Module name extraction
- Exit code aggregation

---

## Report Generation System

### Directory Structure

```
tests_reports/
├── tests/         # TestAnalyzer reports
├── coverage/      # CoverageAnalyzer reports
├── failures/      # FailedTestExtractor reports
└── suite/         # TestOrchestrator unified reports
```

### Naming Convention

**Pattern**: `{module_name}_{report_type}@HHMM_DDMMYY.{md|json}`

**Module suffix rules**:
- `-fo`: Folder analysis (e.g., `test/integration`)
- `-fi`: File analysis (e.g., `test/my_test.dart`)

**Examples**:
- `auth_service-fo_coverage@1435_041124.md`
- `user_test-fi_analysis@0920_041124.json`
- `all_tests-fo_suite@1200_041124.md`

### Report Management

**Automatic cleanup** via `ReportUtils.cleanOldReports()`:
- Groups reports by pattern
- Keeps latest report per pattern
- Deletes older duplicates
- Supports subdirectory organization

---

## Key Utilities

### ReportUtils (lib/src/utils/report_utils.dart)

```dart
class ReportUtils {
  static Future<String> getReportDirectory();
  static Future<void> cleanOldReports({
    required String pathName,
    required List<String> prefixPatterns,
    String? subdirectory,
    bool verbose,
    bool keepLatest,
  });
}
```

### FormattingUtils (lib/src/utils/formatting_utils.dart)

- ANSI color codes
- Progress bars
- Table formatting
- Percentage calculations

### PathUtils (lib/src/utils/path_utils.dart)

- Path normalization
- Module name extraction
- Test file detection

---

## Architecture Patterns

### 1. Entry Point Separation

**bin/*.dart** (minimal):
```dart
import 'package:test_reporter/src/bin/analyze_tests_lib.dart' as analyzer_lib;

void main(List<String> args) {
  analyzer_lib.main(args);
}
```

**lib/src/bin/*_lib.dart** (full implementation):
- Contains all business logic
- Testable and reusable
- Exportable as library

**Benefits**:
- Clean bin/ directory
- Logic can be imported by other packages
- Easier testing

### 2. Modern Dart 3+ Features

**Sealed Classes** for type-safe enumerations:
- Exhaustive pattern matching
- Compiler-enforced completeness
- Rich associated data

**Records** for multi-value returns:
- Lightweight and immutable
- Named fields with destructuring
- No class boilerplate

### 3. Self-Testing Strategy

**Meta-testing**: Tools test themselves
- Run suite analyzer on bin/
- Run coverage analyzer on lib/src
- Use fixture generation for consistency
- Script-based test automation

---

## Statistics

- **Total Dart files**: 28
- **Total lines of code**: ~6,699 (excluding scripts)
- **Number of classes**: 38
- **Number of sealed classes**: 13 (failure types)
- **Number of record types**: 8
- **CLI executables**: 4
- **Supported SDK**: Dart >=3.6.0

---

## Entry Points & Flow

### analyze_tests Flow

1. Parse CLI arguments (`args` package)
2. Create `TestAnalyzer` instance
3. Run tests N times (default: 3)
4. Collect failures and timings
5. Detect patterns using `detectFailureType()`
6. Generate reliability matrix
7. Write markdown + JSON reports
8. Return exit code (0 = all passed, 1 = failures, 2 = error)

### analyze_coverage Flow

1. Parse CLI arguments
2. Create `CoverageAnalyzer` instance
3. Run `dart test --coverage`
4. Parse `coverage/lcov.info`
5. Calculate line/branch coverage
6. If `--fix`: Generate missing test stubs
7. Write markdown + JSON reports
8. Validate against thresholds
9. Return exit code

### extract_failures Flow

1. Parse CLI arguments
2. Run tests with JSON reporter (`--reporter json`)
3. Parse JSON output for failures
4. Extract failed test info (name, file, error, stack trace)
5. Group by file if requested
6. Generate rerun commands
7. Auto-rerun if enabled
8. Write report with failure analysis
9. Return exit code

### analyze_suite Flow

1. Parse CLI arguments
2. Create `TestOrchestrator` instance
3. Run `analyze_coverage`
4. Run `analyze_tests`
5. Collect results from both tools
6. Extract module name from test path
7. Generate unified report combining both analyses
8. Return aggregated exit code

---

## Modern Dart Features in Use

### Pattern Matching

```dart
switch (failure) {
  case AssertionFailure(:final message, :final location):
    handleAssertion(message, location);
  case NullError(:final variableName):
    handleNullError(variableName);
  case TimeoutFailure(:final duration):
    handleTimeout(duration);
}
```

### Record Destructuring

```dart
final (success: ok, totalTests: count, error: err) = await analyze();
if (!ok) print('Error: $err');
```

### Sealed Class Exhaustiveness

```dart
String getSuggestion(FailureType failure) => switch (failure) {
  AssertionFailure() => 'Check test assertions',
  NullError() => 'Add null checks',
  TimeoutFailure() => 'Increase timeout or optimize code',
  // Compiler warns if any case is missing!
};
```

---

## Testing & Quality

### Linting

Uses `very_good_analysis` package with strict rules:
- All lint rules enabled
- No warnings allowed
- Format enforcement

### Self-Testing Commands

```bash
# Analyze the analyzers
dart run test_reporter:analyze_suite bin/ --runs=3

# Coverage of coverage tool
dart run test_reporter:analyze_coverage lib/src

# Extract failures from test run
dart run test_reporter:extract_failures test/
```

### Quality Gates

- `dart analyze` must show 0 issues
- `dart format --set-exit-if-changed` must pass
- All 4 executables must run successfully
- Self-tests must pass

---

## Common File Locations

- **Main exports**: `lib/test_reporter.dart`
- **Failure types**: `lib/src/models/failure_types.dart`
- **Result types**: `lib/src/models/result_types.dart`
- **Report utils**: `lib/src/utils/report_utils.dart`
- **Entry points**: `bin/*.dart`
- **Implementations**: `lib/src/bin/*_lib.dart`
- **Scripts**: `scripts/*.dart`
- **Documentation**: `.agent/`, `CLAUDE.md`, `README.md`

---

## Publishing Workflow

1. Update version in `pubspec.yaml`
2. Update `CHANGELOG.md`
3. Run quality checks (`dart analyze`, `dart format`)
4. Test all executables
5. Run `dart pub publish --dry-run`
6. Run `dart pub publish`
7. Create GitHub release with tag

---

## Token Usage Guidance

**Loading this file**: ~15-20K tokens

**Best used for**:
- First-time project exploration
- Major refactoring
- Architecture decisions
- Understanding the "big picture"

**Not needed for**:
- Small bug fixes
- Adding single failure type
- Simple report modifications

**Recommended pairings**:
- With `analyzer_architecture.md` for deep dive
- With specific SOP for implementation
- At start of large tasks (6+ hours)
