# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

**Last Updated**: November 2025

> **CRITICAL**: This file is automatically loaded by Claude Code at session start. Contains essential project rules and session startup procedures.

---

## 🎯 Communication Philosophy

**Objective First**: Prioritize technical accuracy over agreement. If a proposed approach has issues, explain them directly with better alternatives. Challenge suboptimal decisions, question assumptions, and provide honest technical assessment even when it contradicts requests. Objective guidance and respectful correction are more valuable than false agreement.

---

## 🚨 MANDATORY Session Startup Protocol

**Before doing ANYTHING, you MUST:**

1. ✅ **Check Context Usage**: Run `/context` to see current token usage
2. ✅ **Read Documentation Index**: Load `.agent/README.md` for complete project context
3. ✅ **Estimate Token Requirements**: Plan for context management based on task size
4. ✅ **Check Active MCP Servers**: Run `/mcp` and disable unused servers to save tokens

**Why?** Claude Code has a **200K token** context window, and MCP servers alone can consume 66K+ tokens (33% of total!). Proactive management prevents hitting 95% auto-compact.

---

## 📚 Documentation System

**All documentation lives in `.agent/` directory** - ALWAYS check there first!

### Directory Structure

```
.agent/
├── README.md                            # 📖 START HERE - Complete documentation index
├── knowledge/                            # Project context files
│   ├── full_codebase.md                # Complete project overview
│   ├── analyzer_architecture.md        # How analyzers work
│   ├── report_system.md                # Report generation system
│   ├── failure_patterns.md             # Failure type patterns
│   ├── modern_dart_features.md         # Sealed classes, records
│   └── tdd_methodology.md              # 🔴🟢♻️ TDD red-green-refactor cycle (MANDATORY)
├── guides/                             # 📋 Standard Operating Procedures (7 guides)
│   ├── 01_adding_failure_pattern.md
│   ├── 02_adding_new_analyzer.md
│   ├── 03_adding_report_type.md
│   ├── 04_publishing_release.md
│   ├── 05_extending_record_types.md
│   ├── 06_debugging_analyzer.md
│   └── 07_self_testing.md
├── templates/                           # Code templates
│   ├── analyzer_template.dart
│   ├── failure_type_template.dart
│   ├── record_type_template.dart
│   └── report_format_template.md
└── archives/                            # Conversation archives
    └── conversations/
```

**Before ANY implementation**: Read `.agent/README.md` first to get full context.

---

## 💾 Git Commit Message Format

**STRICT FORMAT - NO EXCEPTIONS:**

```bash
# Correct format
feat: add user profile management
fix: resolve navigation bug in onboarding flow
chore: update dependencies
test: add ViewModel unit tests
docs: update architecture documentation

# NEVER include author attribution or footers like:
❌ 🤖 Generated with [Claude Code](https://claude.com/claude-code)
❌ Co-Authored-By: Claude <noreply@anthropic.com>
```

**Single line summary only** - commit message describes WHAT changed, not WHO did it.

---

## Project Overview

test_reporter is a **Dart package** (NOT a Flutter app) providing comprehensive test reporting tools for Flutter/Dart projects. It exposes 4 CLI executables for test analysis, coverage analysis, failure extraction, and unified reporting.

**Key Characteristics:**
- Pure Dart package (no Flutter dependencies)
- CLI tools designed for global activation or project dependency
- Uses modern Dart 3+ features (sealed classes, records)
- Self-testing meta-strategy (the test tools test themselves)

---

## Development Commands

### Essential Dart Commands

- **Install dependencies**: `dart pub get`
- **Run analyzer**: `dart analyze`
- **Format code**: `dart format .`
- **Publish (dry-run)**: `dart pub publish --dry-run`
- **Publish to pub.dev**: `dart pub publish`

### Running Tools (Development)

```bash
# Run from bin/ during development
dart bin/analyze_tests.dart --help
dart bin/analyze_coverage.dart --help
dart bin/extract_failures.dart --help
dart bin/analyze_suite.dart --help

# Run specific tool
dart bin/analyze_tests.dart --runs=5 --performance
dart bin/analyze_coverage.dart --fix lib/src/core
dart bin/extract_failures.dart test/ --watch
dart bin/analyze_suite.dart --verbose
```

### Running Tools (After Global Activation)

```bash
# Install globally
dart pub global activate test_reporter

# Use directly
analyze_tests --runs=5
analyze_coverage --fix
extract_failures test/
analyze_suite --performance
```

### Running Tools (As Project Dependency)

```bash
# Add to dev_dependencies in pubspec.yaml
# Then run with dart run:
dart run test_reporter:analyze_tests --runs=5
dart run test_reporter:analyze_coverage --fix
dart run test_reporter:extract_failures test/
dart run test_reporter:analyze_suite --performance
```

---

## 🚀 CRITICAL: Context & Token Optimization (2025)

**Proactive context management is essential for optimal performance.**

### Context Health Thresholds (200K Claude Code Window)

| Usage | Tokens | Status | Action |
|-------|--------|--------|--------|
| < 60% | < 120K | 🟢 Healthy | Continue normally |
| 60-75% | 120K-150K | 🟡 Monitor | Check at task transitions with `/context` |
| 75-85% | 150K-170K | 🟠 Caution | Use `/clear` at task boundary or `/compact` if mid-task |
| 85-95% | 170K-190K | 🔴 Critical | **COMPACT NOW** with `/compact preserve [instructions]` |
| > 95% | > 190K | 🚨 Emergency | Auto-compact triggers (you lose control!) |

### Essential Commands

```bash
# Check current context usage (at task transitions!)
/context

# Clear context between tasks (Anthropic recommended - use frequently!)
/clear

# Smart compact mid-task (if you can't /clear)
/compact preserve [specific instructions about what to keep]

# View session token costs
/cost

# Manage MCP servers (disable unused ones!)
/mcp
```

**Anthropic Official Guidance**: "Use the `/clear` command **frequently** during long sessions to keep context focused" - especially between different tasks.

### Token Estimation Before Starting

**Small task** (< 2 hrs): 50-100K tokens - No compact needed
**Medium task** (2-6 hrs): 100-300K tokens - Plan 1 compact
**Large task** (6+ hrs): 300-800K tokens - Plan 2-3 compacts
**Epic task** (multi-day): 800K+ tokens - Plan 5-10+ compacts

**Reference**: `.agent/guides/` for task-specific guidance

---

## Code Architecture

### Entry Point Pattern

All executables follow a consistent separation pattern:
- **bin/*.dart**: Minimal entry points that import and delegate to library implementations
- **lib/src/bin/*_lib.dart**: Contains the actual business logic and implementation

This pattern keeps bin/ clean and allows the logic to be tested and reused as a library.

**Example:**
```dart
// bin/analyze_tests.dart
import 'package:test_reporter/src/bin/analyze_tests_lib.dart' as analyzer_lib;

void main(List<String> args) {
  analyzer_lib.main(args);
}
```

### Directory Structure

```
lib/
├── test_reporter.dart                   # Main library export file
└── src/
    ├── bin/                             # CLI tool implementations
    │   ├── analyze_tests_lib.dart       # Test reliability analyzer (2,663 lines)
    │   ├── analyze_coverage_lib.dart    # Coverage analyzer (2,199 lines)
    │   ├── extract_failures_lib.dart    # Failure extractor (791 lines)
    │   └── analyze_suite_lib.dart       # Unified orchestrator (1,046 lines)
    ├── models/                          # Type definitions
    │   ├── failure_types.dart           # Sealed classes for failure types
    │   └── result_types.dart            # Record types for results
    └── utils/                           # Shared utilities
        ├── report_utils.dart            # Report generation and management
        ├── formatting_utils.dart        # Output formatting
        ├── path_utils.dart              # Path manipulation
        ├── extensions.dart              # Extension methods
        └── constants.dart               # Shared constants
```

### Modern Dart Features

This codebase uses modern Dart 3+ features:

#### Sealed Classes (`lib/src/models/failure_types.dart`)

Provides exhaustive pattern matching for failure types:

```dart
sealed class FailureType {
  const FailureType();
  String get category;
  String? get suggestion;
}

final class AssertionFailure extends FailureType { ... }
final class NullError extends FailureType { ... }
final class TimeoutFailure extends FailureType { ... }

// Compiler ensures all cases are handled
switch (failure) {
  case AssertionFailure(:final message):
    print('Assertion failed: $message');
  case NullError(:final variableName):
    print('Null error on $variableName');
  case TimeoutFailure(:final duration):
    print('Test timed out after $duration');
  // ... other cases - compiler warns if any are missing
}
```

#### Records (`lib/src/models/result_types.dart`)

Lightweight way to return multiple values:

```dart
typedef AnalysisResult = ({
  bool success,
  int totalTests,
  int passedTests,
  int failedTests,
  String? error,
});

// Usage with destructuring
final (success: ok, data: analysisData) = await runTestAnalysis();

// Or access by name
final result = await runTestAnalysis();
print('Success: ${result.success}, Total: ${result.totalTests}');
```

### Report Generation System

All tools generate reports in `tests_reports/` with subdirectories:
- `tests_reports/tests/` - Test reliability reports
- `tests_reports/coverage/` - Coverage analysis reports
- `tests_reports/failures/` - Failed test extraction reports
- `tests_reports/suite/` - Unified suite reports

**Report Naming Convention**:
- Format: `{module_name}_{report_type}@HHMM_DDMMYY.{md|json}`
- Module suffix: `-fo` (folder analysis), `-fi` (file analysis)
- Example: `auth_service-fo_coverage@1435_041125.md`

**Report Management**:
- `ReportUtils.cleanOldReports()` removes old reports, keeping only latest per pattern
- Both markdown (human-readable) and JSON (machine-parseable) formats generated

### Key Classes

**TestAnalyzer** (`lib/src/bin/analyze_tests_lib.dart` - 2,663 lines):
- Runs tests multiple times to detect flaky tests
- Pattern recognition for failure types (null errors, timeouts, assertions, etc.)
- Performance profiling
- Generates detailed reports with fix suggestions

**CoverageAnalyzer** (`lib/src/bin/analyze_coverage_lib.dart` - 2,199 lines):
- Line and branch coverage analysis
- Incremental coverage for changed files
- Auto-generation of missing test cases (with `--fix`)
- Coverage thresholds and validation

**FailedTestExtractor** (`lib/src/bin/extract_failures_lib.dart` - 791 lines):
- Parses JSON reporter output to identify failures
- Generates targeted rerun commands
- Groups failures by file for batch execution

**TestOrchestrator** (`lib/src/bin/analyze_suite_lib.dart` - 1,046 lines):
- Runs all analysis tools in sequence
- Combines results into unified report
- Handles module name extraction from test paths

---

## 🔴🟢♻️ TDD Methodology (MANDATORY)

**ALL development MUST follow Test-Driven Development (TDD)** with the red-green-refactor cycle.

### The Cycle

1. **🔴 RED**: Write a failing test FIRST
   - Test describes desired behavior
   - Run test to confirm it fails with expected message
   - No implementation code yet!

2. **🟢 GREEN**: Write minimal code to pass the test
   - Only write code to make the test pass
   - Keep it simple, no premature optimization
   - Run test to confirm it passes

3. **♻️ REFACTOR**: Clean up while keeping tests green
   - Improve code quality, readability, maintainability
   - Update exhaustive pattern matches
   - Run all tests to ensure nothing broke

4. **🔄 META-TEST**: Self-test with analyzers
   - Run tools on themselves to verify behavior
   - Check generated reports are clean

### Quick TDD Commands

```bash
# 🔴 RED: Run test to see failure
dart test test/unit/models/failure_types_test.dart

# 🟢 GREEN: Run test to confirm pass
dart test test/unit/models/failure_types_test.dart

# ♻️ REFACTOR: Run all tests + analyzer
dart test
dart analyze

# 🔄 META-TEST: Run tool on itself
dart run test_reporter:analyze_tests --path=test
```

### Why TDD for test_reporter?

- ✅ We're building test analysis tools - our code must be thoroughly tested
- ✅ Pattern detection logic is complex and error-prone without tests
- ✅ Sealed classes require exhaustive test coverage
- ✅ Meta-testing strategy aligns perfectly with TDD
- ✅ Prevents regressions in analyzer behavior

**📖 Complete TDD Guide**: `.agent/knowledge/tdd_methodology.md`

**All development guides** (`.agent/guides/*.md`) include explicit TDD steps.

---

## 🔴 Testing Strategy

### Self-Testing Approach

**Meta-testing**: This package uses a unique self-testing strategy where the test tools test themselves.

```bash
# Run the suite analyzer on itself
dart run test_reporter:analyze_suite bin/ --runs=3

# Run coverage analyzer on the package
dart run test_reporter:analyze_coverage lib/src --fix

# Extract any failures
dart run test_reporter:extract_failures test/
```

### Fixture Generation

Integration tests use generated fixtures:

```bash
# Generate integration test fixtures
dart run scripts/generate_integration_tests.dart

# Generate test fixtures
dart run scripts/fixture_generator.dart
```

### Integration Tests (Important!)

**Integration tests are SKIPPED by default** to prevent polluting the `tests_reports/` directory with mock data during normal test runs.

**Running Unit Tests Only (Default)**:
```bash
dart test  # Runs 778 unit tests, skips 165 integration tests
```

**Running Integration Tests Explicitly**:
```bash
# Run ONLY integration tests
dart test --tags integration

# Run ALL tests (unit + integration)
dart test --tags unit,integration

# Run specific integration test file
dart test test/integration/bin/coverage_analyzer_workflow_test.dart --tags integration
```

**Why Integration Tests are Isolated**:
- Integration tests generate **real reports** in `tests_reports/` directories
- Running them during `dart test` pollutes production report directories with synthetic/mock data
- This caused confusion when mock "failure reports" appeared alongside real failures
- All integration test files now have `@Tags(['integration'])` annotation
- Configuration is in `dart_test.yaml` (integration tag is skipped by default)
- **Note**: 7 misplaced "integration" tests were deleted (they were actually unit tests with no real I/O)

**When to Run Integration Tests**:
- Before publishing a new release
- When testing report generation functionality
- When debugging analyzer workflows
- For comprehensive pre-commit validation

**Cleaning Up Integration Test Reports**:
Integration tests generate real reports in `tests_reports/` subdirectories. After running integration tests explicitly, clean up test-generated reports:

```bash
# Clean up integration test reports (keep only production reports)
rm -rf tests_reports/reliability/  # Test analyzer integration test reports
rm -rf tests_reports/quality/      # Old coverage integration test reports

# Or clean ALL reports (nuclear option)
rm -rf tests_reports/*
```

**Note**: The `tests_reports/` directory is in `.gitignore` - these reports are never committed to the repository.

### Testing Workflow

1. **Dogfooding**: Run tools on themselves to verify functionality
2. **Fixture-based**: Use generated fixtures for consistent testing
3. **Integration-focused**: Emphasize end-to-end workflows over unit tests
4. **Script automation**: Use scripts/ for test generation and automation
5. **TDD-first**: All new features start with failing tests (see TDD section above)

---

## Package Publishing

### Pre-publish Checklist

Before publishing to pub.dev:

- [ ] Update version in `pubspec.yaml`
- [ ] Update `CHANGELOG.md` with changes
- [ ] Run `dart analyze` (must be 0 issues)
- [ ] Run `dart format --set-exit-if-changed`
- [ ] Test all 4 executables manually
- [ ] Run dry-run: `dart pub publish --dry-run`
- [ ] Review package scoring recommendations

### Publishing Workflow

```bash
# Dry run to check for issues
dart pub publish --dry-run

# Publish to pub.dev (requires authentication)
dart pub publish

# Create GitHub release
# - Tag version (e.g., v2.0.0)
# - Copy CHANGELOG entry to release notes
```

**Reference**: `.agent/guides/04_publishing_release.md` for detailed workflow

---

## Development Guidelines

### Adding New Features

1. Keep business logic in `lib/src/` for testability and reusability
2. Use sealed classes for type-safe enumerations with behavior
3. Use records for lightweight multi-value returns
4. Follow the existing report generation patterns in `report_utils.dart`
5. Maintain the separation between bin/ entry points and lib/src/ implementations

### Code Quality Standards

- **Linting**: Uses `very_good_analysis` package
- **Run `dart analyze` before committing** (0 issues required)
- **Format**: Run `dart format .` before commits
- **Minimum SDK**: Dart 3.6.0 (for sealed classes and records)

### Modern Dart Best Practices

**When to use Sealed Classes:**
- Type-safe enumerations with associated data
- Exhaustive pattern matching requirements
- Replacing old enum+class patterns

**When to use Records:**
- Returning multiple values from functions
- Lightweight data structures without behavior
- Temporary data grouping (not domain models)

**When to use regular Classes:**
- Domain models with behavior
- Mutable state requirements
- Complex initialization logic

### Terminal Output

The tools use ANSI color codes for terminal output:
- Colors defined in analyzer classes (red, green, yellow, blue, etc.)
- Use `mason_logger` package for consistent CLI output patterns
- Progressive disclosure: summary first, details on demand

---

## Development Workflow (Context-Aware)

### Step 0: Context Check (ALWAYS FIRST!)

```bash
/context  # Check current token usage
```

### Step 1: Read Relevant Documentation

```bash
# For architecture questions
.agent/knowledge/analyzer_architecture.md

# For failure patterns
.agent/knowledge/failure_patterns.md

# For report system
.agent/knowledge/report_system.md
```

### Step 2: Choose Appropriate SOP

```bash
# Adding new failure type?
.agent/guides/01_adding_failure_pattern.md

# Creating new analyzer?
.agent/guides/02_adding_new_analyzer.md

# Extending reports?
.agent/guides/03_adding_report_type.md
```

### Step 3: Implement with Templates

```bash
# Use provided templates
.agent/templates/analyzer_template.dart
.agent/templates/failure_type_template.dart
.agent/templates/record_type_template.dart
```

### Step 4: Test

```bash
# Run analyzer
dart analyze

# Format code
dart format .

# Self-test the tool
dart run test_reporter:analyze_suite bin/
```

### Step 5: Clear Context Between Tasks (Anthropic Recommended)

```bash
# After completing a task/feature
/clear

# Before starting a new, different task
/clear

# When switching contexts (e.g., debugging → new feature)
/clear

# Check context at transitions
/context  # Check if approaching 75%+ usage
# If > 75%: Use /clear if at task boundary, or /compact if mid-task
```

### Complete Workflow Guides

- **Adding Failure Patterns**: `.agent/guides/01_adding_failure_pattern.md`
- **Adding Analyzers**: `.agent/guides/02_adding_new_analyzer.md`
- **Adding Report Types**: `.agent/guides/03_adding_report_type.md`
- **Publishing Releases**: `.agent/guides/04_publishing_release.md`

---

## Best Practices

### Context & Token Management (Anthropic Official)

1. ✅ **Check `/context` at session start and task transitions**
2. ✅ **Use `/clear` frequently** - after each task/feature (Anthropic recommended)
3. ✅ **Use `/clear` between different tasks** to keep Claude focused
4. ✅ **Estimate token requirements** before starting tasks
5. ✅ **Use `/compact` only mid-task** when you can't /clear
6. ✅ **Disable unused MCP servers** to save tokens
7. ✅ **Never let context exceed 95%** (auto-compact loses control)

### Code Architecture

8. ✅ **Keep bin/ minimal** - delegate to lib/src/bin/
9. ✅ **Use sealed classes** for type-safe failure types
10. ✅ **Use records** for multi-value returns
11. ✅ **Follow report naming conventions** - module_name-fo/fi_type@timestamp
12. ✅ **Use ReportUtils** for consistent report generation
13. ✅ **Export public APIs** through lib/test_reporter.dart

### Testing & Quality

14. ✅ **Run `dart analyze` before commits** (0 issues required)
15. ✅ **Format with `dart format`** before commits
16. ✅ **Self-test tools** on themselves (dogfooding)
17. ✅ **Use very_good_analysis** linting rules
18. ✅ **Test all 4 executables** before publishing

### Terminal UX

19. ✅ **Use ANSI colors** for better readability
20. ✅ **Provide progress indicators** for long operations
21. ✅ **Use mason_logger** for consistent output
22. ✅ **Progressive disclosure** - summary first, details on demand

---

## 🎯 Quick Reference

**User Documentation**: [README.md](README.md) - Installation & usage
**Developer Documentation**: `.agent/README.md` - START HERE!
**Architecture**: `.agent/knowledge/analyzer_architecture.md`
**Failure Patterns**: `.agent/knowledge/failure_patterns.md`
**Report System**: `.agent/knowledge/report_system.md`
**TDD Methodology**: `.agent/knowledge/tdd_methodology.md` - 🔴🟢♻️ Red-green-refactor (MANDATORY)

**Context Commands**: `/context`, `/clear` (use frequently!), `/compact`, `/cost`, `/mcp`
**Development Commands**: `dart pub get`, `dart analyze`, `dart format .`
**Testing Command**: `dart run test_reporter:analyze_suite bin/`
**Publish Command**: `dart pub publish --dry-run`
**TDD Commands**: `dart test [file]` (red/green), `dart test` (refactor), `dart analyze`

**Remember**:
- This is a Dart package, NOT a Flutter app!
- Use `/clear` frequently between tasks (Anthropic official guidance!)
- Context management is critical
- 🔴🟢♻️ TDD is MANDATORY - write tests FIRST!
- Sealed classes + records = modern Dart!
- Self-test the tools on themselves!
