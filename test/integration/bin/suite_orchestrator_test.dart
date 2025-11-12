@Tags(['integration'])
library;

/// Phase 4.1: Suite Orchestration Integration Tests
///
/// Tests for analyze_suite_lib.dart (TestOrchestrator)
/// Status: 🔴 RED Phase - All tests failing
/// Goal: Test orchestration logic, path detection, health scoring, and report aggregation
///
/// Test Suites:
/// - Suite 1: Orchestration Workflow Tests (10 tests)
/// - Suite 2: Report Aggregation Tests (6 tests)
/// - Suite 3: Health Scoring Tests (4 tests)
///
/// Total: 20 tests
///
/// Methodology: 🔴🟢♻️🔄 TDD

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_reporter/src/bin/analyze_suite_lib.dart';
import 'package:test_reporter/src/utils/report_utils.dart';

void main() {
  group('Suite 1: Orchestration Workflow Tests', () {
    test('should create orchestrator with required parameters', () {
      final orchestrator = TestOrchestrator(testPath: 'test/');

      expect(orchestrator.testPath, equals('test/'));
      expect(orchestrator.runs, equals(3)); // default
      expect(orchestrator.performance, isFalse); // default
      expect(orchestrator.verbose, isFalse); // default
      expect(orchestrator.parallel, isFalse); // default
    });

    test('should create orchestrator with custom parameters', () {
      final orchestrator = TestOrchestrator(
        testPath: 'test/integration/',
        runs: 5,
        performance: true,
        verbose: true,
        parallel: true,
      );

      expect(orchestrator.testPath, equals('test/integration/'));
      expect(orchestrator.runs, equals(5));
      expect(orchestrator.performance, isTrue);
      expect(orchestrator.verbose, isTrue);
      expect(orchestrator.parallel, isTrue);
    });

    test('should map test paths to lib paths correctly', () {
      final orchestrator1 = TestOrchestrator(testPath: 'test/');
      final orchestrator2 = TestOrchestrator(testPath: 'test/integration');
      final orchestrator3 = TestOrchestrator(testPath: 'test/ui');
      final orchestrator4 = TestOrchestrator(testPath: 'test/src');

      expect(orchestrator1.getSourcePath(), equals('lib/'));
      expect(orchestrator2.getSourcePath(), equals('lib/integration'));
      expect(orchestrator3.getSourcePath(), equals('lib/ui'));
      expect(orchestrator4.getSourcePath(), equals('lib/src'));
    });

    test('should respect explicit source path override', () {
      final orchestrator = TestOrchestrator(
        testPath: 'test/ui',
        sourcePathOverride: 'lib/app/ui',
      );

      expect(orchestrator.getSourcePath(), equals('lib/app/ui'));
    });

    test('should extract module name correctly', () {
      final orchestrator1 = TestOrchestrator(testPath: 'test/');
      final orchestrator2 = TestOrchestrator(testPath: 'test/integration/');
      final orchestrator3 = TestOrchestrator(testPath: 'test/my_test.dart');

      expect(orchestrator1.extractModuleName(), isNotEmpty);
      expect(orchestrator2.extractModuleName(), contains('-fo')); // folder
      expect(orchestrator3.extractModuleName(), contains('-fi')); // file
    });

    test('should use explicit module name when provided', () {
      final orchestrator = TestOrchestrator(
        testPath: 'test/',
        explicitModuleName: 'my-custom-module-fo',
      );

      expect(orchestrator.extractModuleName(), equals('my-custom-module-fo'));
    });

    test('should have results map for aggregation', () {
      final orchestrator = TestOrchestrator(testPath: 'test/');

      expect(orchestrator.results, isA<Map<String, dynamic>>());
      expect(orchestrator.results, isEmpty); // Empty initially
    });

    test('should have failures list for tracking errors', () {
      final orchestrator = TestOrchestrator(testPath: 'test/');

      expect(orchestrator.failures, isA<List<String>>());
      expect(orchestrator.failures, isEmpty); // Empty initially
    });

    test('should have reportPaths map for tracking generated reports', () {
      final orchestrator = TestOrchestrator(testPath: 'test/');

      expect(orchestrator.reportPaths, isA<Map<String, String>>());
      expect(orchestrator.reportPaths, isEmpty); // Empty initially
    });

    test('should allow manual result population', () {
      final orchestrator = TestOrchestrator(testPath: 'test/');

      // Simulate adding coverage results
      orchestrator.results['coverage'] = {
        'summary': {'overall_coverage': 85.0}
      };

      // Simulate adding test analysis results
      orchestrator.results['test_analysis'] = {
        'summary': {'pass_rate': 90.0}
      };

      expect(orchestrator.results.keys, contains('coverage'));
      expect(orchestrator.results.keys, contains('test_analysis'));
      expect(orchestrator.results['coverage'], isNotNull);
      expect(orchestrator.results['test_analysis'], isNotNull);
    });
  });

  group('Suite 2: Report Aggregation Tests', () {
    test('should aggregate coverage data from results', () {
      final orchestrator = TestOrchestrator(testPath: 'test/');

      orchestrator.results['coverage'] = {
        'summary': {
          'overall_coverage': 85.5,
          'total_lines': 1000,
          'covered_lines': 855,
          'uncovered_lines': 145,
          'files_analyzed': 25,
        }
      };

      final coverage = orchestrator.results['coverage'] as Map<String, dynamic>;
      final summary = coverage['summary'] as Map<String, dynamic>;

      expect(summary['overall_coverage'], equals(85.5));
      expect(summary['total_lines'], equals(1000));
      expect(summary['covered_lines'], equals(855));
    });

    test('should aggregate test analysis data from results', () {
      final orchestrator = TestOrchestrator(testPath: 'test/');

      orchestrator.results['test_analysis'] = {
        'summary': {
          'pass_rate': 95.0,
          'stability_score': 92.0,
          'total_tests': 100,
          'passed_consistently': 95,
          'consistent_failures': 3,
          'flaky_tests': 2,
        }
      };

      final testAnalysis =
          orchestrator.results['test_analysis'] as Map<String, dynamic>;
      final summary = testAnalysis['summary'] as Map<String, dynamic>;

      expect(summary['pass_rate'], equals(95.0));
      expect(summary['total_tests'], equals(100));
      expect(summary['flaky_tests'], equals(2));
    });

    test('should extract metrics for health calculation', () {
      final orchestrator = TestOrchestrator(testPath: 'test/');

      orchestrator.results['coverage'] = {
        'summary': {'overall_coverage': 85.0}
      };

      orchestrator.results['test_analysis'] = {
        'summary': {
          'pass_rate': 92.0,
          'stability_score': 88.0,
        }
      };

      // Extract metrics (mimicking what generateUnifiedReport does)
      final coverage = orchestrator.results['coverage'] as Map?;
      final testAnalysis = orchestrator.results['test_analysis'] as Map?;
      final coverageSummary = coverage?['summary'] as Map?;
      final testSummary = testAnalysis?['summary'] as Map?;

      final overallCoverage = coverageSummary?['overall_coverage'] as double?;
      final passRate = testSummary?['pass_rate'] as double?;
      final stabilityScore = testSummary?['stability_score'] as double?;

      expect(overallCoverage, equals(85.0));
      expect(passRate, equals(92.0));
      expect(stabilityScore, equals(88.0));
    });

    test('should handle missing coverage data gracefully', () {
      final orchestrator = TestOrchestrator(testPath: 'test/');

      // Only add test analysis, no coverage
      orchestrator.results['test_analysis'] = {
        'summary': {'pass_rate': 95.0}
      };

      final coverage = orchestrator.results['coverage'] as Map?;

      expect(coverage, isNull);
    });

    test('should handle missing test analysis data gracefully', () {
      final orchestrator = TestOrchestrator(testPath: 'test/');

      // Only add coverage, no test analysis
      orchestrator.results['coverage'] = {
        'summary': {'overall_coverage': 85.0}
      };

      final testAnalysis = orchestrator.results['test_analysis'] as Map?;

      expect(testAnalysis, isNull);
    });

    test('should generate unified report with combined data', () async {
      final orchestrator = TestOrchestrator(testPath: 'test/');

      orchestrator.results['coverage'] = {
        'summary': {
          'overall_coverage': 85.0,
          'total_lines': 1000,
          'covered_lines': 850,
          'uncovered_lines': 150,
          'files_analyzed': 25,
        }
      };

      orchestrator.results['test_analysis'] = {
        'summary': {
          'pass_rate': 95.0,
          'stability_score': 92.0,
          'total_tests': 100,
          'passed_consistently': 95,
          'consistent_failures': 2,
          'flaky_tests': 3,
        }
      };

      await orchestrator.generateUnifiedReport();

      // Verify unified report was created
      final reportDir = await ReportUtils.getReportDirectory();
      final suiteDir = Directory(p.join(reportDir, 'suite'));

      expect(await suiteDir.exists(), isTrue);

      // Find the report file
      final reports = await suiteDir.list().where((f) => f is File).toList();
      expect(reports, isNotEmpty);
    });
  });

  group('Suite 3: Health Scoring Tests', () {
    test('should calculate health score from all three metrics', () {
      final orchestrator = TestOrchestrator(testPath: 'test/');

      final healthScore = orchestrator.calculateHealthScore(
        80.0, // coverage
        90.0, // pass rate
        85.0, // stability
      );

      // Average: (80 + 90 + 85) / 3 = 85.0
      expect(healthScore, equals(85.0));
    });

    test('should calculate health score from coverage only', () {
      final orchestrator = TestOrchestrator(testPath: 'test/');

      final healthScore = orchestrator.calculateHealthScore(
        85.0, // coverage
        null, // no pass rate
        null, // no stability
      );

      expect(healthScore, equals(85.0));
    });

    test('should calculate health score from pass rate only', () {
      final orchestrator = TestOrchestrator(testPath: 'test/');

      final healthScore = orchestrator.calculateHealthScore(
        null, // no coverage
        92.0, // pass rate
        null, // no stability
      );

      expect(healthScore, equals(92.0));
    });

    test('should calculate health score from stability only', () {
      final orchestrator = TestOrchestrator(testPath: 'test/');

      final healthScore = orchestrator.calculateHealthScore(
        null, // no coverage
        null, // no pass rate
        88.0, // stability
      );

      expect(healthScore, equals(88.0));
    });

    test('should return 0.0 when no metrics available', () {
      final orchestrator = TestOrchestrator(testPath: 'test/');

      final healthScore = orchestrator.calculateHealthScore(
        null, // no coverage
        null, // no pass rate
        null, // no stability
      );

      expect(healthScore, equals(0.0));
    });

    test('should get health status for excellent health (>= 90)', () {
      final orchestrator = TestOrchestrator(testPath: 'test/');

      final status1 = orchestrator.getHealthStatus(90.0);
      final status2 = orchestrator.getHealthStatus(95.0);
      final status3 = orchestrator.getHealthStatus(100.0);

      expect(status1, equals('🟢 Excellent'));
      expect(status2, equals('🟢 Excellent'));
      expect(status3, equals('🟢 Excellent'));
    });

    test('should get health status for good health (75-89)', () {
      final orchestrator = TestOrchestrator(testPath: 'test/');

      final status1 = orchestrator.getHealthStatus(75.0);
      final status2 = orchestrator.getHealthStatus(80.0);
      final status3 = orchestrator.getHealthStatus(89.0);

      expect(status1, equals('🟡 Good'));
      expect(status2, equals('🟡 Good'));
      expect(status3, equals('🟡 Good'));
    });

    test('should get health status for fair health (60-74)', () {
      final orchestrator = TestOrchestrator(testPath: 'test/');

      final status1 = orchestrator.getHealthStatus(60.0);
      final status2 = orchestrator.getHealthStatus(65.0);
      final status3 = orchestrator.getHealthStatus(74.0);

      expect(status1, equals('🟠 Fair'));
      expect(status2, equals('🟠 Fair'));
      expect(status3, equals('🟠 Fair'));
    });

    test('should get health status for poor health (< 60)', () {
      final orchestrator = TestOrchestrator(testPath: 'test/');

      final status1 = orchestrator.getHealthStatus(0.0);
      final status2 = orchestrator.getHealthStatus(30.0);
      final status3 = orchestrator.getHealthStatus(59.0);

      expect(status1, equals('🔴 Poor'));
      expect(status2, equals('🔴 Poor'));
      expect(status3, equals('🔴 Poor'));
    });

    test('should get coverage status indicators', () {
      final orchestrator = TestOrchestrator(testPath: 'test/');

      final status1 = orchestrator.getCoverageStatus(85.0); // >= 80
      final status2 = orchestrator.getCoverageStatus(65.0); // 60-79
      final status3 = orchestrator.getCoverageStatus(45.0); // 40-59
      final status4 = orchestrator.getCoverageStatus(30.0); // < 40
      final status5 = orchestrator.getCoverageStatus(null); // null

      expect(status1, equals('✅ Excellent'));
      expect(status2, equals('🟡 Adequate'));
      expect(status3, equals('🟠 Low'));
      expect(status4, equals('🔴 Critical'));
      expect(status5, equals('❓'));
    });

    test('should get pass rate status indicators', () {
      final orchestrator = TestOrchestrator(testPath: 'test/');

      final status1 = orchestrator.getPassRateStatus(96.0); // >= 95
      final status2 = orchestrator.getPassRateStatus(88.0); // 85-94
      final status3 = orchestrator.getPassRateStatus(72.0); // 70-84
      final status4 = orchestrator.getPassRateStatus(50.0); // < 70
      final status5 = orchestrator.getPassRateStatus(null); // null

      expect(status1, equals('✅ Excellent'));
      expect(status2, equals('🟡 Good'));
      expect(status3, equals('🟠 Fair'));
      expect(status4, equals('🔴 Poor'));
      expect(status5, equals('❓'));
    });

    test('should get stability status indicators', () {
      final orchestrator = TestOrchestrator(testPath: 'test/');

      final status1 = orchestrator.getStabilityStatus(96.0); // >= 95
      final status2 = orchestrator.getStabilityStatus(88.0); // 85-94
      final status3 = orchestrator.getStabilityStatus(72.0); // 70-84
      final status4 = orchestrator.getStabilityStatus(50.0); // < 70
      final status5 = orchestrator.getStabilityStatus(null); // null

      expect(status1, equals('✅ Stable'));
      expect(status2, equals('🟡 Mostly Stable'));
      expect(status3, equals('🟠 Unstable'));
      expect(status4, equals('🔴 Very Unstable'));
      expect(status5, equals('❓'));
    });
  });
}
