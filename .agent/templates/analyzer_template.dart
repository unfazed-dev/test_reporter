/// Template for creating a new analyzer tool
///
/// Steps to use this template:
/// 1. Copy this file to lib/src/bin/your_analyzer_lib.dart
/// 2. Replace YOUR_ANALYZER with your analyzer name
/// 3. Implement the core analysis logic
/// 4. Create corresponding bin/your_analyzer.dart entry point
/// 5. Add to pubspec.yaml executables
/// 6. Test and document

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:test_reporter/src/utils/report_utils.dart';

/// YOUR_ANALYZER - Description of what this analyzer does
///
/// Features:
/// - Feature 1
/// - Feature 2
/// - Feature 3
class YourAnalyzer {
  YourAnalyzer({
    required this.targetPath,
    this.verbose = false,
    this.option1 = false,
    this.option2 = 'default',
  });

  final String targetPath;
  final bool verbose;
  final bool option1;
  final String option2;

  // Analysis results storage
  final Map<String, dynamic> results = {};
  final List<String> issues = [];

  /// Main entry point for the analyzer
  Future<int> run() async {
    try {
      printHeader();
      await analyze();
      await generateReport();
      return issues.isEmpty ? 0 : 1;
    } catch (e) {
      print('\n❌ Analysis failed: $e');
      return 2;
    }
  }

  /// Print analyzer header
  void printHeader() {
    print('╔════════════════════════════════════════╗');
    print('║  YOUR_ANALYZER - Description          ║');
    print('╚════════════════════════════════════════╝');
    print('');
    print('Target: $targetPath');
    print('Options: option1=$option1, option2=$option2');
    print('');
  }

  /// Core analysis logic
  Future<void> analyze() async {
    if (verbose) print('🔍 Starting analysis...');

    // TODO: Implement your analysis logic here
    // Examples:
    // - Find and scan files
    // - Parse content
    // - Detect patterns
    // - Collect metrics
    // - Identify issues

    if (verbose) print('✅ Analysis complete');
  }

  /// Generate markdown and JSON reports
  Future<void> generateReport() async {
    final moduleName = extractModuleName(targetPath);
    final timestamp = generateTimestamp();

    // Clean old reports
    await ReportUtils.cleanOldReports(
      pathName: moduleName,
      prefixPatterns: ['your_report_type'],
      subdirectory: 'your_subdir',
      verbose: verbose,
    );

    // Generate reports
    final markdown = generateMarkdownReport();
    final json = generateJsonReport();

    // Save reports
    final reportDir = await ReportUtils.getReportDirectory();
    final subdir = Directory('$reportDir/your_subdir');
    if (!await subdir.exists()) {
      await subdir.create(recursive: true);
    }

    final mdPath = '$reportDir/your_subdir/${moduleName}_your_report_type@$timestamp.md';
    final jsonPath = '$reportDir/your_subdir/${moduleName}_your_report_type@$timestamp.json';

    await File(mdPath).writeAsString(markdown);
    await File(jsonPath).writeAsString(json);

    print('\n📝 Reports generated:');
    print('   Markdown: $mdPath');
    print('   JSON: $jsonPath');
  }

  /// Generate markdown report
  String generateMarkdownReport() {
    final buffer = StringBuffer();

    buffer.writeln('# YOUR_ANALYZER Report - $targetPath');
    buffer.writeln();
    buffer.writeln('Generated: ${DateTime.now()}');
    buffer.writeln();

    buffer.writeln('## 📊 Summary');
    buffer.writeln();
    buffer.writeln('- **Total Items**: ${results.length}');
    buffer.writeln('- **Issues Found**: ${issues.length}');
    buffer.writeln();

    if (issues.isNotEmpty) {
      buffer.writeln('## ❌ Issues');
      buffer.writeln();
      for (final issue in issues) {
        buffer.writeln('- $issue');
      }
      buffer.writeln();
    }

    buffer.writeln('## 📋 Details');
    buffer.writeln();
    // TODO: Add detailed report sections

    return buffer.toString();
  }

  /// Generate JSON report
  String generateJsonReport() {
    return jsonEncode({
      'meta': {
        'tool': 'your_analyzer',
        'version': '2.0.0',
        'timestamp': DateTime.now().toIso8601String(),
        'targetPath': targetPath,
      },
      'summary': {
        'totalItems': results.length,
        'issuesFound': issues.length,
      },
      'issues': issues,
      'results': results,
    });
  }

  /// Extract module name from path
  String extractModuleName(String path) {
    final normalized = path.replaceAll(r'\', '/').replaceAll(RegExp(r'/$'), '');
    final segments = normalized.split('/').where((s) => s.isNotEmpty).toList();

    if (segments.isEmpty) return 'all-fo';

    var moduleName = segments.last;

    if (moduleName.endsWith('.dart')) {
      moduleName = moduleName.substring(0, moduleName.length - 5);
      return '$moduleName-fi';
    }

    return '$moduleName-fo';
  }

  /// Generate timestamp in format HHMM_DDMMYY
  String generateTimestamp() {
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final year = now.year.toString().substring(2);

    return '${hour}${minute}_$day$month$year';
  }
}

/// Main entry point with CLI argument parsing
void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      'path',
      abbr: 'p',
      help: 'Path to analyze',
      defaultsTo: '.',
    )
    ..addFlag(
      'verbose',
      abbr: 'v',
      help: 'Verbose output',
      negatable: false,
    )
    ..addFlag(
      'option1',
      help: 'Description of option1',
      negatable: false,
    )
    ..addOption(
      'option2',
      help: 'Description of option2',
      defaultsTo: 'default',
    )
    ..addFlag(
      'help',
      abbr: 'h',
      help: 'Show this help message',
      negatable: false,
    );

  ArgResults args;
  try {
    args = parser.parse(arguments);
  } catch (e) {
    print('Error: $e\n');
    print(parser.usage);
    exit(2);
  }

  if (args['help'] as bool) {
    print('YOUR_ANALYZER - Description');
    print('\nUsage: dart your_analyzer.dart [options]\n');
    print(parser.usage);
    exit(0);
  }

  final analyzer = YourAnalyzer(
    targetPath: args['path'] as String,
    verbose: args['verbose'] as bool,
    option1: args['option1'] as bool,
    option2: args['option2'] as String,
  );

  final exitCode = await analyzer.run();
  exit(exitCode);
}
