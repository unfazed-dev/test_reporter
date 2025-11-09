/// Unit tests for ReportRegistry
///
/// Tests the report registry system that tracks all generated reports
/// across different tools for cross-tool discovery.
///
/// TDD Phase: 🔴 RED - These tests will FAIL until implementation is complete

import 'package:test/test.dart';
import 'package:test_reporter/src/utils/report_registry.dart';

void main() {
  group('ReportRegistry', () {
    late ReportRegistry registry;

    setUp(() {
      registry = ReportRegistry();
    });

    tearDown(() {
      registry.clear();
    });

    group('register()', () {
      test('should register a report successfully', () {
        // Arrange
        const reportPath =
            'tests_reports/coverage/test-fo_coverage@1234_051125.md';
        const toolName = 'analyze_coverage';
        const reportType = 'coverage';
        const moduleName = 'test-fo';

        // Act
        registry.register(
          reportPath: reportPath,
          toolName: toolName,
          reportType: reportType,
          moduleName: moduleName,
        );

        // Assert
        final reports = registry.getReports();
        expect(reports, hasLength(1));
        expect(reports.first.reportPath, equals(reportPath));
        expect(reports.first.toolName, equals(toolName));
        expect(reports.first.reportType, equals(reportType));
        expect(reports.first.moduleName, equals(moduleName));
      });

      test('should register multiple reports from different tools', () {
        // Arrange & Act
        registry.register(
          reportPath: 'tests_reports/coverage/test-fo_coverage@1234_051125.md',
          toolName: 'analyze_coverage',
          reportType: 'coverage',
          moduleName: 'test-fo',
        );
        registry.register(
          reportPath: 'tests_reports/tests/test-fo_tests@1235_051125.md',
          toolName: 'analyze_tests',
          reportType: 'tests',
          moduleName: 'test-fo',
        );

        // Assert
        final reports = registry.getReports();
        expect(reports, hasLength(2));
        expect(reports.map((r) => r.toolName),
            containsAll(['analyze_coverage', 'analyze_tests']));
      });

      test('should store timestamp with registered report', () {
        // Arrange
        const reportPath = 'tests_reports/suite/test-fo_suite@1234_051125.md';
        final beforeTime = DateTime.now();

        // Act
        registry.register(
          reportPath: reportPath,
          toolName: 'analyze_suite',
          reportType: 'suite',
          moduleName: 'test-fo',
        );
        final afterTime = DateTime.now();

        // Assert
        final reports = registry.getReports();
        expect(reports, hasLength(1));
        expect(
            reports.first.timestamp.isAfter(beforeTime) ||
                reports.first.timestamp.isAtSameMomentAs(beforeTime),
            isTrue);
        expect(
            reports.first.timestamp.isBefore(afterTime) ||
                reports.first.timestamp.isAtSameMomentAs(afterTime),
            isTrue);
      });
    });

    group('getReports()', () {
      test('should return empty list when no reports registered', () {
        // Act
        final reports = registry.getReports();

        // Assert
        expect(reports, isEmpty);
      });

      test('should filter reports by toolName', () {
        // Arrange
        registry.register(
          reportPath: 'tests_reports/coverage/test-fo_coverage@1234_051125.md',
          toolName: 'analyze_coverage',
          reportType: 'coverage',
          moduleName: 'test-fo',
        );
        registry.register(
          reportPath: 'tests_reports/tests/test-fo_tests@1235_051125.md',
          toolName: 'analyze_tests',
          reportType: 'tests',
          moduleName: 'test-fo',
        );

        // Act
        final coverageReports =
            registry.getReports(toolName: 'analyze_coverage');

        // Assert
        expect(coverageReports, hasLength(1));
        expect(coverageReports.first.toolName, equals('analyze_coverage'));
      });

      test('should filter reports by reportType', () {
        // Arrange
        registry.register(
          reportPath: 'tests_reports/coverage/test-fo_coverage@1234_051125.md',
          toolName: 'analyze_coverage',
          reportType: 'coverage',
          moduleName: 'test-fo',
        );
        registry.register(
          reportPath: 'tests_reports/tests/test-fo_tests@1235_051125.md',
          toolName: 'analyze_tests',
          reportType: 'tests',
          moduleName: 'test-fo',
        );

        // Act
        final testReports = registry.getReports(reportType: 'tests');

        // Assert
        expect(testReports, hasLength(1));
        expect(testReports.first.reportType, equals('tests'));
      });

      test('should filter reports by moduleName', () {
        // Arrange
        registry.register(
          reportPath: 'tests_reports/coverage/test-fo_coverage@1234_051125.md',
          toolName: 'analyze_coverage',
          reportType: 'coverage',
          moduleName: 'test-fo',
        );
        registry.register(
          reportPath: 'tests_reports/coverage/auth-fo_coverage@1236_051125.md',
          toolName: 'analyze_coverage',
          reportType: 'coverage',
          moduleName: 'auth-fo',
        );

        // Act
        final authReports = registry.getReports(moduleName: 'auth-fo');

        // Assert
        expect(authReports, hasLength(1));
        expect(authReports.first.moduleName, equals('auth-fo'));
      });
    });

    group('printSummary()', () {
      test('should print summary with no reports', () {
        // Act & Assert (should not throw)
        expect(() => registry.printSummary(), returnsNormally);
      });

      test('should print summary with single report', () {
        // Arrange
        registry.register(
          reportPath: 'tests_reports/coverage/test-fo_coverage@1234_051125.md',
          toolName: 'analyze_coverage',
          reportType: 'coverage',
          moduleName: 'test-fo',
        );

        // Act & Assert (should not throw)
        expect(() => registry.printSummary(), returnsNormally);
      });

      test('should print summary with multiple reports', () {
        // Arrange
        registry.register(
          reportPath: 'tests_reports/coverage/test-fo_coverage@1234_051125.md',
          toolName: 'analyze_coverage',
          reportType: 'coverage',
          moduleName: 'test-fo',
        );
        registry.register(
          reportPath: 'tests_reports/tests/test-fo_tests@1235_051125.md',
          toolName: 'analyze_tests',
          reportType: 'tests',
          moduleName: 'test-fo',
        );
        registry.register(
          reportPath: 'tests_reports/suite/test-fo_suite@1236_051125.md',
          toolName: 'analyze_suite',
          reportType: 'suite',
          moduleName: 'test-fo',
        );

        // Act & Assert (should not throw)
        expect(() => registry.printSummary(), returnsNormally);
      });
    });

    group('clear()', () {
      test('should clear all registered reports', () {
        // Arrange
        registry.register(
          reportPath: 'tests_reports/coverage/test-fo_coverage@1234_051125.md',
          toolName: 'analyze_coverage',
          reportType: 'coverage',
          moduleName: 'test-fo',
        );
        registry.register(
          reportPath: 'tests_reports/tests/test-fo_tests@1235_051125.md',
          toolName: 'analyze_tests',
          reportType: 'tests',
          moduleName: 'test-fo',
        );
        expect(registry.getReports(), hasLength(2));

        // Act
        registry.clear();

        // Assert
        expect(registry.getReports(), isEmpty);
      });
    });
  });

  group('ReportEntry', () {
    test('🔴 toString() should return formatted string representation (lines 42-44)', () {
      // Create a ReportEntry
      final entry = ReportEntry(
        reportPath: 'tests_reports/coverage/test-fo_coverage@1234_051125.md',
        toolName: 'analyze_coverage',
        reportType: 'coverage',
        moduleName: 'test-fo',
        timestamp: DateTime(2025, 11, 9, 14, 30),
      );

      // Call toString()
      final result = entry.toString();

      // Verify it contains all the key information
      expect(result, contains('ReportEntry'));
      expect(result, contains('path=tests_reports/coverage/test-fo_coverage@1234_051125.md'));
      expect(result, contains('tool=analyze_coverage'));
      expect(result, contains('type=coverage'));
      expect(result, contains('module=test-fo'));
      expect(result, contains('timestamp=2025-11-09 14:30:00.000'));
    });
  });
}
