# SOP: Extending Record Types

**Estimated Time**: 30 minutes
**Token Budget**: 20-30K tokens
**Difficulty**: Easy
**🔴🟢♻️ TDD**: MANDATORY - Write tests for record usage first

---

## Overview

This SOP guides you through adding new record types using **TDD**.

**Example**: Adding `PerformanceResult` for performance analysis

**TDD Approach**: Write test using the record BEFORE defining the typedef.

---

## Step 0: 🔴 RED Phase - Write Failing Test

```dart
// test/unit/models/result_types_test.dart
test('PerformanceResult should contain all required fields', () {
  final result = analyzePerformance(); // This will fail - doesn't exist yet

  expect(result.duration, greaterThan(0));
  expect(result.success, isTrue);
});
```

---

## Step 1: 🟢 GREEN Phase - Understand Records

Read `.agent/knowledge/modern_dart_features.md` for complete understanding of:
- Record syntax
- Named vs positional fields
- Type aliases with `typedef`
- When to use records vs classes

---

## Step 2: Define New Record Type

**File**: `lib/src/models/result_types.dart`

### 2.1 Add Typedef

```dart
/// Result of a performance analysis operation
typedef PerformanceResult = ({
  bool success,
  int totalTests,
  int slowTests,
  Duration averageDuration,
  Duration p95Duration,
  String? error,
});
```

### 2.2 Naming Convention

- Use descriptive name ending in `Result`
- Use named fields for clarity
- Include `success` and `error` fields for consistency

### 2.3 Common Field Patterns

**Always include**:
```dart
bool success,      // Operation succeeded?
String? error,     // Error message if failed
```

**Optional but common**:
```dart
int totalItems,    // Count of items processed
double percentage, // Some percentage value
Duration duration, // Time taken
```

---

## Step 3: Document the Record Type

### 3.1 Add Doc Comment

```dart
/// Result of a performance analysis operation
///
/// Returns performance metrics including slow test detection
/// and timing statistics.
///
/// Example usage:
/// ```dart
/// final result = await analyzePerformance();
/// if (result.success) {
///   print('Average: ${result.averageDuration}');
///   print('Slow tests: ${result.slowTests}');
/// }
/// ```
typedef PerformanceResult = ({
  bool success,
  int totalTests,
  int slowTests,
  Duration averageDuration,
  Duration p95Duration,
  String? error,
});
```

### 3.2 Update File Header

Add description of new record to library doc comment.

---

## Step 4: Use the Record Type

### 4.1 Return from Function

```dart
PerformanceResult analyzePerformance(List<TestResult> results) {
  try {
    final durations = results.map((r) => r.duration).toList();
    durations.sort();

    final average = durations.fold<Duration>(
      Duration.zero,
      (sum, d) => sum + d,
    ) ~/ durations.length;

    final p95Index = (durations.length * 0.95).floor();
    final p95 = durations[p95Index];

    final slow = results.where((r) => r.duration > Duration(seconds: 1)).length;

    return (
      success: true,
      totalTests: results.length,
      slowTests: slow,
      averageDuration: average,
      p95Duration: p95,
      error: null,
    );
  } catch (e) {
    return (
      success: false,
      totalTests: 0,
      slowTests: 0,
      averageDuration: Duration.zero,
      p95Duration: Duration.zero,
      error: e.toString(),
    );
  }
}
```

### 4.2 Access Fields

```dart
final result = analyzePerformance(tests);

// Named access
if (result.success) {
  print('Average: ${result.averageDuration}');
  print('P95: ${result.p95Duration}');
  print('Slow tests: ${result.slowTests}');
} else {
  print('Error: ${result.error}');
}
```

### 4.3 Destructure

```dart
final (
  success: ok,
  slowTests: slow,
  averageDuration: avg,
  error: err
) = analyzePerformance(tests);

if (!ok) {
  print('Analysis failed: $err');
} else {
  print('Found $slow slow tests, average duration: $avg');
}
```

---

## Step 5: Pattern Matching

### 5.1 Switch on Record

```dart
void processResult(PerformanceResult result) {
  switch (result) {
    case (success: true, slowTests: 0):
      print('✅ All tests are fast!');

    case (success: true, :final slowTests):
      print('⚠️ Found $slowTests slow tests');

    case (success: false, :final error):
      print('❌ Analysis failed: $error');
  }
}
```

### 5.2 Guard Clauses

```dart
String classify(PerformanceResult result) => switch (result) {
  (success: false, :final error) => 'Error: $error',
  (slowTests: 0) => 'All fast',
  (slowTests: final n) when n < 5 => 'Few slow tests',
  (slowTests: final n) when n >= 5 => 'Many slow tests',
  _ => 'Unknown',
};
```

---

## Step 6: Export from Library

**File**: `lib/test_reporter.dart`

Already exported via:
```dart
export 'src/models/result_types.dart';
```

All record types in that file are automatically exported.

---

## Step 7: Testing

### 7.1 Unit Test

```dart
import 'package:test/test.dart';
import 'package:test_reporter/test_reporter.dart';

void main() {
  group('PerformanceResult', () {
    test('success case', () {
      final result = (
        success: true,
        totalTests: 10,
        slowTests: 2,
        averageDuration: Duration(milliseconds: 500),
        p95Duration: Duration(seconds: 1),
        error: null,
      );

      expect(result.success, isTrue);
      expect(result.slowTests, equals(2));
      expect(result.averageDuration.inMilliseconds, equals(500));
    });

    test('failure case', () {
      final result = (
        success: false,
        totalTests: 0,
        slowTests: 0,
        averageDuration: Duration.zero,
        p95Duration: Duration.zero,
        error: 'Analysis failed',
      );

      expect(result.success, isFalse);
      expect(result.error, equals('Analysis failed'));
    });

    test('destructuring', () {
      final result = (
        success: true,
        totalTests: 10,
        slowTests: 2,
        averageDuration: Duration(milliseconds: 500),
        p95Duration: Duration(seconds: 1),
        error: null,
      );

      final (success: ok, slowTests: slow) = result;

      expect(ok, isTrue);
      expect(slow, equals(2));
    });
  });
}
```

---

## When to Use Records vs Classes

### Use Records ✅

- Returning multiple values
- Lightweight DTOs
- Temporary data grouping
- No methods needed
- Structural equality desired

### Use Classes ❌

- Domain models with behavior
- Mutable state
- Complex initialization
- Need inheritance
- Need object identity

---

## Common Patterns

### Result Type Pattern

```dart
typedef Result<T> = ({
  bool success,
  T? data,
  String? error,
});

Result<List<String>> loadData() {
  try {
    final data = expensiveOperation();
    return (success: true, data: data, error: null);
  } catch (e) {
    return (success: false, data: null, error: e.toString());
  }
}
```

### Pagination Result

```dart
typedef PaginatedResult<T> = ({
  List<T> items,
  int total,
  int page,
  int pageSize,
  bool hasMore,
});
```

### Validation Result

```dart
typedef ValidationResult = ({
  bool isValid,
  List<String> errors,
  Map<String, String> fieldErrors,
});
```

---

## Checklist

- [ ] Record type defined with `typedef`
- [ ] Uses named fields for clarity
- [ ] Includes `success` and `error` fields
- [ ] Documented with doc comment
- [ ] Includes usage example
- [ ] Used in at least one function
- [ ] Tested (if adding to public API)
- [ ] Code analyzed and formatted
- [ ] Committed

---

**Token usage**: ~20-25K tokens
**Next steps**: Use the record type in your analyzer implementation
