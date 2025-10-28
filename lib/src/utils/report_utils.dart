import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

/// Report file management utilities
class ReportUtils {
  /// Get the report directory path for the current project
  /// Creates 'test_analyzer_reports/' in project root if it doesn't exist
  static Future<String> getReportDirectory() async {
    final currentDir = Directory.current;
    final reportDir =
        Directory(p.join(currentDir.path, 'test_analyzer_reports'));

    if (!await reportDir.exists()) {
      await reportDir.create(recursive: true);
    }

    return reportDir.path;
  }

  /// Clean old reports for a specific path pattern
  static Future<void> cleanOldReports({
    required String pathName,
    required List<String> prefixPatterns,
    bool verbose = false,
  }) async {
    final reportDir = await getReportDirectory();
    final dir = Directory(reportDir);

    if (!await dir.exists()) return;

    await for (final file in dir.list()) {
      if (file is! File) continue;

      final fileName = file.path.split('/').last;
      final shouldDelete = prefixPatterns.any(
        (pattern) =>
            fileName.startsWith('${pathName}_$pattern@') ||
            fileName.startsWith('${pathName.replaceAll('_', '')}_${pattern}__'),
      );

      if (shouldDelete) {
        try {
          await file.delete();
          if (verbose) print('  🗑️  Removed old report: $fileName');
        } catch (e) {
          if (verbose) print('  ⚠️  Failed to delete $fileName: $e');
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
  /// - 'coverage' -> coverage/
  /// - 'analyzer' -> analyzer/
  /// - 'failed' -> failed/
  /// - '' (empty) -> unified/
  ///
  /// Naming convention: {name}-{fo|fi}_test_report_{tool}@timestamp.md
  /// - fo = folder
  /// - fi = file
  static Future<String> getReportPath(
    String moduleName,
    String timestamp, {
    String suffix = '',
  }) async {
    final reportDir = await getReportDirectory();

    // Determine subdirectory based on suffix
    // Suffix should be full tool name: coverage, analyzer, failed, or empty for unified
    final subdir = switch (suffix) {
      'coverage' => 'coverage',
      'analyzer' => 'analyzer',
      'failed' => 'failed',
      _ => 'unified',
    };

    // Create subdirectory if it doesn't exist
    final subdirPath = p.join(reportDir, subdir);
    final subdirDir = Directory(subdirPath);
    if (!await subdirDir.exists()) {
      await subdirDir.create(recursive: true);
    }

    final suffixPart = suffix.isNotEmpty ? '_$suffix' : '';
    return p.join(
        subdirPath, '${moduleName}_test_report$suffixPart@$timestamp.md');
  }

  /// Write a unified report with markdown content and embedded JSON data
  ///
  /// This creates a single file with:
  /// - Human-readable markdown at the top
  /// - Machine-parseable JSON embedded at the bottom
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
  }) async {
    final reportPath =
        await getReportPath(moduleName, timestamp, suffix: suffix);
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
