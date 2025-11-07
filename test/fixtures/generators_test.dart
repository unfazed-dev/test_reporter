/// Tests for fixture generators
///
/// Coverage Target: 100% of fixture generator utilities
/// Test Strategy: Unit tests for LCOV, test output, and pubspec generators
/// TDD Approach: 🔴 RED → 🟢 GREEN → ♻️ REFACTOR → 🔄 META-TEST
///
/// These generators create realistic test data for integration tests
/// of the bin/ analyzers (coverage, tests, suite, failures).

import 'package:test/test.dart';

import 'lcov_generator.dart';
import 'sample_pubspec.dart';
import 'test_output_generator.dart';

void main() {
  group('LcovGenerator', () {
    test('should generate basic LCOV file', () {
      final lcov = LcovGenerator.generate(
        filePath: 'lib/src/example.dart',
        totalLines: 100,
        coveredLines: 80,
      );

      expect(lcov, contains('SF:lib/src/example.dart'));
      expect(lcov, contains('LF:100')); // total lines
      expect(lcov, contains('LH:80')); // covered lines
      expect(lcov, contains('end_of_record'));
    });

    test('should generate LCOV with specific coverage percentage', () {
      final lcov = LcovGenerator.generate(
        filePath: 'lib/src/example.dart',
        totalLines: 100,
        coveragePercent: 75.0,
      );

      expect(lcov, contains('LF:100'));
      expect(lcov, contains('LH:75')); // 75% of 100 = 75 lines
    });

    test('should generate LCOV with branch data', () {
      final lcov = LcovGenerator.generateWithBranches(
        filePath: 'lib/src/example.dart',
        totalLines: 50,
        coveredLines: 40,
        totalBranches: 10,
        coveredBranches: 8,
      );

      expect(lcov, contains('BRF:10')); // total branches found
      expect(lcov, contains('BRH:8')); // branches hit
    });

    test('should generate LCOV for multiple files', () {
      final lcov = LcovGenerator.generateMultiple([
        LcovFileData(
          filePath: 'lib/src/file1.dart',
          totalLines: 50,
          coveredLines: 40,
        ),
        LcovFileData(
          filePath: 'lib/src/file2.dart',
          totalLines: 60,
          coveredLines: 50,
        ),
      ]);

      expect(lcov, contains('SF:lib/src/file1.dart'));
      expect(lcov, contains('SF:lib/src/file2.dart'));
      expect(lcov.split('end_of_record'), hasLength(3)); // 2 files + trailing
    });

    test('should generate LCOV with uncovered line details', () {
      final lcov = LcovGenerator.generateWithLineDetails(
        filePath: 'lib/src/example.dart',
        coveredLines: [1, 2, 3, 5, 7, 8],
        uncoveredLines: [4, 6, 9, 10],
      );

      expect(lcov, contains('DA:1,1')); // line 1, hit count 1
      expect(lcov, contains('DA:4,0')); // line 4, hit count 0 (uncovered)
      expect(lcov, contains('LF:10')); // total 10 lines
      expect(lcov, contains('LH:6')); // 6 covered
    });

    test('should generate realistic Dart package LCOV', () {
      final lcov = LcovGenerator.generateRealisticDartPackage(
        packageName: 'my_package',
        fileCount: 5,
        avgCoveragePercent: 85.0,
      );

      expect(lcov, contains('SF:lib/src/')); // contains lib/src paths
      expect(lcov.split('end_of_record').length, greaterThan(5));
    });

    test('should generate realistic Flutter package LCOV', () {
      final lcov = LcovGenerator.generateRealisticFlutterPackage(
        packageName: 'my_flutter_app',
        fileCount: 10,
        avgCoveragePercent: 70.0,
      );

      expect(lcov, contains('SF:lib/')); // contains lib paths
      expect(lcov, contains('.dart'));
    });

    test('should parse and validate generated LCOV', () {
      final lcov = LcovGenerator.generate(
        filePath: 'lib/src/example.dart',
        totalLines: 100,
        coveredLines: 75,
      );

      final parsed = LcovGenerator.parse(lcov);
      expect(parsed.files, hasLength(1));
      expect(parsed.files.first.filePath, equals('lib/src/example.dart'));
      expect(parsed.files.first.totalLines, equals(100));
      expect(parsed.files.first.coveredLines, equals(75));
    });
  });

  group('TestOutputGenerator', () {
    test('should generate passing test JSON', () {
      final json = TestOutputGenerator.generatePassing(
        testName: 'should pass successfully',
        suitePath: 'test/unit/example_test.dart',
      );

      expect(json, contains('"result":"success"'));
      expect(json, contains('"name":"should pass successfully"'));
      expect(json, contains('test/unit/example_test.dart'));
    });

    test('should generate failing test JSON', () {
      final json = TestOutputGenerator.generateFailing(
        testName: 'should fail with error',
        suitePath: 'test/unit/example_test.dart',
        errorMessage: 'Expected: 5, Actual: 3',
        stackTrace: 'at example_test.dart:42',
      );

      expect(json, contains('"result":"error"'));
      expect(json, contains('"error":"Expected: 5, Actual: 3"'));
      expect(json, contains('"stackTrace":"at example_test.dart:42"'));
    });

    test('should generate flaky test pattern', () {
      final outputs = TestOutputGenerator.generateFlakyPattern(
        testName: 'should be flaky',
        suitePath: 'test/integration/flaky_test.dart',
        runs: 5,
        failureRate: 0.4, // 40% failure rate
      );

      expect(outputs, hasLength(5));
      final failures =
          outputs.where((o) => o.contains('"result":"error"')).length;
      expect(failures, greaterThan(0)); // at least one failure
      expect(failures, lessThan(5)); // at least one pass
    });

    test('should generate timeout failure JSON', () {
      final json = TestOutputGenerator.generateTimeout(
        testName: 'should timeout',
        suitePath: 'test/integration/slow_test.dart',
        timeoutSeconds: 30,
      );

      expect(json, contains('"result":"error"'));
      expect(json, contains('Test timed out after 30 seconds'));
    });

    test('should generate null error JSON', () {
      final json = TestOutputGenerator.generateNullError(
        testName: 'should fail with null',
        suitePath: 'test/unit/example_test.dart',
        variableName: 'user.name',
        lineNumber: 42,
      );

      expect(json, contains('"result":"error"'));
      expect(json, contains('Null check operator used on a null value'));
      expect(json, contains('user.name'));
    });

    test('should generate assertion failure JSON', () {
      final json = TestOutputGenerator.generateAssertionFailure(
        testName: 'should fail assertion',
        suitePath: 'test/unit/example_test.dart',
        expected: '5',
        actual: '3',
      );

      expect(json, contains('"result":"error"'));
      expect(json, contains('Expected: 5'));
      expect(json, contains('Actual: 3'));
    });

    test('should generate complete test suite JSON', () {
      final json = TestOutputGenerator.generateSuite(
        suitePath: 'test/unit/example_test.dart',
        testCount: 10,
        passRate: 0.8, // 80% pass rate
      );

      final lines = json.split('\n').where((l) => l.isNotEmpty).toList();
      expect(lines.length, greaterThanOrEqualTo(10)); // at least 10 tests
    });

    test('should generate test run with mixed results', () {
      final json = TestOutputGenerator.generateMixedRun(
        totalTests: 20,
        passCount: 15,
        failCount: 3,
        skipCount: 2,
      );

      expect(json, contains('"result":"success"')); // passing tests
      expect(json, contains('"result":"error"')); // failing tests
      expect(json, contains('"result":"skipped"')); // skipped tests
    });
  });

  group('SamplePubspec', () {
    test('should generate basic Dart package pubspec', () {
      final pubspec = SamplePubspec.generateDartPackage(
        name: 'my_package',
        version: '1.0.0',
        sdkVersion: '>=3.0.0 <4.0.0',
      );

      expect(pubspec, contains('name: my_package'));
      expect(pubspec, contains('version: 1.0.0'));
      expect(pubspec, contains('sdk: ">=3.0.0 <4.0.0"'));
    });

    test('should generate Flutter package pubspec', () {
      final pubspec = SamplePubspec.generateFlutterPackage(
        name: 'my_flutter_app',
        version: '1.0.0',
        flutterVersion: '>=3.0.0',
      );

      expect(pubspec, contains('name: my_flutter_app'));
      expect(pubspec, contains('flutter:'));
      expect(pubspec, contains('sdk: flutter'));
    });

    test('should generate pubspec with dependencies', () {
      final pubspec = SamplePubspec.generateWithDependencies(
        name: 'my_package',
        dependencies: {
          'http': '^1.0.0',
          'path': '^1.8.0',
        },
        devDependencies: {
          'test': '^1.24.0',
          'very_good_analysis': '^5.0.0',
        },
      );

      expect(pubspec, contains('dependencies:'));
      expect(pubspec, contains('http: ^1.0.0'));
      expect(pubspec, contains('dev_dependencies:'));
      expect(pubspec, contains('test: ^1.24.0'));
    });

    test('should parse generated pubspec', () {
      final pubspec = SamplePubspec.generateDartPackage(
        name: 'test_package',
        version: '2.0.0',
      );

      final parsed = SamplePubspec.parse(pubspec);
      expect(parsed['name'], equals('test_package'));
      expect(parsed['version'], equals('2.0.0'));
    });
  });
}
