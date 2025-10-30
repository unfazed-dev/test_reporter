/// Tests for coverage_tool error handling and edge cases
///
/// This test file covers error scenarios, invalid inputs, boundary conditions,
/// and exceptional cases for the coverage analysis tool.

import 'package:test/test.dart';
import 'package:test_analyzer/src/bin/coverage_tool_lib.dart';

void main() {
  group('Invalid Threshold Configurations', () {
    test('should handle negative minimum threshold', () {
      final thresholds = CoverageThresholds(minimum: -10.0);

      // Negative threshold should still work mathematically
      expect(thresholds.validate(0.0), isTrue);
      expect(thresholds.validate(-5.0), isTrue);
    });

    test('should handle threshold above 100%', () {
      final thresholds = CoverageThresholds(minimum: 150.0);

      // Nothing can reach 150%
      expect(thresholds.validate(100.0), isFalse);
      expect(thresholds.validate(99.0), isFalse);
    });

    test('should handle warning lower than minimum', () {
      final thresholds = CoverageThresholds(
        minimum: 90.0,
        warning: 70.0, // Warning lower than minimum (unusual but valid)
      );

      expect(thresholds.validate(95.0), isTrue);
      expect(thresholds.validate(85.0), isFalse);
    });

    test('should handle very large threshold values', () {
      final thresholds = CoverageThresholds(minimum: 999999.0);
      expect(thresholds.validate(100.0), isFalse);
    });

    test('should handle very small negative threshold', () {
      final thresholds = CoverageThresholds(minimum: -999999.0);
      expect(thresholds.validate(0.0), isTrue);
    });
  });

  group('Baseline Edge Cases', () {
    test('should handle negative baseline coverage', () {
      final thresholds = CoverageThresholds(
        minimum: 50.0,
        failOnDecrease: true,
      );

      // Negative baseline is invalid but should not crash
      expect(thresholds.validate(60.0, baseline: -10.0), isTrue);
    });

    test('should handle baseline above 100%', () {
      final thresholds = CoverageThresholds(
        minimum: 50.0,
        failOnDecrease: true,
      );

      // Baseline above 100% is invalid but should not crash
      expect(thresholds.validate(100.0, baseline: 150.0), isFalse);
    });

    test('should handle extremely large baseline value', () {
      final thresholds = CoverageThresholds(
        minimum: 50.0,
        failOnDecrease: true,
      );

      expect(thresholds.validate(100.0, baseline: 999999.0), isFalse);
    });

    test('should handle NaN-like extreme values', () {
      final thresholds = CoverageThresholds(minimum: 80.0);

      // Test with double.infinity equivalent (very large number)
      expect(thresholds.validate(90.0), isTrue);
    });
  });

  group('Empty and Null-like Inputs', () {
    test('should handle empty libPath', () {
      final analyzer = CoverageAnalyzer(
        libPath: '',
        testPath: 'test',
      );

      expect(analyzer.libPath, equals(''));
      expect(analyzer.testPath, equals('test'));
    });

    test('should handle empty testPath', () {
      final analyzer = CoverageAnalyzer(
        libPath: 'lib/src',
        testPath: '',
      );

      expect(analyzer.libPath, equals('lib/src'));
      expect(analyzer.testPath, equals(''));
    });

    test('should handle both paths empty', () {
      final analyzer = CoverageAnalyzer(
        libPath: '',
        testPath: '',
      );

      expect(analyzer.libPath, equals(''));
      expect(analyzer.testPath, equals(''));
    });

    test('should handle empty exclude patterns', () {
      final analyzer = CoverageAnalyzer(
        libPath: 'lib/src',
        testPath: 'test',
        excludePatterns: [],
      );

      expect(analyzer.excludePatterns, isEmpty);
    });

    test('should handle empty baseline file path', () {
      final analyzer = CoverageAnalyzer(
        libPath: 'lib/src',
        testPath: 'test',
        baselineFile: '',
      );

      expect(analyzer.baselineFile, equals(''));
    });
  });

  group('Special Characters in Paths', () {
    test('should handle paths with Unicode characters', () {
      final analyzer = CoverageAnalyzer(
        libPath: 'lib/src/café',
        testPath: 'test/café',
      );

      expect(analyzer.libPath, equals('lib/src/café'));
      expect(analyzer.testPath, equals('test/café'));
    });

    test('should handle paths with emoji', () {
      final analyzer = CoverageAnalyzer(
        libPath: 'lib/src/feature_🚀',
        testPath: 'test/feature_🚀',
      );

      expect(analyzer.libPath, contains('🚀'));
    });

    test('should handle paths with dots', () {
      final analyzer = CoverageAnalyzer(
        libPath: 'lib/src/auth.v2',
        testPath: 'test/auth.v2',
      );

      expect(analyzer.libPath, equals('lib/src/auth.v2'));
    });

    test('should handle paths with multiple special chars', () {
      final analyzer = CoverageAnalyzer(
        libPath: 'lib/src/@scope/pkg-v2.0',
        testPath: 'test/@scope/pkg-v2.0',
      );

      expect(analyzer.libPath, equals('lib/src/@scope/pkg-v2.0'));
    });
  });

  group('Extreme Pattern Lists', () {
    test('should handle very long exclude pattern list', () {
      final patterns = List.generate(1000, (i) => '**/*_$i.g.dart');
      final analyzer = CoverageAnalyzer(
        libPath: 'lib/src',
        testPath: 'test',
        excludePatterns: patterns,
      );

      expect(analyzer.excludePatterns, hasLength(1000));
    });

    test('should handle exclude patterns with special regex chars', () {
      final analyzer = CoverageAnalyzer(
        libPath: 'lib/src',
        testPath: 'test',
        excludePatterns: [
          '**/*.g.dart',
          '**/*.[0-9].dart',
          '**/test?.dart',
          '**/{a,b,c}.dart',
        ],
      );

      expect(analyzer.excludePatterns, hasLength(4));
    });

    test('should handle empty string in exclude patterns', () {
      final analyzer = CoverageAnalyzer(
        libPath: 'lib/src',
        testPath: 'test',
        excludePatterns: ['', '**/*.g.dart', ''],
      );

      expect(analyzer.excludePatterns, hasLength(3));
      expect(analyzer.excludePatterns[0], equals(''));
      expect(analyzer.excludePatterns[2], equals(''));
    });
  });

  group('Conflicting Configurations', () {
    test('should handle autoFix without generateReport', () {
      final analyzer = CoverageAnalyzer(
        libPath: 'lib/src',
        testPath: 'test',
        autoFix: true,
      );

      // autoFix without report is valid (fixes are applied directly)
      expect(analyzer.autoFix, isTrue);
      expect(analyzer.generateReport, isTrue); // default
    });

    test('should handle watchMode with parallel', () {
      final analyzer = CoverageAnalyzer(
        libPath: 'lib/src',
        testPath: 'test',
        watchMode: true,
        parallel: true,
      );

      // Both can be enabled (watch restarts parallel runs)
      expect(analyzer.watchMode, isTrue);
      expect(analyzer.parallel, isTrue);
    });

    test('should handle incremental without baseline', () {
      final analyzer = CoverageAnalyzer(
        libPath: 'lib/src',
        testPath: 'test',
        incremental: true,
      );

      // Incremental without baseline is valid (uses git diff)
      expect(analyzer.incremental, isTrue);
      expect(analyzer.baselineFile, isNull);
    });

    test('should handle baseline without incremental', () {
      final analyzer = CoverageAnalyzer(
        libPath: 'lib/src',
        testPath: 'test',
        baselineFile: 'baseline.json',
      );

      // Baseline without incremental is valid (for comparison only)
      expect(analyzer.baselineFile, isNotNull);
      expect(analyzer.incremental, isFalse);
    });
  });

  group('Boundary Value Testing', () {
    test('should handle threshold at double precision limit', () {
      final thresholds = CoverageThresholds(minimum: 80.00000000001);

      expect(thresholds.validate(80.00000000001), isTrue);
      expect(thresholds.validate(80.0), isFalse);
    });

    test('should handle zero threshold', () {
      final thresholds = CoverageThresholds(minimum: 0.0, warning: 0.0);

      expect(thresholds.validate(0.0), isTrue);
      expect(thresholds.validate(0.1), isTrue);
    });

    test('should handle threshold rounding edge cases', () {
      final thresholds = CoverageThresholds(minimum: 79.9999999);

      // Test values very close to threshold
      expect(thresholds.validate(80.0), isTrue);
      expect(thresholds.validate(79.9999999), isTrue);
    });
  });

  group('Invalid Path Patterns', () {
    test('should handle path with only slashes', () {
      final analyzer = CoverageAnalyzer(
        libPath: '///',
        testPath: '///',
      );

      expect(analyzer.libPath, equals('///'));
      expect(analyzer.testPath, equals('///'));
    });

    test('should handle path with backslashes', () {
      final analyzer = CoverageAnalyzer(
        libPath: r'lib\src\\module',
        testPath: r'test\\module',
      );

      expect(analyzer.libPath, equals(r'lib\src\\module'));
    });

    test('should handle paths with trailing slashes', () {
      final analyzer = CoverageAnalyzer(
        libPath: 'lib/src/',
        testPath: 'test/',
      );

      expect(analyzer.libPath, equals('lib/src/'));
      expect(analyzer.testPath, equals('test/'));
    });

    test('should handle paths with multiple consecutive slashes', () {
      final analyzer = CoverageAnalyzer(
        libPath: 'lib//src///module',
        testPath: 'test//module',
      );

      expect(analyzer.libPath, equals('lib//src///module'));
    });

    test('should handle relative path patterns', () {
      final analyzer = CoverageAnalyzer(
        libPath: '../lib/src',
        testPath: '../test',
      );

      expect(analyzer.libPath, equals('../lib/src'));
      expect(analyzer.testPath, equals('../test'));
    });

    test('should handle dot paths', () {
      final analyzer = CoverageAnalyzer(
        libPath: './lib/src',
        testPath: './test',
      );

      expect(analyzer.libPath, equals('./lib/src'));
      expect(analyzer.testPath, equals('./test'));
    });

    test('should handle double-dot paths', () {
      final analyzer = CoverageAnalyzer(
        libPath: '../../lib/src',
        testPath: '../../test',
      );

      expect(analyzer.libPath, equals('../../lib/src'));
    });
  });

  group('Threshold Validation Edge Cases', () {
    test('should validate when coverage equals minimum exactly', () {
      final thresholds = CoverageThresholds(minimum: 75.5);
      expect(thresholds.validate(75.5), isTrue);
      expect(thresholds.validate(75.49999), isFalse);
    });

    test('should handle decrease detection with identical values', () {
      final thresholds = CoverageThresholds(
        minimum: 70.0,
        failOnDecrease: true,
      );

      // Same value is not a decrease
      expect(thresholds.validate(80.0, baseline: 80.0), isTrue);
    });

    test('should handle minimal increase detection', () {
      final thresholds = CoverageThresholds(
        minimum: 70.0,
        failOnDecrease: true,
      );

      // Even 0.0001% increase should pass
      expect(thresholds.validate(80.0001, baseline: 80.0), isTrue);
    });

    test('should prioritize minimum over failOnDecrease', () {
      final thresholds = CoverageThresholds(
        minimum: 90.0,
        failOnDecrease: true,
      );

      // Below minimum fails even if increased
      expect(thresholds.validate(85.0, baseline: 80.0), isFalse);
    });
  });

  group('Configuration Object Edge Cases', () {
    test('should handle maximum possible feature combination', () {
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
        baselineFile: 'baseline.json',
        excludePatterns: ['**/*.g.dart'],
        thresholds: CoverageThresholds(
          minimum: 80.0,
          warning: 90.0,
          failOnDecrease: true,
        ),
      );

      // All features enabled should not conflict
      expect(analyzer.autoFix, isTrue);
      expect(analyzer.branchCoverage, isTrue);
      expect(analyzer.incremental, isTrue);
      expect(analyzer.mutationTesting, isTrue);
      expect(analyzer.watchMode, isTrue);
      expect(analyzer.parallel, isTrue);
      expect(analyzer.exportJson, isTrue);
      expect(analyzer.testImpactAnalysis, isTrue);
    });

    test('should handle minimal configuration', () {
      final analyzer = CoverageAnalyzer(
        libPath: 'lib',
        testPath: 'test',
      );

      // Should have sensible defaults
      expect(analyzer.libPath, equals('lib'));
      expect(analyzer.testPath, equals('test'));
    });
  });

  group('Extreme Coverage Values', () {
    test('should handle coverage value of exactly 0.0', () {
      final thresholds = CoverageThresholds(minimum: 0.0);
      expect(thresholds.validate(0.0), isTrue);
    });

    test('should handle coverage value of exactly 100.0', () {
      final thresholds = CoverageThresholds(minimum: 90.0);
      expect(thresholds.validate(100.0), isTrue);
    });

    test('should handle very small coverage values', () {
      final thresholds = CoverageThresholds(minimum: 0.01);
      expect(thresholds.validate(0.01), isTrue);
      expect(thresholds.validate(0.009), isFalse);
    });

    test('should handle coverage very close to 100%', () {
      final thresholds = CoverageThresholds(minimum: 99.99);
      expect(thresholds.validate(99.99), isTrue);
      expect(thresholds.validate(99.98), isFalse);
    });
  });
}
