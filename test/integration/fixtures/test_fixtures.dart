/// Test fixtures for integration tests
///
/// Provides sample data, outputs, and configurations for testing.

/// Sample LCOV coverage data
const sampleLcovData = """
SF:lib/src/auth/auth_service.dart
DA:10,1
DA:11,1
DA:12,0
DA:15,1
LF:4
LH:3
end_of_record
""";

/// Sample test JSON output
const sampleTestJsonOutput = """
{"suite":{"id":0,"path":"test/auth_test.dart"}}
{"group":{"id":1,"name":"AuthService Tests"}}
{"test":{"id":2,"name":"should authenticate user","groupID":1}}
{"testStart":{"id":2}}
{"testDone":{"id":2,"result":"success","time":150}}
{"done":{"success":true}}
""";

/// Sample failed test JSON output
const sampleFailedTestJson = """
{"suite":{"id":0,"path":"test/auth_test.dart"}}
{"test":{"id":1,"name":"should validate credentials"}}
{"testStart":{"id":1}}
{"error":{"id":1,"error":"Expected: true\nActual: false","stackTrace":"at auth_test.dart:42:7"}}
{"testDone":{"id":1,"result":"error","time":200}}
{"done":{"success":false}}
""";

/// Sample coverage report content
const sampleCoverageReport = """
# 📊 Coverage Report

**Generated:** 2024-10-30 10:00:00
**Module:** lib/src/auth

## 📈 Executive Summary

| Metric | Value |
|--------|-------|
| **Overall Coverage** | **85.5%** |
| Total Lines | 1443 |
| Covered Lines | 1234 |
| Uncovered Lines | 209 |
""";

/// Sample pubspec.yaml for Flutter project
const sampleFlutterPubspec = """
name: test_project
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
""";

/// Sample pubspec.yaml for Dart project
const sampleDartPubspec = """
name: test_project
version: 1.0.0

environment:
  sdk: '>=3.0.0 <4.0.0'

dev_dependencies:
  test: ^1.24.0
""";
