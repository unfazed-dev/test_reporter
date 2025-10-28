/// Modern sealed class hierarchy for test failure types
///
/// This replaces the old FailureType enum with a more powerful sealed class
/// system that supports pattern matching and exhaustive checking.
///
/// Example usage:
/// ```dart
/// final failure = AssertionFailure(
///   message: 'Expected value to be 5, got 3',
///   location: 'test/my_test.dart:42',
/// );
///
/// // Pattern matching
/// switch (failure) {
///   case AssertionFailure(:final message):
///     print('Assertion failed: $message');
///   case NullError(:final variableName):
///     print('Null error on $variableName');
///   case TimeoutFailure(:final duration):
///     print('Test timed out after $duration');
///   // ... other cases
/// }
/// ```
library;

/// Base sealed class for all failure types
///
/// Sealed classes ensure exhaustive pattern matching - the compiler will
/// warn if you forget to handle any case.
sealed class FailureType {
  const FailureType();

  /// Human-readable category name
  String get category;

  /// Suggested fix for this failure type
  String? get suggestion;
}

/// Assertion failures (test expectations that failed)
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
  String get category => 'Assertion Failure';

  @override
  String get suggestion =>
      'Review test assertions - expected value may not match actual behavior. '
      'Consider if business logic changed or test expectations are incorrect.';
}

/// Null reference errors
final class NullError extends FailureType {
  const NullError({
    required this.variableName,
    required this.location,
  });

  final String variableName;
  final String location;

  @override
  String get category => 'Null Reference Error';

  @override
  String get suggestion =>
      'Add null checks or use null-aware operators (?.  ??). '
      'Ensure proper initialization in setUp() methods.';
}

/// Test timeout failures
final class TimeoutFailure extends FailureType {
  const TimeoutFailure({
    required this.duration,
    required this.operation,
  });

  final Duration duration;
  final String operation;

  @override
  String get category => 'Timeout';

  @override
  String get suggestion =>
      'Increase timeout value or optimize async operations. '
      'Check for infinite loops or unresolved futures.';
}

/// Range/index out of bounds errors
final class RangeError extends FailureType {
  const RangeError({
    required this.index,
    required this.validRange,
  });

  final int index;
  final String validRange;

  @override
  String get category => 'Range Error';

  @override
  String get suggestion => 'Verify collection sizes before accessing elements. '
      'Add bounds checking or use safe accessors like elementAtOrNull().';
}

/// Type casting or type mismatch errors
final class TypeError extends FailureType {
  const TypeError({
    required this.expectedType,
    required this.actualType,
    required this.location,
  });

  final String expectedType;
  final String actualType;
  final String location;

  @override
  String get category => 'Type Error';

  @override
  String get suggestion =>
      'Check type casts and ensure proper type annotations. '
      'Consider using pattern matching or type guards for safer type handling.';
}

/// File I/O or file system errors
final class IOError extends FailureType {
  const IOError({
    required this.operation,
    required this.path,
  });

  final String operation;
  final String path;

  @override
  String get category => 'I/O Error';

  @override
  String get suggestion => 'Check file paths and permissions. '
      'Ensure required files exist in test fixtures or use proper mocking.';
}

/// Network-related errors
final class NetworkError extends FailureType {
  const NetworkError({
    required this.operation,
    required this.endpoint,
    this.statusCode,
  });

  final String operation;
  final String endpoint;
  final int? statusCode;

  @override
  String get category => 'Network Error';

  @override
  String get suggestion =>
      'Mock network calls in tests to avoid external dependencies. '
      'Use packages like http_mock_adapter or mockito for HTTP mocking.';
}

/// Unknown or unclassified failures
final class UnknownFailure extends FailureType {
  const UnknownFailure({
    required this.message,
  });

  final String message;

  @override
  String get category => 'Unknown';

  @override
  String? get suggestion => null;
}

/// Helper functions for pattern detection and conversion

/// Detect failure type from error message
FailureType detectFailureType(String error, String stackTrace) {
  final errorLower = error.toLowerCase();

  // Assertion failures
  if (errorLower.contains('expected:') ||
      errorLower.contains('actual:') ||
      errorLower.contains('assertion')) {
    return AssertionFailure(
      message: error,
      location: _extractLocation(stackTrace),
      expectedValue: _extractExpected(error),
      actualValue: _extractActual(error),
    );
  }

  // Null errors
  if (errorLower.contains('null') ||
      errorLower.contains('nullpointerexception')) {
    return NullError(
      variableName: _extractNullVariable(error),
      location: _extractLocation(stackTrace),
    );
  }

  // Timeout errors
  if (errorLower.contains('timeout') || errorLower.contains('timed out')) {
    return TimeoutFailure(
      duration: _extractDuration(error),
      operation: _extractOperation(error),
    );
  }

  // Range errors
  if (errorLower.contains('range') || errorLower.contains('index')) {
    return RangeError(
      index: _extractIndex(error),
      validRange: _extractValidRange(error),
    );
  }

  // Type errors
  if (errorLower.contains('type') ||
      errorLower.contains('cast') ||
      errorLower.contains('is not a subtype')) {
    return TypeError(
      expectedType: _extractExpectedType(error),
      actualType: _extractActualType(error),
      location: _extractLocation(stackTrace),
    );
  }

  // I/O errors
  if (errorLower.contains('filenotfound') ||
      errorLower.contains('permission') ||
      errorLower.contains('ioexception')) {
    return IOError(
      operation: _extractIOOperation(error),
      path: _extractPath(error),
    );
  }

  // Network errors
  if (errorLower.contains('socket') ||
      errorLower.contains('http') ||
      errorLower.contains('connection')) {
    return NetworkError(
      operation: _extractNetworkOperation(error),
      endpoint: _extractEndpoint(error),
      statusCode: _extractStatusCode(error),
    );
  }

  // Unknown
  return UnknownFailure(message: error);
}

// Private helper functions for extracting details from error messages

String _extractLocation(String stackTrace) {
  final lines = stackTrace.split('\n');
  if (lines.isEmpty) return 'unknown';
  // Extract first line of stack trace that contains a file location
  final match = RegExp(r'(.*\.dart:\d+)').firstMatch(lines.first);
  return match?.group(1) ?? 'unknown';
}

String? _extractExpected(String error) {
  final match = RegExp(r'[Ee]xpected:?\s*(.+?)(?:\n|$)').firstMatch(error);
  return match?.group(1)?.trim();
}

String? _extractActual(String error) {
  final match = RegExp(r'[Aa]ctual:?\s*(.+?)(?:\n|$)').firstMatch(error);
  return match?.group(1)?.trim();
}

String _extractNullVariable(String error) {
  final match = RegExp(r"'(\w+)'.*null").firstMatch(error);
  return match?.group(1) ?? 'variable';
}

Duration _extractDuration(String error) {
  final match =
      RegExp(r'(\d+)\s*(ms|milliseconds|s|seconds)').firstMatch(error);
  if (match != null) {
    final value = int.parse(match.group(1)!);
    final unit = match.group(2);
    if (unit == 's' || unit == 'seconds') {
      return Duration(seconds: value);
    }
    return Duration(milliseconds: value);
  }
  return const Duration(seconds: 30); // Default timeout
}

String _extractOperation(String error) {
  if (error.contains('future')) return 'async operation';
  if (error.contains('stream')) return 'stream operation';
  return 'operation';
}

int _extractIndex(String error) {
  final match = RegExp(r'[Ii]ndex:?\s*(\d+)').firstMatch(error);
  return match != null ? int.parse(match.group(1)!) : -1;
}

String _extractValidRange(String error) {
  final match = RegExp(r'0[.]{2}(\d+)').firstMatch(error);
  return match != null ? '0..${match.group(1)}' : 'unknown';
}

String _extractExpectedType(String error) {
  final match =
      RegExp(r'type\s+["\x27](\w+)["\x27]\s+is not').firstMatch(error);
  return match?.group(1) ?? 'unknown';
}

String _extractActualType(String error) {
  final match = RegExp(r'got\s+["\x27](\w+)["\x27]').firstMatch(error);
  return match?.group(1) ?? 'unknown';
}

String _extractIOOperation(String error) {
  if (error.contains('read')) return 'read';
  if (error.contains('write')) return 'write';
  if (error.contains('open')) return 'open';
  return 'file operation';
}

String _extractPath(String error) {
  final match = RegExp(r'["\x27]([^"\x27]+\.[a-z]+)["\x27]').firstMatch(error);
  return match?.group(1) ?? 'unknown';
}

String _extractNetworkOperation(String error) {
  if (error.contains('GET')) return 'GET';
  if (error.contains('POST')) return 'POST';
  if (error.contains('PUT')) return 'PUT';
  if (error.contains('DELETE')) return 'DELETE';
  return 'HTTP request';
}

String _extractEndpoint(String error) {
  final match = RegExp(r'https?://[^\s]+').firstMatch(error);
  return match?.group(0) ?? 'unknown';
}

int? _extractStatusCode(String error) {
  final match = RegExp(r'status\s*:?\s*(\d{3})').firstMatch(error);
  return match != null ? int.parse(match.group(1)!) : null;
}
