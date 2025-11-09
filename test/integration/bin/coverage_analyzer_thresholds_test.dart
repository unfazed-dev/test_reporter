@Tags(['integration'])
library;

// 🔴 RED Phase: Phase 2.4 - Threshold Validation & Baseline Tests
// Status: IN PROGRESS - Creating tests with TDD methodology
// TDD Methodology: Write FAILING tests FIRST
//
// Test Coverage (Phase 2.4):
// - Suite 1: Threshold Validation Tests (6 tests)
// - Suite 2: Baseline Management Tests (4 tests)
// Total: 10 tests

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:test_reporter/src/bin/analyze_coverage_lib.dart';

import '../../helpers/mock_process.dart';
import '../../fixtures/lcov_generator.dart';
import '../../fixtures/sample_pubspec.dart';

void main() {
  group('Phase 2.4: Threshold Validation & Baseline Tests', () {
    late MockProcessManager processManager;
    late Directory tempDir;

    setUp(() {
      processManager = MockProcessManager();
      tempDir = Directory.systemTemp.createTempSync('threshold_test_');
    });

    tearDown(() async {
      processManager.reset();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    // ========================================================================
    // Suite 1: Threshold Validation Tests (6 tests)
    // ========================================================================

    group('Suite 1: Threshold Validation Tests', () {
      test('should pass when coverage >= minimum threshold', () async {
        // Arrange
        final projectDir = Directory('${tempDir.path}/pass_threshold');
        await projectDir.create(recursive: true);

        final libDir = Directory('${projectDir.path}/lib');
        await libDir.create(recursive: true);

        final testDir = Directory('${projectDir.path}/test');
        await testDir.create(recursive: true);

        final pubspecFile = File('${projectDir.path}/pubspec.yaml');
        await pubspecFile.writeAsString(
          SamplePubspec.generateDartPackage(name: 'pass', version: '1.0.0'),
        );

        // Generate LCOV with 85% coverage (above minimum 80%)
        final lcovContent = LcovGenerator.generate(
          filePath: 'lib/service.dart',
          totalLines: 100,
          coveredLines: 85,
        );

        processManager.mockProcessRun(
          command: 'dart',
          args: ['test', '--coverage=coverage'],
          result: MockProcessResult(exitCode: 0, stdout: '', stderr: ''),
        );

        final coverageDir = Directory('${projectDir.path}/coverage');
        await coverageDir.create(recursive: true);
        final lcovFile = File('${coverageDir.path}/lcov.info');
        await lcovFile.writeAsString(lcovContent);

        // Act
        final thresholds = CoverageThresholds(minimum: 80.0, warning: 90.0);
        final analyzer = CoverageAnalyzer(
          testPath: testDir.path,
          libPath: libDir.path,
          thresholds: thresholds,
          processManager: processManager,
        );

        final exitCode = await analyzer.run();

        // Assert: Should pass (exit code 0)
        expect(exitCode, equals(0),
            reason: 'Should pass when coverage >= minimum threshold');
        expect(analyzer.thresholdViolation, isFalse,
            reason: 'Should not flag threshold violation');
      });

      test('should fail when coverage < minimum threshold', () async {
        // Arrange
        final projectDir = Directory('${tempDir.path}/fail_threshold');
        await projectDir.create(recursive: true);

        final libDir = Directory('${projectDir.path}/lib');
        await libDir.create(recursive: true);

        final testDir = Directory('${projectDir.path}/test');
        await testDir.create(recursive: true);

        final pubspecFile = File('${projectDir.path}/pubspec.yaml');
        await pubspecFile.writeAsString(
          SamplePubspec.generateDartPackage(name: 'fail', version: '1.0.0'),
        );

        // Generate LCOV with 70% coverage (below minimum 80%)
        final lcovContent = LcovGenerator.generate(
          filePath: 'lib/service.dart',
          totalLines: 100,
          coveredLines: 70,
        );

        processManager.mockProcessRun(
          command: 'dart',
          args: ['test', '--coverage=coverage'],
          result: MockProcessResult(exitCode: 0, stdout: '', stderr: ''),
        );

        final coverageDir = Directory('${projectDir.path}/coverage');
        await coverageDir.create(recursive: true);
        final lcovFile = File('${coverageDir.path}/lcov.info');
        await lcovFile.writeAsString(lcovContent);

        // Act
        final thresholds = CoverageThresholds(minimum: 80.0);
        final analyzer = CoverageAnalyzer(
          testPath: testDir.path,
          libPath: libDir.path,
          thresholds: thresholds,
          processManager: processManager,
        );

        final exitCode = await analyzer.run();

        // Assert: Should fail (exit code non-zero)
        expect(exitCode, isNot(equals(0)),
            reason: 'Should fail when coverage < minimum threshold');
        expect(analyzer.thresholdViolation, isTrue,
            reason: 'Should flag threshold violation');
      });

      test('should warn when coverage < warning threshold', () async {
        // Arrange
        final projectDir = Directory('${tempDir.path}/warn_threshold');
        await projectDir.create(recursive: true);

        final libDir = Directory('${projectDir.path}/lib');
        await libDir.create(recursive: true);

        final testDir = Directory('${projectDir.path}/test');
        await testDir.create(recursive: true);

        final pubspecFile = File('${projectDir.path}/pubspec.yaml');
        await pubspecFile.writeAsString(
          SamplePubspec.generateDartPackage(name: 'warn', version: '1.0.0'),
        );

        // Generate LCOV with 85% coverage (between minimum 80% and warning 90%)
        final lcovContent = LcovGenerator.generate(
          filePath: 'lib/service.dart',
          totalLines: 100,
          coveredLines: 85,
        );

        processManager.mockProcessRun(
          command: 'dart',
          args: ['test', '--coverage=coverage'],
          result: MockProcessResult(exitCode: 0, stdout: '', stderr: ''),
        );

        final coverageDir = Directory('${projectDir.path}/coverage');
        await coverageDir.create(recursive: true);
        final lcovFile = File('${coverageDir.path}/lcov.info');
        await lcovFile.writeAsString(lcovContent);

        // Act
        final thresholds = CoverageThresholds(minimum: 80.0, warning: 90.0);
        final analyzer = CoverageAnalyzer(
          testPath: testDir.path,
          libPath: libDir.path,
          thresholds: thresholds,
          processManager: processManager,
        );

        final exitCode = await analyzer.run();

        // Assert: Should pass but with warning
        expect(exitCode, equals(0),
            reason: 'Should pass when coverage >= minimum');
        expect(analyzer.thresholdViolation, isFalse,
            reason: 'Should not be a violation (just a warning)');
      });

      test('should validate against baseline (fail on decrease)', () async {
        // Arrange
        final projectDir = Directory('${tempDir.path}/baseline_decrease');
        await projectDir.create(recursive: true);

        final libDir = Directory('${projectDir.path}/lib');
        await libDir.create(recursive: true);

        final testDir = Directory('${projectDir.path}/test');
        await testDir.create(recursive: true);

        final pubspecFile = File('${projectDir.path}/pubspec.yaml');
        await pubspecFile.writeAsString(
          SamplePubspec.generateDartPackage(name: 'decrease', version: '1.0.0'),
        );

        // Create baseline with 90% coverage
        final reportsDir =
            Directory('${projectDir.path}/tests_reports/coverage');
        await reportsDir.create(recursive: true);

        final baselineFile = File('${reportsDir.path}/baseline.json');
        await baselineFile.writeAsString(jsonEncode({
          'overall_coverage': 90.0,
        }));

        // Current coverage: 85% (decreased by 5%)
        final lcovContent = LcovGenerator.generate(
          filePath: 'lib/service.dart',
          totalLines: 100,
          coveredLines: 85,
        );

        processManager.mockProcessRun(
          command: 'dart',
          args: ['test', '--coverage=coverage'],
          result: MockProcessResult(exitCode: 0, stdout: '', stderr: ''),
        );

        final coverageDir = Directory('${projectDir.path}/coverage');
        await coverageDir.create(recursive: true);
        final lcovFile = File('${coverageDir.path}/lcov.info');
        await lcovFile.writeAsString(lcovContent);

        // Act
        final thresholds =
            CoverageThresholds(minimum: 80.0, failOnDecrease: true);
        final analyzer = CoverageAnalyzer(
          testPath: testDir.path,
          libPath: libDir.path,
          baseline: baselineFile.path,
          thresholds: thresholds,
          processManager: processManager,
        );

        final exitCode = await analyzer.run();

        // Assert: Should fail due to coverage decrease
        expect(exitCode, isNot(equals(0)),
            reason: 'Should fail when coverage decreases from baseline');
        expect(analyzer.thresholdViolation, isTrue,
            reason: 'Should flag violation on coverage decrease');
      });

      test('should handle null thresholds gracefully', () async {
        // Arrange
        final projectDir = Directory('${tempDir.path}/no_threshold');
        await projectDir.create(recursive: true);

        final libDir = Directory('${projectDir.path}/lib');
        await libDir.create(recursive: true);

        final testDir = Directory('${projectDir.path}/test');
        await testDir.create(recursive: true);

        final pubspecFile = File('${projectDir.path}/pubspec.yaml');
        await pubspecFile.writeAsString(
          SamplePubspec.generateDartPackage(name: 'none', version: '1.0.0'),
        );

        // Generate LCOV with 50% coverage (would normally fail)
        final lcovContent = LcovGenerator.generate(
          filePath: 'lib/service.dart',
          totalLines: 100,
          coveredLines: 50,
        );

        processManager.mockProcessRun(
          command: 'dart',
          args: ['test', '--coverage=coverage'],
          result: MockProcessResult(exitCode: 0, stdout: '', stderr: ''),
        );

        final coverageDir = Directory('${projectDir.path}/coverage');
        await coverageDir.create(recursive: true);
        final lcovFile = File('${coverageDir.path}/lcov.info');
        await lcovFile.writeAsString(lcovContent);

        // Act - No thresholds specified (uses defaults)
        final analyzer = CoverageAnalyzer(
          testPath: testDir.path,
          libPath: libDir.path,
          processManager: processManager,
        );

        final exitCode = await analyzer.run();

        // Assert: Should handle gracefully (default thresholds are 0%, so it passes)
        expect(exitCode, equals(0),
            reason:
                'Should pass with default thresholds (minimum 0%, opt-in enforcement)');
      });

      test('should return correct exit codes for threshold violations',
          () async {
        // Arrange
        final projectDir = Directory('${tempDir.path}/exit_codes');
        await projectDir.create(recursive: true);

        final libDir = Directory('${projectDir.path}/lib');
        await libDir.create(recursive: true);

        final testDir = Directory('${projectDir.path}/test');
        await testDir.create(recursive: true);

        final pubspecFile = File('${projectDir.path}/pubspec.yaml');
        await pubspecFile.writeAsString(
          SamplePubspec.generateDartPackage(name: 'codes', version: '1.0.0'),
        );

        // Generate LCOV with 60% coverage (below threshold)
        final lcovContent = LcovGenerator.generate(
          filePath: 'lib/service.dart',
          totalLines: 100,
          coveredLines: 60,
        );

        processManager.mockProcessRun(
          command: 'dart',
          args: ['test', '--coverage=coverage'],
          result: MockProcessResult(exitCode: 0, stdout: '', stderr: ''),
        );

        final coverageDir = Directory('${projectDir.path}/coverage');
        await coverageDir.create(recursive: true);
        final lcovFile = File('${coverageDir.path}/lcov.info');
        await lcovFile.writeAsString(lcovContent);

        // Act
        final thresholds = CoverageThresholds(minimum: 80.0);
        final analyzer = CoverageAnalyzer(
          testPath: testDir.path,
          libPath: libDir.path,
          thresholds: thresholds,
          processManager: processManager,
        );

        final exitCode = await analyzer.run();

        // Assert: Should return specific exit code for threshold violation
        expect(exitCode, isNot(equals(0)),
            reason: 'Should return non-zero exit code');
        expect(exitCode, anyOf(equals(1), equals(2)),
            reason: 'Exit code should be 1 (failure) or 2 (error)');
      });
    });

    // ========================================================================
    // Suite 2: Baseline Management Tests (4 tests)
    // ========================================================================

    group('Suite 2: Baseline Management Tests', () {
      test('should load baseline from JSON file', () async {
        // Arrange
        final projectDir = Directory('${tempDir.path}/load_baseline');
        await projectDir.create(recursive: true);

        final libDir = Directory('${projectDir.path}/lib');
        await libDir.create(recursive: true);

        final testDir = Directory('${projectDir.path}/test');
        await testDir.create(recursive: true);

        final pubspecFile = File('${projectDir.path}/pubspec.yaml');
        await pubspecFile.writeAsString(
          SamplePubspec.generateDartPackage(name: 'load', version: '1.0.0'),
        );

        // Create baseline file
        final reportsDir =
            Directory('${projectDir.path}/tests_reports/coverage');
        await reportsDir.create(recursive: true);

        final baselineFile = File('${reportsDir.path}/baseline.json');
        await baselineFile.writeAsString(jsonEncode({
          'overall_coverage': 85.0,
          'total_lines': 100,
          'covered_lines': 85,
          'files': {
            'lib/service.dart': {'coverage': 85.0, 'total': 100, 'covered': 85}
          }
        }));

        final lcovContent = LcovGenerator.generate(
          filePath: 'lib/service.dart',
          totalLines: 100,
          coveredLines: 87,
        );

        processManager.mockProcessRun(
          command: 'dart',
          args: ['test', '--coverage=coverage'],
          result: MockProcessResult(exitCode: 0, stdout: '', stderr: ''),
        );

        final coverageDir = Directory('${projectDir.path}/coverage');
        await coverageDir.create(recursive: true);
        final lcovFile = File('${coverageDir.path}/lcov.info');
        await lcovFile.writeAsString(lcovContent);

        // Act
        final analyzer = CoverageAnalyzer(
          testPath: testDir.path,
          libPath: libDir.path,
          baseline: baselineFile.path,
          processManager: processManager,
        );

        final exitCode = await analyzer.run();

        // Assert: Should load baseline successfully
        expect(exitCode, equals(0), reason: 'Should load baseline and pass');
        expect(baselineFile.existsSync(), isTrue,
            reason: 'Baseline file should exist');
      });

      test('should save current coverage as baseline', () async {
        // Arrange
        final projectDir = Directory('${tempDir.path}/save_baseline');
        await projectDir.create(recursive: true);

        final libDir = Directory('${projectDir.path}/lib');
        await libDir.create(recursive: true);

        final testDir = Directory('${projectDir.path}/test');
        await testDir.create(recursive: true);

        final pubspecFile = File('${projectDir.path}/pubspec.yaml');
        await pubspecFile.writeAsString(
          SamplePubspec.generateDartPackage(name: 'save', version: '1.0.0'),
        );

        final lcovContent = LcovGenerator.generate(
          filePath: 'lib/service.dart',
          totalLines: 100,
          coveredLines: 88,
        );

        processManager.mockProcessRun(
          command: 'dart',
          args: ['test', '--coverage=coverage'],
          result: MockProcessResult(exitCode: 0, stdout: '', stderr: ''),
        );

        final coverageDir = Directory('${projectDir.path}/coverage');
        await coverageDir.create(recursive: true);
        final lcovFile = File('${coverageDir.path}/lcov.info');
        await lcovFile.writeAsString(lcovContent);

        // Act
        final reportsDir =
            Directory('${projectDir.path}/tests_reports/coverage');
        await reportsDir.create(recursive: true);

        final baselineFile = File('${reportsDir.path}/baseline.json');

        final analyzer = CoverageAnalyzer(
          testPath: testDir.path,
          libPath: libDir.path,
          saveBaseline: baselineFile.path, // Save as baseline
          processManager: processManager,
        );

        await analyzer.run();

        // Assert: Baseline file should be created with current coverage
        expect(baselineFile.existsSync(), isTrue,
            reason: 'Baseline file should be created');

        final baselineContent = await baselineFile.readAsString();
        final baselineData =
            jsonDecode(baselineContent) as Map<String, dynamic>;

        expect(baselineData['overall_coverage'], equals(88.0),
            reason: 'Baseline should contain current coverage (88%)');
      });

      test('should compare current vs baseline', () async {
        // Arrange
        final projectDir = Directory('${tempDir.path}/compare_baseline');
        await projectDir.create(recursive: true);

        final libDir = Directory('${projectDir.path}/lib');
        await libDir.create(recursive: true);

        final testDir = Directory('${projectDir.path}/test');
        await testDir.create(recursive: true);

        final pubspecFile = File('${projectDir.path}/pubspec.yaml');
        await pubspecFile.writeAsString(
          SamplePubspec.generateDartPackage(name: 'compare', version: '1.0.0'),
        );

        // Create baseline with 80% coverage
        final reportsDir =
            Directory('${projectDir.path}/tests_reports/coverage');
        await reportsDir.create(recursive: true);

        final baselineFile = File('${reportsDir.path}/baseline.json');
        await baselineFile.writeAsString(jsonEncode({
          'overall_coverage': 80.0,
        }));

        // Current: 85% (improvement of +5%)
        final lcovContent = LcovGenerator.generate(
          filePath: 'lib/service.dart',
          totalLines: 100,
          coveredLines: 85,
        );

        processManager.mockProcessRun(
          command: 'dart',
          args: ['test', '--coverage=coverage'],
          result: MockProcessResult(exitCode: 0, stdout: '', stderr: ''),
        );

        final coverageDir = Directory('${projectDir.path}/coverage');
        await coverageDir.create(recursive: true);
        final lcovFile = File('${coverageDir.path}/lcov.info');
        await lcovFile.writeAsString(lcovContent);

        // Act
        final analyzer = CoverageAnalyzer(
          testPath: testDir.path,
          libPath: libDir.path,
          baseline: baselineFile.path,
          processManager: processManager,
        );

        await analyzer.run();

        // Assert: Should compare and show improvement
        final mdFiles = reportsDir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.md'))
            .toList();

        expect(mdFiles.isNotEmpty, isTrue);
        final reportContent = await mdFiles.first.readAsString();

        // Should show comparison (baseline, diff, improvement)
        expect(reportContent, contains('baseline'),
            reason: 'Report should show baseline comparison');
        expect(reportContent, anyOf(contains('80'), contains('85')),
            reason: 'Report should show both old and new coverage');
      });

      test('should generate diff report showing changes', () async {
        // Arrange
        final projectDir = Directory('${tempDir.path}/diff_report');
        await projectDir.create(recursive: true);

        final libDir = Directory('${projectDir.path}/lib');
        await libDir.create(recursive: true);

        final testDir = Directory('${projectDir.path}/test');
        await testDir.create(recursive: true);

        final pubspecFile = File('${projectDir.path}/pubspec.yaml');
        await pubspecFile.writeAsString(
          SamplePubspec.generateDartPackage(name: 'diff', version: '1.0.0'),
        );

        // Create baseline
        final reportsDir =
            Directory('${projectDir.path}/tests_reports/coverage');
        await reportsDir.create(recursive: true);

        final baselineFile = File('${reportsDir.path}/baseline.json');
        await baselineFile.writeAsString(jsonEncode({
          'overall_coverage': 75.0,
          'files': {
            'lib/file1.dart': {'coverage': 80.0},
            'lib/file2.dart': {'coverage': 70.0}
          }
        }));

        // Current: file1 increased, file2 decreased
        final lcovContent = LcovGenerator.generateMultiple([
          LcovFileData(
              filePath: 'lib/file1.dart', totalLines: 100, coveredLines: 85),
          LcovFileData(
              filePath: 'lib/file2.dart', totalLines: 100, coveredLines: 65),
        ]);

        processManager.mockProcessRun(
          command: 'dart',
          args: ['test', '--coverage=coverage'],
          result: MockProcessResult(exitCode: 0, stdout: '', stderr: ''),
        );

        final coverageDir = Directory('${projectDir.path}/coverage');
        await coverageDir.create(recursive: true);
        final lcovFile = File('${coverageDir.path}/lcov.info');
        await lcovFile.writeAsString(lcovContent);

        // Act
        final analyzer = CoverageAnalyzer(
          testPath: testDir.path,
          libPath: libDir.path,
          baseline: baselineFile.path,
          processManager: processManager,
        );

        await analyzer.run();

        // Assert: Diff report should show per-file changes
        final mdFiles = reportsDir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.md'))
            .toList();

        expect(mdFiles.isNotEmpty, isTrue);
        final reportContent = await mdFiles.first.readAsString();

        // Should show diff with increase/decrease indicators
        expect(reportContent, contains('file1.dart'),
            reason: 'Should show file1 in diff');
        expect(reportContent, contains('file2.dart'),
            reason: 'Should show file2 in diff');
        expect(
            reportContent,
            anyOf(contains('↑'), contains('↓'), contains('increased'),
                contains('decreased')),
            reason: 'Should show increase/decrease indicators');
      });
    });
  });
}
