import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:test_reporter/src/utils/report_manager.dart';

/// Report file management utilities
class ReportUtils {
  /// Get the report directory path for the current project
  /// Creates 'tests_reports/' in project root if it doesn't exist
  /// Respects ReportManager.overrideReportsRoot() for testing
  static Future<String> getReportDirectory() async {
    final currentDir = Directory.current;
    final reportsRoot = ReportManager.reportsRoot;
    final reportDir = Directory(p.join(currentDir.path, reportsRoot));

    if (!await reportDir.exists()) {
      await reportDir.create(recursive: true);
    }

    return reportDir.path;
  }

  /// Cleans old reports matching the specified patterns.
  ///
  /// Removes old reports keeping only the latest timestamp per pattern.
  ///
  /// **Naming Format**: `{pathName}_{pattern}@{timestamp}.{ext}`
  ///
  /// **Example**: `flaky-fi_report_tests@2153_041125.md`
  ///
  /// **Parameters**:
  /// - [pathName]: Module name (e.g., `'flaky-fi'`, `'auth_service-fo'`)
  /// - [prefixPatterns]: Patterns to match (e.g., `['report_tests']`)
  /// - [subdirectory]: Optional subdirectory filter (`'reliability'`, `'quality'`, etc.)
  /// - [verbose]: Print detailed cleanup information
  /// - [keepLatest]: Keep the latest report (default: true)
  /// - [baseDir]: Optional base directory (for testing). Defaults to project's tests_reports/
  ///
  /// **Cleanup Strategy**:
  /// 1. Groups reports by pattern
  /// 2. Sorts by timestamp (newest first)
  /// 3. Keeps only the latest report per pattern
  /// 4. Deletes all older reports
  ///
  /// **Example**:
  /// ```dart
  /// await ReportUtils.cleanOldReports(
  ///   pathName: 'flaky-fi',
  ///   prefixPatterns: ['report_tests'],
  ///   subdirectory: 'reliability',
  ///   verbose: true,
  /// );
  /// ```
  static Future<void> cleanOldReports({
    required String pathName,
    required List<String> prefixPatterns,
    String? subdirectory,
    bool verbose = false,
    bool keepLatest = true,
    String? baseDir,
  }) async {
    final reportDir = baseDir ?? await getReportDirectory();

    // List of subdirectories to clean
    final subdirs = subdirectory != null
        ? [subdirectory]
        : ['reliability', 'quality', 'failures', 'suite'];

    for (final subdir in subdirs) {
      final dir = Directory(p.join(reportDir, subdir));
      if (!await dir.exists()) continue;

      // Group files by pattern
      final filesByPattern = <String, List<File>>{};

      await for (final file in dir.list()) {
        if (file is! File) continue;

        final fileName = file.path.split('/').last;
        if (verbose) print('  🔎 Checking file: $fileName in $subdir');

        for (final pattern in prefixPatterns) {
          // Match pattern: {pathName}_{pattern}@{timestamp}.{ext}
          final matchPattern = '${pathName}_$pattern@';

          if (verbose) {
            print('    Looking for pattern: $matchPattern');
          }

          if (fileName.startsWith(matchPattern)) {
            if (verbose) print('    ✅ MATCHED pattern: $pattern');
            filesByPattern.putIfAbsent(pattern, () => []).add(file);
            break;
          }
        }
      }

      // For each pattern, keep all files with the latest timestamp
      for (final entry in filesByPattern.entries) {
        final files = entry.value;
        if (files.isEmpty) continue;

        // Group files by timestamp (extract from @timestamp.ext pattern)
        final filesByTimestamp = <String, List<File>>{};
        for (final file in files) {
          final fileName = file.path.split('/').last;
          // Extract timestamp: modulename_pattern@HHMM_DDMMYY.ext
          final atIndex = fileName.lastIndexOf('@');
          final dotIndex = fileName.lastIndexOf('.');
          if (atIndex != -1 && dotIndex != -1) {
            final timestamp = fileName.substring(atIndex + 1, dotIndex);
            filesByTimestamp.putIfAbsent(timestamp, () => []).add(file);
          }
        }

        if (filesByTimestamp.isEmpty) continue;

        // Sort timestamps (newest first)
        final sortedTimestamps = filesByTimestamp.keys.toList()
          ..sort((a, b) => b.compareTo(a));

        // Keep all files with the latest timestamp, delete the rest
        final latestTimestamp = sortedTimestamps.first;

        for (final timestamp in sortedTimestamps) {
          if (!keepLatest || timestamp != latestTimestamp) {
            for (final file in filesByTimestamp[timestamp]!) {
              try {
                final fileName = file.path.split('/').last;
                await file.delete();
                if (verbose) print('  🗑️  Removed old report: $fileName');
              } catch (e) {
                if (verbose) {
                  print(
                      '  ⚠️  Failed to delete ${file.path.split('/').last}: $e');
                }
              }
            }
          }
        }
      }
    }
  }

  /// Create directory if it doesn't exist
  static Future<void> ensureDirectoryExists(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  /// Get full report path for a module
  ///
  /// Organizes reports into subdirectories based on tool suffix:
  /// - 'coverage' -> quality/
  /// - 'tests' -> reliability/
  /// - 'failures' -> failures/
  /// - '' (empty) -> suite/
  ///
  /// Naming convention: {name}-{fo|fi}_report_{tool}@timestamp.md
  /// - fo = folder
  /// - fi = file
  static Future<String> getReportPath(
    String moduleName,
    String timestamp, {
    String suffix = '',
    String? baseDir,
  }) async {
    final reportDir = baseDir ?? await getReportDirectory();

    // Determine subdirectory based on suffix
    // Suffix should be full tool name: coverage, tests, failures, or empty for suite
    final subdir = switch (suffix) {
      'coverage' => 'quality',
      'tests' => 'reliability',
      'failures' => 'failures',
      _ => 'suite',
    };

    // Create subdirectory if it doesn't exist
    final subdirPath = p.join(reportDir, subdir);
    final subdirDir = Directory(subdirPath);
    if (!await subdirDir.exists()) {
      await subdirDir.create(recursive: true);
    }

    final suffixPart = suffix.isNotEmpty ? '_$suffix' : '';
    return p.join(subdirPath, '${moduleName}_report$suffixPart@$timestamp.md');
  }

  /// Write a unified report with markdown content and embedded JSON data
  ///
  /// This creates a single file with:
  /// - Human-readable markdown at the top
  /// - Machine-parseable JSON embedded at the bottom
  ///
  /// Automatically cleans up old reports for the same module/suffix before writing.
  ///
  /// Example:
  /// ```dart
  /// await ReportUtils.writeUnifiedReport(
  ///   moduleName: 'my_module',
  ///   timestamp: '2025-01-21_14-30-00',
  ///   markdownContent: '# My Report\n\nContent here...',
  ///   jsonData: {'metric': 'value'},
  ///   verbose: true,
  /// );
  /// ```
  static Future<String> writeUnifiedReport({
    required String moduleName,
    required String timestamp,
    required String markdownContent,
    required Map<String, dynamic> jsonData,
    String suffix = '',
    bool verbose = false,
    String? baseDir,
  }) async {
    // NOTE: Cleanup is now handled by the calling code (coverage_tool, test_analyzer, run_all)
    // This prevents accidentally deleting reports that need to be retained for the unified report

    final reportPath = await getReportPath(
      moduleName,
      timestamp,
      suffix: suffix,
      baseDir: baseDir,
    );
    final file = File(reportPath);

    // Build unified report content
    final content = StringBuffer();

    // Add markdown content
    content.write(markdownContent);

    // Add separator
    content.writeln();
    content.writeln('---');
    content.writeln();

    // Add JSON data section
    content.writeln('## 📊 Machine-Readable Data');
    content.writeln();
    content.writeln(
      'The following JSON contains all report data in machine-parseable format:',
    );
    content.writeln();
    content.writeln('```json');
    content.writeln(
      const JsonEncoder.withIndent('  ').convert(jsonData),
    );
    content.writeln('```');

    // Write to file
    await file.writeAsString(content.toString());

    if (verbose) {
      print('  ✅ Report saved to: $reportPath');
    }

    return reportPath;
  }

  /// Extract JSON data from a unified report file
  ///
  /// Returns null if no JSON section is found.
  static Future<Map<String, dynamic>?> extractJsonFromReport(
    String reportPath,
  ) async {
    final file = File(reportPath);
    if (!await file.exists()) return null;

    final content = await file.readAsString();

    // Find the LAST occurrence of ```json (the actual embedded JSON section)
    // This is important because the report content may contain code examples
    // that also include the string '```json'
    final jsonStart = content.lastIndexOf('```json');
    if (jsonStart == -1) return null;

    final jsonEnd = content.indexOf('```', jsonStart + 7);
    if (jsonEnd == -1) return null;

    // Extract and parse JSON
    final jsonString = content.substring(jsonStart + 7, jsonEnd).trim();
    try {
      final decoded = jsonDecode(jsonString);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (e) {
      // Ignore parsing errors and return null
      return null;
    }
  }
}
