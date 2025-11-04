# SOP: Adding New Failure Pattern

**Estimated Time**: 30-60 minutes
**Token Budget**: 40-60K tokens
**Difficulty**: Medium
**🔴🟢♻️ TDD**: MANDATORY - Follow red-green-refactor cycle

---

## Prerequisites

- [ ] Read `../knowledge/failure_patterns.md`
- [ ] Read `../knowledge/modern_dart_features.md` (sealed classes section)
- [ ] Read `../knowledge/tdd_methodology.md` (red-green-refactor cycle)
- [ ] Understand the failure type you want to add
- [ ] Have example test output showing the failure

---

## Overview

This SOP guides you through adding a new failure type to the sealed class hierarchy using **Test-Driven Development (TDD)**.

**Example**: Adding `MemoryLeakFailure` to detect memory leaks in tests

**TDD Workflow**:
1. 🔴 **RED**: Write failing test for pattern detection
2. 🟢 **GREEN**: Implement sealed class + detection logic minimally
3. ♻️ **REFACTOR**: Update exhaustive switches, clean code
4. 🔄 **META-TEST**: Run analyzer on itself

---

## Step 0: 🔴 RED Phase - Write Failing Test FIRST

**CRITICAL**: Write the test BEFORE any implementation!

### 0.1 Create Test File (if doesn't exist)

```bash
# Ensure test directory exists
mkdir -p test/unit/models
```

### 0.2 Write Failing Test

**File**: `test/unit/models/failure_types_test.dart`

```dart
import 'package:test/test.dart';
import 'package:test_reporter/src/models/failure_types.dart';
import 'package:test_reporter/src/bin/analyze_tests_lib.dart';

void main() {
  group('MemoryLeakFailure', () {
    test('should be detected from memory leak output', () {
      const output = '''
══╡ MEMORY LEAK DETECTED ╞══
Leaked objects: [StreamController, Timer]
Total leaked memory: 2048 bytes
Location: test/my_test.dart:42
      ''';

      final analyzer = TestAnalyzer(targetPath: 'test');
      final failure = analyzer.detectFailureType(output);

      // This will FAIL - MemoryLeakFailure doesn't exist yet!
      expect(failure, isA<MemoryLeakFailure>());
      expect(failure.category, equals('Memory Leak'));

      final memLeak = failure as MemoryLeakFailure;
      expect(memLeak.leakedObjects, contains('StreamController'));
      expect(memLeak.leakedObjects, contains('Timer'));
      expect(memLeak.leakSize, equals(2048));
    });
  });
}
```

### 0.3 Run Test to Confirm RED

```bash
# Run test - it MUST fail
dart test test/unit/models/failure_types_test.dart

# Expected output:
# ❌ type 'UnknownFailure' is not a subtype of type 'MemoryLeakFailure'
# or
# ❌ The class 'MemoryLeakFailure' isn't defined
```

**🚨 STOP**: If test doesn't fail, do NOT proceed. Fix your test first!

---

## Step 1: 🟢 GREEN Phase - Define the New Sealed Class

**File**: `lib/src/models/failure_types.dart`

### 1.1 Add the Sealed Class Definition

Add your new class to the file, following the existing pattern:

```dart
/// Memory leak detected during test execution
final class MemoryLeakFailure extends FailureType {
  const MemoryLeakFailure({
    required this.leakedObjects,
    required this.leakSize,
    this.location,
  });

  final List<String> leakedObjects;
  final int leakSize;  // bytes
  final String? location;

  @override
  String get category => 'Memory Leak';

  @override
  String? get suggestion {
    final objects = leakedObjects.join(', ');
    return 'Memory leak detected: $leakSize bytes. '
           'Leaked objects: $objects. '
           'Ensure proper disposal in tearDown()';
  }
}
```

### 1.2 Required Elements

Every failure type MUST include:

1. **Extends FailureType**: `final class YourFailure extends FailureType`
2. **Const constructor**: `const YourFailure({...})`
3. **Required fields**: Relevant context data
4. **category getter**: Human-readable category name
5. **suggestion getter**: Fix recommendation

### 1.3 Verification

```bash
# Run analyzer to check for errors
dart analyze lib/src/models/failure_types.dart
```

---

## Step 2: 🟢 GREEN Phase - Add Detection Logic

**Still GREEN Phase**: Continue minimal implementation

**File**: `lib/src/bin/analyze_tests_lib.dart`
**Method**: `detectFailureType(String output)`

### 2.1 Identify the Pattern

Examine test output to find unique patterns:

```
Example output:
══╡ MEMORY LEAK DETECTED ╞══
Leaked objects: [StreamController, Timer]
Total leaked memory: 2048 bytes
Location: test/my_test.dart:42
```

### 2.2 Write Detection Logic

Add your detection code to the `detectFailureType()` method:

```dart
FailureType detectFailureType(String output) {
  // ... existing patterns

  // Memory leak detection
  if (output.contains('MEMORY LEAK DETECTED')) {
    final leakedObjects = <String>[];
    final leakMatch = RegExp(r'Leaked objects: \[(.+?)\]').firstMatch(output);
    if (leakMatch != null) {
      leakedObjects.addAll(
        leakMatch.group(1)!.split(',').map((s) => s.trim())
      );
    }

    final sizeMatch = RegExp(r'Total leaked memory: (\d+) bytes').firstMatch(output);
    final leakSize = int.parse(sizeMatch?.group(1) ?? '0');

    return MemoryLeakFailure(
      leakedObjects: leakedObjects,
      leakSize: leakSize,
      location: extractLocation(output),
    );
  }

  // ... other patterns

  // Fallback
  return UnknownFailure(rawOutput: output);
}
```

### 2.3 Detection Best Practices

1. **Order matters**: Add new patterns BEFORE the `UnknownFailure` fallback
2. **Be specific**: Use unique identifiers to avoid false positives
3. **Extract data**: Pull out relevant context (variables, locations, values)
4. **Use regex**: For pattern matching and data extraction
5. **Handle edge cases**: Use null-safe operators and defaults

### 2.4 Run Test to Confirm GREEN ✅

```bash
# Run the test again - it should PASS now
dart test test/unit/models/failure_types_test.dart

# Expected output:
# ✅ All tests passed!
```

**🚨 STOP**: If test still fails, debug before moving to REFACTOR!

---

## Step 3: ♻️ REFACTOR Phase - Update Pattern Matching

**Now we REFACTOR**: Clean code while keeping tests green

### 3.1 Find All Switch Statements

Search for exhaustive switches on `FailureType`:

```bash
grep -r "switch (.*FailureType" lib/
```

### 3.2 Update Each Switch

Add your new pattern to all exhaustive switches:

```dart
// Example location: generating suggestions
String getSuggestion(FailureType failure) {
  return switch (failure) {
    AssertionFailure() => '...',
    NullError() => '...',
    TimeoutFailure() => '...',
    // ... existing cases
    MemoryLeakFailure(:final leakedObjects, :final leakSize) =>
      'Fix memory leak: $leakSize bytes in ${leakedObjects.join(", ")}',
    UnknownFailure() => '...',
  };
}
```

### 3.3 Compiler Verification

```bash
# Compiler will ERROR if you miss any switches!
dart analyze

# Expected: 0 issues
```

### 3.4 Run Tests After Each Refactor

**CRITICAL**: Tests MUST stay green during refactoring!

```bash
# Run all tests after each refactor step
dart test

# Run your specific test
dart test test/unit/models/failure_types_test.dart

# Expected: ✅ All tests pass
```

---

## Step 4: ♻️ REFACTOR Phase - Enhance Pattern Detection (Optional)

### 4.1 Create Test Output

Create a test file with your failure pattern:

```dart
// test/memory_leak_test.dart
import 'package:test/test.dart';

void main() {
  test('simulates memory leak', () {
    // This test intentionally leaks memory
    final controller = StreamController();
    // Forget to call controller.close() ← Memory leak!

    expect(true, isTrue);
  });
}
```

### 4.2 Run Test Analyzer

```bash
dart run test_reporter:analyze_tests test/memory_leak_test.dart --verbose
```

### 4.3 Verify Detection

Check the report for:
- ✅ Your failure type is correctly detected
- ✅ Category name appears (`Memory Leak`)
- ✅ Suggestion is helpful
- ✅ Extracted data is accurate (leaked objects, size)

---

## Step 5: Update Documentation

### 5.1 Add to failure_patterns.md

**File**: `.agent/knowledge/failure_patterns.md`

Add a section for your new failure type:

````markdown
### 13. MemoryLeakFailure

**When**: Memory leaks detected during test execution

```dart
final class MemoryLeakFailure extends FailureType {
  const MemoryLeakFailure({
    required this.leakedObjects,
    required this.leakSize,
    this.location,
  });

  final List<String> leakedObjects;
  final int leakSize;
  final String? location;

  @override
  String get category => 'Memory Leak';

  @override
  String? get suggestion => '...';
}
```

**Detection Pattern**:
```dart
if (output.contains('MEMORY LEAK DETECTED')) {
  // Extract leaked objects and size
  return MemoryLeakFailure(...);
}
```

**Suggestions**:
- Ensure proper disposal in tearDown()
- Close streams and controllers
- Cancel timers
- Remove listeners
````

### 5.2 Update the Hierarchy Diagram

Add your failure type to the class hierarchy:

```markdown
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
├── MemoryLeakFailure    ← NEW
└── UnknownFailure
```

---

## Step 6: 🔄 META-TEST Phase - Self-Test the Analyzer

**Final TDD step**: Run the analyzer on itself to verify the changes work!

### 6.1 Run Analyzer on Test Suite

```bash
# Run the test analyzer on the test suite itself
dart run test_reporter:analyze_tests test/ --runs=3

# Check the generated report
ls tests_reports/tests/
```

### 6.2 Run Analyzer on Source Code

```bash
# Analyze the analyzer tools themselves
dart run test_reporter:analyze_suite bin/
```

### 6.3 Verify Reports

Check that:
- ✅ Reports generate without errors
- ✅ New failure type appears correctly if detected
- ✅ No unexpected failures or regressions
- ✅ Meta-testing completes successfully

---

## Step 7: Commit Changes

### 7.1 Pre-commit Checks

```bash
# Analyze code
dart analyze

# Format code
dart format .

# Self-test the analyzer
dart run test_reporter:analyze_tests bin/
```

### 7.2 Create Commit

```bash
git add lib/src/models/failure_types.dart
git add lib/src/bin/analyze_tests_lib.dart
git add test/unit/models/failure_types_test.dart
git add .agent/knowledge/failure_patterns.md

git commit -m "feat: add MemoryLeakFailure pattern detection"
```

---

## Troubleshooting

### Pattern Not Detected

**Problem**: New failure type isn't being detected

**Solutions**:
1. Check detection order - add BEFORE UnknownFailure
2. Verify regex pattern matches actual output
3. Add debug logging to see what's being matched
4. Test with `--verbose` flag for detailed output

### Compiler Errors on Switch

**Problem**: "The type 'FailureType' is not exhaustively matched by the switch cases"

**Solutions**:
1. Find all `switch (failure)` statements
2. Add case for your new type
3. Use IDE "Add missing cases" quick fix

### Incorrect Data Extraction

**Problem**: Fields have wrong values or null

**Solutions**:
1. Print `output` to see actual format
2. Test regex patterns at https://regex101.com
3. Add fallback values for missing matches
4. Use null-safe operators (`?.`, `??`)

---

## Checklist

Before marking this task complete:

**🔴 RED Phase:**
- [ ] Test written FIRST in `test/unit/models/failure_types_test.dart`
- [ ] Test run and confirmed FAILING

**🟢 GREEN Phase:**
- [ ] New sealed class added to `failure_types.dart`
- [ ] Detection logic added to `detectFailureType()`
- [ ] Test run and confirmed PASSING

**♻️ REFACTOR Phase:**
- [ ] All exhaustive switches updated
- [ ] `dart analyze` shows 0 issues
- [ ] Code formatted with `dart format`
- [ ] Tests still passing after refactoring

**🔄 META-TEST Phase:**
- [ ] Analyzer run on itself (`dart run test_reporter:analyze_tests test/`)
- [ ] No regressions detected

**Final Steps:**
- [ ] Documentation updated in `.agent/knowledge/failure_patterns.md`
- [ ] Changes committed with proper TDD workflow message

---

## Example: Complete Implementation

Here's a complete example for `DeprecationWarning`:

```dart
// lib/src/models/failure_types.dart
final class DeprecationWarning extends FailureType {
  const DeprecationWarning({
    required this.deprecatedApi,
    required this.replacement,
    this.sinceVersion,
  });

  final String deprecatedApi;
  final String replacement;
  final String? sinceVersion;

  @override
  String get category => 'Deprecation';

  @override
  String? get suggestion =>
      'Replace deprecated $deprecatedApi with $replacement';
}

// lib/src/bin/analyze_tests_lib.dart (in detectFailureType)
if (output.contains('DEPRECATED') || output.contains('deprecated')) {
  final apiMatch = RegExp(r"'(\w+)' is deprecated").firstMatch(output);
  final replaceMatch = RegExp(r'Use (\w+) instead').firstMatch(output);

  return DeprecationWarning(
    deprecatedApi: apiMatch?.group(1) ?? 'unknown',
    replacement: replaceMatch?.group(1) ?? 'see documentation',
    sinceVersion: extractVersion(output),
  );
}
```

---

**Token usage for this SOP**: ~40-50K tokens (including context files)

**Next steps**: Test the new pattern with real-world scenarios
