# TDD Methodology for test_reporter

**Status**: Mandatory Development Protocol
**Last Updated**: 2025-11-04
**Applies To**: All feature development, bug fixes, and refactoring

## 🔴🟢♻️ Overview

Test-Driven Development (TDD) is the **mandatory** development methodology for test_reporter. All code changes MUST follow the red-green-refactor cycle.

**Why TDD for test_reporter?**
- We're building test analysis tools - our code must be thoroughly tested
- Pattern detection logic is complex and error-prone without tests
- Sealed classes and exhaustive pattern matching require test coverage
- Meta-testing strategy aligns perfectly with TDD principles
- Prevents regressions in analyzer behavior

---

## The Red-Green-Refactor Cycle

### 🔴 RED: Write a Failing Test

**Write the test FIRST**, before any implementation code.

**Rules:**
- Test must fail for the right reason (not compile errors)
- Test should be as simple as possible
- Test describes desired behavior, not implementation
- Run test to confirm it fails with expected message

**Example - Adding new sealed class failure type:**
```dart
// test/unit/models/failure_types_test.dart
test('TimeoutFailure should be detected from timeout output', () {
  const output = '''
00:00 +0: Test timeout
00:00 +0: Test timed out after 30 seconds
  ''';

  final analyzer = TestAnalyzer(targetPath: 'test');
  final failure = analyzer.detectFailureType(output);

  // This will fail - TimeoutFailure doesn't exist yet
  expect(failure, isA<TimeoutFailure>());
  expect(failure.category, equals('Timeout'));
});
```

**Run test:**
```bash
dart test test/unit/models/failure_types_test.dart
# Expected: Fails with "type 'UnknownFailure' is not a subtype of type 'TimeoutFailure'"
```

### 🟢 GREEN: Write Minimal Code to Pass

**Write the SIMPLEST code** that makes the test pass.

**Rules:**
- Only write code to satisfy the failing test
- No premature optimization
- No extra features "just in case"
- Aim for "good enough" not "perfect"
- Run test to confirm it passes

**Example - Minimal implementation:**
```dart
// lib/src/models/failure_types.dart
final class TimeoutFailure extends FailureType {
  const TimeoutFailure({required this.message, required this.duration});

  final String message;
  final String duration;

  @override
  String get category => 'Timeout';

  @override
  String? get suggestion => 'Increase test timeout duration';
}

// lib/src/bin/analyze_tests_lib.dart
FailureType detectFailureType(String output) {
  // ... existing patterns

  if (output.contains('timed out')) {
    final match = RegExp(r'timed out after (\d+)').firstMatch(output);
    return TimeoutFailure(
      message: 'Test timed out',
      duration: match?.group(1) ?? 'unknown',
    );
  }

  // ... rest of detection logic
}
```

**Run test:**
```bash
dart test test/unit/models/failure_types_test.dart
# Expected: ✅ All tests pass
```

### ♻️ REFACTOR: Improve Without Changing Behavior

**Clean up code** while keeping all tests green.

**Rules:**
- Tests must stay green throughout refactoring
- Run tests after each refactoring step
- Improve code quality, readability, maintainability
- Extract methods, remove duplication, clarify naming
- Update exhaustive pattern matches

**Example - Refactor after green:**
```dart
// Extract timeout detection to helper method
String _extractTimeout(String output) {
  final match = RegExp(r'timed out after (\d+)').firstMatch(output);
  return match?.group(1) ?? 'unknown';
}

FailureType detectFailureType(String output) {
  // ... existing patterns

  if (output.contains('timed out')) {
    return TimeoutFailure(
      message: 'Test timed out',
      duration: _extractTimeout(output),
    );
  }

  // ... rest of detection logic
}

// Update all exhaustive switches
String formatFailure(FailureType failure) {
  return switch (failure) {
    TimeoutFailure(:final duration) => '⏱️ Timeout after ${duration}s',
    NullError() => '❌ Null reference error',
    // ... all other cases (compiler enforces exhaustiveness)
  };
}
```

**Run all tests:**
```bash
dart test
dart analyze
# Expected: ✅ All pass, no warnings
```

---

## TDD for Different Components

### 1. Adding Sealed Class Failure Types

**RED Phase:**
```dart
// test/unit/models/failure_types_test.dart
test('NewFailure should parse error details', () {
  const output = 'Error output here';
  final failure = detectFailureType(output);

  expect(failure, isA<NewFailure>());
  expect(failure.category, equals('Expected Category'));
});
```

**GREEN Phase:**
```dart
// lib/src/models/failure_types.dart
final class NewFailure extends FailureType {
  const NewFailure({required this.message});
  final String message;

  @override
  String get category => 'Expected Category';

  @override
  String? get suggestion => null;
}
```

**REFACTOR Phase:**
- Update all exhaustive pattern matches
- Add detailed suggestion logic
- Extract regex patterns to constants

### 2. Adding New Analyzer Tool

**RED Phase:**
```dart
// test/integration/analyzers/new_analyzer_test.dart
test('NewAnalyzer should analyze target path', () async {
  final analyzer = NewAnalyzer(targetPath: 'test/fixtures');
  final exitCode = await analyzer.run();

  expect(exitCode, equals(0));
  expect(analyzer.results, isNotEmpty);
});
```

**GREEN Phase:**
```dart
// lib/src/bin/new_analyzer_lib.dart
class NewAnalyzer {
  Future<int> run() async {
    // Minimal implementation to pass test
    results['sample'] = 'data';
    return 0;
  }
}
```

**REFACTOR Phase:**
- Extract analysis logic to methods
- Add report generation
- Implement proper error handling
- Add verbose logging

### 3. Adding Record Types

**RED Phase:**
```dart
// test/unit/models/result_types_test.dart
test('NewResult should contain all required fields', () {
  final result = performOperation();

  expect(result.success, isTrue);
  expect(result.metric, greaterThan(0));
  expect(result.error, isNull);
});
```

**GREEN Phase:**
```dart
// lib/src/models/result_types.dart
typedef NewResult = ({
  bool success,
  double metric,
  String? error,
});

NewResult performOperation() {
  return (success: true, metric: 1.0, error: null);
}
```

**REFACTOR Phase:**
- Add destructuring examples
- Document usage patterns
- Add pattern matching support

### 4. Pattern Detection Logic

**RED Phase:**
```dart
test('should detect complex failure pattern', () {
  const output = '''
Complex multiline
error output
with specific pattern
  ''';

  final failure = detectFailureType(output);
  expect(failure, isA<SpecificFailure>());
});
```

**GREEN Phase:**
```dart
if (output.contains('specific pattern')) {
  return SpecificFailure(message: 'detected');
}
```

**REFACTOR Phase:**
- Refine regex patterns
- Handle edge cases
- Extract pattern constants
- Add regex comments for clarity

---

## TDD Best Practices for test_reporter

### Test Organization

**Unit Tests** - Fast, isolated, test single functions:
```
test/unit/
├── models/
│   ├── failure_types_test.dart    # Sealed class tests
│   └── result_types_test.dart     # Record type tests
├── utils/
│   └── report_utils_test.dart     # Utility function tests
└── bin/
    └── analyzer_helpers_test.dart  # Helper function tests
```

**Integration Tests** - Test full analyzer workflows:
```
test/integration/
├── analyzers/
│   ├── test_analyzer_test.dart
│   ├── coverage_analyzer_test.dart
│   └── suite_analyzer_test.dart
└── fixtures/
    └── sample_test_outputs/
```

### Writing Good Tests

**✅ Good Test:**
```dart
test('NullError should extract variable name from output', () {
  const output = "NoSuchMethodError: The getter 'userName' was called on null";

  final failure = detectFailureType(output) as NullError;

  expect(failure.variableName, equals('userName'));
  expect(failure.category, equals('Null Error'));
});
```

**❌ Bad Test:**
```dart
test('it works', () {
  final result = doSomething();
  expect(result, isNotNull); // Too vague, tests nothing specific
});
```

### Test Naming

Use descriptive names that explain behavior:

**✅ Good:**
- `test('TimeoutFailure should parse duration from output')`
- `test('analyze_tests should generate both markdown and JSON reports')`
- `test('ReportUtils.cleanOldReports should delete files matching prefix')`

**❌ Bad:**
- `test('test1')`
- `test('works correctly')`
- `test('analyzer test')`

### Test Data

Use constants for test data:
```dart
const timeoutOutput = '''
00:00 +0: Test timeout
00:00 +0: Test timed out after 30 seconds
''';

const nullErrorOutput = '''
NoSuchMethodError: The getter 'userName' was called on null.
''';

test('should detect timeout', () {
  final failure = detectFailureType(timeoutOutput);
  expect(failure, isA<TimeoutFailure>());
});
```

---

## TDD Workflow Commands

### Running Tests During TDD

```bash
# 🔴 RED: Run specific test file to see failure
dart test test/unit/models/failure_types_test.dart

# 🟢 GREEN: Run same test to confirm it passes
dart test test/unit/models/failure_types_test.dart

# ♻️ REFACTOR: Run all tests to ensure nothing broke
dart test

# Run with coverage
dart test --coverage=coverage
dart pub global activate coverage
dart pub global run coverage:format_coverage \
  --lcov \
  --in=coverage \
  --out=coverage/lcov.info \
  --report-on=lib
```

### Quality Checks After Refactor

```bash
# Run analyzer (must pass)
dart analyze

# Run formatter (must not change anything)
dart format --output=none --set-exit-if-changed .

# Run all tests (must all pass)
dart test

# Self-test: Run tools on themselves
dart run test_reporter:analyze_tests --path=test
dart run test_reporter:analyze_coverage --path=lib
```

---

## TDD with Meta-Testing Strategy

test_reporter uses **meta-testing** - the tools test themselves.

**TDD Cycle with Meta-Testing:**

1. 🔴 **RED**: Write failing test for new feature
2. 🟢 **GREEN**: Implement feature minimally
3. ♻️ **REFACTOR**: Clean up code
4. 🔄 **META-TEST**: Run analyzer on itself

**Example:**
```bash
# After adding TimeoutFailure sealed class
dart test test/unit/models/failure_types_test.dart  # Unit tests pass

# Meta-test: Analyze the test_reporter codebase itself
dart run test_reporter:analyze_tests --path=test
dart run test_reporter:analyze_suite --path=test

# Verify reports generated correctly
ls tests_reports/tests/
# Should see: all-fo_analysis@*.md and all-fo_analysis@*.json
```

---

## Common TDD Pitfalls to Avoid

### ❌ Writing Tests After Implementation
```dart
// WRONG: Implemented first, then wrote test
// This is not TDD - you'll write tests to match implementation
// instead of tests that drive design
```

### ❌ Writing Multiple Features at Once
```dart
// WRONG: Trying to add 3 failure types in one RED phase
test('should detect timeout, null error, and type error', () { ... });

// RIGHT: One feature per RED-GREEN-REFACTOR cycle
test('should detect timeout failure', () { ... });
```

### ❌ Skipping the Refactor Phase
```dart
// Test passes ✅ -> Moving to next feature ❌
// Always refactor after green! Clean code pays off.
```

### ❌ Tests Too Large/Complex
```dart
// WRONG: 100-line test with 20 assertions
test('complex test', () {
  // ... 100 lines of setup
  expect(...); // 20 assertions
});

// RIGHT: Break into smaller, focused tests
test('should handle case A', () { ... });
test('should handle case B', () { ... });
```

---

## TDD Enforcement in dart-dev Agent

The dart-dev agent enforces TDD through:

1. **Activation check**: Warns if tests don't exist before implementation
2. **Workflow steps**: Every guide includes explicit TDD steps
3. **Quality gates**: Blocks commits if tests fail
4. **Meta-testing**: Self-tests verify analyzer behavior

**Agent commands enforce TDD:**
```bash
*new-failure    # Requires writing test first
*new-analyzer   # Starts with integration test
*new-record     # Begins with unit test
```

---

## Success Metrics

Development is following TDD correctly when:

- ✅ Tests are written BEFORE implementation
- ✅ Tests fail initially (RED phase confirmed)
- ✅ Implementation makes tests pass (GREEN)
- ✅ Refactoring keeps tests green
- ✅ Test coverage remains high (>80%)
- ✅ All tests pass before commits
- ✅ dart analyze shows no warnings
- ✅ Meta-testing produces clean reports

---

## Related Documentation

- [Full Codebase Overview](.agent/knowledge/full_codebase.md) - Project structure
- [Analyzer Architecture](.agent/knowledge/analyzer_architecture.md) - How analyzers work
- [Failure Patterns](.agent/knowledge/failure_patterns.md) - Sealed class hierarchy
- [Self-Testing Guide](.agent/guides/07_self_testing.md) - Meta-testing strategy
- [Adding Failure Pattern](.agent/guides/01_adding_failure_pattern.md) - TDD for sealed classes
- [Adding New Analyzer](.agent/guides/02_adding_new_analyzer.md) - TDD for CLI tools

---

## Quick Reference Card

```
┌─────────────────────────────────────────────────┐
│  TDD CYCLE FOR test_reporter                   │
├─────────────────────────────────────────────────┤
│                                                 │
│  🔴 RED: Write Failing Test                    │
│     ├─ Write test first                        │
│     ├─ Run: dart test [file]                   │
│     └─ Confirm: Test fails with right reason   │
│                                                 │
│  🟢 GREEN: Make Test Pass                      │
│     ├─ Write minimal code                      │
│     ├─ Run: dart test [file]                   │
│     └─ Confirm: Test passes                    │
│                                                 │
│  ♻️ REFACTOR: Clean Up Code                    │
│     ├─ Improve code quality                    │
│     ├─ Run: dart test (all)                    │
│     ├─ Run: dart analyze                       │
│     └─ Confirm: All tests still pass           │
│                                                 │
│  🔄 META-TEST: Self-Test                       │
│     ├─ Run: dart run test_reporter:analyze_*   │
│     └─ Confirm: Reports clean                  │
│                                                 │
└─────────────────────────────────────────────────┘
```

---

**Remember**: TDD is not optional. It's the foundation of reliable test analysis tools.
