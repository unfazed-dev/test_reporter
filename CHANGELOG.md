# Changelog

All notable changes to the test_reporter package will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Removed

#### CLI Flag Cleanup - Stub Flag Removal

**analyze_tests** - Removed 3 unimplemented stub flags:
- `--dependencies` / `-d`: Dependency analysis feature (never implemented)
- `--mutation` / `-m`: Mutation testing feature (never implemented)
- `--impact`: Test impact analysis feature (never implemented)

**analyze_coverage** - Removed 6 unimplemented stub flags:
- `--branch`: Branch coverage analysis (never implemented)
- `--incremental`: Incremental coverage for changed files (never implemented)
- `--mutation`: Mutation testing (never implemented)
- `--watch`: Watch mode (never implemented)
- `--parallel`: Parallel execution (never implemented)
- `--impact`: Test impact analysis (never implemented)

**Rationale**: These flags were parsed but had no implementation, causing user confusion. Removing broken promises provides a cleaner, more honest UX.

**Migration**: If you were using these flags, simply remove them from your CLI commands. The flags had no effect, so removal will not change behavior.

---

### Fixed

#### --module-name Auto-Qualification

**Problem**: Manual `--module-name` values were not being qualified with required suffixes (-fo/-fi/-pr), causing inconsistent report naming.

**Solution**: All 3 tools now auto-qualify manual module names:
- `--module-name utils` + folder path → `utils-fo`
- `--module-name report_utils` + file path → `report-utils-fi`
- `--module-name my_tests` + project path → `my-tests-pr`

**Validation**: Throws ArgumentError if pre-qualified name doesn't match detected path type:
- ❌ `--module-name utils-fi` for folder path (invalid)
- ✅ `--module-name utils-fo` for folder path (valid)

**Implementation**:
- Added `ModuleIdentifier.qualifyManualModuleName()` function
- Updated `analyze_tests_lib.dart`, `analyze_coverage_lib.dart`, `extract_failures_lib.dart`
- All tools now call `qualifyManualModuleName()` when `--module-name` is provided
- Help text updated with "(auto-qualified with -fo/-fi/-pr)" note

**Backward Compatibility**: Already-qualified names (e.g., `--module-name utils-fo`) continue to work, now with validation.

---

## [3.1.0] - 2025-11-06

**Feature Release**: Interactive actionable checklists in all reports.

---

### Added

#### Actionable Checklists

**ChecklistUtils** (`lib/src/utils/checklist_utils.dart`):
- `ChecklistItem`: Represents individual checklist tasks with sub-items, tips, and commands
- `ChecklistSection`: Groups checklist items with titles, subtitles, and priority levels
- `ChecklistPriority`: Enum for critical, important, and optional priorities
- Helper functions:
  - `formatLineRangeDescription()`: Converts line numbers to human-readable descriptions
  - `suggestTestFile()`: Infers test file paths from source file paths
  - `groupLinesIntoTestCases()`: Groups consecutive uncovered lines into logical test cases
  - `prioritizeItems()`: Sorts checklist items by severity
- 31 comprehensive unit tests (100% passing)
- Exported in main library: `package:test_reporter/test_reporter.dart`

**Coverage Analyzer Checklists** (`analyze_coverage_lib.dart`):
- `## ✅ Coverage Action Items` section in all coverage reports
- Checklist of files needing test coverage with:
  - Grouped consecutive lines as logical test cases
  - Suggested test file paths with directory inference
  - Step-by-step sub-items (open file, write tests, run tests)
  - Tips for edge cases and error conditions
  - Quick commands section with copy-pasteable bash commands
  - Progress tracking footer showing completion status
- CLI flags: `--no-checklist` (disable) and `--minimal-checklist` (compact format)

**Test Reliability Checklists** (`analyze_tests_lib.dart`):
- `## ✅ Test Reliability Action Items` section in all test analysis reports
- 3-tier priority system:
  - 🔴 **Priority 1: Fix Failing Tests** - Critical issues blocking CI/CD
    - Failure type identification (Null Error, Timeout, Assertion, etc.)
    - Targeted fix suggestions based on failure patterns
    - Verification commands per failing test
  - 🟠 **Priority 2: Stabilize Flaky Tests** - Important reliability improvements
    - Reliability percentage (e.g., "66.7% reliable")
    - Common cause checklist (race conditions, shared state, async issues)
    - Stability verification command (run 10x in loop)
  - 🟡 **Priority 3: Optimize Slow Tests** - Optional performance improvements
    - Average duration display
    - Optimization strategy checklist (mocking, scope reduction, parallel execution)
- Per-priority progress tracking
- Quick commands section for batch operations
- CLI flags: `--no-checklist` (disable) and `--minimal-checklist` (compact format)

**Failure Triage Checklists** (`extract_failures_lib.dart`):
- `## ✅ Failure Triage Workflow` section in all failure extraction reports
- 3-step workflow per failing test:
  - **Step 1: Identify root cause** with truncated error snippet (200 char max)
  - **Step 2: Apply fix** with code modification reminder
  - **Step 3: Verify fix** with copy-pasteable test command
- Grouped by file for batch processing
- Progress tracking showing triaged percentage
- Quick commands section with batch rerun commands per file
- CLI flags: `--checklist` (default: true) and `--minimal-checklist` (compact format)

**Master Workflow Checklists** (`analyze_suite_lib.dart`):
- `## ✅ Recommended Workflow` section in unified suite reports
- 3-phase strategic approach:
  - **Phase 1: Critical Issues** (🔴) - Failing tests + low coverage (< 80%)
  - **Phase 2: Stability** (🟠) - Flaky test stabilization
  - **Phase 3: Optimization** (🟡) - Slow test performance improvements
- Combines data from coverage and test analysis
- Per-phase progress tracking
- Links to detailed reports for drill-down
- Master progress counter across all phases
- CLI flags: `--checklist` (default: true) and `--minimal-checklist` (compact format)

**CLI Flag Support** (All 4 tools):
- `--no-checklist`: Completely disables checklist generation in reports
- `--minimal-checklist`: Generates compact single-line checklists without sub-items or tips
- Flags propagate through suite orchestrator to child analyzers
- Default behavior: Full detailed checklists enabled

---

### Changed

- **Report Format**: All markdown reports now include actionable checklist sections by default
- **Header Documentation**: Added checklist flags to usage help text in all 4 CLI tools
- **Token Usage**: Added ~50 lines per analyzer for checklist generation methods

---

### Documentation

- Updated `.agent/knowledge/report_system.md` with comprehensive checklist documentation
  - Overview of checklist feature across all 4 analyzers
  - CLI flag reference table
  - Full mode vs minimal mode comparison
  - Example checklists for each analyzer type
  - Implementation details with code examples
  - Best practices and GitHub integration workflow
- Updated `.agent/templates/report_format_template.md` with checklist section template
  - Checklist markdown template structure
  - Best practices for checklist design
  - Implementation guide using ChecklistUtils
- Updated documentation index in `.agent/README.md` (not modified in this release)

---

## [3.0.0] - 2025-11-05

**Major Version**: Complete architectural re-engineering with enhanced CLI and cross-tool features.

---

### Added

#### Phase 1: Foundation Utilities (Core Architecture)

**PathResolver** (`lib/src/utils/path_resolver.dart`):
- Automatic bidirectional path inference (test ↔ source)
- Smart mapping: `test/` ↔ `lib/src/` (priority 1) or `lib/` (priority 2)
- File mapping: `test/auth_test.dart` ↔ `lib/src/auth.dart`
- Path existence validation with `validatePaths()`
- Cross-platform support (Windows vs Unix path separators)
- 26 comprehensive unit tests (100% passing)

**ModuleIdentifier** (`lib/src/utils/module_identifier.dart`):
- Qualified module naming: `{module}-{fo|fi|pr}` format
  - `-fo`: Folder analysis (e.g., `test/auth/` → `auth-fo`)
  - `-fi`: File analysis (e.g., `test/auth_test.dart` → `auth-fi`)
  - `-pr`: Project-wide (e.g., `test/` → `test-pr`)
- Bidirectional parsing: `parseQualifiedName()` extracts base name and type
- Name validation and normalization (underscores → hyphens)
- 37 comprehensive unit tests (100% passing)

**ReportManager** (`lib/src/utils/report_manager.dart`):
- Unified report generation (markdown + JSON in atomic operation)
- Automatic cleanup with configurable keep count (default: latest 1)
- Report context tracking (timestamp, reportId, subdirectory)
- `findLatestReport()` for querying by criteria
- `extractJsonFromReport()` for markdown-embedded JSON parsing
- 26 comprehensive unit tests (100% passing)

#### Phase 2: Tool Refactoring (Code Quality)

- **analyze_coverage_lib**: Removed 67 lines (2,200 → 2,133)
  - Replaced custom path inference with PathResolver
  - Replaced `_extractPathName()` with ModuleIdentifier
  - Integrated ReportManager for unified reporting
- **analyze_tests_lib**: Removed 32 lines (2,694 → 2,662)
  - Consistent module naming with ModuleIdentifier
  - ReportManager for both tests and failures reports
  - Removed manual cleanup logic
- **analyze_suite_lib**: Removed 71 lines (1,121 → 1,050)
  - Deleted 3 duplicate methods (detectSourcePath, detectTestPath, extractModuleName)
  - Integrated PathResolver for consistent path handling
  - Simplified orchestration logic
- **extract_failures_lib**: Module naming simplified
  - Consistent qualified naming across all tools

**Total**: 170 lines of duplicate code eliminated (79% of target)

#### Phase 3: Enhanced Features

**CLI Flags** (All 4 tools):
- `--test-path`: Explicit test path override
- `--source-path`: Explicit source path override (alias for --lib in coverage)
- `--module-name`: Custom module name for report generation
- Consistent flag support across analyze_coverage, analyze_tests, analyze_suite, extract_failures

**Input Validation** (All 4 tools):
- Path validation with existence checks before analysis
- Clear error messages showing which paths exist (✓) or don't exist (✗)
- Helpful usage examples on validation failures
- Exit code 2 for validation errors (distinct from test failures = 1)

**ReportRegistry System** (`lib/src/utils/report_registry.dart`):
- Session-wide tracking of all generated reports
- Cross-tool report discovery and querying
- Filter by `toolName`, `reportType`, or `moduleName`
- `printSummary()` for report overview
- 11 comprehensive unit tests (100% passing)
- Exported in main library: `package:test_reporter/test_reporter.dart`

---

### Changed

#### Report Naming Convention

**Old Format** (v2.x):
```
{module_name}_{report_type}@HHMM_DDMMYY.{md|json}
```

**New Format** (v3.0):
```
{module_name}-{qualifier}_{tool}_{type}@YYYYMMDD-HHMM.{md|json}
```

**Examples**:
- v2.x: `auth_service_coverage@1435_041125.md`
- v3.0: `auth-service-fo_report_coverage@20251105-1435.md`

#### Module Name Extraction

- Now uses ModuleIdentifier for consistent qualified naming
- Automatic qualifier based on path type (folder/file/project)
- Override available with `--module-name` flag
- Underscores converted to hyphens for consistency

#### Path Resolution

- Coverage tool now accepts test OR source path (other auto-inferred)
- PathResolver handles bidirectional inference with priority ordering
- Validation checks both paths exist before analysis
- Clear error messages guide users on path issues

---

### Breaking Changes

**1. Report Naming Format**

Module names now include qualifiers:
- `-fo` suffix for folder analysis
- `-fi` suffix for file analysis
- `-pr` suffix for project-wide analysis

**Migration**: Update any scripts parsing report filenames to handle new format.

**2. Path Inference Behavior**

PathResolver uses priority-based inference:
- Priority 1: `test/` ↔ `lib/src/` (most common)
- Priority 2: `test/` ↔ `lib/` (fallback)

**Migration**: Verify path mappings work as expected. Use explicit `--test-path` or `--source-path` flags if needed.

**3. Module Name Generation**

Underscores in path names are now converted to hyphens in module names.

**Migration**: Update any scripts expecting underscore-based module names.

**4. Coverage Tool Arguments**

The coverage tool now accepts a single path argument (test or source), with the other inferred.

**Migration**:
```bash
# Old (v2.x) - required both paths
dart run test_reporter:analyze_coverage --lib lib/src --test test/

# New (v3.0) - provide one, other inferred
dart run test_reporter:analyze_coverage test/
# Or
dart run test_reporter:analyze_coverage lib/src/

# Explicit override still supported
dart run test_reporter:analyze_coverage test/ --source-path lib/src/
```

---

### Fixed

- **Path Resolution Bugs**: Centralized PathResolver eliminates inconsistent path handling across tools
- **Module Naming Conflicts**: ModuleIdentifier ensures consistent naming across all 4 tools
- **Duplicate Code**: 170 lines of duplicate code removed, reducing maintenance burden
- **Report Cleanup**: ReportManager provides reliable cleanup with safety checks

---

### Testing

**New Tests**:
- PathResolver: 26 unit tests (100% passing)
- ModuleIdentifier: 37 unit tests (100% passing)
- ReportManager: 26 unit tests (100% passing)
- ReportRegistry: 11 unit tests (100% passing)

**Total Tests**: 313 unit tests passing (100%)

**Meta-Testing**: All 4 tools tested on test_reporter itself
- analyze_coverage: ✅ Report generated
- analyze_tests: ✅ Report generated
- extract_failures: ✅ Report generated
- analyze_suite: ✅ Unified report generated

**Quality Gates**:
- ✅ 0 analyzer issues
- ✅ All files formatted
- ✅ All tools verified working with real data

---

### Metrics

| Metric | Value |
|--------|-------|
| Lines removed | 170 (79% of 215 target) |
| New utilities | 4 (PathResolver, ModuleIdentifier, ReportManager, ReportRegistry) |
| New unit tests | 100 |
| Total tests | 313 (100% passing) |
| Tools refactored | 4/4 (100%) |
| Analyzer issues | 0 |

---

### Upgrade Guide

**1. Install v3.0.0**
```bash
dart pub global activate test_reporter
# Or update pubspec.yaml
test_reporter: ^3.0.0
```

**2. Update Scripts**

If you parse report filenames:
```dart
// Old (v2.x)
final regex = RegExp(r'(.+)_(.+)@(\d{4})_(\d{6})\.md');

// New (v3.0)
final regex = RegExp(r'(.+)-(\w+)_(\w+)_(\w+)@(\d{8})-(\d{4})\.md');
```

**3. Verify Path Mappings**

Run tools with `--verbose` to see path resolution:
```bash
dart run test_reporter:analyze_coverage test/ --verbose
# Shows: Source path inferred: lib/src/
```

**4. Update CI/CD**

If checking report names in CI:
```bash
# Old
ls tests_reports/coverage/auth_service_coverage@*.md

# New
ls tests_reports/coverage/auth-service-fo_report_coverage@*.md
```

---

### Acknowledgments

Developed using TDD methodology (🔴🟢♻️🔄) with 100% test coverage for all new utilities.

---

## [2.0.0] - 2024

### Added
- Coverage analysis with branch coverage support
- Flaky test detection with multiple test runs
- Performance profiling and slow test detection
- Failed test extraction and rerun capabilities
- Unified reporting system
- Modern Dart 3+ features (sealed classes, records)

---

## [1.0.0] - Initial Release

- Basic test analysis capabilities
- Simple coverage reporting
- Test failure extraction
