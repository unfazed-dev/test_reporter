import 'package:test/test.dart';
import 'package:test_reporter/src/bin/analyze_coverage_lib.dart';

/// Tests for coverage_tool main() and CoverageAnalyzer with various configurations
void main() {
  group('CoverageAnalyzer Configuration', () {
    test('should create analyzer with default settings', () {
      final analyzer = CoverageAnalyzer(
        libPath: 'lib/src',
        testPath: 'test',
      );

      expect(analyzer.libPath, equals('lib/src'));
      expect(analyzer.testPath, equals('test'));
      expect(analyzer.autoFix, isFalse);
      expect(analyzer.generateReport, isTrue);
      expect(analyzer.branchCoverage, isFalse);
      expect(analyzer.incremental, isFalse);
      expect(analyzer.mutationTesting, isFalse);
      expect(analyzer.watchMode, isFalse);
      expect(analyzer.parallel, isFalse);
      expect(analyzer.exportJson, isFalse);
      expect(analyzer.testImpactAnalysis, isFalse);
    });

    test('should create analyzer with autoFix enabled', () {
      final analyzer = CoverageAnalyzer(
        libPath: 'lib/src',
        testPath: 'test',
        autoFix: true,
      );

      expect(analyzer.autoFix, isTrue);
    });

    test('should create analyzer with branch coverage enabled', () {
      final analyzer = CoverageAnalyzer(
        libPath: 'lib/src',
        testPath: 'test',
        branchCoverage: true,
      );

      expect(analyzer.branchCoverage, isTrue);
    });

    test('should create analyzer with incremental mode enabled', () {
      final analyzer = CoverageAnalyzer(
        libPath: 'lib/src',
        testPath: 'test',
        incremental: true,
      );

      expect(analyzer.incremental, isTrue);
    });

    test('should create analyzer with mutation testing enabled', () {
      final analyzer = CoverageAnalyzer(
        libPath: 'lib/src',
        testPath: 'test',
        mutationTesting: true,
      );

      expect(analyzer.mutationTesting, isTrue);
    });

    test('should create analyzer with watch mode enabled', () {
      final analyzer = CoverageAnalyzer(
        libPath: 'lib/src',
        testPath: 'test',
        watchMode: true,
      );

      expect(analyzer.watchMode, isTrue);
    });

    test('should create analyzer with parallel execution enabled', () {
      final analyzer = CoverageAnalyzer(
        libPath: 'lib/src',
        testPath: 'test',
        parallel: true,
      );

      expect(analyzer.parallel, isTrue);
    });

    test('should create analyzer with JSON export enabled', () {
      final analyzer = CoverageAnalyzer(
        libPath: 'lib/src',
        testPath: 'test',
        exportJson: true,
      );

      expect(analyzer.exportJson, isTrue);
    });

    test('should create analyzer with test impact analysis enabled', () {
      final analyzer = CoverageAnalyzer(
        libPath: 'lib/src',
        testPath: 'test',
        testImpactAnalysis: true,
      );

      expect(analyzer.testImpactAnalysis, isTrue);
    });

    test('should create analyzer with custom thresholds', () {
      final thresholds = CoverageThresholds(
        minimum: 85.0,
        warning: 95.0,
        failOnDecrease: true,
      );

      final analyzer = CoverageAnalyzer(
        libPath: 'lib/src',
        testPath: 'test',
        thresholds: thresholds,
      );

      expect(analyzer.thresholds.minimum, equals(85.0));
      expect(analyzer.thresholds.warning, equals(95.0));
      expect(analyzer.thresholds.failOnDecrease, isTrue);
    });

    test('should create analyzer with exclude patterns', () {
      final analyzer = CoverageAnalyzer(
        libPath: 'lib/src',
        testPath: 'test',
        excludePatterns: ['*.g.dart', '*.freezed.dart', 'test/mocks/*'],
      );

      expect(analyzer.excludePatterns, hasLength(3));
      expect(analyzer.excludePatterns, contains('*.g.dart'));
      expect(analyzer.excludePatterns, contains('*.freezed.dart'));
      expect(analyzer.excludePatterns, contains('test/mocks/*'));
    });

    test('should create analyzer with baseline file', () {
      final analyzer = CoverageAnalyzer(
        libPath: 'lib/src',
        testPath: 'test',
        baselineFile: 'coverage/baseline.json',
      );

      expect(analyzer.baselineFile, equals('coverage/baseline.json'));
    });

    test('should create analyzer with all features enabled', () {
      final analyzer = CoverageAnalyzer(
        libPath: 'lib/src/auth',
        testPath: 'test/auth',
        autoFix: true,
        generateReport: true,
        branchCoverage: true,
        incremental: true,
        mutationTesting: true,
        watchMode: false, // Can't combine watch with other modes in practice
        parallel: true,
        exportJson: true,
        testImpactAnalysis: true,
        excludePatterns: ['*.g.dart'],
        thresholds: CoverageThresholds(
          minimum: 90.0,
          warning: 95.0,
          failOnDecrease: true,
        ),
        baselineFile: 'coverage/baseline.json',
      );

      expect(analyzer.libPath, equals('lib/src/auth'));
      expect(analyzer.testPath, equals('test/auth'));
      expect(analyzer.autoFix, isTrue);
      expect(analyzer.branchCoverage, isTrue);
      expect(analyzer.parallel, isTrue);
      expect(analyzer.thresholds.minimum, equals(90.0));
    });

    test('should create analyzer for bin/ directory', () {
      final analyzer = CoverageAnalyzer(
        libPath: 'bin',
        testPath: 'test/bin',
      );

      expect(analyzer.libPath, equals('bin'));
      expect(analyzer.testPath, equals('test/bin'));
    });

    test('should create analyzer for scripts/ directory', () {
      final analyzer = CoverageAnalyzer(
        libPath: 'scripts',
        testPath: 'test/scripts',
      );

      expect(analyzer.libPath, equals('scripts'));
      expect(analyzer.testPath, equals('test/scripts'));
    });

    test('should create analyzer with no report generation', () {
      final analyzer = CoverageAnalyzer(
        libPath: 'lib/src',
        testPath: 'test',
        generateReport: false,
      );

      expect(analyzer.generateReport, isFalse);
    });
  });

  group('CoverageThresholds', () {
    test('should use default thresholds when not specified', () {
      final thresholds = CoverageThresholds();

      expect(thresholds.minimum, equals(80.0));
      expect(thresholds.warning, equals(90.0));
      expect(thresholds.failOnDecrease, isFalse);
    });

    test('should allow custom minimum threshold', () {
      final thresholds = CoverageThresholds(minimum: 75.0);

      expect(thresholds.minimum, equals(75.0));
      expect(thresholds.warning, equals(90.0));
    });

    test('should allow custom warning threshold', () {
      final thresholds = CoverageThresholds(warning: 85.0);

      expect(thresholds.minimum, equals(80.0));
      expect(thresholds.warning, equals(85.0));
    });

    test('should allow custom failOnDecrease setting', () {
      final thresholds = CoverageThresholds(failOnDecrease: true);

      expect(thresholds.failOnDecrease, isTrue);
    });

    test('should validate coverage meets all criteria', () {
      final thresholds = CoverageThresholds(
        minimum: 70.0,
        warning: 85.0,
        failOnDecrease: false,
      );

      expect(thresholds.validate(95.0), isTrue);
      expect(thresholds.validate(90.0), isTrue);
      expect(thresholds.validate(80.0), isTrue);
      expect(thresholds.validate(75.0), isTrue);
      expect(thresholds.validate(65.0), isFalse); // Below minimum
    });

    test('should validate with baseline comparison when failOnDecrease is true',
        () {
      final thresholds = CoverageThresholds(
        minimum: 70.0,
        failOnDecrease: true,
      );

      // Coverage improved - should pass
      expect(thresholds.validate(85.0, baseline: 80.0), isTrue);
      // Coverage stayed same - should pass
      expect(thresholds.validate(80.0, baseline: 80.0), isTrue);
      // Coverage decreased - should fail
      expect(thresholds.validate(75.0, baseline: 80.0), isFalse);
    });

    test('should pass when coverage decreased but failOnDecrease is false', () {
      final thresholds = CoverageThresholds(
        minimum: 70.0,
        failOnDecrease: false,
      );

      // Coverage decreased but above minimum - should pass
      expect(thresholds.validate(75.0, baseline: 80.0), isTrue);
    });

    test('should fail when coverage below minimum regardless of baseline', () {
      final thresholds = CoverageThresholds(
        minimum: 80.0,
        failOnDecrease: true,
      );

      // Below minimum even though it didn't decrease
      expect(thresholds.validate(75.0, baseline: 75.0), isFalse);
      // Below minimum and decreased
      expect(thresholds.validate(75.0, baseline: 80.0), isFalse);
    });
  });

  // Integration tests would require mocking Process.run() and file I/O
  // These will be added in the advanced test file
}
