# Analyzer Architecture - test_reporter

**Last Updated**: January 2025
**Purpose**: Deep understanding of how the 4 analyzer tools work
**Token Estimate**: ~10-15K tokens

---

## Overview

test_reporter provides 4 CLI analyzer tools, each following the same architectural pattern:

1. **analyze_tests** - Test reliability and flaky test detection
2. **analyze_coverage** - Test coverage analysis with auto-fix
3. **extract_failures** - Failed test extraction and rerun
4. **analyze_suite** - Unified orchestration of all tools

---

## Entry Point Pattern

All executables follow a **separation of concerns** pattern:

### bin/*.dart (Entry Points)

**Purpose**: Minimal CLI entry points that delegate to library code

**Pattern**:
```dart
#!/usr/bin/env dart

import 'package:test_reporter/src/bin/{tool}_lib.dart' as lib;

void main(List<String> args) {
  lib.main(args);
}
```

**Benefits**:
1. Keeps bin/ directory clean and simple
2. Allows logic to be imported as a library
3. Makes code testable
4. Enables reuse in other packages

### lib/src/bin/*_lib.dart (Implementations)

**Purpose**: Full business logic implementation

**Contains**:
- Main class (e.g., `TestAnalyzer`, `CoverageAnalyzer`)
- CLI argument parsing
- Core analysis logic
- Report generation
- Error handling

**Can be imported**:
```dart
import 'package:test_reporter/src/bin/analyze_tests_lib.dart';

final analyzer = TestAnalyzer(runCount: 5, verbose: true);
await analyzer.run(['test/my_test.dart']);
```

---

## 1. TestAnalyzer Architecture

**File**: `lib/src/bin/analyze_tests_lib.dart` (2,663 lines)
**Entry**: `bin/analyze_tests.dart` (12 lines)

### Core Responsibility

Detect flaky tests by running tests multiple times and analyzing failure patterns.

### Class Structure

```dart
class TestAnalyzer {
  // Configuration
  final int runCount;              // Number of test runs (default: 3)
  final bool verbose;              // Detailed output
  final bool interactive;          // Interactive debug mode
  final bool performanceMode;      // Track performance metrics
  final bool watch;                // Watch mode for continuous testing
  final bool parallel;             // Parallel test execution
  final int maxWorkers;            // Worker pool size (default: 4)

  // Data structures
  final Map<String, TestRun> testRuns = {};
  final Map<String, List<TestFailure>> failures = {};
  final Map<String, TestPerformance> performance = {};
  final Map<String, FailurePattern> patterns = {};

  // Key methods
  Future<int> run(List<String> targetFiles);
  Future<void> runTestsMultipleTimes();
  FailureType detectFailureType(String output);
  void analyzeFailurePatterns();
  void calculateReliabilityScores();
  Future<void> generateReport();
}
```

### Workflow

```
1. Parse CLI arguments (args package)
   ↓
2. Create TestAnalyzer instance with configuration
   ↓
3. Clean old reports for this test path
   ↓
4. Run tests N times (runCount)
   │
   ├─→ For each run:
   │   ├─ Execute: dart test [files] --reporter json
   │   ├─ Parse JSON output
   │   ├─ Collect test results (pass/fail/skip)
   │   ├─ Record timings
   │   └─ Detect failure types
   │
   ↓
5. Analyze results across all runs
   │
   ├─ Identify consistent failures (failed every run)
   ├─ Identify flaky tests (intermittent failures)
   ├─ Calculate reliability scores (0-100%)
   ├─ Detect failure patterns (null, timeout, assertion, etc.)
   └─ Profile performance (slow tests)
   │
   ↓
6. Generate suggestions based on patterns
   ↓
7. Generate reports (markdown + JSON)
   │
   ├─ Summary statistics
   ├─ Consistent failures with fixes
   ├─ Flaky tests with reliability scores
   ├─ Failure pattern distribution
   ├─ Performance metrics
   └─ Actionable insights
   │
   ↓
8. Return exit code:
   - 0: All tests passed consistently
   - 1: Some tests failed
   - 2: Analysis error
```

### Pattern Detection

**Method**: `detectFailureType(String output)` returns `FailureType`

Uses regex patterns to classify failures into 13 sealed class types:

```dart
// Null errors
if (output.contains('NoSuchMethodError') && output.contains('null')) {
  return NullError(...);
}

// Timeouts
if (output.contains('TimeoutException') || output.contains('timed out')) {
  return TimeoutFailure(...);
}

// Assertions
if (output.contains('Expected:') && output.contains('Actual:')) {
  return AssertionFailure(...);
}

// ... 10 more patterns
```

### Performance Profiling

Tracks timing for each test:

```dart
class TestPerformance {
  final List<Duration> durations = [];
  Duration get average => ...;
  Duration get min => ...;
  Duration get max => ...;
  bool isSlow(Duration threshold) => average > threshold;
}
```

Default slow threshold: 1.0 second (configurable with `--slow`)

### Reliability Scoring

```dart
double calculateReliability(String testName) {
  final runs = testRuns[testName];
  final passes = runs.where((r) => r.passed).length;
  return (passes / runCount) * 100.0;
}

// Scores:
// 100% = Always passes (reliable)
// 0% = Always fails (consistent failure)
// 50-99% = Flaky (intermittent)
```

---

## 2. CoverageAnalyzer Architecture

**File**: `lib/src/bin/analyze_coverage_lib.dart` (2,199 lines)
**Entry**: `bin/analyze_coverage.dart` (14 lines)

### Core Responsibility

Analyze test coverage and optionally generate missing tests.

### Class Structure

```dart
class CoverageAnalyzer {
  // Configuration
  final String libPath;            // Source files (default: lib/src)
  final String testPath;           // Test files (default: test)
  final bool autoFix;              // Generate missing tests
  final bool branchCoverage;       // Include branch coverage
  final bool incremental;          // Only changed files (git diff)
  final bool mutationTesting;      // Run mutation testing
  final bool watchMode;            // Continuous monitoring
  final bool parallel;             // Parallel execution
  final CoverageThresholds thresholds;

  // Key methods
  Future<void> analyze();
  Future<Map<String, FileCoverage>> parseLcov(String lcovPath);
  Future<void> generateMissingTests();
  Future<void> generateReport();
  bool validateThresholds(double coverage);
}

class CoverageThresholds {
  final double minimum;            // Minimum required (default: 80%)
  final double warning;            // Warning threshold (default: 90%)
  final bool failOnDecrease;       // Fail if coverage drops

  bool validate(double coverage, {double? baseline});
}
```

### Workflow

```
1. Parse CLI arguments
   ↓
2. Create CoverageAnalyzer instance
   ↓
3. Clean old coverage reports
   ↓
4. Collect coverage data
   │
   ├─ Run: dart test --coverage
   ├─ Generate: coverage/lcov.info
   └─ Parse LCOV format
   │
   ↓
5. Analyze coverage
   │
   ├─ Calculate line coverage
   ├─ Calculate branch coverage (if enabled)
   ├─ Identify uncovered files
   ├─ Identify partially covered files
   └─ Compare to thresholds
   │
   ↓
6. Auto-fix mode (if --fix)
   │
   ├─ Scan lib/ for files without tests
   ├─ Generate test file stubs
   ├─ Add basic test structure
   └─ Report generated files
   │
   ↓
7. Generate reports (markdown + JSON)
   │
   ├─ Coverage summary
   ├─ Coverage by file
   ├─ Uncovered lines
   ├─ Coverage badge
   └─ Generated tests (if --fix)
   │
   ↓
8. Return exit code:
   - 0: Coverage meets thresholds
   - 1: Coverage below threshold
   - 2: Analysis error
```

### LCOV Parsing

```dart
Future<Map<String, FileCoverage>> parseLcov(String lcovPath) {
  // Parse format:
  // SF:<source file>
  // DA:<line>,<hits>
  // LF:<lines found>
  // LH:<lines hit>
  // end_of_record

  // Returns:
  // {
  //   'lib/src/utils/report_utils.dart': FileCoverage(
  //     totalLines: 100,
  //     coveredLines: 85,
  //     coverage: 85.0%,
  //     uncoveredLines: [10, 15, 42, ...]
  //   ),
  //   ...
  // }
}
```

### Auto-Fix Generation

When `--fix` is enabled:

```dart
Future<void> generateMissingTests() {
  // 1. Find files without tests
  for (final sourceFile in libFiles) {
    final testFile = getTestPath(sourceFile);
    if (!exists(testFile)) {
      // 2. Generate test stub
      final content = '''
import 'package:test/test.dart';
import 'package:test_reporter/${getImportPath(sourceFile)}';

void main() {
  group('${getClassName(sourceFile)}', () {
    test('TODO: Add tests', () {
      // TODO: Implement test
      expect(true, isTrue);
    });
  });
}
''';
      // 3. Write file
      await File(testFile).writeAsString(content);
    }
  }
}
```

### Threshold Validation

```dart
bool validateThresholds(double coverage, {double? baseline}) {
  if (coverage < thresholds.minimum) {
    print('❌ Coverage $coverage% below minimum ${thresholds.minimum}%');
    return false;
  }

  if (baseline != null && thresholds.failOnDecrease && coverage < baseline) {
    print('❌ Coverage decreased from $baseline% to $coverage%');
    return false;
  }

  if (coverage < thresholds.warning) {
    print('⚠️ Coverage $coverage% below warning ${thresholds.warning}%');
  }

  return true;
}
```

---

## 3. FailedTestExtractor Architecture

**File**: `lib/src/bin/extract_failures_lib.dart` (791 lines)
**Entry**: `bin/extract_failures.dart` (15 lines)

### Core Responsibility

Extract only failed tests and generate rerun commands.

### Class Structure

```dart
class FailedTestExtractor {
  // Configuration
  final bool autoRerun;            // Auto-rerun failed tests
  final bool watch;                // Watch mode
  final bool saveResults;          // Save detailed report
  final bool groupByFile;          // Group by test file
  final int timeout;               // Test timeout (default: 120s)

  // Key methods
  Future<void> run(List<String> arguments);
  Future<TestResults> extractFailures(String testPath);
  List<String> generateRerunCommands(List<FailedTest> failures);
  Future<void> rerunFailedTests(List<FailedTest> tests);
}

class FailedTest {
  final String name;               // Test name
  final String filePath;           // Test file path
  final String testId;             // Unique ID
  final String? group;             // Group name
  final String? error;             // Error message
  final String? stackTrace;        // Stack trace
  final Duration? runtime;         // Test duration
}

class TestResults {
  final List<FailedTest> failedTests;
  final int totalTests;
  final int passedTests;
  final Duration totalTime;
  final DateTime timestamp;
}
```

### Workflow

```
1. Parse CLI arguments
   ↓
2. Run tests with JSON reporter
   │
   ├─ Execute: dart test [path] --reporter json
   └─ Capture JSON output
   │
   ↓
3. Parse JSON for failures
   │
   ├─ For each line in output:
   │   ├─ Parse JSON event
   │   ├─ If type == 'testDone' && result == 'error':
   │   │   └─ Extract failure info
   │   └─ If type == 'done':
   │       └─ Extract summary
   │
   ↓
4. Group failures (if --group-by-file)
   │
   ├─ Group by test file
   └─ Sort by file path
   │
   ↓
5. Generate rerun commands
   │
   ├─ By file: dart test test/my_test.dart
   ├─ By name: dart test test/my_test.dart --name="specific test"
   └─ Batch: dart test file1.dart file2.dart ...
   │
   ↓
6. Auto-rerun (if --auto-rerun)
   │
   ├─ Execute rerun commands
   ├─ Collect new results
   └─ Report outcomes
   │
   ↓
7. Generate report
   │
   ├─ Failed test list
   ├─ Rerun commands (copy-pasteable)
   ├─ Failure analysis
   └─ Recommendations
   │
   ↓
8. Watch mode (if --watch)
   │
   └─ Monitor file changes → repeat
```

### JSON Reporter Parsing

```dart
Future<TestResults> extractFailures(String testPath) {
  final process = await Process.start('dart', [
    'test',
    testPath,
    '--reporter',
    'json',
  ]);

  final failures = <FailedTest>[];

  await for (final line in process.stdout.transform(utf8.decoder).transform(LineSplitter())) {
    final event = jsonDecode(line) as Map<String, dynamic>;

    switch (event['type']) {
      case 'testDone':
        if (event['result'] == 'error') {
          failures.add(FailedTest(
            name: event['test']['name'],
            filePath: event['test']['url'],
            testId: event['testID'].toString(),
            error: event['error'],
            stackTrace: event['stackTrace'],
          ));
        }
        break;

      case 'done':
        final summary = event['success'] as bool;
        // Process summary
        break;
    }
  }

  return TestResults(...);
}
```

### Rerun Command Generation

```dart
List<String> generateRerunCommands(List<FailedTest> failures) {
  if (groupByFile) {
    // Group by file
    final byFile = <String, List<FailedTest>>{};
    for (final failure in failures) {
      byFile.putIfAbsent(failure.filePath, () => []).add(failure);
    }

    return byFile.entries.map((entry) {
      return 'dart test ${entry.key}';
    }).toList();
  } else {
    // Individual commands
    return failures.map((f) {
      return 'dart test ${f.filePath} --name="${f.name}"';
    }).toList();
  }
}
```

---

## 4. TestOrchestrator Architecture

**File**: `lib/src/bin/analyze_suite_lib.dart` (1,046 lines)
**Entry**: `bin/analyze_suite.dart` (90 lines)

### Core Responsibility

Unified orchestration of coverage + test analysis with combined reporting.

### Class Structure

```dart
class TestOrchestrator {
  // Configuration
  final String testPath;           // Test path to analyze
  final int runs;                  // Number of test runs
  final bool performance;          // Enable performance profiling
  final bool verbose;              // Verbose output
  final bool parallel;             // Parallel execution

  // Results tracking
  final Map<String, dynamic> results = {};
  final List<String> failures = [];
  final Map<String, String> reportPaths = {};

  // Key methods
  Future<void> runAll();
  Future<bool> runCoverageTool();
  Future<bool> runTestAnalyzer();
  Future<void> generateUnifiedReport();
  String extractModuleName();
}
```

### Workflow

```
1. Parse CLI arguments
   ↓
2. Create TestOrchestrator
   ↓
3. Extract module name from test path
   │
   ├─ test/integration → integration-fo
   ├─ test/my_test.dart → my_test-fi
   └─ test → all_tests-fo
   │
   ↓
4. Run coverage tool
   │
   ├─ Execute: dart run analyze_coverage [testPath]
   ├─ Capture exit code and output
   ├─ Parse JSON report (if exists)
   └─ Store results
   │
   ↓
5. Run test analyzer
   │
   ├─ Execute: dart run analyze_tests [testPath] --runs=[N]
   ├─ Capture exit code and output
   ├─ Parse JSON report (if exists)
   └─ Store results
   │
   ↓
6. Combine results
   │
   ├─ Merge coverage data
   ├─ Merge test reliability data
   ├─ Aggregate statistics
   └─ Combine recommendations
   │
   ↓
7. Generate unified report
   │
   ├─ Executive summary
   ├─ Coverage section (from coverage tool)
   ├─ Reliability section (from test analyzer)
   ├─ Combined insights
   └─ Action items
   │
   ↓
8. Save to tests_reports/suite/
   │
   └─ Format: {module_name}_suite@HHMM_DDMMYY.md
   │
   ↓
9. Return aggregated exit code:
   - 0: Both tools succeeded
   - 1: At least one tool failed
   - 2: Orchestrator error
```

### Module Name Extraction

```dart
String extractModuleName() {
  final path = testPath
      .replaceAll(r'\', '/')
      .replaceAll(RegExp(r'/$'), '');
  final segments = path.split('/').where((s) => s.isNotEmpty).toList();

  if (segments.isEmpty) return 'all_tests-fo';

  var moduleName = segments.last;
  String suffix;

  // File or folder?
  if (moduleName.endsWith('.dart')) {
    moduleName = moduleName
        .substring(0, moduleName.length - 5)
        .replaceAll('_test', '');
    suffix = '-fi';  // File
  } else if (moduleName == 'test') {
    return 'test-fo';
  } else {
    suffix = '-fo';  // Folder
  }

  return '$moduleName$suffix';
}
```

---

## Shared Utilities

### ReportUtils

Used by all analyzers for consistent report generation:

```dart
class ReportUtils {
  // Get report directory (tests_reports/)
  static Future<String> getReportDirectory();

  // Clean old reports, keep latest
  static Future<void> cleanOldReports({
    required String pathName,
    required List<String> prefixPatterns,
    String? subdirectory,
    bool verbose,
    bool keepLatest,
  });
}
```

Usage example:
```dart
// Before generating new report
await ReportUtils.cleanOldReports(
  pathName: 'auth_service-fo',
  prefixPatterns: ['coverage', 'analysis'],
  subdirectory: 'coverage',
  verbose: true,
  keepLatest: true,
);

// Generate new report
final reportDir = await ReportUtils.getReportDirectory();
final reportPath = '$reportDir/coverage/auth_service-fo_coverage@1435_041124.md';
```

### CLI Argument Parsing

All tools use `args` package with common pattern:

```dart
final parser = ArgParser()
  ..addFlag('verbose', abbr: 'v', help: 'Verbose output')
  ..addFlag('help', abbr: 'h', help: 'Show help')
  ..addOption('runs', defaultsTo: '3', help: 'Number of runs');

final args = parser.parse(arguments);

if (args['help'] as bool) {
  print('Usage: ...');
  print(parser.usage);
  exit(0);
}

final verbose = args['verbose'] as bool;
final runs = int.parse(args['runs'] as String);
```

---

## Exit Code Conventions

All tools follow the same exit code pattern:

- **0**: Success - all checks passed
- **1**: Failure - tests failed, coverage below threshold, etc.
- **2**: Error - analysis error, invalid arguments, crash

This allows CI/CD integration:
```bash
dart run test_reporter:analyze_suite || exit 1
```

---

## Report Format Consistency

All tools generate both markdown and JSON:

**Markdown** (`*.md`):
- Human-readable
- ANSI colors (in terminal)
- Tables and formatting
- Detailed explanations

**JSON** (`*.json`):
- Machine-parseable
- CI/CD integration
- Structured data
- Complete metrics

---

## Token Usage Guidance

**Loading this file**: ~10-15K tokens

**Best used for**:
- Understanding analyzer internals
- Modifying existing analyzers
- Creating new analyzer tool
- Debugging analyzer issues

**Recommended pairings**:
- With relevant SOP (e.g., `02_adding_new_analyzer.md`)
- With `analyzer_template.dart` for implementation
- With `failure_patterns.md` for pattern detection

---

## Performance Considerations

### Parallel Execution

TestAnalyzer supports parallel testing:

```dart
if (parallel) {
  final pool = Pool(maxWorkers);
  await Future.wait(
    testFiles.map((file) => pool.withResource(() => runTest(file))),
  );
}
```

### Watch Mode

Multiple analyzers support watch mode:

```dart
if (watch) {
  final watcher = DirectoryWatcher(testPath);
  await for (final event in watcher.events) {
    if (event.type == ChangeType.MODIFY) {
      await rerunAnalysis();
    }
  }
}
```

### Incremental Analysis

CoverageAnalyzer supports incremental mode:

```dart
if (incremental) {
  final changed = await getChangedFiles();  // git diff
  libPath = changed.where((f) => f.startsWith('lib/')).toList();
}
```

---

This architecture enables:
- ✅ Modular design (each tool is independent)
- ✅ Reusable code (lib/src/ can be imported)
- ✅ Testable components (pure Dart functions)
- ✅ Consistent UX (same patterns across all tools)
- ✅ Extensibility (easy to add new analyzers)
