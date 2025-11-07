/// LCOV file generator for testing coverage analyzers
///
/// Generates realistic LCOV coverage files for integration tests.
/// Supports line coverage, branch coverage, and multi-file reports.

/// Data class for LCOV file information
class LcovFileData {
  LcovFileData({
    required this.filePath,
    required this.totalLines,
    required this.coveredLines,
    this.totalBranches,
    this.coveredBranches,
  });

  final String filePath;
  final int totalLines;
  final int coveredLines;
  final int? totalBranches;
  final int? coveredBranches;
}

/// Parsed LCOV data
class ParsedLcov {
  ParsedLcov({required this.files});

  final List<LcovFileData> files;
}

/// Generator for LCOV coverage files
class LcovGenerator {
  /// Generate basic LCOV file with line coverage
  static String generate({
    required String filePath,
    int? totalLines,
    int? coveredLines,
    double? coveragePercent,
  }) {
    final total = totalLines ?? 100;
    final covered = coveredLines ??
        (coveragePercent != null ? (total * coveragePercent / 100).round() : 0);

    final buffer = StringBuffer();
    buffer.writeln('SF:$filePath');

    // Generate line data (DA: line_number, hit_count)
    for (var i = 1; i <= total; i++) {
      final hitCount = i <= covered ? 1 : 0;
      buffer.writeln('DA:$i,$hitCount');
    }

    // Summary
    buffer.writeln('LF:$total'); // lines found
    buffer.writeln('LH:$covered'); // lines hit
    buffer.writeln('end_of_record');

    return buffer.toString();
  }

  /// Generate LCOV with branch coverage
  static String generateWithBranches({
    required String filePath,
    required int totalLines,
    required int coveredLines,
    required int totalBranches,
    required int coveredBranches,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('SF:$filePath');

    // Line data
    for (var i = 1; i <= totalLines; i++) {
      final hitCount = i <= coveredLines ? 1 : 0;
      buffer.writeln('DA:$i,$hitCount');
    }

    // Branch data (BRDA: line,block,branch,taken)
    for (var i = 0; i < totalBranches; i++) {
      final line = (i * 2) + 1; // Distribute branches across lines
      final taken = i < coveredBranches ? 1 : 0;
      buffer.writeln('BRDA:$line,0,$i,$taken');
    }

    // Summary
    buffer.writeln('LF:$totalLines');
    buffer.writeln('LH:$coveredLines');
    buffer.writeln('BRF:$totalBranches'); // branches found
    buffer.writeln('BRH:$coveredBranches'); // branches hit
    buffer.writeln('end_of_record');

    return buffer.toString();
  }

  /// Generate LCOV for multiple files
  static String generateMultiple(List<LcovFileData> files) {
    final buffer = StringBuffer();

    for (final file in files) {
      buffer.writeln('SF:${file.filePath}');

      // Line data
      for (var i = 1; i <= file.totalLines; i++) {
        final hitCount = i <= file.coveredLines ? 1 : 0;
        buffer.writeln('DA:$i,$hitCount');
      }

      // Summary
      buffer.writeln('LF:${file.totalLines}');
      buffer.writeln('LH:${file.coveredLines}');

      // Branch data if available
      if (file.totalBranches != null && file.coveredBranches != null) {
        buffer.writeln('BRF:${file.totalBranches}');
        buffer.writeln('BRH:${file.coveredBranches}');
      }

      buffer.writeln('end_of_record');
    }

    return buffer.toString();
  }

  /// Generate LCOV with specific line details
  static String generateWithLineDetails({
    required String filePath,
    required List<int> coveredLines,
    required List<int> uncoveredLines,
  }) {
    final allLines = [...coveredLines, ...uncoveredLines]..sort();
    final totalLines = allLines.length;
    final buffer = StringBuffer();

    buffer.writeln('SF:$filePath');

    // Generate line data
    for (final line in allLines) {
      final hitCount = coveredLines.contains(line) ? 1 : 0;
      buffer.writeln('DA:$line,$hitCount');
    }

    // Summary
    buffer.writeln('LF:$totalLines');
    buffer.writeln('LH:${coveredLines.length}');
    buffer.writeln('end_of_record');

    return buffer.toString();
  }

  /// Generate realistic Dart package LCOV
  static String generateRealisticDartPackage({
    required String packageName,
    required int fileCount,
    required double avgCoveragePercent,
  }) {
    final files = <LcovFileData>[];

    for (var i = 0; i < fileCount; i++) {
      final fileName = 'file_${i + 1}.dart';
      final filePath = 'lib/src/$fileName';
      final totalLines = 50 + (i * 10); // Varying file sizes
      final covered = (totalLines * avgCoveragePercent / 100).round();

      files.add(LcovFileData(
        filePath: filePath,
        totalLines: totalLines,
        coveredLines: covered,
      ));
    }

    return generateMultiple(files);
  }

  /// Generate realistic Flutter package LCOV
  static String generateRealisticFlutterPackage({
    required String packageName,
    required int fileCount,
    required double avgCoveragePercent,
  }) {
    final files = <LcovFileData>[];

    // Add lib files
    for (var i = 0; i < fileCount; i++) {
      final fileName = 'widget_${i + 1}.dart';
      final filePath = 'lib/$fileName';
      final totalLines = 80 + (i * 15); // Larger files for Flutter
      final covered = (totalLines * avgCoveragePercent / 100).round();

      files.add(LcovFileData(
        filePath: filePath,
        totalLines: totalLines,
        coveredLines: covered,
      ));
    }

    return generateMultiple(files);
  }

  /// Parse LCOV content
  static ParsedLcov parse(String lcovContent) {
    final files = <LcovFileData>[];
    String? currentFile;
    int? totalLines;
    int? coveredLines;

    for (final line in lcovContent.split('\n')) {
      if (line.startsWith('SF:')) {
        currentFile = line.substring(3);
      } else if (line.startsWith('LF:')) {
        totalLines = int.parse(line.substring(3));
      } else if (line.startsWith('LH:')) {
        coveredLines = int.parse(line.substring(3));
      } else if (line == 'end_of_record') {
        if (currentFile != null && totalLines != null && coveredLines != null) {
          files.add(LcovFileData(
            filePath: currentFile,
            totalLines: totalLines,
            coveredLines: coveredLines,
          ));
        }
        // Reset for next file
        currentFile = null;
        totalLines = null;
        coveredLines = null;
      }
    }

    return ParsedLcov(files: files);
  }
}
