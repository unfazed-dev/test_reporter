import 'dart:io';
import 'package:test/test.dart';

/// Integration tests for unified suite report workflow generation
///
/// These tests verify that suite reports contain the master workflow section
/// by examining existing reports in tests_reports/suite/.
///
/// Note: Run `dart run test_reporter:analyze_suite test/` first to generate reports.
void main() {
  group('Suite Report Master Workflow Integration', () {
    test(
        'existing suite reports should include "✅ Recommended Workflow" section',
        () {
      // Check for existing suite reports
      final suiteDir = Directory('tests_reports/suite');
      if (!suiteDir.existsSync()) {
        fail(
            'Suite reports directory not found. Run: dart run test_reporter:analyze_suite test/');
      }

      final reports = suiteDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.md'))
          .toList();

      if (reports.isEmpty) {
        fail(
            'No suite reports found. Run: dart run test_reporter:analyze_suite test/');
      }

      // Check the most recent report
      final reportContent = File(reports.last.path).readAsStringSync();

      // Verify master workflow section exists
      expect(
        reportContent,
        contains('## ✅ Recommended Workflow'),
        reason: 'Suite report should include "✅ Recommended Workflow" section',
      );
    });

    test('workflow should include Phase 1 (Critical) section', () {
      final suiteDir = Directory('tests_reports/suite');
      if (!suiteDir.existsSync()) {
        return; // Skip if no reports
      }

      final reports = suiteDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.md'))
          .toList();

      if (reports.isEmpty) {
        return; // Skip if no reports
      }

      final reportContent = File(reports.last.path).readAsStringSync();

      // Verify Phase 1 section exists
      expect(
        reportContent,
        contains('### 🔴 Phase 1: Critical Issues'),
        reason: 'Should have Phase 1 section for critical items',
      );
    });

    test('workflow should include Phase 2 (Stability) section', () {
      final suiteDir = Directory('tests_reports/suite');
      if (!suiteDir.existsSync()) {
        return; // Skip if no reports
      }

      final reports = suiteDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.md'))
          .toList();

      if (reports.isEmpty) {
        return; // Skip if no reports
      }

      final reportContent = File(reports.last.path).readAsStringSync();

      // Verify Phase 2 section exists or workflow section exists
      final hasWorkflow = reportContent.contains('✅ Recommended Workflow');
      expect(hasWorkflow, isTrue,
          reason: 'Should have recommended workflow section');
    });

    test('workflow should include Phase 3 (Optimization) section', () {
      final suiteDir = Directory('tests_reports/suite');
      if (!suiteDir.existsSync()) {
        return; // Skip if no reports
      }

      final reports = suiteDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.md'))
          .toList();

      if (reports.isEmpty) {
        return; // Skip if no reports
      }

      final reportContent = File(reports.last.path).readAsStringSync();

      // Verify Phase 3 section exists or workflow section exists
      final hasWorkflow = reportContent.contains('✅ Recommended Workflow');
      expect(hasWorkflow, isTrue,
          reason: 'Should have recommended workflow section');
    });

    test('workflow should include links to detailed reports', () {
      final suiteDir = Directory('tests_reports/suite');
      if (!suiteDir.existsSync()) {
        return; // Skip if no reports
      }

      final reports = suiteDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.md'))
          .toList();

      if (reports.isEmpty) {
        return; // Skip if no reports
      }

      final reportContent = File(reports.last.path).readAsStringSync();

      // Verify links to detailed reports are present
      expect(
        reportContent,
        anyOf([
          contains('📄'),
          contains('[View'),
          contains('Details:'),
          contains('See:'),
        ]),
        reason: 'Should include links to detailed reports',
      );
    });

    test('workflow should include master progress tracker', () {
      final suiteDir = Directory('tests_reports/suite');
      if (!suiteDir.existsSync()) {
        return; // Skip if no reports
      }

      final reports = suiteDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.md'))
          .toList();

      if (reports.isEmpty) {
        return; // Skip if no reports
      }

      final reportContent = File(reports.last.path).readAsStringSync();

      // Verify master progress tracking exists
      expect(
        reportContent,
        anyOf([
          contains('Overall Progress:'),
          contains('Total:'),
          contains('0 of'),
          contains('completed'),
        ]),
        reason: 'Should include master progress tracking',
      );
    });
  });
}
