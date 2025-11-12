/// Tests for analyze_suite_lib.dart - Unified Test Analysis Orchestrator
///
/// Coverage Target: 100% of pure logic methods
/// Test Strategy: Unit tests for pure logic, integration tests for orchestration
/// TDD Approach: 🔴 RED → 🟢 GREEN → ♻️ REFACTOR
///
/// NOTE: The TestOrchestrator class has methods that rely on Process.start() for
/// running subprocesses (analyze_coverage, analyze_tests). These methods also
/// perform file I/O operations. Full coverage requires integration tests with
/// actual test execution and mocked file systems.
///
/// This file focuses on thoroughly testing the pure logic methods:
/// - toDouble() helper function
/// - extractModuleName() path parsing
/// - calculateHealthScore() scoring logic
/// - Status indicator methods (health, coverage, pass rate, stability)
/// - generateInsights() insight generation
/// - generateRecommendations() recommendation generation

import 'package:test/test.dart';
import 'package:test_reporter/src/bin/analyze_suite_lib.dart';

void main() {
  group('toDouble() Helper Function', () {
    test('should convert int to double', () {
      expect(toDouble(42), equals(42.0));
      expect(toDouble(0), equals(0.0));
      expect(toDouble(-100), equals(-100.0));
    });

    test('should return double unchanged', () {
      expect(toDouble(42.5), equals(42.5));
      expect(toDouble(0.0), equals(0.0));
      expect(toDouble(-3.14), equals(-3.14));
    });

    test('should parse numeric string to double', () {
      expect(toDouble('42'), equals(42.0));
      expect(toDouble('42.5'), equals(42.5));
      expect(toDouble('0'), equals(0.0));
      expect(toDouble('-3.14'), equals(-3.14));
    });

    test('should return null for invalid string', () {
      expect(toDouble('not a number'), isNull);
      expect(toDouble('42abc'), isNull);
      expect(toDouble(''), isNull);
    });

    test('should return null for null input', () {
      expect(toDouble(null), isNull);
    });

    test('should return null for unsupported types', () {
      expect(toDouble(true), isNull);
      expect(toDouble([]), isNull);
      expect(toDouble({}), isNull);
    });
  });

  group('TestOrchestrator', () {
    group('Constructor', () {
      test('should create TestOrchestrator with required testPath', () {
        final orchestrator = TestOrchestrator(testPath: 'test/unit');

        expect(orchestrator.testPath, equals('test/unit'));
        expect(orchestrator.runs, equals(3)); // default
        expect(orchestrator.performance, isFalse); // default
        expect(orchestrator.verbose, isFalse); // default
        expect(orchestrator.parallel, isFalse); // default
      });

      test('should create TestOrchestrator with all parameters', () {
        final orchestrator = TestOrchestrator(
          testPath: 'test/integration',
          runs: 5,
          performance: true,
          verbose: true,
          parallel: true,
        );

        expect(orchestrator.testPath, equals('test/integration'));
        expect(orchestrator.runs, equals(5));
        expect(orchestrator.performance, isTrue);
        expect(orchestrator.verbose, isTrue);
        expect(orchestrator.parallel, isTrue);
      });

      test('should initialize empty collections', () {
        final orchestrator = TestOrchestrator(testPath: 'test');

        expect(orchestrator.results, isEmpty);
        expect(orchestrator.failures, isEmpty);
        expect(orchestrator.reportPaths, isEmpty);
      });
    });

    group('extractModuleName()', () {
      test('should extract module name from simple folder path', () {
        final orchestrator = TestOrchestrator(testPath: 'test/auth');
        expect(orchestrator.extractModuleName(), equals('auth-fo'));
      });

      test('should extract module name from nested folder path', () {
        final orchestrator = TestOrchestrator(testPath: 'test/auth/service');
        expect(orchestrator.extractModuleName(), equals('service-fo'));
      });

      test('should handle test root path', () {
        final orchestrator = TestOrchestrator(testPath: 'test');
        expect(orchestrator.extractModuleName(), equals('test-fo'));
      });

      test('should handle test root path with trailing slash', () {
        final orchestrator = TestOrchestrator(testPath: 'test/');
        expect(orchestrator.extractModuleName(), equals('test-fo'));
      });

      test('should extract file name without _test suffix', () {
        final orchestrator = TestOrchestrator(testPath: 'test/auth_test.dart');
        expect(orchestrator.extractModuleName(), equals('auth-fi'));
      });

      test('should extract file name from nested path', () {
        final orchestrator =
            TestOrchestrator(testPath: 'test/unit/utils/formatter_test.dart');
        expect(orchestrator.extractModuleName(), equals('formatter-fi'));
      });

      test('should handle file without _test suffix', () {
        final orchestrator =
            TestOrchestrator(testPath: 'test/integration/main.dart');
        expect(orchestrator.extractModuleName(), equals('main-fi'));
      });

      test('should handle Windows-style paths', () {
        final orchestrator = TestOrchestrator(testPath: r'test\auth\service');
        expect(orchestrator.extractModuleName(), equals('service-fo'));
      });

      test('should handle mixed path separators', () {
        final orchestrator = TestOrchestrator(testPath: r'test/auth\service');
        expect(orchestrator.extractModuleName(), equals('service-fo'));
      });

      test('should handle empty path segments', () {
        final orchestrator = TestOrchestrator(testPath: 'test//auth//');
        expect(orchestrator.extractModuleName(), equals('auth-fo'));
      });

      test('should return default for empty path', () {
        final orchestrator = TestOrchestrator(testPath: '');
        expect(orchestrator.extractModuleName(), equals('test-fo'));
      });

      test('should return default for root-only path', () {
        final orchestrator = TestOrchestrator(testPath: '/');
        expect(orchestrator.extractModuleName(), equals('test-fo'));
      });
    });

    group('calculateHealthScore()', () {
      test('should calculate average of all three metrics', () {
        final orchestrator = TestOrchestrator(testPath: 'test');
        final score =
            orchestrator.calculateHealthScore(90.0, 85.0, 95.0); // avg = 90

        expect(score, equals(90.0));
      });

      test('should calculate average when coverage is null', () {
        final orchestrator = TestOrchestrator(testPath: 'test');
        final score =
            orchestrator.calculateHealthScore(null, 80.0, 90.0); // avg = 85

        expect(score, equals(85.0));
      });

      test('should calculate average when passRate is null', () {
        final orchestrator = TestOrchestrator(testPath: 'test');
        final score =
            orchestrator.calculateHealthScore(80.0, null, 90.0); // avg = 85

        expect(score, equals(85.0));
      });

      test('should calculate average when stability is null', () {
        final orchestrator = TestOrchestrator(testPath: 'test');
        final score =
            orchestrator.calculateHealthScore(80.0, 90.0, null); // avg = 85

        expect(score, equals(85.0));
      });

      test('should return 0.0 when all metrics are null', () {
        final orchestrator = TestOrchestrator(testPath: 'test');
        final score = orchestrator.calculateHealthScore(null, null, null);

        expect(score, equals(0.0));
      });

      test('should handle single non-null metric', () {
        final orchestrator = TestOrchestrator(testPath: 'test');
        final score = orchestrator.calculateHealthScore(75.0, null, null);

        expect(score, equals(75.0));
      });

      test('should handle perfect scores', () {
        final orchestrator = TestOrchestrator(testPath: 'test');
        final score = orchestrator.calculateHealthScore(100.0, 100.0, 100.0);

        expect(score, equals(100.0));
      });

      test('should handle zero scores', () {
        final orchestrator = TestOrchestrator(testPath: 'test');
        final score = orchestrator.calculateHealthScore(0.0, 0.0, 0.0);

        expect(score, equals(0.0));
      });

      test('should calculate correct average with mixed values', () {
        final orchestrator = TestOrchestrator(testPath: 'test');
        final score = orchestrator.calculateHealthScore(
            70.0, 85.0, 90.0); // avg = 81.666...

        expect(score, closeTo(81.67, 0.01));
      });
    });

    group('getHealthStatus()', () {
      test('should return Excellent for score >= 90', () {
        final orchestrator = TestOrchestrator(testPath: 'test');

        expect(orchestrator.getHealthStatus(90.0), equals('🟢 Excellent'));
        expect(orchestrator.getHealthStatus(95.0), equals('🟢 Excellent'));
        expect(orchestrator.getHealthStatus(100.0), equals('🟢 Excellent'));
      });

      test('should return Good for score 75-89', () {
        final orchestrator = TestOrchestrator(testPath: 'test');

        expect(orchestrator.getHealthStatus(75.0), equals('🟡 Good'));
        expect(orchestrator.getHealthStatus(80.0), equals('🟡 Good'));
        expect(orchestrator.getHealthStatus(89.9), equals('🟡 Good'));
      });

      test('should return Fair for score 60-74', () {
        final orchestrator = TestOrchestrator(testPath: 'test');

        expect(orchestrator.getHealthStatus(60.0), equals('🟠 Fair'));
        expect(orchestrator.getHealthStatus(65.0), equals('🟠 Fair'));
        expect(orchestrator.getHealthStatus(74.9), equals('🟠 Fair'));
      });

      test('should return Poor for score < 60', () {
        final orchestrator = TestOrchestrator(testPath: 'test');

        expect(orchestrator.getHealthStatus(0.0), equals('🔴 Poor'));
        expect(orchestrator.getHealthStatus(30.0), equals('🔴 Poor'));
        expect(orchestrator.getHealthStatus(59.9), equals('🔴 Poor'));
      });

      test('should handle boundary values correctly', () {
        final orchestrator = TestOrchestrator(testPath: 'test');

        expect(orchestrator.getHealthStatus(89.99), equals('🟡 Good'));
        expect(orchestrator.getHealthStatus(90.0), equals('🟢 Excellent'));
        expect(orchestrator.getHealthStatus(74.99), equals('🟠 Fair'));
        expect(orchestrator.getHealthStatus(75.0), equals('🟡 Good'));
        expect(orchestrator.getHealthStatus(59.99), equals('🔴 Poor'));
        expect(orchestrator.getHealthStatus(60.0), equals('🟠 Fair'));
      });
    });

    group('getCoverageStatus()', () {
      test('should return Unknown for null coverage', () {
        final orchestrator = TestOrchestrator(testPath: 'test');
        expect(orchestrator.getCoverageStatus(null), equals('❓'));
      });

      test('should return Excellent for coverage >= 80', () {
        final orchestrator = TestOrchestrator(testPath: 'test');

        expect(orchestrator.getCoverageStatus(80.0), equals('✅ Excellent'));
        expect(orchestrator.getCoverageStatus(90.0), equals('✅ Excellent'));
        expect(orchestrator.getCoverageStatus(100.0), equals('✅ Excellent'));
      });

      test('should return Adequate for coverage 60-79', () {
        final orchestrator = TestOrchestrator(testPath: 'test');

        expect(orchestrator.getCoverageStatus(60.0), equals('🟡 Adequate'));
        expect(orchestrator.getCoverageStatus(70.0), equals('🟡 Adequate'));
        expect(orchestrator.getCoverageStatus(79.9), equals('🟡 Adequate'));
      });

      test('should return Low for coverage 40-59', () {
        final orchestrator = TestOrchestrator(testPath: 'test');

        expect(orchestrator.getCoverageStatus(40.0), equals('🟠 Low'));
        expect(orchestrator.getCoverageStatus(50.0), equals('🟠 Low'));
        expect(orchestrator.getCoverageStatus(59.9), equals('🟠 Low'));
      });

      test('should return Critical for coverage < 40', () {
        final orchestrator = TestOrchestrator(testPath: 'test');

        expect(orchestrator.getCoverageStatus(0.0), equals('🔴 Critical'));
        expect(orchestrator.getCoverageStatus(20.0), equals('🔴 Critical'));
        expect(orchestrator.getCoverageStatus(39.9), equals('🔴 Critical'));
      });

      test('should handle boundary values correctly', () {
        final orchestrator = TestOrchestrator(testPath: 'test');

        expect(orchestrator.getCoverageStatus(79.99), equals('🟡 Adequate'));
        expect(orchestrator.getCoverageStatus(80.0), equals('✅ Excellent'));
        expect(orchestrator.getCoverageStatus(59.99), equals('🟠 Low'));
        expect(orchestrator.getCoverageStatus(60.0), equals('🟡 Adequate'));
        expect(orchestrator.getCoverageStatus(39.99), equals('🔴 Critical'));
        expect(orchestrator.getCoverageStatus(40.0), equals('🟠 Low'));
      });
    });

    group('getPassRateStatus()', () {
      test('should return Unknown for null pass rate', () {
        final orchestrator = TestOrchestrator(testPath: 'test');
        expect(orchestrator.getPassRateStatus(null), equals('❓'));
      });

      test('should return Excellent for pass rate >= 95', () {
        final orchestrator = TestOrchestrator(testPath: 'test');

        expect(orchestrator.getPassRateStatus(95.0), equals('✅ Excellent'));
        expect(orchestrator.getPassRateStatus(98.0), equals('✅ Excellent'));
        expect(orchestrator.getPassRateStatus(100.0), equals('✅ Excellent'));
      });

      test('should return Good for pass rate 85-94', () {
        final orchestrator = TestOrchestrator(testPath: 'test');

        expect(orchestrator.getPassRateStatus(85.0), equals('🟡 Good'));
        expect(orchestrator.getPassRateStatus(90.0), equals('🟡 Good'));
        expect(orchestrator.getPassRateStatus(94.9), equals('🟡 Good'));
      });

      test('should return Fair for pass rate 70-84', () {
        final orchestrator = TestOrchestrator(testPath: 'test');

        expect(orchestrator.getPassRateStatus(70.0), equals('🟠 Fair'));
        expect(orchestrator.getPassRateStatus(75.0), equals('🟠 Fair'));
        expect(orchestrator.getPassRateStatus(84.9), equals('🟠 Fair'));
      });

      test('should return Poor for pass rate < 70', () {
        final orchestrator = TestOrchestrator(testPath: 'test');

        expect(orchestrator.getPassRateStatus(0.0), equals('🔴 Poor'));
        expect(orchestrator.getPassRateStatus(50.0), equals('🔴 Poor'));
        expect(orchestrator.getPassRateStatus(69.9), equals('🔴 Poor'));
      });

      test('should handle boundary values correctly', () {
        final orchestrator = TestOrchestrator(testPath: 'test');

        expect(orchestrator.getPassRateStatus(94.99), equals('🟡 Good'));
        expect(orchestrator.getPassRateStatus(95.0), equals('✅ Excellent'));
        expect(orchestrator.getPassRateStatus(84.99), equals('🟠 Fair'));
        expect(orchestrator.getPassRateStatus(85.0), equals('🟡 Good'));
        expect(orchestrator.getPassRateStatus(69.99), equals('🔴 Poor'));
        expect(orchestrator.getPassRateStatus(70.0), equals('🟠 Fair'));
      });
    });

    group('getStabilityStatus()', () {
      test('should return Unknown for null stability', () {
        final orchestrator = TestOrchestrator(testPath: 'test');
        expect(orchestrator.getStabilityStatus(null), equals('❓'));
      });

      test('should return Stable for stability >= 95', () {
        final orchestrator = TestOrchestrator(testPath: 'test');

        expect(orchestrator.getStabilityStatus(95.0), equals('✅ Stable'));
        expect(orchestrator.getStabilityStatus(98.0), equals('✅ Stable'));
        expect(orchestrator.getStabilityStatus(100.0), equals('✅ Stable'));
      });

      test('should return Mostly Stable for stability 85-94', () {
        final orchestrator = TestOrchestrator(testPath: 'test');

        expect(
            orchestrator.getStabilityStatus(85.0), equals('🟡 Mostly Stable'));
        expect(
            orchestrator.getStabilityStatus(90.0), equals('🟡 Mostly Stable'));
        expect(
            orchestrator.getStabilityStatus(94.9), equals('🟡 Mostly Stable'));
      });

      test('should return Unstable for stability 70-84', () {
        final orchestrator = TestOrchestrator(testPath: 'test');

        expect(orchestrator.getStabilityStatus(70.0), equals('🟠 Unstable'));
        expect(orchestrator.getStabilityStatus(75.0), equals('🟠 Unstable'));
        expect(orchestrator.getStabilityStatus(84.9), equals('🟠 Unstable'));
      });

      test('should return Very Unstable for stability < 70', () {
        final orchestrator = TestOrchestrator(testPath: 'test');

        expect(
            orchestrator.getStabilityStatus(0.0), equals('🔴 Very Unstable'));
        expect(
            orchestrator.getStabilityStatus(50.0), equals('🔴 Very Unstable'));
        expect(
            orchestrator.getStabilityStatus(69.9), equals('🔴 Very Unstable'));
      });

      test('should handle boundary values correctly', () {
        final orchestrator = TestOrchestrator(testPath: 'test');

        expect(
            orchestrator.getStabilityStatus(94.99), equals('🟡 Mostly Stable'));
        expect(orchestrator.getStabilityStatus(95.0), equals('✅ Stable'));
        expect(orchestrator.getStabilityStatus(84.99), equals('🟠 Unstable'));
        expect(
            orchestrator.getStabilityStatus(85.0), equals('🟡 Mostly Stable'));
        expect(
            orchestrator.getStabilityStatus(69.99), equals('🔴 Very Unstable'));
        expect(orchestrator.getStabilityStatus(70.0), equals('🟠 Unstable'));
      });
    });

    group('generateInsights()', () {
      test('should generate critical insight for low coverage < 80%', () {
        final orchestrator = TestOrchestrator(testPath: 'test');
        orchestrator.results['coverage'] = {
          'summary': {'overall_coverage': 75.5},
        };

        final insights = orchestrator.generateInsights();

        expect(insights, hasLength(1));
        expect(insights[0]['severity'], equals('🔴 Critical'));
        expect(insights[0]['message'],
            contains('Coverage is 75.5% - below 80% threshold'));
      });

      test('should generate warning insight for coverage 80-89%', () {
        final orchestrator = TestOrchestrator(testPath: 'test');
        orchestrator.results['coverage'] = {
          'summary': {'overall_coverage': 85.0},
        };

        final insights = orchestrator.generateInsights();

        expect(insights, hasLength(1));
        expect(insights[0]['severity'], equals('🟡 Warning'));
        expect(
            insights[0]['message'], contains('Coverage is 85.0% - could be'));
      });

      test('should not generate coverage insight for coverage >= 90%', () {
        final orchestrator = TestOrchestrator(testPath: 'test');
        orchestrator.results['coverage'] = {
          'summary': {'overall_coverage': 95.0},
        };

        final insights = orchestrator.generateInsights();

        expect(insights, isEmpty);
      });

      test('should generate critical insight for consistent failures > 0', () {
        final orchestrator = TestOrchestrator(testPath: 'test');
        orchestrator.results['test_analysis'] = {
          'summary': {'consistent_failures': 5},
        };

        final insights = orchestrator.generateInsights();

        expect(insights, hasLength(1));
        expect(insights[0]['severity'], equals('🔴 Critical'));
        expect(insights[0]['message'],
            contains('5 tests failing consistently - requires immediate'));
      });

      test('should generate warning insight for flaky tests > 0', () {
        final orchestrator = TestOrchestrator(testPath: 'test');
        orchestrator.results['test_analysis'] = {
          'summary': {'flaky_tests': 3},
        };

        final insights = orchestrator.generateInsights();

        expect(insights, hasLength(1));
        expect(insights[0]['severity'], equals('🟠 Warning'));
        expect(insights[0]['message'],
            contains('3 flaky tests detected - investigate test isolation'));
      });

      test('should generate notice insight for pass rate < 95%', () {
        final orchestrator = TestOrchestrator(testPath: 'test');
        orchestrator.results['test_analysis'] = {
          'summary': {'pass_rate': 90.0},
        };

        final insights = orchestrator.generateInsights();

        expect(insights, hasLength(1));
        expect(insights[0]['severity'], equals('🟡 Notice'));
        expect(
            insights[0]['message'], contains('Pass rate is 90.0% - aim for'));
      });

      test('should generate multiple insights when multiple issues exist', () {
        final orchestrator = TestOrchestrator(testPath: 'test');
        orchestrator.results['coverage'] = {
          'summary': {'overall_coverage': 75.0},
        };
        orchestrator.results['test_analysis'] = {
          'summary': {
            'consistent_failures': 2,
            'flaky_tests': 1,
            'pass_rate': 88.0,
          },
        };

        final insights = orchestrator.generateInsights();

        expect(insights, hasLength(4));
        // Check that all severities are present
        final severities = insights.map((i) => i['severity']).toList();
        expect(severities, contains('🔴 Critical')); // coverage + failures
        expect(severities, contains('🟠 Warning')); // flaky tests
        expect(severities, contains('🟡 Notice')); // pass rate
      });

      test('should return empty list when no issues found', () {
        final orchestrator = TestOrchestrator(testPath: 'test');
        orchestrator.results['coverage'] = {
          'summary': {'overall_coverage': 95.0},
        };
        orchestrator.results['test_analysis'] = {
          'summary': {
            'consistent_failures': 0,
            'flaky_tests': 0,
            'pass_rate': 98.0,
          },
        };

        final insights = orchestrator.generateInsights();

        expect(insights, isEmpty);
      });

      test('should handle missing coverage results gracefully', () {
        final orchestrator = TestOrchestrator(testPath: 'test');
        orchestrator.results['test_analysis'] = {
          'summary': {'consistent_failures': 0},
        };

        final insights = orchestrator.generateInsights();

        expect(insights, isEmpty);
      });

      test('should handle missing test_analysis results gracefully', () {
        final orchestrator = TestOrchestrator(testPath: 'test');
        orchestrator.results['coverage'] = {
          'summary': {'overall_coverage': 95.0},
        };

        final insights = orchestrator.generateInsights();

        expect(insights, isEmpty);
      });

      test('should handle null summary data gracefully', () {
        final orchestrator = TestOrchestrator(testPath: 'test');
        orchestrator.results['coverage'] = <String, dynamic>{};
        orchestrator.results['test_analysis'] = <String, dynamic>{};

        final insights = orchestrator.generateInsights();

        expect(insights, isEmpty);
      });
    });

    group('getSourcePath()', () {
      test('should map test/ui to lib/ui', () {
        final orchestrator = TestOrchestrator(testPath: 'test/ui');
        final sourcePath = orchestrator.getSourcePath();

        expect(sourcePath, equals('lib/ui'));
      });

      test('should map test/src to lib/src', () {
        final orchestrator = TestOrchestrator(testPath: 'test/src');
        final sourcePath = orchestrator.getSourcePath();

        expect(sourcePath, equals('lib/src'));
      });

      test('should map test/core to lib/core', () {
        final orchestrator = TestOrchestrator(testPath: 'test/core');
        final sourcePath = orchestrator.getSourcePath();

        expect(sourcePath, equals('lib/core'));
      });

      test('should map test/integration to lib/integration', () {
        final orchestrator = TestOrchestrator(testPath: 'test/integration');
        final sourcePath = orchestrator.getSourcePath();

        expect(sourcePath, equals('lib/integration'));
      });

      test('should default to lib/ for non-test paths', () {
        final orchestrator = TestOrchestrator(testPath: 'somewhere');
        final sourcePath = orchestrator.getSourcePath();

        expect(sourcePath, equals('lib/'));
      });

      test('should respect explicit source path override', () {
        final orchestrator = TestOrchestrator(
          testPath: 'test/ui',
          sourcePathOverride: 'lib/app/ui',
        );
        final sourcePath = orchestrator.getSourcePath();

        expect(sourcePath, equals('lib/app/ui'));
      });

      test('should handle test root by mapping to lib/', () {
        final orchestrator = TestOrchestrator(testPath: 'test/');
        final sourcePath = orchestrator.getSourcePath();

        expect(sourcePath, equals('lib/'));
      });

      test('should handle test without trailing slash', () {
        final orchestrator = TestOrchestrator(testPath: 'test');
        final sourcePath = orchestrator.getSourcePath();

        expect(sourcePath, equals('lib/'));
      });
    });

    group('generateRecommendations()', () {
      test('should recommend increasing coverage when < 80%', () {
        final orchestrator = TestOrchestrator(testPath: 'test');
        orchestrator.results['coverage'] = {
          'summary': {'overall_coverage': 70.0},
        };

        final recommendations = orchestrator.generateRecommendations();

        expect(recommendations, hasLength(1));
        expect(recommendations[0],
            contains('Increase test coverage - run `dart run'));
      });

      test('should not recommend coverage increase when >= 80%', () {
        final orchestrator = TestOrchestrator(testPath: 'test');
        orchestrator.results['coverage'] = {
          'summary': {'overall_coverage': 85.0},
        };

        final recommendations = orchestrator.generateRecommendations();

        expect(recommendations, hasLength(1));
        expect(recommendations[0], contains('Continue monitoring'));
      });

      test('should recommend fixing failing tests when failures > 0', () {
        final orchestrator = TestOrchestrator(testPath: 'test');
        orchestrator.results['test_analysis'] = {
          'summary': {'consistent_failures': 3},
        };

        final recommendations = orchestrator.generateRecommendations();

        expect(recommendations, hasLength(1));
        expect(recommendations[0],
            contains('Fix consistently failing tests - review'));
      });

      test('should recommend investigating flaky tests when flaky > 0', () {
        final orchestrator = TestOrchestrator(testPath: 'test');
        orchestrator.results['test_analysis'] = {
          'summary': {'flaky_tests': 2},
        };

        final recommendations = orchestrator.generateRecommendations();

        expect(recommendations, hasLength(1));
        expect(recommendations[0],
            contains('Investigate flaky tests - check for race conditions'));
      });

      test('should generate multiple recommendations when multiple issues', () {
        final orchestrator = TestOrchestrator(testPath: 'test');
        orchestrator.results['coverage'] = {
          'summary': {'overall_coverage': 65.0},
        };
        orchestrator.results['test_analysis'] = {
          'summary': {
            'consistent_failures': 2,
            'flaky_tests': 1,
          },
        };

        final recommendations = orchestrator.generateRecommendations();

        expect(recommendations, hasLength(3));
        expect(recommendations[0], contains('Increase test coverage'));
        expect(recommendations[1], contains('Fix consistently failing tests'));
        expect(recommendations[2], contains('Investigate flaky tests'));
      });

      test('should provide default recommendation when no issues', () {
        final orchestrator = TestOrchestrator(testPath: 'test');
        orchestrator.results['coverage'] = {
          'summary': {'overall_coverage': 90.0},
        };
        orchestrator.results['test_analysis'] = {
          'summary': {
            'consistent_failures': 0,
            'flaky_tests': 0,
          },
        };

        final recommendations = orchestrator.generateRecommendations();

        expect(recommendations, hasLength(1));
        expect(recommendations[0], contains('Continue monitoring'));
      });

      test('should handle missing coverage results gracefully', () {
        final orchestrator = TestOrchestrator(testPath: 'test');
        orchestrator.results['test_analysis'] = {
          'summary': {'consistent_failures': 0},
        };

        final recommendations = orchestrator.generateRecommendations();

        expect(recommendations, hasLength(1));
        expect(recommendations[0], contains('Continue monitoring'));
      });

      test('should handle missing test_analysis results gracefully', () {
        final orchestrator = TestOrchestrator(testPath: 'test');
        orchestrator.results['coverage'] = {
          'summary': {'overall_coverage': 90.0},
        };

        final recommendations = orchestrator.generateRecommendations();

        expect(recommendations, hasLength(1));
        expect(recommendations[0], contains('Continue monitoring'));
      });

      test('should handle null summary data gracefully', () {
        final orchestrator = TestOrchestrator(testPath: 'test');
        orchestrator.results['coverage'] = <String, dynamic>{};
        orchestrator.results['test_analysis'] = <String, dynamic>{};

        final recommendations = orchestrator.generateRecommendations();

        expect(recommendations, hasLength(1));
        expect(recommendations[0], contains('Continue monitoring'));
      });
    });

    // NOTE: The following methods require integration testing with mocked Process.start()
    // and file system operations. They are marked as pending.

    group('Integration Tests (Pending)', () {
      test('should orchestrate coverage and test analysis tools', () {},
          skip: 'Requires integration test with Process.start() mocking');

      test('should run coverage tool with correct arguments', () {},
          skip: 'Requires integration test with Process.start() mocking');

      test('should run test analyzer with correct arguments', () {},
          skip: 'Requires integration test with Process.start() mocking');

      test('should handle coverage tool failures gracefully', () {},
          skip: 'Requires integration test with Process.start() mocking');

      test('should handle test analyzer failures gracefully', () {},
          skip: 'Requires integration test with Process.start() mocking');

      test('should find latest reports by prefix', () {},
          skip: 'Requires integration test with file system operations');

      test('should extract JSON from latest reports', () {},
          skip: 'Requires integration test with file system operations');

      test('should generate unified markdown report', () {},
          skip: 'Requires integration test with file I/O operations');

      test('should generate unified JSON report', () {},
          skip: 'Requires integration test with file I/O operations');

      test('should generate failed test report when failures exist', () {},
          skip: 'Requires integration test with file I/O operations');

      test('should not generate failed report when no failures', () {},
          skip: 'Requires integration test with file I/O operations');

      test('should clean up old reports after generation', () {},
          skip: 'Requires integration test with file I/O operations');

      test('should handle verbose output mode', () {},
          skip: 'Requires integration test with stdout capturing');

      test('should handle parallel execution mode', () {},
          skip: 'Requires integration test with Process.start() mocking');

      test('should handle performance profiling mode', () {},
          skip: 'Requires integration test with Process.start() mocking');

      test('should aggregate exit codes correctly', () {},
          skip: 'Requires integration test with Process.start() mocking');

      test('should print header with configuration details', () {},
          skip: 'Requires integration test with stdout capturing');

      test('should print summary with tool results', () {},
          skip: 'Requires integration test with stdout capturing');

      test('should handle test path to source path conversion', () {},
          skip: 'Requires integration test with file system operations');

      test('should handle lib path to test path conversion', () {},
          skip: 'Requires integration test with file system operations');

      test('should wait for report files to be written', () {},
          skip: 'Requires integration test with file system operations');

      test('should handle JSON extraction failures gracefully', () {},
          skip: 'Requires integration test with file I/O operations');
    });
  });
}
