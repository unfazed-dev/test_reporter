/// Template for adding a new record type
///
/// Steps to use this template:
/// 1. Copy this typedef to lib/src/models/result_types.dart
/// 2. Replace YOUR_RESULT with your result type name
/// 3. Add relevant fields for your result
/// 4. Update documentation with usage examples
/// 5. Use in your analyzer implementation

/// Result of YOUR_OPERATION
///
/// Returns information about the operation including success status,
/// metrics, and any error messages.
///
/// Example usage:
/// ```dart
/// YourResult performOperation() {
///   try {
///     // ... perform operation
///     return (
///       success: true,
///       itemsProcessed: count,
///       metric1: value1,
///       metric2: value2,
///       error: null,
///     );
///   } catch (e) {
///     return (
///       success: false,
///       itemsProcessed: 0,
///       metric1: 0.0,
///       metric2: 0,
///       error: e.toString(),
///     );
///   }
/// }
/// ```
///
/// Access fields:
/// ```dart
/// final result = performOperation();
/// if (result.success) {
///   print('Processed: ${result.itemsProcessed}');
///   print('Metric 1: ${result.metric1}');
/// } else {
///   print('Error: ${result.error}');
/// }
/// ```
///
/// Destructuring:
/// ```dart
/// final (
///   success: ok,
///   itemsProcessed: count,
///   error: err
/// ) = performOperation();
///
/// if (!ok) {
///   print('Failed: $err');
/// }
/// ```
typedef YourResult = ({
  // Standard fields (include these in all results)
  bool success,
  String? error,

  // Operation-specific metrics
  int itemsProcessed,
  double metric1,
  int metric2,

  // Add more fields as needed for your specific use case
  String? optionalField,
});

// ═══════════════════════════════════════════════════════════════════════════
// USAGE EXAMPLES
// ═══════════════════════════════════════════════════════════════════════════

/*
// Example 1: Returning from function
YourResult performOperation(List<String> items) {
  try {
    var processedCount = 0;
    var metric1Sum = 0.0;

    for (final item in items) {
      // Process item
      processedCount++;
      metric1Sum += calculateMetric(item);
    }

    return (
      success: true,
      itemsProcessed: processedCount,
      metric1: metric1Sum / processedCount,
      metric2: items.length,
      error: null,
      optionalField: 'additional info',
    );
  } catch (e) {
    return (
      success: false,
      itemsProcessed: 0,
      metric1: 0.0,
      metric2: 0,
      error: e.toString(),
      optionalField: null,
    );
  }
}

// Example 2: Pattern matching
void processResult(YourResult result) {
  switch (result) {
    case (success: true, itemsProcessed: 0):
      print('✅ Success but nothing to process');

    case (success: true, :final itemsProcessed, :final metric1):
      print('✅ Processed $itemsProcessed items, metric1: $metric1');

    case (success: false, :final error):
      print('❌ Failed: $error');
  }
}

// Example 3: Guard clauses
String categorize(YourResult result) => switch (result) {
  (success: false, :final error) => 'Error: $error',
  (itemsProcessed: 0) => 'No items',
  (itemsProcessed: final n) when n < 10 => 'Few items: $n',
  (itemsProcessed: final n) when n >= 10 => 'Many items: $n',
  _ => 'Unknown',
};

// Example 4: Chaining operations
Future<YourResult> operationChain() async {
  final result1 = performOperation(['a', 'b']);

  if (!result1.success) {
    return result1;  // Propagate error
  }

  final result2 = performOperation(['c', 'd']);

  return (
    success: result2.success,
    itemsProcessed: result1.itemsProcessed + result2.itemsProcessed,
    metric1: (result1.metric1 + result2.metric1) / 2,
    metric2: result1.metric2 + result2.metric2,
    error: result2.error,
    optionalField: null,
  );
}
*/

// ═══════════════════════════════════════════════════════════════════════════
// TESTING EXAMPLES
// ═══════════════════════════════════════════════════════════════════════════

/*
import 'package:test/test.dart';

void main() {
  group('YourResult', () {
    test('success case', () {
      final result = (
        success: true,
        itemsProcessed: 5,
        metric1: 10.5,
        metric2: 100,
        error: null,
        optionalField: 'test',
      );

      expect(result.success, isTrue);
      expect(result.itemsProcessed, equals(5));
      expect(result.metric1, equals(10.5));
      expect(result.error, isNull);
    });

    test('failure case', () {
      final result = (
        success: false,
        itemsProcessed: 0,
        metric1: 0.0,
        metric2: 0,
        error: 'Operation failed',
        optionalField: null,
      );

      expect(result.success, isFalse);
      expect(result.error, isNotNull);
    });

    test('destructuring', () {
      final result = (
        success: true,
        itemsProcessed: 10,
        metric1: 5.0,
        metric2: 50,
        error: null,
        optionalField: null,
      );

      final (success: ok, itemsProcessed: count) = result;

      expect(ok, isTrue);
      expect(count, equals(10));
    });
  });
}
*/
