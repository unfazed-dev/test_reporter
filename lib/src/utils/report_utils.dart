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
  static Future<String> getReportPath(
    String moduleName,
    String timestamp,
  ) async {
    final reportDir = await getReportDirectory();
    return p.join(reportDir, '${moduleName}_test_report@$timestamp.md');
  }
}
