# Test Reporter: Complete Renaming, Integration Tests & Flag Testing Plan

## Overview
- **Package rename:** `test_analyzer` → `test_reporter`
- **Naming strategy:** Action-based (analyze_coverage, analyze_tests, extract_failures, analyze_suite)
- **No backward compatibility** - clean break
- **Integration tests:** All ~530 tests (mostly real execution)
- **Flag testing:** Fill 9 test gaps for partially tested flags
- **Total work:** ~550 new tests + comprehensive renaming

---

## Phase 1: Complete Package Renaming (Est: 2-3 hours)

### 1.1 Core Package Files
- **pubspec.yaml:**
  - `name: test_analyzer` → `name: test_reporter`
  - Update description: "A comprehensive test reporting toolkit..."
  - Rename executables:
    - `coverage_tool` → `analyze_coverage`
    - `test_analyzer` → `analyze_tests`
    - `failed_test_extractor` → `extract_failures`
    - `run_all` → `analyze_suite`
  - Update repository/homepage URLs if needed

- **Main library file:**
  - Rename: `lib/test_analyzer.dart` → `lib/test_reporter.dart`
  - Update library declaration
  - Update all exports

### 1.2 Binary Files (bin/ directory)
- `coverage_tool.dart` → `analyze_coverage.dart`
- `test_analyzer.dart` → `analyze_tests.dart`
- `failed_test_extractor.dart` → `extract_failures.dart`
- `run_all.dart` → `analyze_suite.dart`
- Update import statements in each file

### 1.3 Library Implementation Files (lib/src/bin/)
- `coverage_tool_lib.dart` → `analyze_coverage_lib.dart`
- `test_analyzer_lib.dart` → `analyze_tests_lib.dart`
- `failed_test_extractor_lib.dart` → `extract_failures_lib.dart`
- `run_all_lib.dart` → `analyze_suite_lib.dart`
- Update all class names and references

### 1.4 Report Directory Structure

**Update constants in `lib/src/utils/constants.dart`:**
- `REPORT_BASE_DIR: 'test_analyzer_reports'` → `'tests_reports'`
- Subdirectory constants:
  - `'analyzer'` → `'tests'`
  - `'code_coverage'` → `'coverage'`
  - `'failed'` → `'failures'`
  - `'unified'` → `'suite'`

**Update report naming in `lib/src/utils/report_utils.dart`:**
- Old pattern: `{module}_test_report_{type}@{timestamp}.md`
- New pattern: `{module}_report_{suffix}@{timestamp}.md`
- Suffixes: `tests`, `coverage`, `failures`, `suite`

### 1.5 Update All Import Statements
Across entire codebase (lib/, bin/, test/):
- `import 'package:test_reporter/` → `import 'package:test_reporter/`
- Update all relative imports that reference renamed files
- Update import paths in test files

### 1.6 Test File Renaming

**test/bin/ directory:**
- `coverage_tool_test.dart` → `analyze_coverage_test.dart`
- `coverage_tool_main_test.dart` → `analyze_coverage_main_test.dart`
- `coverage_tool_advanced_test.dart` → `analyze_coverage_advanced_test.dart`
- `coverage_tool_errors_test.dart` → `analyze_coverage_errors_test.dart`
- (Same pattern for test_analyzer, failed_test_extractor, run_all)

**test/integration/bin/ directory:**
- Update all 4 integration test stub files
- Update fixture references

### 1.7 Documentation Updates
- **README.md:**
  - Update package name throughout
  - Update all example commands with new executable names
  - Update report directory structure documentation
  - Update installation instructions
- **CHANGELOG.md:**
  - Add breaking changes section
  - Document all renames
- **Other docs:**
  - Update any LICENSE, CONTRIBUTING files if they reference package name

---

## Phase 2: Fill Flag Test Gaps (Est: 1-2 hours)

### 2.1 Coverage Tool Flag Tests (3 gaps)

**A. Multiple `--exclude` patterns test**
File: `test/bin/analyze_coverage_main_test.dart`
```dart
test('handles multiple --exclude patterns', () async {
  // Test: --exclude "*.g.dart" --exclude "*.freezed.dart" --exclude "*.mocks.dart"
  // Verify: All patterns applied correctly
  // Verify: Files matching any pattern are excluded
});

test('exclude patterns with wildcards', () async {
  // Test: --exclude "**/*.generated.dart" --exclude "**/mocks/**"
  // Verify: Glob patterns work correctly
});
```

**B. Baseline comparison tests**
File: `test/bin/analyze_coverage_advanced_test.dart`
```dart
test('compares against baseline file correctly', () async {
  // Setup: Create baseline.json with known coverage
  // Test: Run with --baseline baseline.json
  // Verify: Comparison diff calculated
  // Verify: Increase/decrease detected
});

test('fails on coverage decrease with --fail-on-decrease', () async {
  // Setup: Baseline with 80% coverage
  // Test: Current run with 70% coverage + --fail-on-decrease
  // Verify: Exit code != 0
  // Verify: Error message shows decrease
});

test('baseline file not found error', () async {
  // Test: --baseline nonexistent.json
  // Verify: Graceful error handling
});
```

**C. Baseline + exclude combination test**
File: `test/bin/analyze_coverage_advanced_test.dart`
```dart
test('baseline comparison with excluded files', () async {
  // Test: --baseline baseline.json --exclude "*.g.dart"
  // Verify: Excluded files don't affect baseline comparison
});
```

### 2.2 Test Analyzer Flag Tests (5 gaps)

**A. Dependencies analysis tests**
File: `test/bin/analyze_tests_advanced_test.dart`
```dart
test('generates dependency graph with --dependencies', () async {
  // Setup: Tests with import dependencies
  // Test: Run with --dependencies
  // Verify: Dependency graph generated
  // Verify: Circular dependencies detected
});

test('dependency analysis with test failures', () async {
  // Test: Failed test + --dependencies
  // Verify: Shows which tests depend on failed test
});
```

**B. Mutation testing tests**
File: `test/bin/analyze_tests_advanced_test.dart`
```dart
test('runs mutation testing with --mutation', () async {
  // Setup: Tests with good coverage
  // Test: Run with --mutation
  // Verify: Mutations generated and tested
  // Verify: Mutation score calculated
});

test('mutation testing detects weak tests', () async {
  // Setup: Tests that don't actually assert
  // Test: Run with --mutation
  // Verify: Low mutation score reported
});
```

**C. Impact analysis tests**
File: `test/bin/analyze_tests_advanced_test.dart`
```dart
test('analyzes test impact with --impact', () async {
  // Setup: Git repo with recent changes
  // Test: Run with --impact
  // Verify: Changed files detected via git diff
  // Verify: Related tests identified
});

test('impact analysis without git repo', () async {
  // Setup: Non-git directory
  // Test: Run with --impact
  // Verify: Graceful fallback or warning
});
```

**D. Watch mode tests** (2 tests)
File: `test/bin/analyze_tests_advanced_test.dart`
```dart
test('watch mode detects file changes', () async {
  // Setup: Mock file system watcher
  // Test: Start with --watch, simulate file change
  // Verify: Re-analysis triggered
  // Note: Use mock watcher, not real FS watching
});
```

**E. Interactive mode tests** (2 tests)
File: `test/bin/analyze_tests_advanced_test.dart`
```dart
test('interactive mode shows debug menu', () async {
  // Setup: Mock stdin/stdout
  // Test: Run with --interactive after failure
  // Verify: Debug menu displayed
  // Note: Mock IO, not real interaction
});
```

### 2.3 Failed Test Extractor Flag Tests (1 gap)

**Watch mode test**
File: `test/bin/extract_failures_advanced_test.dart`
```dart
test('watch mode monitors for test failures', () async {
  // Setup: Mock file system watcher
  // Test: Start with --watch, simulate test run
  // Verify: Failures extracted automatically
});

test('watch mode with --auto-rerun', () async {
  // Setup: Mock watcher + mock process runner
  // Test: --watch --auto-rerun, simulate failure
  // Verify: Rerun command executed automatically
});
```

**Total new flag tests: ~15 tests**

---

## Phase 3: Integration Test Infrastructure (Est: 1-2 hours)

### 3.1 Test Generator Scripts (scripts/ directory)

**A. `scripts/generate_integration_tests.dart`**
- Master script to generate all ~530 integration tests
- Uses templates from test_templates.dart
- Supports both real and mocked test generation
- Configurable test count per category
- CLI: `dart scripts/generate_integration_tests.dart --real-ratio=0.8`

**B. `scripts/test_templates.dart`**
Template categories:
1. **Process Execution Templates** (~30 per binary)
   - Binary startup with various args
   - Exit code validation (0, 1, 2)
   - Process timeout scenarios
   - Parallel execution validation
   - Error output capture
   - Signal handling

2. **File I/O Templates** (~30 per binary)
   - Report file creation
   - Subdirectory creation (coverage/, tests/, failures/, suite/)
   - Content validation (markdown structure)
   - JSON embedding validation
   - File cleanup (old reports)
   - Permission error handling
   - Concurrent write scenarios

3. **CLI Argument Templates** (~30 per binary)
   - All flag combinations
   - Invalid argument errors
   - Help text validation
   - Conflicting flag detection
   - Default value verification
   - Option parsing (--runs=5, --min-coverage=80)

4. **Integration Workflow Templates** (~30 per binary)
   - End-to-end happy paths
   - Multi-run execution
   - Incremental mode (git diff)
   - Threshold violations
   - Error recovery
   - Report linking

5. **Cross-Tool Templates** (~50 total)
   - analyze_suite orchestration
   - Sequential execution validation
   - JSON extraction and combination
   - Health score calculation
   - Report interoperability

**C. `scripts/fixture_generator.dart`**
Creates sample projects:
```
test/integration/fixtures/
├── sample_flutter_project/
│   ├── lib/
│   │   ├── main.dart (simple app)
│   │   └── utils.dart (testable utilities)
│   ├── test/
│   │   ├── main_test.dart (passing tests)
│   │   └── utils_test.dart (passing tests)
│   └── pubspec.yaml (minimal Flutter deps)
├── sample_dart_project/
│   ├── lib/calculator.dart
│   ├── test/calculator_test.dart
│   └── pubspec.yaml (pure Dart)
├── failing_tests_project/
│   ├── lib/buggy_code.dart
│   ├── test/failing_test.dart (intentional failures)
│   └── pubspec.yaml
└── perfect_coverage_project/
    ├── lib/perfect.dart
    ├── test/perfect_test.dart (100% coverage)
    └── pubspec.yaml
```

### 3.2 Integration Test Helpers

**A. `test/integration/helpers/real_execution_helper.dart`**
```dart
class BinaryExecutor {
  // Execute binary with args, capture output
  Future<ExecutionResult> run(String binary, List<String> args);

  // Execute with timeout
  Future<ExecutionResult> runWithTimeout(String binary, List<String> args, Duration timeout);

  // Execute and stream output
  Stream<String> runStreaming(String binary, List<String> args);
}
```

**B. `test/integration/helpers/temp_directory_helper.dart`**
```dart
class TempTestDirectory {
  // Create isolated temp dir for each test
  Directory create();

  // Copy fixture project to temp dir
  void setupFixture(String fixtureName);

  // Cleanup in tearDown
  void cleanup();
}
```

**C. `test/integration/helpers/assertion_helpers.dart`**
```dart
// Custom matchers
Matcher hasReportFile(String pattern);
Matcher hasValidMarkdown();
Matcher hasEmbeddedJson();
Matcher exitedWithCode(int code);
```

---

## Phase 4: Generate Integration Tests (Est: 3-4 hours)

### 4.1 Test Generation Execution

**Run generator:**
```bash
dart scripts/generate_integration_tests.dart \
  --real-ratio=0.75 \
  --output=test/integration/bin
```

**Generated file structure:**
```
test/integration/
├── bin/
│   ├── analyze_coverage_integration_test.dart (~130 tests)
│   ├── analyze_tests_integration_test.dart (~130 tests)
│   ├── extract_failures_integration_test.dart (~130 tests)
│   ├── analyze_suite_integration_test.dart (~130 tests)
│   └── cross_tool_integration_test.dart (~50 tests)
├── fixtures/ (from fixture_generator.dart)
├── helpers/ (execution, temp dir, assertions)
└── mocks/ (existing ProcessMocker, MockFileSystem)
```

### 4.2 Test Breakdown Per Binary (~130 tests each)

**Each binary test file structure:**

```dart
void main() {
  group('Process Execution Tests (30 tests)', () {
    // Real execution tests: 24
    // Mocked tests: 6
  });

  group('File I/O Tests (30 tests)', () {
    // Real file creation: 22
    // Mocked tests: 8
  });

  group('CLI Arguments Tests (30 tests)', () {
    // Real arg parsing: 28
    // Mocked tests: 2
  });

  group('Integration Workflows (40 tests)', () {
    // Real end-to-end: 30
    // Mocked tests: 10
  });
}
```

**Real vs Mocked Ratio:**
- **Real tests (~75%):**
  - Actual binary execution via Process.run()
  - Real file system operations in temp directories
  - Real git operations (for incremental/impact tests)
  - Real coverage/test execution on fixtures
  - Execution time: ~5-10 seconds per test

- **Mocked tests (~25%):**
  - Edge cases (disk full, permissions)
  - Error scenarios (malformed input)
  - Fast validation of logic
  - Execution time: <1 second per test

### 4.3 Cross-Tool Integration Tests (50 tests)

**File: `test/integration/bin/cross_tool_integration_test.dart`**

```dart
group('Orchestration Flow', () {
  test('analyze_suite runs coverage → tests → unified', () async {
    // Execute: dart run test_reporter:analyze_suite test/
    // Verify: 3 separate reports generated
    // Verify: Unified report combines data
    // Verify: Health score calculated
  });

  test('analyze_suite with failures generates failure report', () async {
    // Use failing_tests_project fixture
    // Execute: analyze_suite
    // Verify: Failure report created in failures/ subdirectory
  });

  // ... 48 more tests
});

group('Report Interoperability', () {
  test('unified report extracts JSON from individual reports', () {
    // Execute: analyze_coverage, analyze_tests separately
    // Execute: analyze_suite (should read existing reports)
    // Verify: JSON data extracted correctly
  });

  // ... more tests
});

group('File System Coordination', () {
  test('concurrent runs create unique timestamped reports', () {
    // Execute: 3 parallel analyze_coverage runs
    // Verify: No file collisions
    // Verify: Unique timestamps
  });

  // ... more tests
});
```

---

## Phase 5: Validation & Cleanup (Est: 1-2 hours)

### 5.1 Run Complete Test Suite

**Execute all tests:**
```bash
# Unit tests (existing + new flag tests)
dart test test/bin/ --reporter=expanded

# Integration tests (new, ~530 tests)
dart test test/integration/ --reporter=expanded --timeout=30s

# Full suite
dart test --reporter=expanded
```

**Expected results:**
- ~117 existing unit tests: PASS
- ~15 new flag tests: PASS
- ~530 new integration tests: PASS
- **Total: ~662 tests passing**

### 5.2 Coverage Validation

```bash
# Run coverage on itself
dart run test_reporter:analyze_coverage lib/src \
  --min-coverage=95 \
  --branch \
  --verbose
```

**Expected coverage:**
- Overall: 95%+ (maintain current 100% on utils)
- New code: 90%+
- Integration tests should cover real execution paths

### 5.3 Smoke Test All Binaries

**Test renamed executables:**
```bash
# analyze_coverage
dart run test_reporter:analyze_coverage lib/src/bin --fix --branch --parallel

# analyze_tests
dart run test_reporter:analyze_tests test/bin --runs=5 --performance

# extract_failures
dart run test_reporter:extract_failures --help

# analyze_suite (the orchestrator)
dart run test_reporter:analyze_suite lib/src/utils --runs=3 --verbose
```

**Verify:**
- All executables run without errors
- Reports generated in correct directories (tests_reports/*)
- File naming matches new pattern
- JSON embedding works
- Cleanup functionality works

### 5.4 Verify Directory Structure

**Check report directories:**
```
tests_reports/
├── coverage/       # Coverage reports (not code_coverage)
├── tests/          # Test analysis reports (not analyzer)
├── failures/       # Failed test reports (not failed)
└── suite/          # Unified reports (not unified)
```

**Check file naming:**
- Pattern: `{module}_report_{suffix}@{timestamp}.md`
- Examples:
  - `utils_report_coverage@1430_301025.md`
  - `auth_report_tests@1431_301025.md`
  - `api_report_failures@1432_301025.md`
  - `features_report_suite@1433_301025.md`

### 5.5 Code Quality

```bash
# Analyze
dart analyze
# Should be: No issues found!

# Format
dart format lib/ bin/ test/
# Should be: Formatted N files

# Pub validation
dart pub publish --dry-run
# Should be: Package has 0 warnings
```

---

## Phase 6: Documentation & Finalization (Est: 1 hour)

### 6.1 Update README.md

**Sections to update:**

1. **Package Name & Description:**
```markdown
# Test Reporter

A comprehensive test reporting and analysis toolkit for Dart and Flutter projects.
Provides coverage analysis, flaky test detection, failure extraction, and unified reporting.
```

2. **Installation:**
```yaml
dev_dependencies:
  test_reporter:
    git:
      url: https://github.com/yourusername/test_reporter
      ref: main
```

3. **Usage Examples:**
```markdown
## Quick Start

### Unified Analysis (Recommended)
dart run test_reporter:analyze_suite lib/src/features --runs=5 --performance

### Individual Tools

#### Coverage Analysis
dart run test_reporter:analyze_coverage lib/src --min-coverage=95 --fix --branch

#### Test Analysis (Flaky Detection)
dart run test_reporter:analyze_tests test/features --runs=5 --performance --parallel

#### Failure Extraction
dart run test_reporter:extract_failures --save-results --verbose

## Report Structure
tests_reports/
├── coverage/    # Coverage analysis reports
├── tests/       # Test reliability reports
├── failures/    # Failed test reports
└── suite/       # Unified comprehensive reports
```

4. **Flag Documentation:**
- Add comprehensive flag table for each tool
- Document common combinations
- Add troubleshooting section

### 6.2 Update CHANGELOG.md

```markdown
## 2.0.0 - 2025-10-30

### BREAKING CHANGES

**Package Rename:**
- Package name: `test_analyzer` → `test_reporter`
- Main library: `test_analyzer.dart` → `test_reporter.dart`

**Executable Renames:**
- `coverage_tool` → `analyze_coverage`
- `test_analyzer` → `analyze_tests`
- `failed_test_extractor` → `extract_failures`
- `run_all` → `analyze_suite`

**Report Directory Changes:**
- Base directory: `test_analyzer_reports/` → `tests_reports/`
- Subdirectories:
  - `code_coverage/` → `coverage/`
  - `analyzer/` → `tests/`
  - `failed/` → `failures/`
  - `unified/` → `suite/`

**Report File Naming:**
- Pattern: `{module}_test_report_{type}@{timestamp}.md` → `{module}_report_{suffix}@{timestamp}.md`
- Suffixes: `coverage`, `tests`, `failures`, `suite`

### Added

- **530 integration tests** for comprehensive end-to-end validation
- **15 new flag tests** filling coverage gaps for advanced features
- **Test fixture projects** for realistic integration testing
- **Test generator scripts** for maintainable test generation
- **Real execution tests** using actual binaries (75% of integration tests)

### Improved

- **Flag test coverage:** 81% → 100% (all 48 flags fully tested)
- **Integration test coverage:** 0% → 100% (530 new tests)
- **Overall test count:** 117 → ~662 tests

### Migration Guide

1. Update dependencies:
   ```yaml
   test_analyzer → test_reporter
   ```

2. Update executable calls:
   ```bash
   dart run test_analyzer:coverage_tool → dart run test_reporter:analyze_coverage
   dart run test_analyzer:test_analyzer → dart run test_reporter:analyze_tests
   dart run test_analyzer:failed_test_extractor → dart run test_reporter:extract_failures
   dart run test_analyzer:run_all → dart run test_reporter:analyze_suite
   ```

3. Update report directory references:
   - Old: `test_analyzer_reports/code_coverage/`
   - New: `tests_reports/coverage/`

4. No backward compatibility - clean migration required.
```

### 6.3 Additional Documentation

**Create/Update:**
- `CONTRIBUTING.md` with new test guidelines
- `docs/FLAGS.md` with comprehensive flag documentation
- `docs/INTEGRATION_TESTS.md` explaining test structure
- Update any screenshots/examples in docs

---

## Summary of Deliverables

### 1. Renamed Package ✅
- Package: `test_reporter`
- 4 action-based executables
- New directory structure: `tests_reports/{coverage,tests,failures,suite}/`
- New file naming: `{module}_report_{suffix}@{timestamp}.md`

### 2. Complete Flag Testing ✅
- 15 new tests for partially tested flags
- Coverage: 81% → 100% (48/48 flags fully tested)
- All edge cases covered (baseline, exclude patterns, advanced features)

### 3. Comprehensive Integration Tests ✅
- 530 new integration tests
- 75% real execution, 25% mocked
- 4 fixture projects for realistic testing
- Cross-tool integration validation
- Process execution, File I/O, CLI args, workflows

### 4. Test Infrastructure ✅
- 3 generator scripts (generate, templates, fixtures)
- Real execution helpers
- Temp directory management
- Custom assertion matchers

### 5. Quality Assurance ✅
- All ~662 tests passing
- 95%+ code coverage maintained
- dart analyze: 0 issues
- Smoke tests: all binaries working
- Documentation: complete and updated

---

## Estimated Timeline

| Phase | Duration | Deliverable |
|-------|----------|-------------|
| 1. Renaming | 2-3 hours | All files renamed, imports updated |
| 2. Flag Tests | 1-2 hours | 15 new flag tests added |
| 3. Test Infrastructure | 1-2 hours | Scripts + helpers created |
| 4. Integration Tests | 3-4 hours | 530 tests generated + validated |
| 5. Validation | 1-2 hours | All tests passing, smoke tests done |
| 6. Documentation | 1 hour | README, CHANGELOG, docs updated |
| **TOTAL** | **9-14 hours** | Complete refactor + 545 new tests |

---

## Risk Mitigation

**Potential Issues:**

1. **Import path misses:**
   - Mitigation: Use global find/replace, then dart analyze
   - Recovery: Fix remaining imports

2. **Integration tests too slow:**
   - Mitigation: Use test timeouts, run in parallel
   - Recovery: Increase mock ratio if needed

3. **Fixture projects break:**
   - Mitigation: Keep fixtures minimal and stable
   - Recovery: Regenerate with fixture_generator.dart

4. **Report directory conflicts:**
   - Mitigation: Clean old directory before testing
   - Recovery: Manual cleanup script

**Quality Gates:**
- ✅ All unit tests pass before proceeding to integration
- ✅ dart analyze shows 0 issues before commit
- ✅ All integration tests pass before documentation
- ✅ Smoke tests succeed before final commit

---

## Next Steps

The plan will be executed in sequential phases to ensure quality at each step. Each phase will be completed and validated before moving to the next.
