/// Tests for coverage_tool advanced features and complex scenarios
///
/// This test file covers advanced feature combinations, complex configurations,
/// and sophisticated use cases for the coverage analysis tool.

import 'package:test/test.dart';
import 'package:test_reporter/src/bin/analyze_coverage_lib.dart';

void main() {
  group('Advanced Feature Combinations', () {
    test('should configure parallel execution with branch coverage', () {
      final analyzer = CoverageAnalyzer(
        libPath: 'lib/src',
        testPath: 'test',
        parallel: true,
        branchCoverage: true,
      );

      expect(analyzer.parallel, isTrue);
      expect(analyzer.branchCoverage, isTrue);
    });

    test('should configure incremental analysis with parallel execution', () {
      final analyzer = CoverageAnalyzer(
        libPath: 'lib/src/auth',
        testPath: 'test/auth',
        incremental: true,
        parallel: true,
      );

      expect(analyzer.incremental, isTrue);
      expect(analyzer.parallel, isTrue);
    });

    test('should configure mutation testing with branch coverage', () {
      final analyzer = CoverageAnalyzer(
        libPath: 'lib/src',
        testPath: 'test',
        mutationTesting: true,
        branchCoverage: true,
      );

      expect(analyzer.mutationTesting, isTrue);
      expect(analyzer.branchCoverage, isTrue);
    });

    test('should configure watch mode with incremental analysis', () {
      final analyzer = CoverageAnalyzer(
        libPath: 'lib/src',
        testPath: 'test',
        watchMode: true,
        incremental: true,
      );

      expect(analyzer.watchMode, isTrue);
      expect(analyzer.incremental, isTrue);
    });

    test('should configure all analysis features together', () {
      final analyzer = CoverageAnalyzer(
        libPath: 'lib/src',
        testPath: 'test',
        branchCoverage: true,
        incremental: true,
        mutationTesting: true,
        testImpactAnalysis: true,
        parallel: true,
      );

      expect(analyzer.branchCoverage, isTrue);
      expect(analyzer.incremental, isTrue);
      expect(analyzer.mutationTesting, isTrue);
      expect(analyzer.testImpactAnalysis, isTrue);
      expect(analyzer.parallel, isTrue);
    });

    test('should configure watch mode with all features', () {
      final analyzer = CoverageAnalyzer(
        libPath: 'lib/src',
        testPath: 'test',
        watchMode: true,
        branchCoverage: true,
        incremental: true,
        autoFix: true,
      );

      expect(analyzer.watchMode, isTrue);
      expect(analyzer.branchCoverage, isTrue);
      expect(analyzer.incremental, isTrue);
      expect(analyzer.autoFix, isTrue);
      expect(analyzer.generateReport, isTrue);
    });
  });

  group('Complex Threshold Scenarios', () {
    test('should validate with strict thresholds and baseline', () {
      final thresholds = CoverageThresholds(
        minimum: 90.0,
        warning: 95.0,
        failOnDecrease: true,
      );

      // Pass: above minimum and improved
      expect(thresholds.validate(92.0, baseline: 90.0), isTrue);

      // Fail: above minimum but decreased
      expect(thresholds.validate(91.0, baseline: 92.0), isFalse);
    });

    test('should handle baseline comparison with zero baseline', () {
      final thresholds = CoverageThresholds(
        minimum: 50.0,
        failOnDecrease: true,
      );

      // Starting from zero should always pass
      expect(thresholds.validate(60.0, baseline: 0.0), isTrue);
    });

    test('should handle 100% baseline comparison', () {
      final thresholds = CoverageThresholds(
        minimum: 95.0,
        failOnDecrease: true,
      );

      // Can only maintain or match 100%
      expect(thresholds.validate(100.0, baseline: 100.0), isTrue);
      expect(thresholds.validate(99.0, baseline: 100.0), isFalse);
    });

    test('should validate edge case: coverage equals baseline', () {
      final thresholds = CoverageThresholds(
        failOnDecrease: true,
      );

      expect(thresholds.validate(85.0, baseline: 85.0), isTrue);
    });

    test('should handle very small coverage improvements', () {
      final thresholds = CoverageThresholds(
        failOnDecrease: true,
      );

      // Tiny improvement should still pass
      expect(thresholds.validate(80.1, baseline: 80.0), isTrue);
    });

    test('should handle very small coverage decreases', () {
      final thresholds = CoverageThresholds(
        failOnDecrease: true,
      );

      // Even tiny decrease should fail when failOnDecrease is true
      expect(thresholds.validate(89.9, baseline: 90.0), isFalse);
    });
  });

  group('Baseline File Configuration', () {
    test('should configure with baseline file', () {
      final analyzer = CoverageAnalyzer(
        libPath: 'lib/src',
        testPath: 'test',
        baselineFile: '.coverage_baseline.json',
      );

      expect(analyzer.baselineFile, equals('.coverage_baseline.json'));
    });

    test('should configure baseline with thresholds', () {
      final analyzer = CoverageAnalyzer(
        libPath: 'lib/src',
        testPath: 'test',
        baselineFile: 'coverage/baseline.json',
        thresholds: CoverageThresholds(
          failOnDecrease: true,
        ),
      );

      expect(analyzer.baselineFile, equals('coverage/baseline.json'));
      expect(analyzer.thresholds.failOnDecrease, isTrue);
    });

    test('should handle different baseline file paths', () {
      final paths = [
        'baseline.json',
        '.coverage/baseline.json',
        '/absolute/path/baseline.json',
        '../relative/baseline.json',
      ];

      for (final path in paths) {
        final analyzer = CoverageAnalyzer(
          libPath: 'lib/src',
          testPath: 'test',
          baselineFile: path,
        );
        expect(analyzer.baselineFile, equals(path));
      }
    });
  });

  group('Exclude Patterns', () {
    test('should configure with single exclude pattern', () {
      final analyzer = CoverageAnalyzer(
        libPath: 'lib/src',
        testPath: 'test',
        excludePatterns: ['**/*.g.dart'],
      );

      expect(analyzer.excludePatterns, hasLength(1));
      expect(analyzer.excludePatterns, contains('**/*.g.dart'));
    });

    test('should configure with multiple exclude patterns', () {
      final analyzer = CoverageAnalyzer(
        libPath: 'lib/src',
        testPath: 'test',
        excludePatterns: [
          '**/*.g.dart',
          '**/*.freezed.dart',
          '**/generated/**',
        ],
      );

      expect(analyzer.excludePatterns, hasLength(3));
      expect(analyzer.excludePatterns, contains('**/*.g.dart'));
      expect(analyzer.excludePatterns, contains('**/*.freezed.dart'));
      expect(analyzer.excludePatterns, contains('**/generated/**'));
    });

    test('should handle common generated file patterns', () {
      final patterns = [
        '**/*.g.dart',
        '**/*.freezed.dart',
        '**/*.gr.dart',
        '**/*.config.dart',
        '**/generated/**',
        '**/.generated/**',
      ];

      final analyzer = CoverageAnalyzer(
        libPath: 'lib/src',
        testPath: 'test',
        excludePatterns: patterns,
      );

      expect(analyzer.excludePatterns, hasLength(6));
      for (final pattern in patterns) {
        expect(analyzer.excludePatterns, contains(pattern));
      }
    });

    test('should handle empty exclude patterns list', () {
      final analyzer = CoverageAnalyzer(
        libPath: 'lib/src',
        testPath: 'test',
        excludePatterns: [],
      );

      expect(analyzer.excludePatterns, isEmpty);
    });
  });

  group('JSON Export Configuration', () {
    test('should enable JSON export', () {
      final analyzer = CoverageAnalyzer(
        libPath: 'lib/src',
        testPath: 'test',
        exportJson: true,
      );

      expect(analyzer.exportJson, isTrue);
    });

    test('should configure JSON export with report generation', () {
      final analyzer = CoverageAnalyzer(
        libPath: 'lib/src',
        testPath: 'test',
        exportJson: true,
      );

      expect(analyzer.exportJson, isTrue);
      expect(analyzer.generateReport, isTrue);
    });

    test('should configure JSON export without markdown report', () {
      final analyzer = CoverageAnalyzer(
        libPath: 'lib/src',
        testPath: 'test',
        exportJson: true,
        generateReport: false,
      );

      expect(analyzer.exportJson, isTrue);
      expect(analyzer.generateReport, isFalse);
    });
  });

  group('Auto-Fix Configuration', () {
    test('should enable auto-fix with report generation', () {
      final analyzer = CoverageAnalyzer(
        libPath: 'lib/src',
        testPath: 'test',
        autoFix: true,
      );

      expect(analyzer.autoFix, isTrue);
      expect(analyzer.generateReport, isTrue);
    });

    test('should enable auto-fix without report', () {
      final analyzer = CoverageAnalyzer(
        libPath: 'lib/src',
        testPath: 'test',
        autoFix: true,
        generateReport: false,
      );

      expect(analyzer.autoFix, isTrue);
      expect(analyzer.generateReport, isFalse);
    });
  });

  group('Complex Path Scenarios', () {
    test('should handle deeply nested module paths', () {
      final analyzer = CoverageAnalyzer(
        libPath: 'lib/src/features/auth/domain/repositories',
        testPath: 'test/features/auth/domain/repositories',
      );

      expect(analyzer.libPath,
          equals('lib/src/features/auth/domain/repositories'));
      expect(
          analyzer.testPath, equals('test/features/auth/domain/repositories'));
    });

    test('should handle Windows-style paths', () {
      final analyzer = CoverageAnalyzer(
        libPath: r'lib\src\auth',
        testPath: r'test\auth',
      );

      expect(analyzer.libPath, equals(r'lib\src\auth'));
      expect(analyzer.testPath, equals(r'test\auth'));
    });

    test('should handle paths with spaces', () {
      final analyzer = CoverageAnalyzer(
        libPath: 'lib/src/my module',
        testPath: 'test/my module',
      );

      expect(analyzer.libPath, equals('lib/src/my module'));
      expect(analyzer.testPath, equals('test/my module'));
    });

    test('should handle paths with special characters', () {
      final analyzer = CoverageAnalyzer(
        libPath: 'lib/src/auth-v2',
        testPath: 'test/auth-v2',
      );

      expect(analyzer.libPath, equals('lib/src/auth-v2'));
      expect(analyzer.testPath, equals('test/auth-v2'));
    });
  });

  group('CI/CD Optimization Configurations', () {
    test('should configure for fast CI execution', () {
      final analyzer = CoverageAnalyzer(
        libPath: 'lib/src',
        testPath: 'test',
        parallel: true,
        exportJson: true,
      );

      expect(analyzer.parallel, isTrue);
      expect(analyzer.generateReport, isTrue);
      expect(analyzer.exportJson, isTrue);
      expect(analyzer.autoFix, isFalse);
      expect(analyzer.watchMode, isFalse);
    });

    test('should configure for PR validation', () {
      final analyzer = CoverageAnalyzer(
        libPath: 'lib/src',
        testPath: 'test',
        incremental: true,
        baselineFile: 'main-baseline.json',
        thresholds: CoverageThresholds(
          failOnDecrease: true,
        ),
      );

      expect(analyzer.incremental, isTrue);
      expect(analyzer.baselineFile, isNotNull);
      expect(analyzer.thresholds.failOnDecrease, isTrue);
    });

    test('should configure for nightly comprehensive analysis', () {
      final analyzer = CoverageAnalyzer(
        libPath: 'lib/src',
        testPath: 'test',
        branchCoverage: true,
        mutationTesting: true,
        testImpactAnalysis: true,
        exportJson: true,
      );

      expect(analyzer.branchCoverage, isTrue);
      expect(analyzer.mutationTesting, isTrue);
      expect(analyzer.testImpactAnalysis, isTrue);
      expect(analyzer.generateReport, isTrue);
      expect(analyzer.exportJson, isTrue);
    });
  });

  group('Developer Workflow Configurations', () {
    test('should configure for local development with watch', () {
      final analyzer = CoverageAnalyzer(
        libPath: 'lib/src',
        testPath: 'test',
        watchMode: true,
        incremental: true,
      );

      expect(analyzer.watchMode, isTrue);
      expect(analyzer.incremental, isTrue);
      expect(analyzer.generateReport, isTrue);
    });

    test('should configure for quick local check', () {
      final analyzer = CoverageAnalyzer(
        libPath: 'lib/src/auth',
        testPath: 'test/auth',
        generateReport: false,
      );

      expect(analyzer.generateReport, isFalse);
      expect(analyzer.autoFix, isFalse);
    });

    test('should configure for focused module testing', () {
      final analyzer = CoverageAnalyzer(
        libPath: 'lib/src/payment',
        testPath: 'test/payment',
        branchCoverage: true,
        thresholds: CoverageThresholds(minimum: 90.0),
      );

      expect(analyzer.libPath, contains('payment'));
      expect(analyzer.testPath, contains('payment'));
      expect(analyzer.branchCoverage, isTrue);
      expect(analyzer.thresholds.minimum, equals(90.0));
    });
  });

  group('Threshold Edge Cases', () {
    test('should handle threshold at exactly 0%', () {
      final thresholds = CoverageThresholds(minimum: 0.0);
      expect(thresholds.validate(0.0), isTrue);
      expect(thresholds.validate(0.1), isTrue);
    });

    test('should handle threshold at exactly 100%', () {
      final thresholds = CoverageThresholds(minimum: 100.0);
      expect(thresholds.validate(100.0), isTrue);
      expect(thresholds.validate(99.9), isFalse);
    });

    test('should handle warning higher than minimum', () {
      final thresholds = CoverageThresholds(
        minimum: 70.0,
        warning: 85.0,
      );

      // Below minimum
      expect(thresholds.validate(60.0), isFalse);
      // Between minimum and warning
      expect(thresholds.validate(75.0), isTrue);
      // Above warning
      expect(thresholds.validate(90.0), isTrue);
    });

    test('should handle fractional threshold values', () {
      final thresholds = CoverageThresholds(
        minimum: 85.5,
        warning: 92.3,
      );

      expect(thresholds.validate(85.5), isTrue);
      expect(thresholds.validate(85.4), isFalse);
      expect(thresholds.validate(92.3), isTrue);
    });
  });

  group('Feature Flag Combinations', () {
    test('should disable all optional features', () {
      final analyzer = CoverageAnalyzer(
        libPath: 'lib/src',
        testPath: 'test',
        generateReport: false,
      );

      expect(analyzer.autoFix, isFalse);
      expect(analyzer.generateReport, isFalse);
      expect(analyzer.branchCoverage, isFalse);
      expect(analyzer.incremental, isFalse);
      expect(analyzer.mutationTesting, isFalse);
      expect(analyzer.watchMode, isFalse);
      expect(analyzer.parallel, isFalse);
      expect(analyzer.exportJson, isFalse);
      expect(analyzer.testImpactAnalysis, isFalse);
    });

    test('should enable all optional features', () {
      final analyzer = CoverageAnalyzer(
        libPath: 'lib/src',
        testPath: 'test',
        autoFix: true,
        branchCoverage: true,
        incremental: true,
        mutationTesting: true,
        watchMode: true,
        parallel: true,
        exportJson: true,
        testImpactAnalysis: true,
      );

      expect(analyzer.autoFix, isTrue);
      expect(analyzer.generateReport, isTrue);
      expect(analyzer.branchCoverage, isTrue);
      expect(analyzer.incremental, isTrue);
      expect(analyzer.mutationTesting, isTrue);
      expect(analyzer.watchMode, isTrue);
      expect(analyzer.parallel, isTrue);
      expect(analyzer.exportJson, isTrue);
      expect(analyzer.testImpactAnalysis, isTrue);
    });
  });

  group('Exclude Patterns', () {
    test('should handle multiple exclude patterns', () {
      final analyzer = CoverageAnalyzer(
        libPath: 'lib/src',
        testPath: 'test',
        excludePatterns: [
          '*.g.dart',
          '*.freezed.dart',
          '*.mocks.dart',
        ],
      );

      expect(analyzer.excludePatterns, hasLength(3));
      expect(analyzer.excludePatterns, contains('*.g.dart'));
      expect(analyzer.excludePatterns, contains('*.freezed.dart'));
      expect(analyzer.excludePatterns, contains('*.mocks.dart'));
    });

    test('should handle exclude patterns with wildcards', () {
      final analyzer = CoverageAnalyzer(
        libPath: 'lib/src',
        testPath: 'test',
        excludePatterns: [
          '**/*.generated.dart',
          '**/mocks/**',
          'lib/src/generated/**',
        ],
      );

      expect(analyzer.excludePatterns, hasLength(3));
      expect(analyzer.excludePatterns, contains('**/*.generated.dart'));
      expect(analyzer.excludePatterns, contains('**/mocks/**'));
      expect(analyzer.excludePatterns, contains('lib/src/generated/**'));
    });

    test('should handle empty exclude patterns list', () {
      final analyzer = CoverageAnalyzer(
        libPath: 'lib/src',
        testPath: 'test',
        excludePatterns: [],
      );

      expect(analyzer.excludePatterns, isEmpty);
    });
  });

  group('Baseline Comparison', () {
    test('should configure baseline file path correctly', () {
      final analyzer = CoverageAnalyzer(
        libPath: 'lib/src',
        testPath: 'test',
        baselineFile: 'coverage-baseline.json',
      );

      expect(analyzer.baselineFile, equals('coverage-baseline.json'));
    });

    test('should handle relative baseline file paths', () {
      final analyzer = CoverageAnalyzer(
        libPath: 'lib/src',
        testPath: 'test',
        baselineFile: '../baselines/main-coverage.json',
      );

      expect(analyzer.baselineFile, equals('../baselines/main-coverage.json'));
    });

    test('should handle absolute baseline file paths', () {
      final analyzer = CoverageAnalyzer(
        libPath: 'lib/src',
        testPath: 'test',
        baselineFile: '/tmp/coverage-baseline.json',
      );

      expect(analyzer.baselineFile, equals('/tmp/coverage-baseline.json'));
    });

    test('should configure fail-on-decrease with baseline', () {
      final analyzer = CoverageAnalyzer(
        libPath: 'lib/src',
        testPath: 'test',
        baselineFile: 'baseline.json',
        thresholds: CoverageThresholds(
          minimum: 85.0,
          failOnDecrease: true,
        ),
      );

      expect(analyzer.baselineFile, isNotNull);
      expect(analyzer.thresholds.failOnDecrease, isTrue);
      expect(analyzer.thresholds.minimum, equals(85.0));
    });

    test('should handle baseline without fail-on-decrease', () {
      final analyzer = CoverageAnalyzer(
        libPath: 'lib/src',
        testPath: 'test',
        baselineFile: 'baseline.json',
        thresholds: CoverageThresholds(minimum: 75.0),
      );

      expect(analyzer.baselineFile, isNotNull);
      expect(analyzer.thresholds.failOnDecrease, isFalse);
    });

    test('should combine baseline with exclude patterns', () {
      final analyzer = CoverageAnalyzer(
        libPath: 'lib/src',
        testPath: 'test',
        baselineFile: 'baseline.json',
        excludePatterns: ['*.g.dart', '*.freezed.dart'],
        thresholds: CoverageThresholds(failOnDecrease: true),
      );

      expect(analyzer.baselineFile, isNotNull);
      expect(analyzer.excludePatterns, hasLength(2));
      expect(analyzer.thresholds.failOnDecrease, isTrue);
    });
  });
}
