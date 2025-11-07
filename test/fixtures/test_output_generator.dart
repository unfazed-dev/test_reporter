/// Test output JSON generator for testing test analyzers
///
/// Generates realistic test JSON output in the format produced by
/// `dart test --reporter json` for integration tests.

import 'dart:math';

/// Generator for test output JSON
class TestOutputGenerator {
  /// Generate passing test JSON
  static String generatePassing({
    required String testName,
    required String suitePath,
    int testID = 1,
    int duration = 100,
  }) {
    return '''
{"test":{"id":$testID,"name":"$testName","suiteID":0,"groupIDs":[],"metadata":{"skip":false,"skipReason":null},"line":10,"column":5,"url":"file://$suitePath"}}
{"testStart":{"testID":$testID,"time":0}}
{"testDone":{"testID":$testID,"result":"success","time":$duration,"hidden":false}}
''';
  }

  /// Generate failing test JSON
  static String generateFailing({
    required String testName,
    required String suitePath,
    required String errorMessage,
    required String stackTrace,
    int testID = 1,
    int duration = 150,
  }) {
    return '''
{"test":{"id":$testID,"name":"$testName","suiteID":0,"groupIDs":[],"metadata":{"skip":false,"skipReason":null},"line":15,"column":5,"url":"file://$suitePath"}}
{"testStart":{"testID":$testID,"time":0}}
{"error":{"testID":$testID,"error":"$errorMessage","stackTrace":"$stackTrace","isFailure":true}}
{"testDone":{"testID":$testID,"result":"error","time":$duration,"hidden":false}}
''';
  }

  /// Generate flaky test pattern (mix of pass/fail)
  static List<String> generateFlakyPattern({
    required String testName,
    required String suitePath,
    required int runs,
    required double failureRate,
  }) {
    final random = Random(42); // Deterministic for testing
    final outputs = <String>[];

    for (var i = 0; i < runs; i++) {
      final shouldFail = random.nextDouble() < failureRate;

      if (shouldFail) {
        outputs.add(generateFailing(
          testName: testName,
          suitePath: suitePath,
          errorMessage: 'Flaky test failure',
          stackTrace: 'at $suitePath:20',
          testID: i + 1,
        ));
      } else {
        outputs.add(generatePassing(
          testName: testName,
          suitePath: suitePath,
          testID: i + 1,
        ));
      }
    }

    return outputs;
  }

  /// Generate timeout failure JSON
  static String generateTimeout({
    required String testName,
    required String suitePath,
    required int timeoutSeconds,
    int testID = 1,
  }) {
    return generateFailing(
      testName: testName,
      suitePath: suitePath,
      errorMessage: 'Test timed out after $timeoutSeconds seconds',
      stackTrace: 'TimeoutException\nat $suitePath:25',
      testID: testID,
      duration: timeoutSeconds * 1000,
    );
  }

  /// Generate null error JSON
  static String generateNullError({
    required String testName,
    required String suitePath,
    required String variableName,
    required int lineNumber,
    int testID = 1,
  }) {
    return generateFailing(
      testName: testName,
      suitePath: suitePath,
      errorMessage:
          'Null check operator used on a null value (accessing $variableName)',
      stackTrace: 'at $suitePath:$lineNumber',
      testID: testID,
    );
  }

  /// Generate assertion failure JSON
  static String generateAssertionFailure({
    required String testName,
    required String suitePath,
    required String expected,
    required String actual,
    int testID = 1,
  }) {
    return generateFailing(
      testName: testName,
      suitePath: suitePath,
      errorMessage: 'Expected: $expected\\nActual: $actual',
      stackTrace: 'at $suitePath:30',
      testID: testID,
    );
  }

  /// Generate complete test suite JSON
  static String generateSuite({
    required String suitePath,
    required int testCount,
    required double passRate,
  }) {
    final buffer = StringBuffer();
    final passCount = (testCount * passRate).round();

    for (var i = 0; i < testCount; i++) {
      final shouldPass = i < passCount;
      final testName = 'test ${i + 1}';

      if (shouldPass) {
        buffer.write(generatePassing(
          testName: testName,
          suitePath: suitePath,
          testID: i + 1,
        ));
      } else {
        buffer.write(generateFailing(
          testName: testName,
          suitePath: suitePath,
          errorMessage: 'Test failed',
          stackTrace: 'at $suitePath:${35 + i}',
          testID: i + 1,
        ));
      }
    }

    return buffer.toString();
  }

  /// Generate test run with mixed results
  static String generateMixedRun({
    required int totalTests,
    required int passCount,
    required int failCount,
    required int skipCount,
  }) {
    final buffer = StringBuffer();
    var testID = 1;

    // Generate passing tests
    for (var i = 0; i < passCount; i++) {
      buffer.write(generatePassing(
        testName: 'passing test ${i + 1}',
        suitePath: 'test/unit/pass_test.dart',
        testID: testID++,
      ));
    }

    // Generate failing tests
    for (var i = 0; i < failCount; i++) {
      buffer.write(generateFailing(
        testName: 'failing test ${i + 1}',
        suitePath: 'test/unit/fail_test.dart',
        errorMessage: 'Test assertion failed',
        stackTrace: 'at fail_test.dart:${40 + i}',
        testID: testID++,
      ));
    }

    // Generate skipped tests
    for (var i = 0; i < skipCount; i++) {
      buffer.write('''
{"test":{"id":$testID,"name":"skipped test ${i + 1}","suiteID":0,"groupIDs":[],"metadata":{"skip":true,"skipReason":"Test skipped"},"line":50,"column":5,"url":"file://test/unit/skip_test.dart"}}
{"testStart":{"testID":$testID,"time":0}}
{"testDone":{"testID":$testID,"result":"skipped","time":0,"hidden":false}}
''');
      testID++;
    }

    return buffer.toString();
  }
}
