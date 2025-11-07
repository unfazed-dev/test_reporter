import 'dart:convert';
import 'dart:io';

// Report directory structure
const _reportsRoot = 'tests_reports';

/// Report types with their corresponding subdirectories
enum ReportType {
  /// Coverage analysis reports → quality/
  coverage,

  /// Test reliability reports → reliability/
  tests,

  /// Failed test extraction reports → failures/
  failures,

  /// Unified suite reports → suite/
  suite,
}

/// Extension to get subdirectory names from report types
extension ReportTypeExtension on ReportType {
  String get subdirectory {
    return switch (this) {
      ReportType.coverage => 'quality',
      ReportType.tests => 'reliability',
      ReportType.failures => 'failures',
      ReportType.suite => 'suite',
    };
  }
}

/// Report generation context
///
/// Tracks all metadata for a report through its lifecycle
class ReportContext {
  /// Qualified module name (e.g., auth-service-fo)
  final String moduleName;

  /// Report type (determines subdirectory)
  final ReportType type;

  /// Tool name (e.g., analyze-coverage, analyze-tests)
  final String toolName;

  /// Generation timestamp
  final DateTime timestamp;

  /// Unique identifier for this report
  final String reportId;

  const ReportContext({
    required this.moduleName,
    required this.type,
    required this.toolName,
    required this.timestamp,
    required this.reportId,
  });

  /// Get subdirectory for this report type
  String get subdirectory => type.subdirectory;

  /// Get base filename without extension
  ///
  /// Format: {moduleName}_{toolName}_{type}@{YYYYMMDD-HHMMSS}-{reportId}
  String get baseFilename {
    final dateStr = _formatTimestamp(timestamp);
    return '${moduleName}_${toolName}_${type.subdirectory}@$dateStr-$reportId';
  }

  /// Format timestamp as YYYYMMDD-HHMMSS
  String _formatTimestamp(DateTime dt) {
    final year = dt.year.toString().padLeft(4, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final second = dt.second.toString().padLeft(2, '0');
    return '$year$month$day-$hour$minute$second';
  }
}

/// Manages complete report lifecycle with atomic operations
class ReportManager {
  // Allow overriding reports root for testing
  static String? _testReportsRoot;

  /// Override reports root directory (for testing)
  static void overrideReportsRoot(String path) {
    _testReportsRoot = path;
  }

  /// Get the actual reports root (respects test override)
  static String get _actualReportsRoot => _testReportsRoot ?? _reportsRoot;

  /// Get the reports root directory path (public - for ReportUtils)
  static String get reportsRoot => _actualReportsRoot;

  /// Start a report generation context
  ///
  /// Returns context for tracking this report through lifecycle
  static ReportContext startReport({
    required String moduleName,
    required ReportType type,
    required String toolName,
  }) {
    return ReportContext(
      moduleName: moduleName,
      type: type,
      toolName: toolName,
      timestamp: DateTime.now(),
      reportId: _generateReportId(),
    );
  }

  /// Write report with automatic cleanup
  ///
  /// Steps:
  /// 1. Generate unique filename with timestamp
  /// 2. Write markdown file
  /// 3. Write JSON file
  /// 4. Clean old reports (keep latest N)
  ///
  /// Returns path to markdown report
  static Future<String> writeReport(
    ReportContext context, {
    required String markdownContent,
    required Map<String, dynamic> jsonData,
    int keepCount = 1,
  }) async {
    // Ensure directory exists
    final reportDir = getReportDirectory(context.type);
    await Directory(reportDir).create(recursive: true);

    // Generate filenames
    final markdownFilename = generateFilename(context, 'md');
    final jsonFilename = generateFilename(context, 'json');

    final markdownPath = '$reportDir/$markdownFilename';
    final jsonPath = '$reportDir/$jsonFilename';

    // Write markdown file
    await File(markdownPath).writeAsString(markdownContent);

    // Write JSON file
    final jsonContent = JsonEncoder.withIndent('  ').convert(jsonData);
    await File(jsonPath).writeAsString(jsonContent);

    // Cleanup old reports
    await cleanupReports(
      moduleName: context.moduleName,
      type: context.type,
      keepCount: keepCount,
    );

    return markdownPath;
  }

  /// Find latest report matching criteria
  ///
  /// Useful for orchestrator to read reports from other tools
  static Future<String?> findLatestReport({
    required String moduleName,
    required ReportType type,
    String? toolName,
  }) async {
    final reportDir = getReportDirectory(type);
    final dir = Directory(reportDir);

    if (!await dir.exists()) {
      return null;
    }

    // List all markdown files
    final files = await dir
        .list()
        .where((entity) =>
            entity is File &&
            entity.path.endsWith('.md') &&
            entity.path.contains(moduleName))
        .map((entity) => entity as File)
        .toList();

    if (files.isEmpty) {
      return null;
    }

    // Filter by tool name if provided
    final filteredFiles = toolName != null
        ? files.where((f) => f.path.contains(toolName)).toList()
        : files;

    if (filteredFiles.isEmpty) {
      return null;
    }

    // Sort by path (filename contains timestamp, so this works)
    filteredFiles.sort((a, b) => b.path.compareTo(a.path));

    return filteredFiles.first.path;
  }

  /// Manual cleanup (usually not needed - writeReport does this)
  static Future<void> cleanupReports({
    required String moduleName,
    required ReportType type,
    int keepCount = 1,
    bool dryRun = false,
  }) async {
    final reportDir = getReportDirectory(type);
    final dir = Directory(reportDir);

    if (!await dir.exists()) {
      return;
    }

    // List all files for this module
    final allFiles = await dir
        .list()
        .where((entity) => entity is File && entity.path.contains(moduleName))
        .map((entity) => entity as File)
        .toList();

    if (allFiles.isEmpty) {
      return;
    }

    // Group by extension (md and json files are paired)
    final mdFiles = allFiles.where((f) => f.path.endsWith('.md')).toList()
      ..sort((a, b) => b.path.compareTo(a.path)); // Newest first

    final jsonFiles = allFiles.where((f) => f.path.endsWith('.json')).toList()
      ..sort((a, b) => b.path.compareTo(a.path)); // Newest first

    // Keep only the latest N reports
    final mdFilesToDelete = mdFiles.skip(keepCount).toList();
    final jsonFilesToDelete = jsonFiles.skip(keepCount).toList();

    // Delete old files
    if (!dryRun) {
      for (final file in [...mdFilesToDelete, ...jsonFilesToDelete]) {
        if (await file.exists()) {
          await file.delete();
        }
      }
    }
  }

  /// Get report directory for a type
  static String getReportDirectory(ReportType type) {
    return '$_actualReportsRoot/${type.subdirectory}';
  }

  /// Generate filename from context
  static String generateFilename(ReportContext context, String extension) {
    return '${context.baseFilename}.$extension';
  }

  /// Extract JSON from markdown report (for orchestrator)
  ///
  /// Reads the corresponding JSON file for a markdown report
  static Future<Map<String, dynamic>?> extractJsonFromReport(
      String reportPath) async {
    // Convert .md path to .json path
    final jsonPath = reportPath.replaceAll('.md', '.json');
    final jsonFile = File(jsonPath);

    if (!await jsonFile.exists()) {
      return null;
    }

    try {
      final content = await jsonFile.readAsString();
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Generate unique report ID
  static String _generateReportId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }
}
