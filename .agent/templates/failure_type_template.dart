/// Template for adding a new failure type
///
/// Steps to use this template:
/// 1. Copy this class to lib/src/models/failure_types.dart
/// 2. Replace YOUR_FAILURE with your failure type name
/// 3. Add relevant fields for your failure type
/// 4. Implement category and suggestion getters
/// 5. Add detection logic to analyze_tests_lib.dart
/// 6. Update all exhaustive switches

/// YOUR_FAILURE - Brief description of when this failure occurs
///
/// Example:
/// ```dart
/// final failure = YourFailure(
///   message: 'Error message',
///   location: 'test/my_test.dart:42',
///   // ... other fields
/// );
/// ```
final class YourFailure extends FailureType {
  const YourFailure({
    required this.message,
    required this.location,
    // Add more fields as needed
    this.additionalField,
  });

  /// The error message from the test output
  final String message;

  /// Location where the failure occurred (file:line)
  final String location;

  /// Additional context-specific field (optional)
  final String? additionalField;

  @override
  String get category => 'Your Failure Category';

  @override
  String? get suggestion {
    // Provide helpful suggestions for fixing this failure type
    return 'Suggestion for fixing this failure: ...'
        '${additionalField != null ? " Related to: $additionalField" : ""}';
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DETECTION LOGIC
// Add this to analyze_tests_lib.dart in detectFailureType() method
// ═══════════════════════════════════════════════════════════════════════════

/*
FailureType detectFailureType(String output) {
  // ... existing patterns

  // YOUR_FAILURE detection
  if (output.contains('YOUR_UNIQUE_PATTERN')) {
    final messageMatch = RegExp(r'YOUR_REGEX_PATTERN').firstMatch(output);
    final locationMatch = RegExp(r'package:.+?\.dart\s+(\d+):(\d+)').firstMatch(output);

    return YourFailure(
      message: messageMatch?.group(1) ?? 'Unknown error',
      location: locationMatch != null
          ? 'line ${locationMatch.group(1)}, column ${locationMatch.group(2)}'
          : 'unknown',
      additionalField: extractAdditionalField(output),
    );
  }

  // ... other patterns
}

/// Helper to extract additional field
String? extractAdditionalField(String output) {
  final match = RegExp(r'PATTERN_FOR_FIELD').firstMatch(output);
  return match?.group(1);
}
*/

// ═══════════════════════════════════════════════════════════════════════════
// EXAMPLE TEST OUTPUT
// Example of what test output looks like for this failure type
// ═══════════════════════════════════════════════════════════════════════════

/*
Example test output:
══╡ YOUR_UNIQUE_PATTERN ╞══
Error message here
Additional context: value
Location: package:test_reporter/test.dart 42:15
*/

// ═══════════════════════════════════════════════════════════════════════════
// PATTERN MATCHING EXAMPLES
// How to use this failure type in switch statements
// ═══════════════════════════════════════════════════════════════════════════

/*
// Example 1: Basic pattern matching
switch (failure) {
  case YourFailure(:final message):
    print('Your failure: $message');
  // ... other cases
}

// Example 2: With guards
switch (failure) {
  case YourFailure(:final additionalField) when additionalField != null:
    print('Your failure with context: $additionalField');
  case YourFailure():
    print('Your failure without context');
  // ... other cases
}

// Example 3: Extracting multiple fields
switch (failure) {
  case YourFailure(:final message, :final location, :final additionalField):
    print('$message at $location (context: $additionalField)');
  // ... other cases
}
*/
