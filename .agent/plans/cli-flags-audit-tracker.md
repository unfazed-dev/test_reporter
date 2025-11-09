# CLI Flags Audit & Fix Implementation Tracker

**Status**: ⚠️ **IN PROGRESS** - Phases 1-4 ✅ complete, Phase 5 pending
**Created**: 2025-11-09
**Last Updated**: 2025-11-09 (Phase 4 complete - analyze_suite behavior documented)
**Target**: Fix all CLI flag issues across 4 analyzer tools with 100% flag verification
**Current Progress**: 4/5 phases complete (80%)
**Methodology**: 🔴🟢♻️🔄 TDD (Red-Green-Refactor-MetaTest)

---

## 📊 Overview

### Investigation Summary

**Comprehensive audit completed** of all CLI flags across 4 analyzer tools:
- **Total Flags**: 65 flags across all tools
- **Critical Bugs**: 1 (--no-report broken in analyze_tests)
- **Stub Flags**: 9 (partially implemented, need removal)
- **Inconsistencies**: 2 tools using manual parsing vs ArgParser

### Critical Findings

1. **🔴 BROKEN**: `--no-report` in `analyze_tests` - flag is parsed but report is STILL printed to stdout
2. **⚠️ STUBS**: 9 flags are partially implemented (parsed but features incomplete)
3. **🟡 INCONSISTENT**: Only `extract_failures` and `analyze_suite` use ArgParser; `analyze_tests` and `analyze_coverage` use manual string parsing

### Scope

This tracker focuses on **systematically fixing all CLI flag issues**:

- **Challenge**: Inconsistent argument parsing, broken flags, stub features confusing users
- **Solution**: Standardize on ArgParser, fix broken flags, remove stubs, comprehensive testing
- **Approach**: TDD methodology for all changes (🔴🟢♻️🔄)
- **Benefit**: Consistent UX across all tools, no broken promises, 100% flag verification

### Time Estimates

- **Phase 1**: Fix --no-report Bug (2-3 hours)
- **Phase 2**: Standardize ArgParser (4-6 hours)
- **Phase 3**: Clean Up Stub Flags (1-2 hours)
- **Phase 4**: Document Behavior (30 min)
- **Phase 5**: Comprehensive Flag Testing (3-4 hours)
- **Total**: 11-16 hours

---

## 🎯 Overall Progress

```
[████████████████░░░░] 80% Complete (Phases 1-4 DONE, Phase 5 PENDING)

Phase 1: ✅ COMPLETE - Fix --no-report Bug (Actual: ~1.5 hours)
  ✅ 🔴 RED: 6 failing tests written
  ✅ 🟢 GREEN: Bug fixed (1 line change)
  ✅ ♻️ REFACTOR: Documentation added, quality checks passed
  ✅ 🔄 META-TEST: Manual CLI verification complete
Phase 2: ✅ COMPLETE - Standardize ArgParser (Actual: ~4 hours)
  ✅ 2.1 analyze_tests (2-3 hours) - Commit dbd7993
  ✅ 2.2 analyze_coverage (2-3 hours) - Commit 3215f5f
Phase 3: ✅ COMPLETE - Clean Up Stub Flags (Actual: ~1 hour)
  ✅ 🔴 RED: 15 failing tests written
  ✅ 🟢 GREEN: 9 stub flags removed (3 from analyze_tests, 6 from analyze_coverage)
  ✅ ♻️ REFACTOR: CHANGELOG updated, help text cleaned, quality checks passed
  ✅ 🔄 META-TEST: Manual CLI verification complete
Phase 4: ✅ COMPLETE - Document analyze_suite (Actual: ~20 min)
  ✅ Design comment added to bin/analyze_suite.dart
  ✅ Help text updated to clarify no --no-report flag
  ✅ CLAUDE.md updated with analyze_suite documentation
  ✅ README.md cleaned up (removed stub flag references)
Phase 5: ⬜ PENDING - Comprehensive Flag Testing (3-4 hours)
  ⬜ 5.1 analyze_tests (1 hour)
  ⬜ 5.2 analyze_coverage (1 hour)
  ⬜ 5.3 extract_failures (30 min)
  ⬜ 5.4 analyze_suite (30 min)
  ⬜ 5.5 Edge cases (1 hour)
```

**Current Status**: ⚠️ **IN PROGRESS** - Phases 1-4 complete (80%), Phase 5 pending
**Tests Created**: 37 / ~66 (6 integration + 7 analyze_tests unit + 9 analyze_coverage unit + 15 stub removal)
**Flags Fixed**: 1 / 1 critical bug ✅
**Tools Refactored**: 2 / 2 (ArgParser migration) ✅
**Stubs Removed**: 9 / 9 ✅
**Documentation**: 4 / 4 files updated ✅
**Blockers**: None
**Known Issues**: None

---

## 📋 Complete Flag Inventory

### analyze_tests (15 flags after stub removal)

| Flag | Short | Default | Status | Notes |
|------|-------|---------|--------|-------|
| `--verbose` | `-v` | false | ✅ WORKING | Show detailed output |
| `--interactive` | `-i` | false | ✅ WORKING | Interactive debug mode |
| `--performance` | `-p` | false | ✅ WORKING | Performance metrics |
| `--watch` | `-w` | false | ✅ WORKING | Watch mode |
| `--parallel` | - | false | ✅ WORKING | Parallel execution |
| `--help` | `-h` | false | ✅ WORKING | Show help |
| **`--no-report`** | - | false | **🔴 BROKEN** | **Report still printed to stdout** |
| `--no-fixes` | - | false | ✅ WORKING | Disable fix suggestions |
| `--no-checklist` | - | false | ✅ WORKING | Disable checklists |
| `--minimal-checklist` | - | false | ✅ WORKING | Compact checklist |
| `--include-fixtures` | - | false | ✅ WORKING | Include fixture tests |
| `--runs=N` | - | 3 | ✅ WORKING | Number of test runs |
| `--slow=N` | - | 1.0 | ✅ WORKING | Slow test threshold |
| `--workers=N` | - | 4 | ✅ WORKING | Max parallel workers |
| `--module-name` | - | null | ✅ WORKING | Override module name |

**Stubs to Remove** (3):
- ~~`--dependencies` / `-d`~~ - Dependency analysis (not implemented)
- ~~`--mutation` / `-m`~~ - Mutation testing (not implemented)
- ~~`--impact`~~ - Impact analysis (not implemented)

---

### analyze_coverage (15 flags after stub removal)

| Flag | Short | Default | Status | Notes |
|------|-------|---------|--------|-------|
| `--help` | `-h` | false | ✅ WORKING | Show help |
| `--fix` | - | false | ✅ WORKING | Generate missing tests |
| `--no-report` | - | false | ✅ WORKING | Skip report generation |
| `--json` | - | false | ✅ WORKING | Export JSON |
| `--no-checklist` | - | false | ✅ WORKING | Disable checklists |
| `--minimal-checklist` | - | false | ✅ WORKING | Compact checklist |
| `--verbose` | - | false | ✅ WORKING | Verbose output |
| `--lib` | - | lib/src | ✅ WORKING | Source path |
| `--source-path` | - | - | ✅ WORKING | Alias for --lib |
| `--test` | - | test | ✅ WORKING | Test path |
| `--test-path` | - | - | ✅ WORKING | Alias for --test |
| `--module-name` | - | null | ✅ WORKING | Override module name |
| `--exclude` | - | [] | ✅ WORKING | Exclude patterns |
| `--baseline` | - | null | ✅ WORKING | Baseline comparison |
| `--min-coverage` | - | 0 | ✅ WORKING | Min threshold |
| `--warn-coverage` | - | 0 | ✅ WORKING | Warning threshold |
| `--fail-on-decrease` | - | false | ✅ WORKING | Fail on decrease |

**Stubs to Remove** (6):
- ~~`--branch`~~ - Branch coverage (not implemented)
- ~~`--incremental`~~ - Incremental coverage (not implemented)
- ~~`--mutation`~~ - Mutation testing (not implemented)
- ~~`--watch`~~ - Watch mode (not implemented)
- ~~`--parallel`~~ - Parallel execution (not implemented)
- ~~`--impact`~~ - Test impact analysis (not implemented)

---

### extract_failures (14 flags)

| Flag | Short | Default | Status | Notes |
|------|-------|---------|--------|-------|
| `--help` | `-h` | - | ✅ WORKING | Show help |
| `--list-only` | `-l` | false | ✅ WORKING | List failures only |
| `--auto-rerun` | `-r` | true | ✅ WORKING | Auto-rerun failed tests |
| `--watch` | `-w` | false | ✅ WORKING | Watch mode |
| `--save-results` | `-s` | false | ✅ WORKING | Save detailed report |
| `--module-name` | - | null | ✅ WORKING | Override module name |
| `--verbose` | `-v` | false | ✅ WORKING | Verbose output |
| `--group-by-file` | `-g` | true | ✅ WORKING | Group by file |
| `--timeout` | `-t` | 120 | ✅ WORKING | Test timeout |
| `--parallel` | `-p` | false | ✅ WORKING | Parallel execution |
| `--max-failures` | - | 0 | ✅ WORKING | Max failures to extract |
| `--checklist` | - | true | ✅ WORKING | Include checklists |
| `--minimal-checklist` | - | false | ✅ WORKING | Compact checklist |
| `--output` | `-o` | '' | ⚠️ DEPRECATED | Legacy option |

**Note**: This tool uses ArgParser properly ✅

---

### analyze_suite (12 flags)

| Flag | Short | Default | Status | Notes |
|------|-------|---------|--------|-------|
| `--help` | `-h` | false | ✅ WORKING | Show help |
| `--path` | `-p` | test | ✅ WORKING | Test path |
| `--runs` | `-r` | 3 | ✅ WORKING | Number of runs |
| `--test-path` | - | null | ✅ WORKING | Explicit test path |
| `--source-path` | - | null | ✅ WORKING | Explicit source path |
| `--module-name` | - | null | ✅ WORKING | Override module name |
| `--performance` | - | false | ✅ WORKING | Performance profiling |
| `--verbose` | `-v` | false | ✅ WORKING | Verbose output |
| `--parallel` | - | false | ✅ WORKING | Parallel execution |
| `--checklist` | - | true | ✅ WORKING | Include checklists |
| `--minimal-checklist` | - | false | ✅ WORKING | Compact checklist |
| `--include-fixtures` | - | false | ✅ WORKING | Include fixtures |

**Note**: This tool uses ArgParser properly ✅
**Design**: No `--no-report` flag - orchestrator's PURPOSE is to generate unified reports

---

## 📋 Phase 1: Fix Critical --no-report Bug (2-3 hours)

**Status**: ⬜ PENDING
**Priority**: 🔴 CRITICAL
**File**: `lib/src/bin/analyze_tests_lib.dart`
**Lines Affected**: ~497, 1445, 3411, 3514
**Methodology**: 🔴🟢♻️🔄 TDD

### Bug Description

**Problem**: The `--no-report` flag in `analyze_tests` is **BROKEN**

**Current Behavior**:
```dart
// Line 3411: Flag is parsed correctly
final noReport = args.contains('--no-report');

// Line 3514: Flag passed to constructor correctly
generateReport: !noReport,

// Line 497: Report generation is called UNCONDITIONALLY ❌
await _generateReport();

// Line 1445: Flag only checked INSIDE _generateReport()
if (generateReport) {
  await _saveReportToFile();  // Only file saving is skipped
}
// But report is STILL printed to stdout (lines 1427-1442) ❌
```

**Expected Behavior**: When `--no-report` is set, NO report should be generated (neither printed nor saved)

**Actual Behavior**: Report is printed to stdout, only file saving is skipped

**Fix Strategy**: Move the `if (generateReport)` check to BEFORE calling `_generateReport()`

---

### 🔴 RED Phase (30 min)

**Goal**: Write failing tests that demonstrate the bug

**Test Checklist**:
- [x] Create test file: `test/integration/bin/analyze_tests_no_report_test.dart`
- [x] Test 1: `--no-report` should NOT print report to stdout
  - [x] Run analyzer with --no-report flag
  - [x] Capture stdout output
  - [x] Expect: stdout does NOT contain report sections
  - [x] Expected result: ❌ FAIL (report is printed)
- [x] Test 2: `--no-report` should NOT create report files
  - [x] Run analyzer with --no-report flag
  - [x] Check tests_reports/tests/ directory
  - [x] Expect: NO .md or .json files created
  - [x] Expected result: ✅ PASS (already works)
- [x] Test 3: `--no-report` with --verbose should still show verbose output
  - [x] Run analyzer with --no-report --verbose
  - [x] Capture stdout
  - [x] Expect: Verbose test output shown, but NO report
  - [x] Expected result: ❌ FAIL (report is printed)
- [x] Test 4: `--no-report` with --runs=5 should work correctly
  - [x] Run analyzer with --no-report --runs=5
  - [x] Verify 5 runs executed (via verbose or exit code)
  - [x] Verify NO report generated
  - [x] Expected result: ❌ FAIL (report is printed)
- [x] Test 5: Default behavior (no flag) should generate report
  - [x] Run analyzer WITHOUT --no-report
  - [x] Expect: Report printed to stdout AND files created
  - [x] Expected result: ✅ PASS (already works)
- [x] Run: `dart test test/integration/bin/analyze_tests_no_report_test.dart`
- [x] Expected: ❌ 3/5 tests fail (Tests 1, 3, 4 fail; Tests 2, 5 pass)

**RED Phase Complete**: [x]
- Total tests written: 6 / 6 (5 core + 1 consistency test)
- Tests failing correctly: [x] (3/5 failed as expected)
- Bug reproduced in tests: [x]

---

### 🟢 GREEN Phase (1 hour)

**Goal**: Fix the bug with minimal code change

**Implementation Checklist**:
- [x] Open `lib/src/bin/analyze_tests_lib.dart`
- [x] Locate report generation in `run()` method (around line 497)
- [x] **Current code** (line ~497):
  ```dart
  // Step 5: Generate comprehensive report
  await _generateReport();
  ```
- [x] **Change to**:
  ```dart
  // Step 5: Generate comprehensive report (if enabled)
  // When --no-report is specified, skip all report generation
  if (generateReport) {
    await _generateReport();
  }
  ```
- [x] Verify `generateReport` field exists in class (should already exist from line 3514)
- [x] **IMPORTANT**: No duplicate check needed - fix is at call site only
  - The check is at the call site (line 498), suppressing all report generation
  - This ensures stdout printing is also skipped
- [x] Run: `dart test test/integration/bin/analyze_tests_no_report_test.dart`
- [x] Expected: ✅ All 6 tests pass

**GREEN Phase Complete**: [x]
- All tests passing: [x] (6/6)
- Bug fixed: [x]
- Minimal change made: [x]

---

### ♻️ REFACTOR Phase (30 min)

**Goal**: Clean up and improve code quality

**Refactor Checklist**:
- [x] Add documentation comment for `generateReport` field
  ```dart
  /// Whether to generate and display test analysis reports.
  /// When false (via --no-report flag), suppresses both stdout output and file creation.
  /// This provides a clean way to run tests multiple times for reliability checks
  /// without cluttering the console or generating report files.
  final bool generateReport;
  ```
- [x] Add documentation comment for the check at line 497
  ```dart
  // Step 5: Generate comprehensive report (if enabled)
  // When --no-report is specified, skip all report generation
  if (generateReport) {
    await _generateReport();
  }
  ```
- [x] Ensure consistent behavior with `analyze_coverage` --no-report
  - [x] Compare implementations
  - [x] Verify both tools suppress output the same way
- [x] Extract report suppression message (optional): Not needed - clean suppression
- [x] Run `dart analyze` - Expected: 0 issues
- [x] Run `dart format .` - Expected: No changes needed
- [x] Run all tests: `dart test`
- [x] Expected: ✅ All tests still pass

**REFACTOR Phase Complete**: [x]
- All tests passing: [x] (6/6)
- dart analyze: 0 issues: [x]
- Code quality improved: [x]
- Documentation added: [x]

---

### 🔄 META-TEST Phase (30 min)

**Goal**: Verify fix works in real-world usage

**Meta-Test Checklist**:
- [x] **Test 1**: Basic --no-report usage
  ```bash
  dart run test_reporter:analyze_tests test/ --runs=1 --no-report
  ```
  - [x] Verify: NO report printed to stdout (only test execution output)
  - [x] Verify: NO files in tests_reports/tests/
  - [x] Verify: Exit code correct (0 if pass, 1 if fail)
- [x] **Test 2**: --no-report with --verbose
  ```bash
  dart run test_reporter:analyze_tests test/ --runs=1 --no-report --verbose
  ```
  - [x] Verify: Verbose test output shown
  - [x] Verify: NO report sections printed
  - [x] Verify: NO files created
- [x] **Test 3**: --no-report with --performance
  ```bash
  dart run test_reporter:analyze_tests test/ --runs=3 --no-report --performance
  ```
  - [x] Verify: Tests run 3 times
  - [x] Verify: Performance data NOT shown (part of report)
  - [x] Verify: NO files created
- [x] **Test 4**: Compare with analyze_coverage --no-report
  ```bash
  dart run test_reporter:analyze_coverage lib/src --no-report
  ```
  - [x] Verify both tools suppress output similarly
  - [x] Verify consistent behavior
- [x] **Test 5**: Default behavior (no flag)
  ```bash
  dart run test_reporter:analyze_tests test/ --runs=1
  ```
  - [x] Verify: Report IS printed to stdout
  - [x] Verify: Files ARE created in tests_reports/tests/
  - [x] Verify: Everything works as before
- [x] Document any issues found: None - all tests passed

**META-TEST Phase Complete**: [x]
- All manual tests passing: [x] (5/5)
- Real-world verification complete: [x]
- No regressions found: [x]

---

**Phase 1 Complete**: [x]
- Total time spent: ~1.5 hours / 2-3 hours (under estimate!)
- Tests created: 6 / 6 (5 core integration tests + 1 consistency test)
- All tests passing: [x] (6/6)
- Bug verified fixed: [x]
- Manual testing complete: [x]
- Ready for Phase 2: [x]

---

## 📋 Phase 2: Standardize ArgParser (4-6 hours)

**Status**: ✅ COMPLETE
**Priority**: 🟡 HIGH
**Goal**: Refactor `analyze_tests` and `analyze_coverage` to use ArgParser like `extract_failures` and `analyze_suite`
**Methodology**: 🔴🟢♻️🔄 TDD
**Progress**: 100% (2/2 tools migrated)
**Time Spent**: ~4 hours (within estimate)

### Why ArgParser?

**Current Problem**: Manual string parsing with `args.contains('--flag')` is:
- ❌ Error-prone (typos, inconsistent parsing)
- ❌ No type validation (can't enforce numeric ranges)
- ❌ No automatic help generation
- ❌ No short alias support consistency
- ❌ Hard to maintain

**ArgParser Benefits**:
- ✅ Automatic help text generation
- ✅ Type validation (string, int, bool)
- ✅ Default values
- ✅ Negatable flags (--flag vs --no-flag)
- ✅ Short aliases (-v, -h)
- ✅ Better error messages
- ✅ Consistent with extract_failures and analyze_suite

---

### 2.1 Refactor analyze_tests to ArgParser (2-3 hours)

**File**: `lib/src/bin/analyze_tests_lib.dart`
**Lines to Change**: 3406-3453 (flag parsing), 3515-3550 (help text)
**Status**: ✅ COMPLETE (Commit: dbd7993)

---

#### 🔴 RED Phase (30 min)

**Test Checklist**:
- [x] Create test file: `test/unit/bin/analyze_tests_argparser_test.dart`
- [x] Test 1: ArgParser parses all 15 flags correctly
  - [x] Parse args with all flags set
  - [x] Verify each flag value is correct
  - [x] Expected: ✅ PASS (ArgParser implemented in test)
- [x] Test 2: Short aliases work (-v, -i, -p, -w, -h)
  - [x] Parse args with short aliases
  - [x] Verify flag values match long forms
  - [x] Expected: ✅ PASS
- [x] Test 3: Negatable flags work (--no-report, --no-checklist, --no-fixes)
  - [x] Parse args with --flag and --no-flag variants
  - [x] Verify both forms work correctly
  - [x] Expected: ✅ PASS
- [x] Test 4: Numeric options parse correctly (--runs=5, --slow=2.0, --workers=8)
  - [x] Parse args with numeric values
  - [x] Verify type conversion (string → int/double)
  - [x] Expected: ✅ PASS
- [x] Test 5: Default values work when flags not provided
  - [x] Parse empty args
  - [x] Verify defaults: runs=3, slow=1.0, workers=4
  - [x] Expected: ✅ PASS
- [x] Test 6: Invalid flag combinations rejected
  - [x] Parse args with unknown flags
  - [x] Expect exception or error
  - [x] Expected: ✅ PASS
- [x] Test 7: Help text generation works
  - [x] Call help text method
  - [x] Verify all flags documented
  - [x] Expected: ✅ PASS
- [x] Run: `dart test test/unit/bin/analyze_tests_argparser_test.dart`
- [x] Expected: ✅ All 7 tests pass (ArgParser in test)

**RED Phase Complete**: [x]
- Total tests written: 7 / 7
- All tests passing (ArgParser implementation in test): [x]

---

#### 🟢 GREEN Phase (1-1.5 hours)

**Implementation Checklist**:
- [x] Add ArgParser import at top of file:
  ```dart
  import 'package:args/args.dart';
  ```
- [x] Create ArgParser instance and setup method:
  ```dart
  ArgParser _createArgParser() {
    return ArgParser()
      ..addFlag('verbose',
          abbr: 'v',
          help: 'Show detailed output and stack traces',
          negatable: false,
      )
      // ... all flags configured
  }
  ```
- [x] Migrate all 15 flags to ArgParser:
  - [x] `--verbose` / `-v` (flag, negatable: false)
  - [x] `--interactive` / `-i` (flag, negatable: false)
  - [x] `--performance` / `-p` (flag, negatable: false)
  - [x] `--watch` / `-w` (flag, negatable: false)
  - [x] `--parallel` (flag, negatable: false)
  - [x] `--help` / `-h` (flag, negatable: false)
  - [x] `--report` (flag, negatable: true, default: true)
  - [x] `--fixes` (flag, negatable: true, default: true)
  - [x] `--checklist` (flag, negatable: true, default: true)
  - [x] `--minimal-checklist` (flag, negatable: false)
  - [x] `--include-fixtures` (flag, negatable: false)
  - [x] `--runs` (option, defaultsTo: '3')
  - [x] `--slow` (option, defaultsTo: '1.0')
  - [x] `--workers` (option, defaultsTo: '4')
  - [x] `--module-name` (option)
- [x] Replace manual string parsing (lines 3406-3453):
  ```dart
  // NEW:
  final parser = _createArgParser();
  final results = parser.parse(args);
  final verbose = results['verbose'] as bool;
  final generateReport = results['report'] as bool;
  ```
- [x] Update help text to use `_parser.usage`:
  ```dart
  void _printUsage(ArgParser parser) {
    print('Usage: dart analyze_tests.dart [options] <test-path>');
    print('');
    print('Options:');
    print(parser.usage);
  }
  ```
- [x] Run: `dart test test/unit/bin/analyze_tests_argparser_test.dart`
- [x] Expected: ✅ All 7 tests pass

**GREEN Phase Complete**: [x]
- All tests passing: [x] (7/7)
- ArgParser implemented: [x]
- All 15 flags migrated: [x]

---

#### ♻️ REFACTOR Phase (30 min)

**Refactor Checklist**:
- [x] Extract flag setup to separate method for clarity (_createArgParser)
- [x] Add comprehensive help text for each flag
- [x] Ensure consistent naming with other tools
- [x] Group related flags in ArgParser setup:
  - Output flags (verbose, report, checklist)
  - Mode flags (interactive, watch, performance, parallel)
  - Configuration flags (runs, slow, workers)
- [x] Add validation for numeric ranges (using tryParse with defaults)
- [x] Update error messages to be more helpful (FormatException handling)
- [x] Run `dart analyze` - Expected: 0 issues
- [x] Run `dart format .`
- [x] Run all tests: `dart test`

**REFACTOR Phase Complete**: [x]
- All tests passing: [x]
- dart analyze: 0 issues: [x]
- Code quality improved: [x]

---

#### 🔄 META-TEST Phase (30 min)

**Meta-Test Checklist**:
- [x] Test help output:
  ```bash
  dart run test_reporter:analyze_tests --help
  ```
  - [x] Verify all flags documented
  - [x] Verify formatting is clear
- [x] Test invalid flag:
  ```bash
  dart run test_reporter:analyze_tests --invalid-flag
  ```
  - [x] Verify clear error message
- [x] Test all flag aliases:
  ```bash
  dart run test_reporter:analyze_tests test/ -v -i -p -w
  ```
  - [x] Verify short aliases work (-v works)
- [x] Test negatable flags:
  ```bash
  dart run test_reporter:analyze_tests test/ --no-report
  ```
  - [x] Verify negation works
- [x] Test numeric options:
  ```bash
  dart run test_reporter:analyze_tests test/ --runs=2
  ```
  - [x] Verify numeric parsing works
- [x] Compare with old behavior to ensure no regressions

**META-TEST Phase Complete**: [x]

**Phase 2.1 Complete**: [x]
- Total time spent: ~2 hours / 2-3 hours
- Tests created: 7 / 7
- ArgParser fully migrated: [x]
- No regressions: [x]

---

### 2.2 Refactor analyze_coverage to ArgParser (2-3 hours)

**File**: `lib/src/bin/analyze_coverage_lib.dart`
**Lines to Change**: 2824-2973 (flag parsing), help text generation
**Status**: ✅ COMPLETE (Commit: 3215f5f)

---

#### 🔴 RED Phase (30 min)

**Test Checklist**:
- [x] Create test file: `test/unit/bin/analyze_coverage_argparser_test.dart`
- [x] Test 1: ArgParser parses all boolean flags correctly
- [x] Test 2: Path options parse correctly with aliases (--lib/--source-path, --test/--test-path)
- [x] Test 3: Numeric thresholds parse correctly (--min-coverage, --warn-coverage)
- [x] Test 4: Multi-value options work (--exclude patterns)
- [x] Test 5: Default values work when flags not provided
- [x] Test 6: Invalid flag combinations rejected
- [x] Test 7: Help text generation works
- [x] Test 8: Short alias for help works (-h)
- [x] Test 9: Rest arguments captured correctly
- [x] Run: `dart test test/unit/bin/analyze_coverage_argparser_test.dart`
- [x] Expected: ✅ All 9 tests pass (ArgParser in test)

**RED Phase Complete**: [x]
- Total tests written: 9 / 9
- All tests passing (ArgParser implementation in test): [x]

---

#### 🟢 GREEN Phase (1-1.5 hours)

**Implementation Checklist**:
- [x] Add ArgParser import
- [x] Create ArgParser instance and setup method (_createArgParser)
- [x] Migrate all 17 flags to ArgParser:
  - [x] Basic flags (fix, report, checklist, help)
  - [x] Path options with aliases (lib/source-path, test/test-path)
  - [x] Advanced flags (branch, incremental, mutation, watch, parallel, impact)
  - [x] Export flags (json, include-fixtures)
  - [x] Threshold options (min-coverage, warn-coverage, fail-on-decrease)
  - [x] Multi-value option (exclude)
  - [x] Baseline option
  - [x] Module name option
- [x] Replace manual string parsing with ArgParser
- [x] Update help text to use parser.usage
- [x] Preserve path resolution logic (PathResolver)
- [x] Run: `dart test test/unit/bin/analyze_coverage_argparser_test.dart`
- [x] Expected: ✅ All 9 tests pass

**GREEN Phase Complete**: [x]
- All tests passing: [x] (9/9)
- ArgParser implemented: [x]
- All 17 flags migrated: [x]

---

#### ♻️ REFACTOR Phase (30 min)

**Refactor Checklist**:
- [x] Extract flag setup to clear method (_createArgParser)
- [x] Add comprehensive help text for all flags
- [x] Ensure consistent naming with analyze_tests
- [x] Add validation for threshold ranges (using tryParse with defaults)
- [x] Run `dart analyze` - 0 issues
- [x] Run `dart format .`
- [x] Run all tests

**REFACTOR Phase Complete**: [x]
- All tests passing: [x]
- dart analyze: 0 issues: [x]
- Code quality improved: [x]

---

#### 🔄 META-TEST Phase (30 min)

**Meta-Test Checklist**:
- [x] Test help output (--help shows ArgParser-generated help)
- [x] Test invalid flag (--invalid-flag shows error)
- [x] Test path aliases (--lib and --source-path both work)
- [x] Test --no-report suppression
- [x] Compare with old behavior (no regressions)

**META-TEST Phase Complete**: [x]

**Phase 2.2 Complete**: [x]
- Total time spent: ~2 hours / 2-3 hours
- Tests created: 9 / 9
- ArgParser fully migrated: [x]
- No regressions: [x]

---

### Phase 2 Summary

**Status**: ✅ COMPLETE

**Completion Checklist**:
- [x] analyze_tests uses ArgParser (Phase 2.1) - Commit dbd7993
- [x] analyze_coverage uses ArgParser (Phase 2.2) - Commit 3215f5f
- [x] All 4 tools now use ArgParser consistently
- [x] Help text consistent across all tools
- [x] Flag naming standardized
- [x] All tests passing (16 new unit tests total: 7 + 9)

**Phase 2 Complete**: [x]
- Total time spent: ~4 hours / 4-6 hours (within estimate)
- Tests created: 16 / 16 unit tests
- Both tools refactored: [x]
- No regressions: [x]

---

## 📋 Phase 3: Clean Up Stub Flags (1-2 hours)

**Status**: ✅ COMPLETE
**Priority**: 🟢 MEDIUM
**Goal**: Remove 9 partially implemented stub flags
**Methodology**: 🔴🟢♻️🔄 TDD
**Time Spent**: ~1 hour / 1-2 hours (under estimate!)

### Stub Flags to Remove

**analyze_tests** (3 stubs):
1. `--dependencies` / `-d` - Dependency analysis (feature not implemented)
2. `--mutation` / `-m` - Mutation testing (feature not implemented)
3. `--impact` - Impact analysis (feature not implemented)

**analyze_coverage** (6 stubs):
1. `--branch` - Branch coverage analysis (feature not implemented)
2. `--incremental` - Incremental coverage (feature not implemented)
3. `--mutation` - Mutation testing (feature not implemented)
4. `--watch` - Watch mode (feature not implemented)
5. `--parallel` - Parallel execution (feature not implemented)
6. `--impact` - Test impact analysis (feature not implemented)

**Rationale**: Better to remove broken promises than confuse users with non-functional flags

---

### 🔴 RED Phase (15 min)

**Test Checklist**:
- [x] Create test file: `test/unit/bin/stub_flags_removal_test.dart`
- [x] Test 1: `--dependencies` flag is rejected in analyze_tests
  - [x] Parse args with --dependencies
  - [x] Expect: Exception or error
  - [x] Expected: ✅ PASS (will pass after removal)
- [x] Test 2: `--mutation` flag is rejected in analyze_tests
- [x] Test 3: `--impact` flag is rejected in analyze_tests
- [x] Test 4: `--branch` flag is rejected in analyze_coverage
- [x] Test 5: `--incremental` flag is rejected in analyze_coverage
- [x] Test 6: `--mutation` flag is rejected in analyze_coverage
- [x] Test 7: `--watch` flag is rejected in analyze_coverage
- [x] Test 8: `--parallel` flag is rejected in analyze_coverage
- [x] Test 9: `--impact` flag is rejected in analyze_coverage
- [x] Test 10: Help text does NOT mention removed flags
- [x] Run: `dart test test/unit/bin/stub_flags_removal_test.dart`
- [x] Expected: ❌ All 10 tests fail (stubs still exist)

**RED Phase Complete**: [x]
- Total tests written: 15 / 15 (13 stub tests + 2 working flag tests)
- All tests failing: [x] (11/13 failed as expected)

---

### 🟢 GREEN Phase (30-45 min)

**Implementation Checklist**:

**analyze_tests** (lib/src/bin/analyze_tests_lib.dart):
- [x] Remove `--dependencies` from ArgParser definition
- [x] Remove `-d` short alias
- [x] Remove any related parsing code
- [x] Remove any placeholder variables
- [x] Remove from help text

- [x] Remove `--mutation` from ArgParser definition
- [x] Remove `-m` short alias
- [x] Remove any related parsing code
- [x] Remove any placeholder variables
- [x] Remove from help text

- [x] Remove `--impact` from ArgParser definition
- [x] Remove any related parsing code
- [x] Remove any placeholder variables
- [x] Remove from help text

**analyze_coverage** (lib/src/bin/analyze_coverage_lib.dart):
- [x] Remove `--branch` from ArgParser definition
- [x] Remove any related parsing code
- [x] Remove any placeholder variables
- [x] Remove from help text

- [x] Remove `--incremental` from ArgParser definition
- [x] Remove any related parsing code
- [x] Remove any placeholder variables
- [x] Remove from help text

- [x] Remove `--mutation` from ArgParser definition
- [x] Remove any related parsing code
- [x] Remove any placeholder variables
- [x] Remove from help text

- [x] Remove `--watch` from ArgParser definition
- [x] Remove any related parsing code
- [x] Remove any placeholder variables
- [x] Remove from help text

- [x] Remove `--parallel` from ArgParser definition
- [x] Remove any related parsing code
- [x] Remove any placeholder variables
- [x] Remove from help text

- [x] Remove `--impact` from ArgParser definition
- [x] Remove any related parsing code
- [x] Remove any placeholder variables
- [x] Remove from help text

- [x] Run: `dart test test/unit/bin/stub_flags_removal_test.dart`
- [x] Expected: ✅ All 15 tests pass

**GREEN Phase Complete**: [x]
- All tests passing: [x] (15/15)
- All 9 stubs removed: [x]

---

### ♻️ REFACTOR Phase (15 min)

**Refactor Checklist**:
- [x] Clean up any unused imports
- [x] Remove unused variables
- [x] Clean up comments mentioning removed features
- [x] Update CHANGELOG.md to document removal
- [x] Run `dart analyze` - Expected: 0 issues
- [x] Run `dart format .`
- [x] Run all tests: `dart test`

**REFACTOR Phase Complete**: [x]
- All tests passing: [x]
- dart analyze: 0 issues: [x]
- Code cleaned up: [x]

---

### 🔄 META-TEST Phase (15 min)

**Meta-Test Checklist**:
- [x] Test removed flags are rejected:
  ```bash
  dart run test_reporter:analyze_tests --dependencies
  ```
  - [x] Verify: Clear error message ("Unknown flag: --dependencies")
- [x] Test help text clean:
  ```bash
  dart run test_reporter:analyze_tests --help
  ```
  - [x] Verify: No mention of removed flags
- [x] Test help text clean:
  ```bash
  dart run test_reporter:analyze_coverage --help
  ```
  - [x] Verify: No mention of removed flags
- [x] Verify existing flags still work correctly

**META-TEST Phase Complete**: [x]

**Phase 3 Complete**: [x]
- Total time spent: ~1 hour / 1-2 hours (under estimate!)
- Tests created: 15 / 15 (13 stub tests + 2 working flag tests)
- All 9 stubs removed: [x]
- Documentation updated: [x]

---

## 📋 Phase 4: Document analyze_suite Behavior (30 min)

**Status**: ✅ COMPLETE
**Priority**: 🟢 LOW
**Goal**: Document why `analyze_suite` doesn't have `--no-report` flag

### Design Decision

**Finding**: `analyze_suite` does NOT have a `--no-report` flag

**Rationale**:
- `analyze_suite` is an **orchestrator tool**
- Its PRIMARY PURPOSE is to generate unified reports combining coverage + test analysis
- Adding `--no-report` would make the tool pointless
- This is intentional design, not an oversight

**Decision**: Document this as intentional, do NOT add the flag

---

### Implementation Checklist:

- [x] Add comment in `bin/analyze_suite.dart`:
  ```dart
  // NOTE: This tool does NOT support --no-report flag by design.
  // The suite orchestrator's primary purpose is to generate unified
  // reports combining coverage and test analysis. Use individual tools
  // (analyze_tests, analyze_coverage) with --no-report if you want
  // to skip report generation.
  ```

- [x] Update `README.md` to document flag availability:
  - [x] Removed stub flag references from examples (lines 177-178, 187, 238-240, 266-272)
  - [x] Cleaned up all documentation of removed flags

- [x] Add to `CLAUDE.md` documentation:
  ```markdown
  **Important**: `analyze_suite` does NOT support `--no-report` - this is
  intentional. The suite's purpose IS to generate unified reports. Use
  individual tools if you need to skip report generation.
  ```

- [x] Update help text in `bin/analyze_suite.dart`:
  ```dart
  print('Note: Reports are always generated (this tool\'s primary purpose).');
  print('      Use individual tools with --no-report to skip reports.');
  ```

**Phase 4 Complete**: [x]
- Documentation added to code: [x]
- README.md updated: [x]
- CLAUDE.md updated: [x]
- Help text clarified: [x]

---

## 📋 Phase 5: Comprehensive Flag Testing (3-4 hours)

**Status**: ⬜ PENDING
**Priority**: 🟡 HIGH
**Goal**: Create integration tests for ALL flags across all 4 tools
**Methodology**: 🔴🟢♻️🔄 TDD

---

### 5.1 analyze_tests Flag Tests (1 hour)

**File**: `test/integration/bin/analyze_tests_flags_test.dart`
**Status**: ⬜ PENDING
**Target**: ~20 integration tests for 15 flags

**Test Checklist**:
- [ ] Test all boolean flags:
  - [ ] `--verbose` / `-v` shows detailed output
  - [ ] `--interactive` / `-i` enters interactive mode
  - [ ] `--performance` / `-p` shows performance metrics
  - [ ] `--watch` / `-w` enters watch mode
  - [ ] `--parallel` runs tests in parallel
  - [ ] `--help` / `-h` shows help text
  - [ ] `--no-report` skips report (from Phase 1)
  - [ ] `--no-fixes` disables fix suggestions
  - [ ] `--no-checklist` disables checklists
  - [ ] `--minimal-checklist` shows compact checklist
  - [ ] `--include-fixtures` includes fixture tests
- [ ] Test numeric options:
  - [ ] `--runs=5` runs tests 5 times
  - [ ] `--slow=2.0` sets slow threshold to 2.0s
  - [ ] `--workers=8` uses 8 parallel workers
- [ ] Test string options:
  - [ ] `--module-name=custom` overrides module name
- [ ] Test flag combinations:
  - [ ] `--verbose --performance --runs=5` works correctly
  - [ ] `--no-report --verbose` shows output but no report
- [ ] Test aliases work:
  - [ ] `-v` equals `--verbose`
  - [ ] `-i -p -w` equals `--interactive --performance --watch`
- [ ] Test default values:
  - [ ] runs defaults to 3
  - [ ] slow defaults to 1.0
  - [ ] workers defaults to 4

**Tests Complete**: [ ] (0/20)

---

### 5.2 analyze_coverage Flag Tests (1 hour)

**File**: `test/integration/bin/analyze_coverage_flags_test.dart`
**Status**: ⬜ PENDING
**Target**: ~20 integration tests for 17 flags

**Test Checklist**:
- [ ] Test all boolean flags:
  - [ ] `--help` / `-h` shows help text
  - [ ] `--fix` generates missing tests
  - [ ] `--no-report` skips report generation
  - [ ] `--json` exports JSON report
  - [ ] `--no-checklist` disables checklists
  - [ ] `--minimal-checklist` shows compact checklist
  - [ ] `--verbose` shows detailed output
  - [ ] `--fail-on-decrease` fails when coverage drops
- [ ] Test path options:
  - [ ] `--lib=lib` uses lib directory
  - [ ] `--source-path=src` aliases to --lib
  - [ ] `--test=test` uses test directory
  - [ ] `--test-path=tests` aliases to --test
- [ ] Test numeric thresholds:
  - [ ] `--min-coverage=80` enforces minimum
  - [ ] `--warn-coverage=90` shows warning
- [ ] Test file options:
  - [ ] `--baseline=baseline.json` loads baseline
  - [ ] `--exclude='**/*_test.dart'` excludes files
- [ ] Test string options:
  - [ ] `--module-name=custom` overrides module name
- [ ] Test flag combinations:
  - [ ] `--fix --verbose` generates tests with output
  - [ ] `--min-coverage=80 --fail-on-decrease` enforces thresholds
- [ ] Test path aliases:
  - [ ] `--lib` and `--source-path` are equivalent
  - [ ] `--test` and `--test-path` are equivalent
- [ ] Test default values:
  - [ ] lib defaults to lib/src
  - [ ] test defaults to test
  - [ ] min-coverage defaults to 0
  - [ ] warn-coverage defaults to 0

**Tests Complete**: [ ] (0/20)

---

### 5.3 extract_failures Flag Tests (30 min)

**File**: `test/integration/bin/extract_failures_flags_test.dart`
**Status**: ⬜ PENDING (verify existing coverage)
**Target**: ~5 additional tests (most already exist)

**Test Checklist**:
- [ ] Verify existing tests cover all 14 flags
- [ ] Add missing tests if needed:
  - [ ] `--list-only` / `-l` lists without rerunning
  - [ ] `--auto-rerun` / `-r` reruns automatically (default: true)
  - [ ] `--watch` / `-w` watch mode
  - [ ] `--save-results` / `-s` saves report
  - [ ] `--verbose` / `-v` verbose output
  - [ ] `--group-by-file` / `-g` groups by file (default: true)
  - [ ] `--timeout` / `-t` sets timeout
  - [ ] `--parallel` / `-p` parallel execution
  - [ ] `--max-failures=10` limits failures
  - [ ] `--checklist` includes checklist (default: true)
  - [ ] `--minimal-checklist` compact checklist
  - [ ] `--module-name` overrides module name
- [ ] Test aliases work correctly
- [ ] Test default values (auto-rerun=true, group-by-file=true, checklist=true)

**Tests Complete**: [ ] (0/5)

---

### 5.4 analyze_suite Flag Tests (30 min)

**File**: `test/integration/bin/analyze_suite_flags_test.dart`
**Status**: ⬜ PENDING (verify existing coverage)
**Target**: ~5 additional tests (most already exist)

**Test Checklist**:
- [ ] Verify existing tests cover all 12 flags
- [ ] Add missing tests if needed:
  - [ ] `--path` / `-p` sets test path
  - [ ] `--runs` / `-r` sets number of runs
  - [ ] `--test-path` explicit test path
  - [ ] `--source-path` explicit source path
  - [ ] `--module-name` overrides module name
  - [ ] `--performance` enables profiling
  - [ ] `--verbose` / `-v` verbose output
  - [ ] `--parallel` parallel execution
  - [ ] `--checklist` includes checklist (default: true)
  - [ ] `--minimal-checklist` compact checklist
  - [ ] `--include-fixtures` includes fixtures
  - [ ] `--help` / `-h` shows help
- [ ] Test flag propagation to sub-tools
- [ ] Test aliases work correctly
- [ ] Test default values

**Tests Complete**: [ ] (0/5)

---

### 5.5 Edge Cases & Cross-Tool Tests (1 hour)

**File**: `test/integration/bin/flags_cross_tool_test.dart`
**Status**: ⬜ PENDING
**Target**: ~10 integration tests

**Test Checklist**:
- [ ] Test same flag across different tools:
  - [ ] `--verbose` consistent behavior in all 4 tools
  - [ ] `--module-name` works the same in all 4 tools
  - [ ] `--help` / `-h` consistent format in all 4 tools
- [ ] Test checklist flags across tools:
  - [ ] `--checklist` default=true in extract_failures & analyze_suite
  - [ ] `--no-checklist` works in analyze_tests & analyze_coverage
  - [ ] `--minimal-checklist` works consistently
- [ ] Test invalid flags are rejected:
  - [ ] Unknown flag `--invalid` rejected in all tools
  - [ ] Clear error messages in all tools
- [ ] Test help text consistency:
  - [ ] All tools use similar format
  - [ ] All flags documented clearly
  - [ ] Examples provided
- [ ] Test flag conflicts:
  - [ ] `--no-report --minimal-checklist` (report disabled, checklist moot)
  - [ ] Conflicting paths handled gracefully
- [ ] Test numeric validation:
  - [ ] `--runs=-1` rejected
  - [ ] `--min-coverage=150` rejected (>100)
  - [ ] `--timeout=-10` rejected

**Tests Complete**: [ ] (0/10)

---

### Phase 5 Summary

**Status**: ⬜ PENDING

**Completion Checklist**:
- [ ] analyze_tests flag tests (20 tests) - Phase 5.1
- [ ] analyze_coverage flag tests (20 tests) - Phase 5.2
- [ ] extract_failures flag tests (5 tests) - Phase 5.3
- [ ] analyze_suite flag tests (5 tests) - Phase 5.4
- [ ] Edge cases & cross-tool tests (10 tests) - Phase 5.5
- [ ] **Total**: 60 new integration tests created
- [ ] All tests passing
- [ ] 100% flag coverage verified

**Phase 5 Complete**: [ ]
- Total time spent: 0 hours / 3-4 hours
- Tests created: 0 / 60
- All flags verified: [ ]

---

## 📊 Final Summary

### Overall Progress

```
Phase 1: [ ] Fix --no-report Bug - 0% (⬜ PENDING)
Phase 2: [ ] Standardize ArgParser - 0% (⬜ PENDING)
  [ ] 2.1 analyze_tests - 0%
  [ ] 2.2 analyze_coverage - 0%
Phase 3: [ ] Clean Up Stubs - 0% (⬜ PENDING)
Phase 4: [ ] Document Behavior - 0% (⬜ PENDING)
Phase 5: [ ] Flag Testing - 0% (⬜ PENDING)
  [ ] 5.1 analyze_tests - 0%
  [ ] 5.2 analyze_coverage - 0%
  [ ] 5.3 extract_failures - 0%
  [ ] 5.4 analyze_suite - 0%
  [ ] 5.5 Edge cases - 0%

Total Progress: 0% (Planning Complete, Implementation Pending)
```

### Metrics

| Metric | Target | Current | Status |
|--------|--------|---------|--------|
| **Flags Audited** | 65 | 65 | ✅ COMPLETE |
| **Critical Bugs Fixed** | 1 | 0 | ⬜ PENDING |
| **Tools Using ArgParser** | 4 | 2 | ⚠️ 50% |
| **Stub Flags Removed** | 9 | 0 | ⬜ PENDING |
| **Flags with Integration Tests** | 65 | ~30 | ⚠️ 46% |
| **New Tests Created** | ~60 | 0 | ⬜ PENDING |
| **Documentation Updated** | 4 files | 0 | ⬜ PENDING |

### Flag Summary by Tool

| Tool | Total Flags | Working | Broken | Stubs | ArgParser |
|------|-------------|---------|--------|-------|-----------|
| analyze_tests | 18 | 14 | 1 | 3 | ❌ → ✅ |
| analyze_coverage | 23 | 17 | 0 | 6 | ❌ → ✅ |
| extract_failures | 14 | 14 | 0 | 0 | ✅ |
| analyze_suite | 12 | 12 | 0 | 0 | ✅ |
| **TOTAL** | **67** | **57** | **1** | **9** | **2/4 → 4/4** |

### Quality Gates

**Phase 1 Complete When**:
- [ ] `--no-report` in `analyze_tests` prevents ALL output
- [ ] 5 integration tests created and passing
- [ ] Manual testing verifies fix works
- [ ] `dart analyze` shows 0 issues

**Phase 2 Complete When**:
- [ ] Both tools use ArgParser
- [ ] 14 new unit tests created and passing
- [ ] Help text consistent across all tools
- [ ] No regressions in existing functionality

**Phase 3 Complete When**:
- [ ] All 9 stub flags removed
- [ ] 10 new tests verify flags rejected
- [ ] Help text updated
- [ ] CHANGELOG.md documents removal

**Phase 4 Complete When**:
- [ ] Documentation added to 4 files
- [ ] Design decision clearly explained
- [ ] Users understand why flag doesn't exist

**Phase 5 Complete When**:
- [ ] 60 new integration tests created
- [ ] All 65 flags verified working
- [ ] Cross-tool consistency confirmed
- [ ] Edge cases covered

**ALL PHASES Complete When**:
- [ ] 1 critical bug fixed
- [ ] 4 tools use ArgParser consistently
- [ ] 9 stub flags removed
- [ ] ~89 new tests created (5 + 14 + 10 + 60)
- [ ] All tests passing
- [ ] Documentation updated
- [ ] `dart analyze` - 0 issues
- [ ] `dart format` - all files formatted
- [ ] All 4 tools self-test successfully
- [ ] README.md has complete flag matrix

---

## 🚀 Next Steps

**Current Status**: Planning complete, ready to begin implementation

**Implementation Order** (by priority):
1. **Phase 1** (CRITICAL) - Fix `--no-report` bug in analyze_tests
2. **Phase 2** (HIGH) - Standardize ArgParser for consistency
3. **Phase 3** (MEDIUM) - Remove stub flags to prevent confusion
4. **Phase 5** (HIGH) - Comprehensive testing for reliability
5. **Phase 4** (LOW) - Documentation for clarity

**Immediate Next Action**: Begin Phase 1 (🔴 RED phase)
1. Create test file: `test/integration/bin/analyze_tests_no_report_test.dart`
2. Write 5 failing tests demonstrating the bug
3. Verify tests fail correctly
4. Proceed to GREEN phase

---

## 📝 Notes & Blockers

### Current Blockers

- None

### Implementation Strategy

- **TDD Mandatory**: All changes follow 🔴🟢♻️🔄 cycle
- **Test First**: Write failing tests before implementation
- **Incremental**: Complete one phase before starting next
- **Quality**: Run `dart analyze` and `dart format` after each phase
- **Self-Test**: Run all 4 tools on themselves after changes

### Design Decisions

1. **ArgParser Standardization**: Use ArgParser for all CLI parsing (consistency + safety)
2. **Stub Removal**: Remove incomplete features rather than leaving broken promises
3. **analyze_suite --no-report**: Document as intentional omission (orchestrator's purpose is reports)
4. **Flag Naming**: Consistent naming across all tools (--verbose, --module-name, etc.)
5. **Negatable Flags**: Change from `--no-flag` to `--flag` with negatable:true where appropriate

### Key Reference Files

- **Investigation Report**: Embedded in this tracker (Section: Complete Flag Inventory)
- **bin-coverage-100-tracker.md**: Template for this tracker structure
- **CLAUDE.md**: Project guidelines and commit message format
- **README.md**: User-facing documentation (to be updated with flag matrix)

---

## 🔄 Update History

- **2025-11-09**: Tracker created - Planning complete
- **2025-11-09**: Investigation complete - 65 flags audited, 1 critical bug found, 9 stubs identified

---

**Ready to begin Phase 1!** 🚀
