# Failure Patterns - test_reporter

**Last Updated**: November 2025
**Purpose**: Understanding the sealed class failure type system and pattern detection
**Token Estimate**: ~8-12K tokens

---

## Overview

The test_reporter uses a **sealed class hierarchy** to represent different types of test failures. This provides:

1. **Type safety** - Compiler ensures all cases are handled
2. **Exhaustive pattern matching** - No missing cases
3. **Rich data** - Each failure type carries relevant context
4. **Smart suggestions** - Context-aware fix recommendations

**File**: `lib/src/models/failure_types.dart` (~250 lines)

---

## Sealed Class Hierarchy

```dart
sealed class FailureType {
  const FailureType();

  /// Human-readable category name
  String get category;

  /// Suggested fix for this failure type
  String? get suggestion;
}
```

### All Failure Types

```
FailureType (sealed base class)
├── AssertionFailure      # Test expectations that failed
├── NullError             # Null reference errors
├── TimeoutFailure        # Test timeouts
├── TypeMismatch          # Type errors
├── AsyncError            # Async/await issues
├── StateError            # Invalid state
├── NetworkError          # Network failures
├── FileSystemError       # File I/O errors
├── ParseError            # Parsing/format errors
├── InitializationError   # Setup failures
├── DisposalError         # Teardown failures
├── ConfigurationError    # Config issues
└── UnknownFailure        # Unclassified errors
```

---

## Failure Type Definitions

### 1. AssertionFailure

**When**: Test expectations fail (expected vs actual mismatch)

```dart
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
```

**Example Output**:
```
Expected: true
  Actual: false
```

**Detection Pattern**:
```dart
if (output.contains('Expected:') && output.contains('Actual:')) {
  final expectedMatch = RegExp(r'Expected:\s*(.+)').firstMatch(output);
  final actualMatch = RegExp(r'Actual:\s*(.+)').firstMatch(output);

  return AssertionFailure(
    message: 'Assertion failed',
    location: extractLocation(output),
    expectedValue: expectedMatch?.group(1),
    actualValue: actualMatch?.group(1),
  );
}
```

**Suggestion**:
- Review test logic for correctness
- Check if expected value is accurate
- Verify test setup provides correct state

---

### 2. NullError

**When**: Attempting to access properties/methods on null

```dart
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
```

**Example Output**:
```
NoSuchMethodError: The getter 'token' was called on null.
Receiver: null
Tried calling: token
```

**Detection Pattern**:
```dart
if (output.contains('NoSuchMethodError') && output.contains('null')) {
  final variableMatch = RegExp(r"Tried calling: (\w+)").firstMatch(output);
  final variable = variableMatch?.group(1) ?? 'unknown';

  return NullError(
    message: 'Null reference error',
    variableName: variable,
    location: extractLocation(output),
  );
}
```

**Suggestions**:
- Add null check: `if (variable != null)`
- Use null-aware operators: `variable?.method()`
- Initialize variable in setUp()
- Use late initialization with assertion

---

### 3. TimeoutFailure

**When**: Test or operation exceeds time limit

```dart
final class TimeoutFailure extends FailureType {
  const TimeoutFailure({
    required this.duration,
    required this.timeout,
    this.operation,
  });

  final Duration duration;
  final Duration timeout;
  final String? operation;

  @override
  String get category => 'Timeout';

  @override
  String? get suggestion =>
      'Increase timeout (was ${timeout.inSeconds}s) or optimize ${operation ?? "operation"}';
}
```

**Example Output**:
```
TimeoutException after 0:00:05.000000: Future not completed
```

**Detection Pattern**:
```dart
if (output.contains('TimeoutException') || output.contains('timed out')) {
  final durationMatch = RegExp(r'(\d+):(\d+):(\d+)\.(\d+)').firstMatch(output);

  Duration? duration;
  if (durationMatch != null) {
    duration = Duration(
      hours: int.parse(durationMatch.group(1)!),
      minutes: int.parse(durationMatch.group(2)!),
      seconds: int.parse(durationMatch.group(3)!),
    );
  }

  return TimeoutFailure(
    duration: duration ?? Duration(seconds: 5),
    timeout: Duration(seconds: 5),
    operation: extractOperation(output),
  );
}
```

**Suggestions**:
- Increase timeout: `test('...', timeout: Timeout(Duration(seconds: 10)))`
- Optimize async operations
- Check for infinite loops
- Mock slow external services

---

### 4. TypeMismatch

**When**: Type casting or type check fails

```dart
final class TypeMismatch extends FailureType {
  const TypeMismatch({
    required this.expectedType,
    required this.actualType,
    this.variableName,
  });

  final String expectedType;
  final String actualType;
  final String? variableName;

  @override
  String get category => 'Type Error';

  @override
  String? get suggestion =>
      'Expected $expectedType but got $actualType for ${variableName ?? "value"}';
}
```

**Example Output**:
```
type 'String' is not a subtype of type 'int'
```

**Detection Pattern**:
```dart
final typeMatch = RegExp(r"type '(.+)' is not a subtype of type '(.+)'").firstMatch(output);
if (typeMatch != null) {
  return TypeMismatch(
    expectedType: typeMatch.group(2)!,
    actualType: typeMatch.group(1)!,
    variableName: extractVariableName(output),
  );
}
```

**Suggestions**:
- Add type conversion: `int.parse(value)`
- Use type checks: `if (value is String)`
- Fix method return type
- Update variable declaration type

---

### 5. AsyncError

**When**: Async/await or Future handling issues

```dart
final class AsyncError extends FailureType {
  const AsyncError({
    required this.message,
    this.missingAwait = false,
    this.unhandledFuture = false,
  });

  final String message;
  final bool missingAwait;
  final bool unhandledFuture;

  @override
  String get category => 'Async Error';

  @override
  String? get suggestion {
    if (missingAwait) return 'Add await keyword before async operation';
    if (unhandledFuture) return 'Handle Future with await or .then()';
    return 'Review async/await usage';
  }
}
```

**Detection Pattern**:
```dart
if (output.contains('Unhandled exception') && output.contains('Future')) {
  return AsyncError(
    message: 'Unhandled future error',
    unhandledFuture: true,
  );
}

if (output.contains('Future') && output.contains('not awaited')) {
  return AsyncError(
    message: 'Missing await',
    missingAwait: true,
  );
}
```

**Suggestions**:
- Add `await` keyword
- Use `expectLater()` instead of `expect()` for futures
- Handle errors with try-catch
- Use `unawaited()` if intentionally not awaiting

---

### 6. StateError

**When**: Invalid object state for operation

```dart
final class StateError extends FailureType {
  const StateError({
    required this.message,
    this.currentState,
    this.expectedState,
  });

  final String message;
  final String? currentState;
  final String? expectedState;

  @override
  String get category => 'State Error';

  @override
  String? get suggestion =>
      'Ensure proper state transition from $currentState to $expectedState';
}
```

**Suggestions**:
- Check state before operation
- Ensure proper initialization
- Verify lifecycle methods called in order
- Reset state in tearDown()

---

### 7. NetworkError

**When**: Network requests fail

```dart
final class NetworkError extends FailureType {
  const NetworkError({
    required this.statusCode,
    required this.endpoint,
    this.message,
  });

  final int? statusCode;
  final String endpoint;
  final String? message;

  @override
  String get category => 'Network';

  @override
  String? get suggestion =>
      'Mock network calls in tests. Status: $statusCode for $endpoint';
}
```

**Suggestions**:
- Mock HTTP client
- Use test fixtures
- Avoid real network calls in tests
- Check network connectivity in setup

---

### 8. FileSystemError

**When**: File I/O operations fail

```dart
final class FileSystemError extends FailureType {
  const FileSystemError({
    required this.path,
    required this.operation,
    this.message,
  });

  final String path;
  final String operation;  // 'read', 'write', 'delete', etc.
  final String? message;

  @override
  String get category => 'File System';

  @override
  String? get suggestion =>
      'Check file exists and permissions for $operation on $path';
}
```

**Suggestions**:
- Use test fixtures
- Create files in setUp(), delete in tearDown()
- Check file permissions
- Use temp directories

---

### 9. UnknownFailure

**When**: Can't classify the failure

```dart
final class UnknownFailure extends FailureType {
  const UnknownFailure({
    required this.rawOutput,
  });

  final String rawOutput;

  @override
  String get category => 'Unknown';

  @override
  String? get suggestion =>
      'Review error output for root cause';
}
```

**Use as fallback** when no patterns match.

---

## Pattern Detection Implementation

**File**: `lib/src/bin/analyze_tests_lib.dart`
**Method**: `detectFailureType(String output)`

### Detection Flow

```
1. Check for assertion patterns
   ↓
2. Check for null errors
   ↓
3. Check for timeout
   ↓
4. Check for type mismatch
   ↓
5. Check for async errors
   ↓
6. Check for state errors
   ↓
7. Check for network errors
   ↓
8. Check for file system errors
   ↓
9. Default to UnknownFailure
```

### Implementation Pattern

```dart
FailureType detectFailureType(String output) {
  // Assertion failures
  if (output.contains('Expected:') && output.contains('Actual:')) {
    return AssertionFailure(...);
  }

  // Null errors
  if (output.contains('NoSuchMethodError') && output.contains('null')) {
    return NullError(...);
  }

  // Timeout failures
  if (output.contains('TimeoutException') || output.contains('timed out')) {
    return TimeoutFailure(...);
  }

  // Type mismatches
  final typeMatch = RegExp(r"type '(.+)' is not a subtype").firstMatch(output);
  if (typeMatch != null) {
    return TypeMismatch(...);
  }

  // ... more patterns

  // Fallback
  return UnknownFailure(rawOutput: output);
}
```

---

## Pattern Matching Usage

### Exhaustive Switch

```dart
String getSuggestion(FailureType failure) {
  return switch (failure) {
    AssertionFailure(:final message) => 'Check assertion: $message',
    NullError(:final variableName) => 'Add null check for $variableName',
    TimeoutFailure(:final timeout) => 'Increase timeout: $timeout',
    TypeMismatch() => 'Fix type mismatch',
    AsyncError(:final missingAwait) => missingAwait ? 'Add await' : 'Handle future',
    StateError() => 'Check state transitions',
    NetworkError() => 'Mock network calls',
    FileSystemError() => 'Use test fixtures',
    ParseError() => 'Validate input format',
    InitializationError() => 'Check setUp()',
    DisposalError() => 'Check tearDown()',
    ConfigurationError() => 'Review config',
    UnknownFailure() => 'Review error output',
  };
}
```

**Compiler guarantees** all cases are handled!

### Type Narrowing

```dart
void handleFailure(FailureType failure) {
  switch (failure) {
    case NullError(:final variableName):
      // Type is narrowed to NullError here
      print('Null error on: $variableName');
      break;

    case TimeoutFailure(:final duration, :final timeout):
      // Type is narrowed to TimeoutFailure
      print('Timeout: took $duration, limit was $timeout');
      break;

    default:
      print('Other failure: ${failure.category}');
  }
}
```

---

## Adding New Failure Types

**See SOP**: `.agent/guides/01_adding_failure_pattern.md`

### Steps Summary:

1. Add new sealed class to `failure_types.dart`
2. Implement required getters (category, suggestion)
3. Add detection logic to `detectFailureType()`
4. Update pattern matching in analyzers
5. Add tests

### Example: Adding ValidationError

```dart
final class ValidationError extends FailureType {
  const ValidationError({
    required this.fieldName,
    required this.constraint,
    this.value,
  });

  final String fieldName;
  final String constraint;
  final String? value;

  @override
  String get category => 'Validation';

  @override
  String? get suggestion =>
      'Field $fieldName failed validation: $constraint';
}
```

Then add detection:

```dart
if (output.contains('ValidationException')) {
  final fieldMatch = RegExp(r'field: (\w+)').firstMatch(output);
  return ValidationError(
    fieldName: fieldMatch?.group(1) ?? 'unknown',
    constraint: extractConstraint(output),
    value: extractValue(output),
  );
}
```

---

## Common Patterns & Regex

### Extracting Location

```dart
String? extractLocation(String output) {
  // Pattern: package:test_reporter/file.dart 42:15
  final match = RegExp(r'package:.+?\.dart\s+(\d+):(\d+)').firstMatch(output);
  if (match != null) {
    return 'line ${match.group(1)}, column ${match.group(2)}';
  }
  return null;
}
```

### Extracting Variable Names

```dart
String? extractVariableName(String output) {
  // Pattern: Tried calling: variableName
  final match = RegExp(r'Tried calling: (\w+)').firstMatch(output);
  return match?.group(1);
}
```

### Extracting Stack Trace

```dart
String? extractStackTrace(String output) {
  final lines = output.split('\n');
  final stackLines = lines.where((line) =>
    line.trim().startsWith('#') ||
    line.contains('package:')
  ).toList();

  return stackLines.isEmpty ? null : stackLines.join('\n');
}
```

---

## Failure Pattern Statistics

Reports include pattern distribution:

```markdown
## Failure Pattern Distribution

| Pattern | Count | Percentage |
|---------|-------|------------|
| NullError | 5 | 45.5% |
| Timeout | 3 | 27.3% |
| Assertion | 2 | 18.2% |
| AsyncError | 1 | 9.1% |
```

**Implementation**:
```dart
void analyzePatterns() {
  final patternCounts = <String, int>{};

  for (final failures in testFailures.values) {
    for (final failure in failures) {
      final category = failure.type.category;
      patternCounts[category] = (patternCounts[category] ?? 0) + 1;
    }
  }

  // Generate distribution chart
}
```

---

## Token Usage Guidance

**Loading this file**: ~8-12K tokens

**Best used for**:
- Adding new failure types
- Understanding pattern detection
- Improving detection accuracy
- Debugging classification issues

**Recommended pairings**:
- With `01_adding_failure_pattern.md` SOP
- With `modern_dart_features.md` for sealed classes
- With `failure_type_template.dart` template

---

## Benefits of Sealed Classes

### vs Enum

**Old way** (enum):
```dart
enum FailureType {
  assertion,
  nullError,
  timeout,
}

// No associated data
// No type safety
// Manual switch statements
```

**New way** (sealed class):
```dart
sealed class FailureType { ... }

final class NullError extends FailureType {
  final String variableName;  // Rich data!
  // ...
}

// Exhaustive checking
// Type-safe pattern matching
// Associated data
```

### Compiler Guarantees

```dart
String handle(FailureType failure) {
  return switch (failure) {
    AssertionFailure() => 'Assertion',
    NullError() => 'Null',
    // If you forget TimeoutFailure, compiler ERROR!
  };
}
```

---

This failure pattern system enables:
- ✅ Accurate failure classification
- ✅ Context-aware suggestions
- ✅ Type-safe pattern matching
- ✅ Extensible architecture
- ✅ Rich failure data
