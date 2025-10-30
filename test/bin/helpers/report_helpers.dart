import 'dart:convert';
import 'dart:io';

/// Helpers for validating and extracting data from test reports

/// Extract JSON data from markdown report
Map<String, dynamic>? extractJsonFromReport(String reportContent) {
  final jsonRegex = RegExp(r'```json\s*\n([\s\S]*?)\n```', multiLine: true);
  final match = jsonRegex.firstMatch(reportContent);

  if (match == null) return null;

  try {
    final jsonString = match.group(1)!;
    return jsonDecode(jsonString) as Map<String, dynamic>;
  } catch (e) {
    return null;
  }
}

/// Extract all JSON blocks from a report
List<Map<String, dynamic>> extractAllJsonFromReport(String reportContent) {
  final jsonRegex = RegExp(r'```json\s*\n([\s\S]*?)\n```', multiLine: true);
  final matches = jsonRegex.allMatches(reportContent);

  final results = <Map<String, dynamic>>[];
  for (final match in matches) {
    try {
      final jsonString = match.group(1)!;
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      results.add(data);
    } catch (e) {
      // Skip invalid JSON
    }
  }

  return results;
}

/// Validate report has required sections
bool validateReportStructure(
  String reportContent, {
  List<String> requiredSections = const [],
}) {
  for (final section in requiredSections) {
    if (!reportContent.contains(section)) {
      return false;
    }
  }
  return true;
}

/// Extract coverage percentage from report
double? extractCoveragePercentage(String reportContent) {
  final coverageRegex = RegExp(r'(?:Line Coverage|Coverage):\s*(\d+\.?\d*)%');
  final match = coverageRegex.firstMatch(reportContent);

  if (match == null) return null;

  return double.tryParse(match.group(1)!);
}

/// Extract test count from report
int? extractTestCount(String reportContent, {String label = 'Total tests'}) {
  final testRegex = RegExp('$label[^\\d]+(\\d+)');
  final match = testRegex.firstMatch(reportContent);

  if (match == null) return null;

  return int.tryParse(match.group(1)!);
}

/// Extract pass rate from report
double? extractPassRate(String reportContent) {
  final passRateRegex = RegExp(r'Pass rate[^:]*:\s*(\d+\.?\d*)%');
  final match = passRateRegex.firstMatch(reportContent);

  if (match == null) return null;

  return double.tryParse(match.group(1)!);
}

/// Create a temporary test file
File createTempTestFile(String content, {String? name}) {
  final tempDir = Directory.systemTemp.createTempSync('test_analyzer_test_');
  final fileName = name ?? 'temp_test.dart';
  final file = File('${tempDir.path}/$fileName');
  file.writeAsStringSync(content);
  return file;
}

/// Create a temporary directory structure
Directory createTempDirectory({Map<String, String>? files}) {
  final tempDir = Directory.systemTemp.createTempSync('test_analyzer_test_');

  if (files != null) {
    for (final entry in files.entries) {
      final file = File('${tempDir.path}/${entry.key}');
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(entry.value);
    }
  }

  return tempDir;
}

/// Clean up temporary directory
void cleanupTempDirectory(Directory dir) {
  if (dir.existsSync()) {
    dir.deleteSync(recursive: true);
  }
}

/// Validate report naming convention
bool validateReportName(String fileName) {
  // Expected format: {module}_test_report_{type}@HHMM_DDMMYY.md
  final nameRegex = RegExp(
    r'^[a-zA-Z0-9_-]+_test_report_(coverage|analyzer|failed|unified)@\d{4}_\d{6}\.md$',
  );
  return nameRegex.hasMatch(fileName);
}

/// Extract module name from report file name
String? extractModuleFromFileName(String fileName) {
  final match = RegExp('^([a-zA-Z0-9_-]+)_test_report_').firstMatch(fileName);
  return match?.group(1);
}

/// Extract report type from file name
String? extractReportType(String fileName) {
  final match = RegExp('_test_report_([a-zA-Z]+)@').firstMatch(fileName);
  return match?.group(1);
}

/// Extract timestamp from report file name
String? extractTimestamp(String fileName) {
  final match = RegExp(r'@(\d{4}_\d{6})\.md$').firstMatch(fileName);
  return match?.group(1);
}

/// Validate JSON structure has required keys
bool validateJsonStructure(
  Map<String, dynamic> json, {
  List<String> requiredKeys = const [],
}) {
  for (final key in requiredKeys) {
    if (!json.containsKey(key)) {
      return false;
    }
  }
  return true;
}

/// Find latest report in directory
File? findLatestReport(Directory dir, {String? type}) {
  if (!dir.existsSync()) return null;

  final files = dir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.md'))
      .toList();

  if (type != null) {
    files.removeWhere((f) => !f.path.contains('_test_report_$type@'));
  }

  if (files.isEmpty) return null;

  // Sort by modification time (most recent first)
  files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

  return files.first;
}

/// Count reports in directory
int countReports(Directory dir, {String? type}) {
  if (!dir.existsSync()) return 0;

  var files =
      dir.listSync().whereType<File>().where((f) => f.path.endsWith('.md'));

  if (type != null) {
    files = files.where((f) => f.path.contains('_test_report_$type@'));
  }

  return files.length;
}

/// Extract health score from unified report
double? extractHealthScore(String reportContent) {
  final scoreRegex = RegExp(r'Health Score[^:]*:\s*(\d+\.?\d*)');
  final match = scoreRegex.firstMatch(reportContent);

  if (match == null) return null;

  return double.tryParse(match.group(1)!);
}

/// Validate report contains link to other reports
bool hasReportLink(String reportContent, String linkText) {
  return reportContent.contains(linkText) && reportContent.contains('.md');
}

/// Create sample lcov file
File createSampleLcovFile({String? content}) {
  final tempDir = Directory.systemTemp.createTempSync('test_analyzer_test_');
  final file = File('${tempDir.path}/lcov.info');
  file.writeAsStringSync(content ??
      '''
TN:
SF:lib/src/example.dart
DA:1,1
DA:2,1
DA:3,0
LF:3
LH:2
end_of_record
''');
  return file;
}

/// Parse simple lcov data
Map<String, Map<String, int>> parseLcovData(String lcovContent) {
  final files = <String, Map<String, int>>{};
  String? currentFile;
  int totalLines = 0;
  int hitLines = 0;

  for (final line in lcovContent.split('\n')) {
    if (line.startsWith('SF:')) {
      currentFile = line.substring(3);
    } else if (line.startsWith('LF:')) {
      totalLines = int.parse(line.substring(3));
    } else if (line.startsWith('LH:')) {
      hitLines = int.parse(line.substring(3));
    } else if (line == 'end_of_record' && currentFile != null) {
      files[currentFile] = {
        'total': totalLines,
        'hit': hitLines,
      };
      currentFile = null;
    }
  }

  return files;
}
