# Modern Dart Features - test_reporter

**Last Updated**: November 2025
**Purpose**: Understanding sealed classes, records, and modern Dart 3+ patterns
**Token Estimate**: ~6-8K tokens

---

## Overview

test_reporter is built with Dart 3.6+ and leverages modern language features:

1. **Sealed Classes** - Type-safe enumerations with exhaustive checking
2. **Records** - Lightweight multi-value returns
3. **Pattern Matching** - Destructuring and type narrowing
4. **Enhanced Enums** - (not currently used, but available)

**Minimum SDK**: Dart 3.6.0

---

## Sealed Classes

### What Are Sealed Classes?

A **sealed class** is a class that can only be extended by a known, finite set of subclasses. This enables **exhaustive pattern matching** where the compiler guarantees all cases are handled.

### Basic Syntax

```dart
sealed class Shape {
  const Shape();
}

final class Circle extends Shape {
  const Circle(this.radius);
  final double radius;
}

final class Rectangle extends Shape {
  const Rectangle(this.width, this.height);
  final double width;
  final double height;
}

final class Triangle extends Shape {
  const Triangle(this.base, this.height);
  final double base;
  final double height;
}
```

### Key Characteristics

1. **Cannot be instantiated**: `Shape()` is an error
2. **Finite subclasses**: Only Circle, Rectangle, Triangle can extend Shape
3. **Exhaustive checking**: Compiler ensures all subtypes are handled
4. **Pattern matching**: Type-safe switches

### Usage in test_reporter

**File**: `lib/src/models/failure_types.dart`

```dart
sealed class FailureType {
  const FailureType();

  String get category;
  String? get suggestion;
}

final class AssertionFailure extends FailureType {
  const AssertionFailure({
    required this.message,
    required this.location,
    this.expectedValue,
    this.actualValue,
  });

  final String message;
  final String location;
  final String? expectedValue;
  final String? actualValue;

  @override
  String get category => 'Assertion';

  @override
  String? get suggestion =>
      'Review test expectations. Expected: $expectedValue, Actual: $actualValue';
}

final class NullError extends FailureType {
  const NullError({
    required this.message,
    required this.variableName,
    this.location,
  });

  final String message;
  final String variableName;
  final String? location;

  @override
  String get category => 'Null Error';

  @override
  String? get suggestion =>
      'Add null check for $variableName or ensure proper initialization';
}

// ... 11 more types
```

### Exhaustive Pattern Matching

The compiler **guarantees** all cases are handled:

```dart
String classifyFailure(FailureType failure) {
  return switch (failure) {
    AssertionFailure() => 'Test assertion failed',
    NullError() => 'Null reference error',
    TimeoutFailure() => 'Test timed out',
    TypeMismatch() => 'Type error occurred',
    AsyncError() => 'Async operation failed',
    StateError() => 'Invalid state',
    NetworkError() => 'Network request failed',
    FileSystemError() => 'File operation failed',
    ParseError() => 'Parse error',
    InitializationError() => 'Setup failed',
    DisposalError() => 'Teardown failed',
    ConfigurationError() => 'Config error',
    UnknownFailure() => 'Unknown error',
  };
}

// If you add a new failure type but forget to handle it,
// the compiler will ERROR! ✅
```

### Pattern Matching with Destructuring

Access fields directly in the pattern:

```dart
void handleFailure(FailureType failure) {
  switch (failure) {
    case AssertionFailure(:final message, :final location):
      print('Assertion failed: $message at $location');

    case NullError(:final variableName):
      print('Null error on: $variableName');

    case TimeoutFailure(:final duration, :final timeout):
      print('Timeout: took $duration, limit was $timeout');

    case NetworkError(statusCode: final code, endpoint: final url):
      print('Network error: $code for $url');

    default:
      print('Other error: ${failure.category}');
  }
}
```

### When to Use Sealed Classes

✅ **Good use cases**:
- Type-safe enumerations with different data per case
- Exhaustive switch requirements
- Domain modeling with fixed variants
- Replacing enum + data class patterns

❌ **Not ideal for**:
- Open hierarchies (use abstract class)
- Single implementation (use regular class)
- Simple enums without data (use enum)

---

## Records

### What Are Records?

**Records** are immutable, anonymous data structures with named or positional fields. They provide a lightweight way to return multiple values without defining a class.

### Basic Syntax

```dart
// Named fields
(int x, int y) point = (10, 20);
print(point.x);  // 10
print(point.y);  // 20

// Mixed named/positional
(String name, {int age, String city}) person = ('Alice', age: 30, city: 'NYC');
print(person.name);  // 'Alice'
print(person.age);   // 30
```

### Type Aliases for Records

Make records reusable with `typedef`:

```dart
typedef Point = ({int x, int y});
typedef Person = ({String name, int age, String city});

Point getOrigin() => (x: 0, y: 0);
Person getPerson() => (name: 'Bob', age: 25, city: 'SF');
```

### Usage in test_reporter

**File**: `lib/src/models/result_types.dart`

```dart
/// Result of a test analysis operation
typedef AnalysisResult = ({
  bool success,
  int totalTests,
  int passedTests,
  int failedTests,
  String? error,
});

/// Result of a coverage analysis operation
typedef CoverageResult = ({
  bool success,
  double coverage,
  int totalLines,
  int coveredLines,
  String? error,
});

/// Result of loading a test file
typedef TestFileResult = ({
  bool success,
  String filePath,
  int loadTimeMs,
  String? error,
});
```

### Using Records

**Return multiple values**:

```dart
AnalysisResult runAnalysis(List<String> tests) {
  // ... run tests

  return (
    success: allPassed,
    totalTests: tests.length,
    passedTests: passedCount,
    failedTests: failedCount,
    error: error,
  );
}
```

**Access fields**:

```dart
final result = runAnalysis(tests);

print('Success: ${result.success}');
print('Total: ${result.totalTests}');
print('Passed: ${result.passedTests}');

if (!result.success) {
  print('Error: ${result.error}');
}
```

**Destructure**:

```dart
final (
  success: ok,
  totalTests: count,
  passedTests: passed,
  failedTests: failed,
  error: err
) = runAnalysis(tests);

if (!ok) {
  print('Analysis failed: $err');
  print('$failed of $count tests failed');
}
```

### Pattern Matching with Records

```dart
void processResult(AnalysisResult result) {
  switch (result) {
    case (success: true, :final totalTests):
      print('✅ All $totalTests tests passed!');

    case (success: false, :final failedTests, :final error):
      print('❌ $failedTests tests failed: $error');
  }
}
```

### When to Use Records

✅ **Good use cases**:
- Returning multiple values from functions
- Temporary data grouping
- Lightweight DTOs (Data Transfer Objects)
- Result types (success/failure with data)

❌ **Not ideal for**:
- Domain models with behavior (use classes)
- Mutable data structures
- Long-lived objects needing identity
- Complex initialization logic

---

## Pattern Matching

### Switch Expressions

Modern switch returns a value:

```dart
String getStatusEmoji(FailureType failure) => switch (failure) {
  AssertionFailure() => '❌',
  NullError() => '⚠️',
  TimeoutFailure() => '⏱️',
  _ => '❓',
};
```

### Destructuring Patterns

Extract values directly:

```dart
// Records
final (x: horizontal, y: vertical) = (x: 10, y: 20);

// Objects
final NullError(:variableName) = detectFailure(output);

// Lists
final [first, second, ...rest] = [1, 2, 3, 4, 5];
```

### Type Patterns

```dart
void handle(Object value) {
  switch (value) {
    case String s:
      print('String: $s');
    case int n when n > 0:
      print('Positive int: $n');
    case List<int> numbers:
      print('Int list: $numbers');
    default:
      print('Other: $value');
  }
}
```

### Guard Clauses

Add conditions with `when`:

```dart
String classify(int value) => switch (value) {
  < 0 => 'negative',
  == 0 => 'zero',
  > 0 && <= 10 => 'small positive',
  > 10 => 'large positive',
  _ => 'unknown',
};
```

---

## Comparison: Old vs New Patterns

### Multi-Value Returns

**Old way** (custom class):

```dart
class AnalysisResult {
  const AnalysisResult({
    required this.success,
    required this.totalTests,
    required this.passedTests,
    required this.failedTests,
    this.error,
  });

  final bool success;
  final int totalTests;
  final int passedTests;
  final int failedTests;
  final String? error;
}

AnalysisResult runAnalysis() {
  return AnalysisResult(
    success: true,
    totalTests: 10,
    passedTests: 10,
    failedTests: 0,
  );
}
```

**New way** (record):

```dart
typedef AnalysisResult = ({
  bool success,
  int totalTests,
  int passedTests,
  int failedTests,
  String? error,
});

AnalysisResult runAnalysis() {
  return (
    success: true,
    totalTests: 10,
    passedTests: 10,
    failedTests: 0,
    error: null,
  );
}
```

**Benefits**: Less boilerplate, structural equality, built-in toString()

---

### Type-Safe Enumerations

**Old way** (enum + switch):

```dart
enum FailureCategory {
  assertion,
  nullError,
  timeout,
}

String getSuggestion(FailureCategory category) {
  switch (category) {
    case FailureCategory.assertion:
      return 'Check assertions';
    case FailureCategory.nullError:
      return 'Add null checks';
    case FailureCategory.timeout:
      return 'Increase timeout';
    // Compiler doesn't verify all cases!
  }
  // Need to handle missing default
}
```

**New way** (sealed class):

```dart
sealed class FailureType {
  String get suggestion;
}

final class AssertionFailure extends FailureType {
  @override
  String get suggestion => 'Check assertions';
}

final class NullError extends FailureType {
  final String variableName;
  @override
  String get suggestion => 'Add null checks for $variableName';
}

String getSuggestion(FailureType failure) {
  return switch (failure) {
    AssertionFailure() => failure.suggestion,
    NullError() => failure.suggestion,
    TimeoutFailure() => failure.suggestion,
    // Compiler ERROR if any case is missing! ✅
  };
}
```

**Benefits**: Associated data, exhaustive checking, type narrowing

---

## Best Practices

### Sealed Classes

1. **Use `final` for leaf classes**: Prevents further extension
   ```dart
   final class NullError extends FailureType { }  // ✅
   class NullError extends FailureType { }        // ❌ Can be extended
   ```

2. **Make base class abstract or sealed**: Never instantiate base
   ```dart
   sealed class FailureType { }   // ✅ Cannot instantiate
   abstract class FailureType { } // ✅ Cannot instantiate
   class FailureType { }          // ❌ Can instantiate
   ```

3. **Provide common interface**: Add abstract methods/getters
   ```dart
   sealed class FailureType {
     String get category;         // All subtypes must implement
     String? get suggestion;
   }
   ```

4. **Use exhaustive switches**: Let compiler verify
   ```dart
   String handle(FailureType f) => switch (f) {
     AssertionFailure() => '...',
     NullError() => '...',
     // Compiler checks all cases ✅
   };
   ```

### Records

1. **Use named fields for clarity**:
   ```dart
   (int, int) tuple = (10, 20);           // ❌ What do these mean?
   ({int x, int y}) point = (x: 10, y: 20); // ✅ Clear meaning
   ```

2. **Create type aliases for reuse**:
   ```dart
   // ❌ Repeat definition everywhere
   ({bool success, String? error}) result1;
   ({bool success, String? error}) result2;

   // ✅ Define once, reuse
   typedef Result = ({bool success, String? error});
   Result result1;
   Result result2;
   ```

3. **Prefer records for temporary data**:
   ```dart
   // ✅ Return multiple values
   ({int min, int max}) getRange() => (min: 0, max: 100);

   // ❌ Don't use for domain models
   typedef User = ({String name, int age});  // Use class instead!
   ```

4. **Use destructuring for readability**:
   ```dart
   final result = analyze();
   if (!result.success) {              // ❌ Verbose
     print(result.error);
   }

   final (success: ok, error: err) = analyze();
   if (!ok) print(err);                // ✅ Concise
   ```

---

## Migration Guide

### From Enum to Sealed Class

**Before**:
```dart
enum FailureType {
  assertion,
  nullError,
  timeout,
}

String getMessage(FailureType type) {
  switch (type) {
    case FailureType.assertion:
      return 'Assertion failed';
    case FailureType.nullError:
      return 'Null error';
    case FailureType.timeout:
      return 'Timeout';
  }
}
```

**After**:
```dart
sealed class FailureType {
  String get message;
}

final class AssertionFailure extends FailureType {
  @override
  String get message => 'Assertion failed';
}

final class NullError extends FailureType {
  final String variable;
  @override
  String get message => 'Null error on $variable';
}

final class TimeoutFailure extends FailureType {
  @override
  String get message => 'Timeout';
}

String getMessage(FailureType type) => type.message;
```

### From Class to Record

**Before**:
```dart
class Point {
  const Point(this.x, this.y);
  final int x;
  final int y;
}

Point add(Point a, Point b) {
  return Point(a.x + b.x, a.y + b.y);
}
```

**After**:
```dart
typedef Point = ({int x, int y});

Point add(Point a, Point b) {
  return (x: a.x + b.x, y: a.y + b.y);
}
```

---

## Token Usage Guidance

**Loading this file**: ~6-8K tokens

**Best used for**:
- Understanding modern Dart patterns
- Learning sealed classes
- Learning records
- Refactoring to modern features

**Recommended pairings**:
- With `failure_patterns.md` for sealed class examples
- With `01_adding_failure_pattern.md` for implementation
- With `failure_type_template.dart` template

---

## Further Reading

- **Dart Language Tour**: https://dart.dev/language
- **Sealed Classes**: https://dart.dev/language/class-modifiers#sealed
- **Records**: https://dart.dev/language/records
- **Pattern Matching**: https://dart.dev/language/patterns

---

This modern Dart approach enables:
- ✅ Type-safe enumerations
- ✅ Exhaustive checking
- ✅ Lightweight data structures
- ✅ Less boilerplate
- ✅ Better IDE support
