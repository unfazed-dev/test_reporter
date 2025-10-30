/// Tests for test_analyzer advanced scenarios and edge cases
///
/// This test file covers complex analyzer configurations, edge cases,
/// and advanced feature combinations for the test debugging tool.

import 'package:test/test.dart';
import 'package:test_analyzer/src/bin/test_analyzer_lib.dart';

void main() {
  group('Advanced Analyzer Configurations', () {
    test('should configure with very high run count', () {
      final analyzer = TestAnalyzer(runCount: 100);
      expect(analyzer.runCount, equals(100));
    });

    test('should configure with single run', () {
      final analyzer = TestAnalyzer(runCount: 1);
      expect(analyzer.runCount, equals(1));
    });

    test('should configure for flaky test detection', () {
      final analyzer = TestAnalyzer(
        runCount: 10,
        verbose: true,
      );

      expect(analyzer.runCount, equals(10));
      expect(analyzer.verbose, isTrue);
    });

    test('should configure for performance profiling', () {
      final analyzer = TestAnalyzer(
        performanceMode: true,
        slowTestThreshold: 0.5,
      );

      expect(analyzer.performanceMode, isTrue);
      expect(analyzer.slowTestThreshold, equals(0.5));
    });

    test('should configure for parallel execution', () {
      final analyzer = TestAnalyzer(
        parallel: true,
        maxWorkers: 16,
      );

      expect(analyzer.parallel, isTrue);
      expect(analyzer.maxWorkers, equals(16));
    });

    test('should configure for comprehensive analysis', () {
      final analyzer = TestAnalyzer(
        runCount: 5,
        performanceMode: true,
        dependencyAnalysis: true,
        mutationTesting: true,
        impactAnalysis: true,
      );

      expect(analyzer.runCount, equals(5));
      expect(analyzer.performanceMode, isTrue);
      expect(analyzer.dependencyAnalysis, isTrue);
      expect(analyzer.mutationTesting, isTrue);
      expect(analyzer.impactAnalysis, isTrue);
    });
  });

  group('Slow Test Threshold Edge Cases', () {
    test('should handle very low threshold', () {
      final analyzer = TestAnalyzer(slowTestThreshold: 0.01);
      expect(analyzer.slowTestThreshold, equals(0.01));
    });

    test('should handle very high threshold', () {
      final analyzer = TestAnalyzer(slowTestThreshold: 300.0);
      expect(analyzer.slowTestThreshold, equals(300.0));
    });

    test('should handle zero threshold', () {
      final analyzer = TestAnalyzer(slowTestThreshold: 0.0);
      expect(analyzer.slowTestThreshold, equals(0.0));
    });

    test('should handle fractional threshold', () {
      final analyzer = TestAnalyzer(slowTestThreshold: 1.5);
      expect(analyzer.slowTestThreshold, equals(1.5));
    });

    test('should handle default threshold', () {
      final analyzer = TestAnalyzer();
      expect(analyzer.slowTestThreshold, equals(1.0));
    });
  });

  group('Target Files Configuration', () {
    test('should handle single target file', () {
      final analyzer = TestAnalyzer(
        targetFiles: ['test/auth_test.dart'],
      );

      expect(analyzer.targetFiles, hasLength(1));
      expect(analyzer.targetFiles.first, equals('test/auth_test.dart'));
    });

    test('should handle multiple target files', () {
      final analyzer = TestAnalyzer(
        targetFiles: [
          'test/auth_test.dart',
          'test/user_test.dart',
          'test/api_test.dart',
        ],
      );

      expect(analyzer.targetFiles, hasLength(3));
    });

    test('should handle empty target files', () {
      final analyzer = TestAnalyzer(targetFiles: []);
      expect(analyzer.targetFiles, isEmpty);
    });

    test('should handle very long file list', () {
      final files = List.generate(100, (i) => 'test/test_$i.dart');
      final analyzer = TestAnalyzer(targetFiles: files);
      expect(analyzer.targetFiles, hasLength(100));
    });

    test('should handle files with special paths', () {
      final analyzer = TestAnalyzer(
        targetFiles: [
          'test/@scope/package_test.dart',
          r'test\windows\path_test.dart',
          'test/café/unicode_test.dart',
        ],
      );

      expect(analyzer.targetFiles, hasLength(3));
    });
  });

  group('Worker Configuration Edge Cases', () {
    test('should handle single worker', () {
      final analyzer = TestAnalyzer(maxWorkers: 1);
      expect(analyzer.maxWorkers, equals(1));
    });

    test('should handle many workers', () {
      final analyzer = TestAnalyzer(maxWorkers: 64);
      expect(analyzer.maxWorkers, equals(64));
    });

    test('should handle zero workers', () {
      final analyzer = TestAnalyzer(maxWorkers: 0);
      expect(analyzer.maxWorkers, equals(0));
    });

    test('should handle negative workers', () {
      final analyzer = TestAnalyzer(maxWorkers: -1);
      expect(analyzer.maxWorkers, equals(-1));
    });

    test('should handle default workers', () {
      final analyzer = TestAnalyzer();
      expect(analyzer.maxWorkers, equals(4));
    });
  });

  group('Feature Flag Combinations', () {
    test('should enable all analysis features', () {
      final analyzer = TestAnalyzer(
        dependencyAnalysis: true,
        mutationTesting: true,
        impactAnalysis: true,
      );

      expect(analyzer.dependencyAnalysis, isTrue);
      expect(analyzer.mutationTesting, isTrue);
      expect(analyzer.impactAnalysis, isTrue);
    });

    test('should disable all analysis features', () {
      final analyzer = TestAnalyzer();

      expect(analyzer.dependencyAnalysis, isFalse);
      expect(analyzer.mutationTesting, isFalse);
      expect(analyzer.impactAnalysis, isFalse);
    });

    test('should combine performance and parallel', () {
      final analyzer = TestAnalyzer(
        performanceMode: true,
        parallel: true,
        maxWorkers: 8,
      );

      expect(analyzer.performanceMode, isTrue);
      expect(analyzer.parallel, isTrue);
      expect(analyzer.maxWorkers, equals(8));
    });

    test('should combine watch with verbose', () {
      final analyzer = TestAnalyzer(
        watch: true,
        verbose: true,
      );

      expect(analyzer.watch, isTrue);
      expect(analyzer.verbose, isTrue);
    });

    test('should combine interactive with verbose', () {
      final analyzer = TestAnalyzer(
        interactive: true,
        verbose: true,
      );

      expect(analyzer.interactive, isTrue);
      expect(analyzer.verbose, isTrue);
    });
  });

  group('Report and Fix Configuration', () {
    test('should enable both report and fixes', () {
      final analyzer = TestAnalyzer(
        generateReport: true,
        generateFixes: true,
      );

      expect(analyzer.generateReport, isTrue);
      expect(analyzer.generateFixes, isTrue);
    });

    test('should disable both report and fixes', () {
      final analyzer = TestAnalyzer(
        generateReport: false,
      );

      expect(analyzer.generateReport, isFalse);
      expect(analyzer.generateFixes, isTrue); // Default is true
    });

    test('should enable report with default fixes', () {
      final analyzer = TestAnalyzer();

      expect(analyzer.generateReport, isTrue);
      expect(analyzer.generateFixes, isTrue);
    });

    test('should enable fixes without report', () {
      final analyzer = TestAnalyzer(
        generateReport: false,
      );

      expect(analyzer.generateReport, isFalse);
      expect(analyzer.generateFixes, isTrue);
    });
  });

  group('Run Count Edge Cases', () {
    test('should handle zero runs', () {
      final analyzer = TestAnalyzer(runCount: 0);
      expect(analyzer.runCount, equals(0));
    });

    test('should handle negative runs', () {
      final analyzer = TestAnalyzer(runCount: -5);
      expect(analyzer.runCount, equals(-5));
    });

    test('should handle very large run count', () {
      final analyzer = TestAnalyzer(runCount: 10000);
      expect(analyzer.runCount, equals(10000));
    });

    test('should handle default run count', () {
      final analyzer = TestAnalyzer();
      expect(analyzer.runCount, equals(3));
    });
  });

  group('Data Structure Initialization', () {
    test('should initialize empty test runs map', () {
      final analyzer = TestAnalyzer();
      expect(analyzer.testRuns, isEmpty);
    });

    test('should initialize empty failures map', () {
      final analyzer = TestAnalyzer();
      expect(analyzer.failures, isEmpty);
    });

    test('should initialize empty performance map', () {
      final analyzer = TestAnalyzer();
      expect(analyzer.performance, isEmpty);
    });

    test('should initialize all data structures', () {
      final analyzer = TestAnalyzer();
      expect(analyzer.testRuns, isEmpty);
      expect(analyzer.failures, isEmpty);
      expect(analyzer.performance, isEmpty);
    });
  });

  group('Workflow-Specific Configurations', () {
    test('should configure for CI/CD pipeline', () {
      final analyzer = TestAnalyzer(
        runCount: 1,
        parallel: true,
      );

      expect(analyzer.runCount, equals(1));
      expect(analyzer.generateReport, isTrue);
      expect(analyzer.generateFixes, isTrue);
      expect(analyzer.parallel, isTrue);
      expect(analyzer.verbose, isFalse);
    });

    test('should configure for development with watch', () {
      final analyzer = TestAnalyzer(
        watch: true,
        interactive: true,
        verbose: true,
      );

      expect(analyzer.watch, isTrue);
      expect(analyzer.interactive, isTrue);
      expect(analyzer.verbose, isTrue);
    });

    test('should configure for quick check', () {
      final analyzer = TestAnalyzer(
        runCount: 1,
        generateReport: false,
      );

      expect(analyzer.runCount, equals(1));
      expect(analyzer.generateReport, isFalse);
    });

    test('should configure for deep analysis', () {
      final analyzer = TestAnalyzer(
        runCount: 10,
        performanceMode: true,
        dependencyAnalysis: true,
        mutationTesting: true,
        impactAnalysis: true,
        verbose: true,
      );

      expect(analyzer.runCount, equals(10));
      expect(analyzer.performanceMode, isTrue);
      expect(analyzer.dependencyAnalysis, isTrue);
      expect(analyzer.mutationTesting, isTrue);
      expect(analyzer.impactAnalysis, isTrue);
      expect(analyzer.verbose, isTrue);
    });
  });
}
