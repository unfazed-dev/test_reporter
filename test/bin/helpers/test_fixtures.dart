/// Test fixtures for bin executable tests
/// Provides sample JSON events, lcov data, and other test data

/// Sample JSON test event: suite
const sampleSuiteEvent = '''
{
  "suite": {
    "id": 0,
    "platform": "vm",
    "path": "test/example_test.dart"
  },
  "type": "suite",
  "time": 0
}
''';

/// Sample JSON test event: testStart
const sampleTestStartEvent = '''
{
  "test": {
    "id": 1,
    "name": "example test passes",
    "suiteID": 0,
    "groupIDs": [],
    "metadata": {
      "skip": false,
      "skipReason": null
    },
    "line": 5,
    "column": 3,
    "url": "file:///path/to/test/example_test.dart"
  },
  "type": "testStart",
  "time": 100
}
''';

/// Sample JSON test event: testDone (passing)
const sampleTestDonePassEvent = '''
{
  "testID": 1,
  "result": "success",
  "hidden": false,
  "type": "testDone",
  "time": 500
}
''';

/// Sample JSON test event: testDone (failing)
const sampleTestDoneFailEvent = '''
{
  "testID": 1,
  "result": "failure",
  "hidden": false,
  "type": "testDone",
  "time": 500
}
''';

/// Sample JSON test event: error
const sampleErrorEvent = '''
{
  "testID": 1,
  "error": "Expected: <true>\\n  Actual: <false>",
  "stackTrace": "package:test_api/src/expect/expect.dart 123:5  expect\\ntest/example_test.dart 10:7  main.<fn>",
  "isFailure": true,
  "type": "error",
  "time": 450
}
''';

/// Sample JSON test event: group
const sampleGroupEvent = '''
{
  "group": {
    "id": 2,
    "suiteID": 0,
    "parentID": null,
    "name": "Example group",
    "metadata": {
      "skip": false,
      "skipReason": null
    },
    "testCount": 5,
    "line": 3,
    "column": 3,
    "url": "file:///path/to/test/example_test.dart"
  },
  "type": "group",
  "time": 50
}
''';

/// Sample JSON test event: done
const sampleDoneEvent = '''
{
  "success": true,
  "type": "done",
  "time": 1000
}
''';

/// Sample lcov coverage data
const sampleLcovData = '''
TN:
SF:lib/src/example.dart
DA:5,1
DA:6,1
DA:7,0
DA:10,1
DA:11,1
DA:12,1
DA:15,0
LF:7
LH:5
end_of_record
SF:lib/src/another.dart
DA:3,1
DA:4,1
DA:5,1
LF:3
LH:3
end_of_record
''';

/// Sample stack trace - assertion failure
const sampleAssertionStackTrace = '''
package:test_api/src/expect/expect.dart 123:5  expect
test/example_test.dart 10:7  main.<fn>
package:test_api/src/backend/invoker.dart 234:9  Invoker._waitForOutstandingCallbacks.<fn>
===== asynchronous gap ===========================
dart:async  _asyncThenWrapperHelper
package:test_api/src/backend/invoker.dart 231:7  Invoker._waitForOutstandingCallbacks
''';

/// Sample stack trace - null error
const sampleNullErrorStackTrace = '''
dart:core  Object.noSuchMethod
lib/src/example.dart 45:12  ExampleClass.doSomething
test/example_test.dart 15:5  main.<fn>
package:test_api/src/backend/invoker.dart 234:9  Invoker._waitForOutstandingCallbacks.<fn>
''';

/// Sample stack trace - timeout
const sampleTimeoutStackTrace = '''
package:test_api/src/backend/live_test.dart 123:7  LiveTest._run.<fn>
package:async/src/cancelable_operation.dart 45:9  CancelableOperation.then.<fn>
dart:async  _rootRunUnary
''';

/// Sample error messages
class SampleErrors {
  static const assertion = 'Expected: <true>\n  Actual: <false>';
  static const nullError =
      "NoSuchMethodError: The method 'doSomething' was called on null.";
  static const timeout = 'Test timed out after 30 seconds.';
  static const rangeError =
      'RangeError (index): Invalid value: Not in inclusive range 0..4: 5';
  static const typeError = "type 'String' is not a subtype of type 'int'";
  static const networkError =
      'SocketException: Connection refused (OS Error: Connection refused, errno = 61)';
  static const fileNotFound =
      "FileSystemException: Cannot open file, path = 'missing.txt' (OS Error: No such file or directory, errno = 2)";
}

/// Sample unified report with embedded JSON
String sampleUnifiedReport({
  double coverage = 85.5,
  int totalTests = 50,
  int passedTests = 48,
  int failedTests = 2,
}) {
  return '''
# Test Analysis Report - Example Module

## Coverage Analysis
- Line Coverage: ${coverage.toStringAsFixed(1)}%
- Total Lines: 100
- Covered Lines: ${coverage * 100 ~/ 100}

## Test Results
- Total Tests: $totalTests
- Passed: $passedTests
- Failed: $failedTests
- Pass Rate: ${(passedTests / totalTests * 100).toStringAsFixed(1)}%

## JSON Data
```json
{
  "coverage": {
    "lineCoverage": $coverage,
    "totalLines": 100,
    "coveredLines": ${coverage * 100 ~/ 100}
  },
  "tests": {
    "total": $totalTests,
    "passed": $passedTests,
    "failed": $failedTests,
    "passRate": ${(passedTests / totalTests * 100).toStringAsFixed(1)}
  }
}
```

Generated: ${DateTime.now().toIso8601String()}
''';
}

/// Sample coverage report
String sampleCoverageReport({
  String module = 'example',
  double coverage = 85.5,
}) {
  return '''
# Coverage Report - $module

## Summary
- Line Coverage: ${coverage.toStringAsFixed(1)}%
- Branch Coverage: ${(coverage - 5).toStringAsFixed(1)}%

## Files
| File | Coverage |
|------|----------|
| lib/src/example.dart | 71.4% |
| lib/src/another.dart | 100.0% |

## JSON Data
```json
{
  "module": "$module",
  "coverage": $coverage,
  "timestamp": "${DateTime.now().toIso8601String()}"
}
```
''';
}

/// Sample analyzer report
String sampleAnalyzerReport({
  String module = 'example',
  int totalTests = 50,
  int passedTests = 48,
}) {
  return '''
# Test Analysis Report - $module

## Statistics
- Total Tests: $totalTests
- Passed: $passedTests
- Failed: ${totalTests - passedTests}

## JSON Data
```json
{
  "module": "$module",
  "totalTests": $totalTests,
  "passed": $passedTests,
  "failed": ${totalTests - passedTests},
  "timestamp": "${DateTime.now().toIso8601String()}"
}
```
''';
}

/// Sample failed test report
String sampleFailedReport({
  String module = 'example',
  int failedCount = 2,
}) {
  return '''
# Failed Tests Report - $module

## Failed Tests ($failedCount)

### test/example_test.dart
- ❌ example test fails
- ❌ another test fails

## JSON Data
```json
{
  "module": "$module",
  "failedCount": $failedCount,
  "timestamp": "${DateTime.now().toIso8601String()}"
}
```
''';
}

/// Test file paths
class TestPaths {
  static const testFile = 'test/example_test.dart';
  static const libFile = 'lib/src/example.dart';
  static const coverageReportDir = 'test_analyzer_reports/code_coverage';
  static const analyzerReportDir = 'test_analyzer_reports/analyzer';
  static const failedReportDir = 'test_analyzer_reports/failed';
  static const unifiedReportDir = 'test_analyzer_reports/unified';
}

/// Sample pubspec.yaml content
const samplePubspecFlutter = '''
name: example_app
description: Example Flutter app
version: 1.0.0

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter
  test: ^1.24.0
''';

const samplePubspecDart = '''
name: example_package
description: Example Dart package
version: 1.0.0

environment:
  sdk: '>=3.0.0 <4.0.0'

dev_dependencies:
  test: ^1.24.0
''';
