/// Tests for test_analyzer CLI configuration and argument parsing
///
/// This test file covers the TestAnalyzer configuration, CLI flags, and options
/// for the advanced test debugging and analysis tool.

import 'package:test/test.dart';
import 'package:test_reporter/src/bin/analyze_tests_lib.dart';

void main() {
  group('TestAnalyzer Configuration', () {
    test('should create analyzer with default settings', () {
      final analyzer = TestAnalyzer();

      expect(analyzer.runCount, equals(3));
      expect(analyzer.verbose, isFalse);
      expect(analyzer.interactive, isFalse);
      expect(analyzer.performanceMode, isFalse);
      expect(analyzer.watch, isFalse);
      expect(analyzer.generateFixes, isTrue);
      expect(analyzer.generateReport, isTrue);
      expect(analyzer.slowTestThreshold, equals(1.0));
      expect(analyzer.targetFiles, isEmpty);
      expect(analyzer.parallel, isFalse);
      expect(analyzer.maxWorkers, equals(4));
      expect(analyzer.dependencyAnalysis, isFalse);
      expect(analyzer.mutationTesting, isFalse);
      expect(analyzer.impactAnalysis, isFalse);
    });

    test('should create analyzer with custom run count', () {
      final analyzer = TestAnalyzer(runCount: 5);
      expect(analyzer.runCount, equals(5));
    });

    test('should create analyzer with verbose enabled', () {
      final analyzer = TestAnalyzer(verbose: true);
      expect(analyzer.verbose, isTrue);
    });

    test('should create analyzer with interactive mode enabled', () {
      final analyzer = TestAnalyzer(interactive: true);
      expect(analyzer.interactive, isTrue);
    });

    test('should create analyzer with performance mode enabled', () {
      final analyzer = TestAnalyzer(performanceMode: true);
      expect(analyzer.performanceMode, isTrue);
    });

    test('should create analyzer with watch mode enabled', () {
      final analyzer = TestAnalyzer(watch: true);
      expect(analyzer.watch, isTrue);
    });

    test('should create analyzer with generateFixes disabled', () {
      final analyzer = TestAnalyzer(generateFixes: false);
      expect(analyzer.generateFixes, isFalse);
    });

    test('should create analyzer with generateReport disabled', () {
      final analyzer = TestAnalyzer(generateReport: false);
      expect(analyzer.generateReport, isFalse);
    });

    test('should create analyzer with custom slow test threshold', () {
      final analyzer = TestAnalyzer(slowTestThreshold: 2.5);
      expect(analyzer.slowTestThreshold, equals(2.5));
    });

    test('should create analyzer with target files', () {
      final analyzer = TestAnalyzer(
        targetFiles: ['test/auth_test.dart', 'test/user_test.dart'],
      );
      expect(analyzer.targetFiles, hasLength(2));
      expect(analyzer.targetFiles, contains('test/auth_test.dart'));
      expect(analyzer.targetFiles, contains('test/user_test.dart'));
    });

    test('should create analyzer with parallel execution enabled', () {
      final analyzer = TestAnalyzer(parallel: true);
      expect(analyzer.parallel, isTrue);
    });

    test('should create analyzer with custom max workers', () {
      final analyzer = TestAnalyzer(maxWorkers: 8);
      expect(analyzer.maxWorkers, equals(8));
    });

    test('should create analyzer with dependency analysis enabled', () {
      final analyzer = TestAnalyzer(dependencyAnalysis: true);
      expect(analyzer.dependencyAnalysis, isTrue);
    });

    test('should create analyzer with mutation testing enabled', () {
      final analyzer = TestAnalyzer(mutationTesting: true);
      expect(analyzer.mutationTesting, isTrue);
    });

    test('should create analyzer with impact analysis enabled', () {
      final analyzer = TestAnalyzer(impactAnalysis: true);
      expect(analyzer.impactAnalysis, isTrue);
    });

    test('should create analyzer with all features enabled', () {
      final analyzer = TestAnalyzer(
        runCount: 10,
        verbose: true,
        interactive: true,
        performanceMode: true,
        watch: true,
        slowTestThreshold: 3.0,
        targetFiles: ['test/integration_test.dart'],
        parallel: true,
        maxWorkers: 16,
        dependencyAnalysis: true,
        mutationTesting: true,
        impactAnalysis: true,
      );

      expect(analyzer.runCount, equals(10));
      expect(analyzer.verbose, isTrue);
      expect(analyzer.interactive, isTrue);
      expect(analyzer.performanceMode, isTrue);
      expect(analyzer.watch, isTrue);
      expect(analyzer.generateFixes, isTrue);
      expect(analyzer.generateReport, isTrue);
      expect(analyzer.slowTestThreshold, equals(3.0));
      expect(analyzer.targetFiles, hasLength(1));
      expect(analyzer.parallel, isTrue);
      expect(analyzer.maxWorkers, equals(16));
      expect(analyzer.dependencyAnalysis, isTrue);
      expect(analyzer.mutationTesting, isTrue);
      expect(analyzer.impactAnalysis, isTrue);
    });
  });

  group('TestAnalyzer Edge Cases', () {
    test('should handle zero run count', () {
      final analyzer = TestAnalyzer(runCount: 0);
      expect(analyzer.runCount, equals(0));
    });

    test('should handle very high run count', () {
      final analyzer = TestAnalyzer(runCount: 100);
      expect(analyzer.runCount, equals(100));
    });

    test('should handle very low slow test threshold', () {
      final analyzer = TestAnalyzer(slowTestThreshold: 0.1);
      expect(analyzer.slowTestThreshold, equals(0.1));
    });

    test('should handle very high slow test threshold', () {
      final analyzer = TestAnalyzer(slowTestThreshold: 60.0);
      expect(analyzer.slowTestThreshold, equals(60.0));
    });

    test('should handle single worker for parallel execution', () {
      final analyzer = TestAnalyzer(maxWorkers: 1);
      expect(analyzer.maxWorkers, equals(1));
    });

    test('should handle many workers for parallel execution', () {
      final analyzer = TestAnalyzer(maxWorkers: 32);
      expect(analyzer.maxWorkers, equals(32));
    });

    test('should handle empty target files list', () {
      final analyzer = TestAnalyzer(targetFiles: []);
      expect(analyzer.targetFiles, isEmpty);
    });

    test('should handle single target file', () {
      final analyzer = TestAnalyzer(targetFiles: ['test/single_test.dart']);
      expect(analyzer.targetFiles, hasLength(1));
      expect(analyzer.targetFiles.first, equals('test/single_test.dart'));
    });

    test('should handle many target files', () {
      final files = List.generate(20, (i) => 'test/test_$i.dart');
      final analyzer = TestAnalyzer(targetFiles: files);
      expect(analyzer.targetFiles, hasLength(20));
    });
  });

  group('CLI Flag Combinations', () {
    test('should handle verbose with interactive', () {
      final analyzer = TestAnalyzer(
        verbose: true,
        interactive: true,
      );
      expect(analyzer.verbose, isTrue);
      expect(analyzer.interactive, isTrue);
    });

    test('should handle performance with parallel', () {
      final analyzer = TestAnalyzer(
        performanceMode: true,
        parallel: true,
      );
      expect(analyzer.performanceMode, isTrue);
      expect(analyzer.parallel, isTrue);
    });

    test('should handle watch with verbose', () {
      final analyzer = TestAnalyzer(
        watch: true,
        verbose: true,
      );
      expect(analyzer.watch, isTrue);
      expect(analyzer.verbose, isTrue);
    });

    test('should handle custom runs with parallel', () {
      final analyzer = TestAnalyzer(
        runCount: 10,
        parallel: true,
        maxWorkers: 8,
      );
      expect(analyzer.runCount, equals(10));
      expect(analyzer.parallel, isTrue);
      expect(analyzer.maxWorkers, equals(8));
    });

    test('should handle dependency and mutation analysis together', () {
      final analyzer = TestAnalyzer(
        dependencyAnalysis: true,
        mutationTesting: true,
      );
      expect(analyzer.dependencyAnalysis, isTrue);
      expect(analyzer.mutationTesting, isTrue);
    });

    test('should handle mutation and impact analysis together', () {
      final analyzer = TestAnalyzer(
        mutationTesting: true,
        impactAnalysis: true,
      );
      expect(analyzer.mutationTesting, isTrue);
      expect(analyzer.impactAnalysis, isTrue);
    });

    test('should handle all analysis modes together', () {
      final analyzer = TestAnalyzer(
        dependencyAnalysis: true,
        mutationTesting: true,
        impactAnalysis: true,
      );
      expect(analyzer.dependencyAnalysis, isTrue);
      expect(analyzer.mutationTesting, isTrue);
      expect(analyzer.impactAnalysis, isTrue);
    });

    test('should handle fixes and reports both disabled', () {
      final analyzer = TestAnalyzer(
        generateFixes: false,
        generateReport: false,
      );
      expect(analyzer.generateFixes, isFalse);
      expect(analyzer.generateReport, isFalse);
    });
  });

  group('TestAnalyzer Data Structures', () {
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
  });

  group('TestAnalyzer Advanced Features', () {
    test('should configure for flaky test detection', () {
      final analyzer = TestAnalyzer(
        runCount: 5,
        verbose: true,
      );
      expect(analyzer.runCount, greaterThanOrEqualTo(3));
      expect(analyzer.verbose, isTrue);
    });

    test('should configure for performance analysis', () {
      final analyzer = TestAnalyzer(
        performanceMode: true,
        slowTestThreshold: 0.5,
      );
      expect(analyzer.performanceMode, isTrue);
      expect(analyzer.slowTestThreshold, lessThan(1.0));
    });

    test('should configure for fast parallel execution', () {
      final analyzer = TestAnalyzer(
        parallel: true,
        maxWorkers: 16,
        runCount: 1,
      );
      expect(analyzer.parallel, isTrue);
      expect(analyzer.maxWorkers, greaterThan(4));
      expect(analyzer.runCount, equals(1));
    });

    test('should configure for comprehensive analysis', () {
      final analyzer = TestAnalyzer(
        runCount: 5,
        performanceMode: true,
        dependencyAnalysis: true,
        mutationTesting: true,
        impactAnalysis: true,
        verbose: true,
      );
      expect(analyzer.runCount, equals(5));
      expect(analyzer.performanceMode, isTrue);
      expect(analyzer.dependencyAnalysis, isTrue);
      expect(analyzer.mutationTesting, isTrue);
      expect(analyzer.impactAnalysis, isTrue);
      expect(analyzer.verbose, isTrue);
    });

    test('should configure for CI/CD pipeline', () {
      final analyzer = TestAnalyzer(
        runCount: 1,
        parallel: true,
      );
      expect(analyzer.runCount, equals(1));
      expect(analyzer.generateFixes, isTrue);
      expect(analyzer.generateReport, isTrue);
      expect(analyzer.parallel, isTrue);
      expect(analyzer.verbose, isFalse);
    });

    test('should configure for development workflow', () {
      final analyzer = TestAnalyzer(
        watch: true,
        interactive: true,
        verbose: true,
        performanceMode: true,
      );
      expect(analyzer.watch, isTrue);
      expect(analyzer.interactive, isTrue);
      expect(analyzer.verbose, isTrue);
      expect(analyzer.performanceMode, isTrue);
    });
  });

  group('TestAnalyzer Special Modes', () {
    test('should configure watch mode for continuous testing', () {
      final analyzer = TestAnalyzer(
        watch: true,
      );
      expect(analyzer.watch, isTrue);
      expect(analyzer.verbose, isFalse);
    });

    test('should configure interactive debugging mode', () {
      final analyzer = TestAnalyzer(
        interactive: true,
        verbose: true,
        runCount: 1,
      );
      expect(analyzer.interactive, isTrue);
      expect(analyzer.verbose, isTrue);
    });

    test('should configure minimal mode for quick checks', () {
      final analyzer = TestAnalyzer(
        runCount: 1,
        generateFixes: false,
      );
      expect(analyzer.runCount, equals(1));
      expect(analyzer.generateFixes, isFalse);
      expect(analyzer.performanceMode, isFalse);
      expect(analyzer.verbose, isFalse);
    });

    test('should configure detailed analysis mode', () {
      final analyzer = TestAnalyzer(
        runCount: 10,
        verbose: true,
        performanceMode: true,
      );
      expect(analyzer.runCount, equals(10));
      expect(analyzer.verbose, isTrue);
      expect(analyzer.performanceMode, isTrue);
      expect(analyzer.generateFixes, isTrue);
      expect(analyzer.generateReport, isTrue);
    });
  });
}
