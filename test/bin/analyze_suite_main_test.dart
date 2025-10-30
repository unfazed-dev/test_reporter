/// Tests for run_all CLI configuration and orchestrator setup
///
/// This test file covers the TestOrchestrator configuration, CLI argument parsing,
/// and helper functions for the unified test analysis orchestrator.

import 'package:test/test.dart';
import 'package:test_reporter/src/bin/analyze_suite_lib.dart';

void main() {
  group('TestOrchestrator Configuration', () {
    test('should create orchestrator with default settings', () {
      final orchestrator = TestOrchestrator(
        testPath: 'test/',
      );

      expect(orchestrator.testPath, equals('test/'));
      expect(orchestrator.runs, equals(3));
      expect(orchestrator.performance, isFalse);
      expect(orchestrator.verbose, isFalse);
      expect(orchestrator.parallel, isFalse);
    });

    test('should create orchestrator with custom runs', () {
      final orchestrator = TestOrchestrator(
        testPath: 'test/auth',
        runs: 5,
      );

      expect(orchestrator.testPath, equals('test/auth'));
      expect(orchestrator.runs, equals(5));
    });

    test('should create orchestrator with performance enabled', () {
      final orchestrator = TestOrchestrator(
        testPath: 'test/',
        performance: true,
      );

      expect(orchestrator.performance, isTrue);
    });

    test('should create orchestrator with verbose enabled', () {
      final orchestrator = TestOrchestrator(
        testPath: 'test/',
        verbose: true,
      );

      expect(orchestrator.verbose, isTrue);
    });

    test('should create orchestrator with parallel enabled', () {
      final orchestrator = TestOrchestrator(
        testPath: 'test/',
        parallel: true,
      );

      expect(orchestrator.parallel, isTrue);
    });

    test('should create orchestrator with all features enabled', () {
      final orchestrator = TestOrchestrator(
        testPath: 'test/integration',
        runs: 10,
        performance: true,
        verbose: true,
        parallel: true,
      );

      expect(orchestrator.testPath, equals('test/integration'));
      expect(orchestrator.runs, equals(10));
      expect(orchestrator.performance, isTrue);
      expect(orchestrator.verbose, isTrue);
      expect(orchestrator.parallel, isTrue);
    });

    test('should initialize empty results map', () {
      final orchestrator = TestOrchestrator(testPath: 'test/');
      expect(orchestrator.results, isEmpty);
    });

    test('should initialize empty failures list', () {
      final orchestrator = TestOrchestrator(testPath: 'test/');
      expect(orchestrator.failures, isEmpty);
    });

    test('should initialize empty reportPaths map', () {
      final orchestrator = TestOrchestrator(testPath: 'test/');
      expect(orchestrator.reportPaths, isEmpty);
    });
  });

  group('Module Name Extraction', () {
    test('should extract module name from simple folder path', () {
      final orchestrator = TestOrchestrator(testPath: 'test/auth');
      expect(orchestrator.extractModuleName(), equals('auth-fo'));
    });

    test('should extract module name from nested folder path', () {
      final orchestrator = TestOrchestrator(testPath: 'test/features/auth');
      expect(orchestrator.extractModuleName(), equals('auth-fo'));
    });

    test('should extract module name from file path', () {
      final orchestrator =
          TestOrchestrator(testPath: 'test/auth/login_test.dart');
      expect(orchestrator.extractModuleName(), equals('login-fi'));
    });

    test('should handle test directory as module name', () {
      final orchestrator = TestOrchestrator(testPath: 'test');
      expect(orchestrator.extractModuleName(), equals('test-fo'));
    });

    test('should handle empty path', () {
      final orchestrator = TestOrchestrator(testPath: '');
      expect(orchestrator.extractModuleName(), equals('all_tests-fo'));
    });

    test('should handle path with trailing slash', () {
      final orchestrator = TestOrchestrator(testPath: 'test/auth/');
      expect(orchestrator.extractModuleName(), equals('auth-fo'));
    });

    test('should handle Windows-style backslashes', () {
      final orchestrator =
          TestOrchestrator(testPath: r'test\auth\login_test.dart');
      expect(orchestrator.extractModuleName(), equals('login-fi'));
    });

    test('should remove _test suffix from file names', () {
      final orchestrator = TestOrchestrator(testPath: 'test/user_test.dart');
      expect(orchestrator.extractModuleName(), equals('user-fi'));
    });

    test('should handle file without _test suffix', () {
      final orchestrator = TestOrchestrator(testPath: 'test/helper.dart');
      expect(orchestrator.extractModuleName(), equals('helper-fi'));
    });
  });

  group('Health Score Calculation', () {
    test('should calculate health score with all metrics', () {
      final orchestrator = TestOrchestrator(testPath: 'test/');
      final score = orchestrator.calculateHealthScore(80.0, 90.0, 95.0);
      expect(score, closeTo(88.33, 0.01));
    });

    test('should calculate health score with two metrics', () {
      final orchestrator = TestOrchestrator(testPath: 'test/');
      final score = orchestrator.calculateHealthScore(80.0, 90.0, null);
      expect(score, equals(85.0));
    });

    test('should calculate health score with one metric', () {
      final orchestrator = TestOrchestrator(testPath: 'test/');
      final score = orchestrator.calculateHealthScore(75.0, null, null);
      expect(score, equals(75.0));
    });

    test('should return 0 when no metrics provided', () {
      final orchestrator = TestOrchestrator(testPath: 'test/');
      final score = orchestrator.calculateHealthScore(null, null, null);
      expect(score, equals(0.0));
    });

    test('should handle perfect scores', () {
      final orchestrator = TestOrchestrator(testPath: 'test/');
      final score = orchestrator.calculateHealthScore(100.0, 100.0, 100.0);
      expect(score, equals(100.0));
    });

    test('should handle zero scores', () {
      final orchestrator = TestOrchestrator(testPath: 'test/');
      final score = orchestrator.calculateHealthScore(0.0, 0.0, 0.0);
      expect(score, equals(0.0));
    });
  });

  group('Health Status Badge', () {
    test('should return Excellent for scores >= 90', () {
      final orchestrator = TestOrchestrator(testPath: 'test/');
      expect(orchestrator.getHealthStatus(95.0), equals('🟢 Excellent'));
      expect(orchestrator.getHealthStatus(90.0), equals('🟢 Excellent'));
    });

    test('should return Good for scores >= 75', () {
      final orchestrator = TestOrchestrator(testPath: 'test/');
      expect(orchestrator.getHealthStatus(85.0), equals('🟡 Good'));
      expect(orchestrator.getHealthStatus(75.0), equals('🟡 Good'));
    });

    test('should return Fair for scores >= 60', () {
      final orchestrator = TestOrchestrator(testPath: 'test/');
      expect(orchestrator.getHealthStatus(70.0), equals('🟠 Fair'));
      expect(orchestrator.getHealthStatus(60.0), equals('🟠 Fair'));
    });

    test('should return Poor for scores < 60', () {
      final orchestrator = TestOrchestrator(testPath: 'test/');
      expect(orchestrator.getHealthStatus(50.0), equals('🔴 Poor'));
      expect(orchestrator.getHealthStatus(0.0), equals('🔴 Poor'));
    });
  });

  group('Coverage Status Indicator', () {
    test('should return Excellent for coverage >= 80%', () {
      final orchestrator = TestOrchestrator(testPath: 'test/');
      expect(orchestrator.getCoverageStatus(90.0), equals('✅ Excellent'));
      expect(orchestrator.getCoverageStatus(80.0), equals('✅ Excellent'));
    });

    test('should return Adequate for coverage >= 60%', () {
      final orchestrator = TestOrchestrator(testPath: 'test/');
      expect(orchestrator.getCoverageStatus(70.0), equals('🟡 Adequate'));
      expect(orchestrator.getCoverageStatus(60.0), equals('🟡 Adequate'));
    });

    test('should return Low for coverage >= 40%', () {
      final orchestrator = TestOrchestrator(testPath: 'test/');
      expect(orchestrator.getCoverageStatus(50.0), equals('🟠 Low'));
      expect(orchestrator.getCoverageStatus(40.0), equals('🟠 Low'));
    });

    test('should return Critical for coverage < 40%', () {
      final orchestrator = TestOrchestrator(testPath: 'test/');
      expect(orchestrator.getCoverageStatus(30.0), equals('🔴 Critical'));
      expect(orchestrator.getCoverageStatus(0.0), equals('🔴 Critical'));
    });

    test('should return question mark for null coverage', () {
      final orchestrator = TestOrchestrator(testPath: 'test/');
      expect(orchestrator.getCoverageStatus(null), equals('❓'));
    });
  });

  group('Pass Rate Status Indicator', () {
    test('should return Excellent for pass rate >= 95%', () {
      final orchestrator = TestOrchestrator(testPath: 'test/');
      expect(orchestrator.getPassRateStatus(100.0), equals('✅ Excellent'));
      expect(orchestrator.getPassRateStatus(95.0), equals('✅ Excellent'));
    });

    test('should return Good for pass rate >= 85%', () {
      final orchestrator = TestOrchestrator(testPath: 'test/');
      expect(orchestrator.getPassRateStatus(90.0), equals('🟡 Good'));
      expect(orchestrator.getPassRateStatus(85.0), equals('🟡 Good'));
    });

    test('should return Fair for pass rate >= 70%', () {
      final orchestrator = TestOrchestrator(testPath: 'test/');
      expect(orchestrator.getPassRateStatus(80.0), equals('🟠 Fair'));
      expect(orchestrator.getPassRateStatus(70.0), equals('🟠 Fair'));
    });

    test('should return Poor for pass rate < 70%', () {
      final orchestrator = TestOrchestrator(testPath: 'test/');
      expect(orchestrator.getPassRateStatus(60.0), equals('🔴 Poor'));
      expect(orchestrator.getPassRateStatus(0.0), equals('🔴 Poor'));
    });

    test('should return question mark for null pass rate', () {
      final orchestrator = TestOrchestrator(testPath: 'test/');
      expect(orchestrator.getPassRateStatus(null), equals('❓'));
    });
  });

  group('Stability Status Indicator', () {
    test('should return Stable for stability >= 95%', () {
      final orchestrator = TestOrchestrator(testPath: 'test/');
      expect(orchestrator.getStabilityStatus(100.0), equals('✅ Stable'));
      expect(orchestrator.getStabilityStatus(95.0), equals('✅ Stable'));
    });

    test('should return Mostly Stable for stability >= 85%', () {
      final orchestrator = TestOrchestrator(testPath: 'test/');
      expect(orchestrator.getStabilityStatus(90.0), equals('🟡 Mostly Stable'));
      expect(orchestrator.getStabilityStatus(85.0), equals('🟡 Mostly Stable'));
    });

    test('should return Unstable for stability >= 70%', () {
      final orchestrator = TestOrchestrator(testPath: 'test/');
      expect(orchestrator.getStabilityStatus(80.0), equals('🟠 Unstable'));
      expect(orchestrator.getStabilityStatus(70.0), equals('🟠 Unstable'));
    });

    test('should return Very Unstable for stability < 70%', () {
      final orchestrator = TestOrchestrator(testPath: 'test/');
      expect(orchestrator.getStabilityStatus(60.0), equals('🔴 Very Unstable'));
      expect(orchestrator.getStabilityStatus(0.0), equals('🔴 Very Unstable'));
    });

    test('should return question mark for null stability', () {
      final orchestrator = TestOrchestrator(testPath: 'test/');
      expect(orchestrator.getStabilityStatus(null), equals('❓'));
    });
  });

  group('toDouble Helper Function', () {
    test('should convert int to double', () {
      expect(toDouble(42), equals(42.0));
    });

    test('should return double as is', () {
      expect(toDouble(42.5), equals(42.5));
    });

    test('should parse string to double', () {
      expect(toDouble('42.5'), equals(42.5));
      expect(toDouble('100'), equals(100.0));
    });

    test('should return null for null input', () {
      expect(toDouble(null), isNull);
    });

    test('should return null for invalid string', () {
      expect(toDouble('invalid'), isNull);
    });

    test('should return null for unsupported types', () {
      expect(toDouble(true), isNull);
      expect(toDouble(<dynamic>[]), isNull);
      expect(toDouble(<dynamic, dynamic>{}), isNull);
    });

    test('should handle zero', () {
      expect(toDouble(0), equals(0.0));
      expect(toDouble('0'), equals(0.0));
    });

    test('should handle negative numbers', () {
      expect(toDouble(-42), equals(-42.0));
      expect(toDouble('-42.5'), equals(-42.5));
    });
  });

  group('CLI Argument Combinations', () {
    test('should handle runs with performance', () {
      final orchestrator = TestOrchestrator(
        testPath: 'test/',
        runs: 5,
        performance: true,
      );

      expect(orchestrator.runs, equals(5));
      expect(orchestrator.performance, isTrue);
    });

    test('should handle verbose with parallel', () {
      final orchestrator = TestOrchestrator(
        testPath: 'test/',
        verbose: true,
        parallel: true,
      );

      expect(orchestrator.verbose, isTrue);
      expect(orchestrator.parallel, isTrue);
    });

    test('should handle custom path with all flags', () {
      final orchestrator = TestOrchestrator(
        testPath: 'test/integration/api',
        runs: 7,
        performance: true,
        verbose: true,
        parallel: true,
      );

      expect(orchestrator.testPath, equals('test/integration/api'));
      expect(orchestrator.runs, equals(7));
      expect(orchestrator.performance, isTrue);
      expect(orchestrator.verbose, isTrue);
      expect(orchestrator.parallel, isTrue);
    });
  });
}
