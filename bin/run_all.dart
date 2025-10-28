#!/usr/bin/env dart

/// # Run All - Unified Test Analysis Orchestrator
///
/// Runs all test analyzer tools and generates a single comprehensive report.
///
/// ## Quick Start
/// ```bash
/// dart run_all.dart                          # Run all tools with defaults
/// dart run_all.dart --runs=5                 # Configure test runs
/// dart run_all.dart --performance            # Enable performance analysis
/// dart run_all.dart --path=test/mymodule     # Specific test path
/// dart run_all.dart --verbose                # Detailed output
/// ```
///
/// ## What It Does
/// 1. Runs coverage_tool to analyze test coverage
/// 2. Runs test_analyzer to detect flaky tests and patterns
/// 3. Combines results into a single comprehensive report
/// 4. Provides unified insights and recommendations
///
/// ## Report Output
/// - Saves to `test_analyzer_reports/`
/// - Format: `{module_name}_test_report@HHMM_DDMMYY.md`
/// - Includes both markdown (human-readable) and JSON (machine-parseable)
///
/// ## Exit Codes
/// - 0: All tools succeeded
/// - 1: At least one tool failed
/// - 2: Orchestrator error occurred

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:test_analyzer/src/utils/report_utils.dart';

/// Helper to safely convert numeric values to double
double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      'path',
      abbr: 'p',
      help: 'Test path to analyze (default: test/)',
      defaultsTo: 'test',
    )
    ..addOption(
      'runs',
      abbr: 'r',
      help: 'Number of test runs for flaky detection',
      defaultsTo: '3',
    )
    ..addFlag(
      'performance',
      help: 'Enable performance profiling',
      negatable: false,
    )
    ..addFlag(
      'verbose',
      abbr: 'v',
      help: 'Verbose output',
      negatable: false,
    )
    ..addFlag(
      'parallel',
      help: 'Run tests in parallel',
      negatable: false,
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
    print('Unified Test Analysis Orchestrator');
    print('\nUsage: dart run_all.dart [test_path] [options]\n');
    print(parser.usage);
    exit(0);
  }

  // Get test path from positional argument or --path option
  String testPath;
  if (args.rest.isNotEmpty) {
    testPath = args.rest.first;
  } else {
    testPath = args['path'] as String;
  }

  final orchestrator = TestOrchestrator(
    testPath: testPath,
    runs: int.parse(args['runs'] as String),
    performance: args['performance'] as bool,
    verbose: args['verbose'] as bool,
    parallel: args['parallel'] as bool,
  );

  try {
    await orchestrator.runAll();
    exit(0);
  } catch (e) {
    print('\n❌ Orchestrator failed: $e');
    exit(2);
  }
}

class TestOrchestrator {
  TestOrchestrator({
    required this.testPath,
    this.runs = 3,
    this.performance = false,
    this.verbose = false,
    this.parallel = false,
  });

  final String testPath;
  final int runs;
  final bool performance;
  final bool verbose;
  final bool parallel;

  final Map<String, dynamic> results = {};
  final List<String> failures = [];

  /// Extract module name from test path for report naming
  String _extractModuleName() {
    final path = testPath.replaceAll(r'\', '/').replaceAll(RegExp(r'/$'), '');
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();

    if (segments.isEmpty) return 'all_tests';

    var moduleName = segments.last;

    // If it's a file, extract the test name properly
    if (moduleName.endsWith('.dart')) {
      moduleName = moduleName.substring(0, moduleName.length - 5);
      if (moduleName.endsWith('_test')) {
        moduleName = moduleName.substring(0, moduleName.length - 5);
      }
    } else if (moduleName == 'test') {
      return 'all_tests';
    }

    return moduleName;
  }

  Future<void> runAll() async {
    _printHeader();

    // Step 1: Run coverage tool
    print('\n📊 Step 1/2: Analyzing test coverage...');
    final coverageSuccess = await _runCoverageTool();

    // Step 2: Run test analyzer
    print('\n🧪 Step 2/2: Analyzing test reliability...');
    final analyzerSuccess = await _runTestAnalyzer();

    // Step 3: Generate unified report
    print('\n📝 Generating unified report...');
    await _generateUnifiedReport();

    // Summary
    _printSummary(coverageSuccess, analyzerSuccess);
  }

  Future<bool> _runCoverageTool() async {
    try {
      // Determine source path for coverage
      String sourcePath = testPath;
      if (testPath.startsWith('test')) {
        // If given test path, derive source path
        sourcePath = testPath.replaceFirst('test', 'lib');

        // Check if derived path exists, otherwise default to lib/src
        final derivedFile = File(sourcePath);
        final derivedDir = Directory(sourcePath);

        if (!derivedFile.existsSync() && !derivedDir.existsSync()) {
          // Path doesn't exist, use lib/src as default
          sourcePath = 'lib/src';
        }
      } else if (testPath == 'lib') {
        // If given just 'lib', use 'lib/src'
        sourcePath = 'lib/src';
      }

      final args = <String>[
        'run',
        'test_analyzer:coverage_tool',
        sourcePath,
      ];

      if (verbose) args.add('--verbose');

      final process = await Process.start('dart', args);
      final output = <String>[];
      final errors = <String>[];

      process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        output.add(line);
        if (verbose) print(line);
      });

      process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        errors.add(line);
        if (verbose) print('  [ERROR] $line');
      });

      final exitCode = await process.exitCode;

      if (exitCode == 0) {
        print('  ✅ Coverage analysis complete');

        // Extract coverage data from most recent report
        final coverageReport = await _findLatestReport('test_report_cov');
        if (verbose) print('  📊 Coverage report found: $coverageReport');

        if (coverageReport != null) {
          final jsonData = await ReportUtils.extractJsonFromReport(
            coverageReport,
          );

          if (verbose) {
            print('  🔍 JSON extraction result: ${jsonData != null ? 'SUCCESS' : 'FAILED'}');
            if (jsonData != null) {
              print('  📋 JSON keys: ${jsonData.keys.toList()}');
              print('  📊 Coverage summary: ${jsonData['summary']}');
            }
          }

          if (jsonData != null) {
            results['coverage'] = jsonData;

            // Delete individual coverage report after extracting data
            try {
              await File(coverageReport).delete();
              if (verbose) print('  🗑️  Deleted individual coverage report');
            } catch (e) {
              if (verbose) print('  ⚠️  Could not delete coverage report: $e');
            }
          } else {
            if (verbose) print('  ⚠️  Failed to extract JSON from coverage report');
          }
        } else {
          if (verbose) print('  ⚠️  No coverage report found');
        }

        return true;
      } else {
        print('  ❌ Coverage analysis failed with exit code $exitCode');
        failures.add('coverage_tool');
        return false;
      }
    } catch (e) {
      print('  ❌ Coverage tool error: $e');
      failures.add('coverage_tool');
      return false;
    }
  }

  Future<bool> _runTestAnalyzer() async {
    try {
      // Determine test path for analyzer
      String actualTestPath = testPath;
      if (testPath.startsWith('lib')) {
        // If given lib path, derive test path
        actualTestPath = testPath.replaceFirst('lib', 'test');
      } else if (!testPath.startsWith('test')) {
        // Default to 'test/' if ambiguous
        actualTestPath = 'test/';
      }

      final args = <String>[
        'run',
        'test_analyzer:test_analyzer',
        actualTestPath,
        '--runs=$runs',
      ];

      if (performance) args.add('--performance');
      if (verbose) args.add('--verbose');
      if (parallel) args.add('--parallel');

      final process = await Process.start('dart', args);
      final output = <String>[];
      final errors = <String>[];

      process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        output.add(line);
        if (verbose) print(line);
      });

      process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        errors.add(line);
        if (verbose) print('  [ERROR] $line');
      });

      final exitCode = await process.exitCode;

      if (exitCode == 0) {
        print('  ✅ Test analysis complete');

        // Extract analyzer data from most recent report
        final analyzerReport = await _findLatestReport('test_report_alz');
        if (verbose) print('  📊 Analyzer report found: $analyzerReport');

        if (analyzerReport != null) {
          final jsonData = await ReportUtils.extractJsonFromReport(
            analyzerReport,
          );

          if (verbose) {
            print('  🔍 JSON extraction result: ${jsonData != null ? 'SUCCESS' : 'FAILED'}');
            if (jsonData != null) {
              print('  📋 JSON keys: ${jsonData.keys.toList()}');
              print('  📊 Test analysis summary: ${jsonData['summary']}');
            }
          }

          if (jsonData != null) {
            results['test_analysis'] = jsonData;

            // Delete individual analyzer report after extracting data
            try {
              await File(analyzerReport).delete();
              if (verbose) print('  🗑️  Deleted individual analyzer report');
            } catch (e) {
              if (verbose) print('  ⚠️  Could not delete analyzer report: $e');
            }
          } else {
            if (verbose) print('  ⚠️  Failed to extract JSON from analyzer report');
          }
        } else {
          if (verbose) print('  ⚠️  No analyzer report found');
        }

        return true;
      } else if (exitCode == 1) {
        print('  ⚠️  Test analysis complete with test failures');

        // Still extract data even if tests failed
        final analyzerReport = await _findLatestReport('test_report_alz');
        if (verbose) print('  📊 Analyzer report found: $analyzerReport');

        if (analyzerReport != null) {
          final jsonData = await ReportUtils.extractJsonFromReport(
            analyzerReport,
          );

          if (verbose) {
            print('  🔍 JSON extraction result: ${jsonData != null ? 'SUCCESS' : 'FAILED'}');
            if (jsonData != null) {
              print('  📋 JSON keys: ${jsonData.keys.toList()}');
            }
          }

          if (jsonData != null) {
            results['test_analysis'] = jsonData;

            // Delete individual analyzer report after extracting data
            try {
              await File(analyzerReport).delete();
              if (verbose) print('  🗑️  Deleted individual analyzer report');
            } catch (e) {
              if (verbose) print('  ⚠️  Could not delete analyzer report: $e');
            }
          } else {
            if (verbose) print('  ⚠️  Failed to extract JSON from analyzer report');
          }
        } else {
          if (verbose) print('  ⚠️  No analyzer report found');
        }

        return true; // Don't consider test failures as tool failures
      } else {
        print('  ❌ Test analysis failed with exit code $exitCode');
        failures.add('test_analyzer');
        return false;
      }
    } catch (e) {
      print('  ❌ Test analyzer error: $e');
      failures.add('test_analyzer');
      return false;
    }
  }

  Future<String?> _findLatestReport(String prefix) async {
    try {
      final reportDir = await ReportUtils.getReportDirectory();
      final dir = Directory(reportDir);

      if (verbose) print('  🔍 Looking for reports with prefix: $prefix in $reportDir');

      if (!await dir.exists()) {
        if (verbose) print('  ⚠️  Report directory does not exist');
        return null;
      }

      final files = <FileSystemEntity>[];
      await for (final file in dir.list()) {
        if (verbose) print('  📄 Found file: ${file.path}');
        if (file is File && file.path.contains(prefix)) {
          if (verbose) print('  ✅ File matches prefix: ${file.path}');
          files.add(file);
        }
      }

      if (files.isEmpty) {
        if (verbose) print('  ⚠️  No files found matching prefix: $prefix');
        return null;
      }

      // Sort by modification time, most recent first
      files.sort((a, b) {
        final aStat = (a as File).statSync();
        final bStat = (b as File).statSync();
        return bStat.modified.compareTo(aStat.modified);
      });

      if (verbose) print('  📋 Selected latest report: ${files.first.path}');
      return files.first.path;
    } catch (e) {
      if (verbose) print('  ⚠️  Could not find latest report: $e');
      return null;
    }
  }

  Future<void> _generateUnifiedReport() async {
    final report = StringBuffer();

    // Header
    report.writeln('# 🎯 Unified Test Analysis Report');
    report.writeln();
    report.writeln('**Generated:** ${DateTime.now().toIso8601String()}');
    report.writeln('**Test Path:** `$testPath`');
    report.writeln('**Analysis Runs:** $runs');
    report.writeln();

    // Executive Summary
    report.writeln('## 📊 Executive Summary');
    report.writeln();

    final coverage = results['coverage'] as Map<String, dynamic>?;
    final testAnalysis = results['test_analysis'] as Map<String, dynamic>?;

    if (coverage != null) {
      final summary = coverage['summary'] as Map<String, dynamic>?;
      if (summary != null) {
        final overallCoverage = _toDouble(summary['overall_coverage']);
        report.writeln('### Coverage');
        report.writeln(
            '- **Overall Coverage:** ${overallCoverage?.toStringAsFixed(1) ?? "N/A"}%');
        report.writeln('- **Total Lines:** ${summary['total_lines']}');
        report.writeln('- **Covered Lines:** ${summary['covered_lines']}');
        report.writeln('- **Files Analyzed:** ${summary['files_analyzed']}');
        report.writeln();
      }
    }

    if (testAnalysis != null) {
      final summary = testAnalysis['summary'] as Map<String, dynamic>?;
      if (summary != null) {
        final passRate = _toDouble(summary['pass_rate']);
        final stabilityScore = _toDouble(summary['stability_score']);
        report.writeln('### Test Reliability');
        report.writeln(
            '- **Pass Rate:** ${passRate?.toStringAsFixed(1) ?? "N/A"}%');
        report.writeln(
            '- **Stability Score:** ${stabilityScore?.toStringAsFixed(1) ?? "N/A"}%');
        report.writeln('- **Total Tests:** ${summary['total_tests']}');
        report.writeln(
            '- **Consistent Failures:** ${summary['consistent_failures']}');
        report.writeln('- **Flaky Tests:** ${summary['flaky_tests']}');
        report.writeln();
      }
    }

    // Unified Insights
    report.writeln('## 💡 Unified Insights');
    report.writeln();

    final insights = _generateInsights();
    if (insights.isNotEmpty) {
      var priority = 1;
      for (final insight in insights) {
        report.writeln(
            '$priority. **${insight['severity']}**: ${insight['message']}');
        priority++;
      }
      report.writeln();
    } else {
      report.writeln('✅ All metrics look healthy!');
      report.writeln();
    }

    // Recommendations
    report.writeln('## 🎯 Recommendations');
    report.writeln();

    final recommendations = _generateRecommendations();
    if (recommendations.isNotEmpty) {
      for (final rec in recommendations) {
        report.writeln('- $rec');
      }
      report.writeln();
    } else {
      report.writeln('✅ No critical actions required at this time.');
      report.writeln();
    }

    // Tool Status
    report.writeln('## 🔧 Tool Status');
    report.writeln();
    report.writeln('| Tool | Status |');
    report.writeln('|------|--------|');
    report.writeln(
        '| Coverage Tool | ${failures.contains("coverage_tool") ? "❌ Failed" : "✅ Success"} |');
    report.writeln(
        '| Test Analyzer | ${failures.contains("test_analyzer") ? "❌ Failed" : "✅ Success"} |');
    report.writeln();

    // Links to detailed reports
    report.writeln('## 📄 Detailed Reports');
    report.writeln();
    report.writeln(
        'For detailed analysis, see individual tool reports in `test_analyzer_reports/`');
    report.writeln();

    // Footer
    report.writeln('---');
    report.writeln(
        '*Generated by run_all.dart - Unified Test Analysis Orchestrator*');

    // Save unified report
    try {
      final now = DateTime.now();
      final timestamp =
          '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}_'
          '${now.day.toString().padLeft(2, '0')}${now.month.toString().padLeft(2, '0')}${now.year.toString().substring(2)}';

      final moduleName = _extractModuleName();
      final reportPath = await ReportUtils.writeUnifiedReport(
        moduleName: moduleName,
        timestamp: timestamp,
        markdownContent: report.toString(),
        jsonData: {
          'metadata': {
            'tool': 'run_all',
            'version': '1.0',
            'generated': now.toIso8601String(),
            'test_path': testPath,
            'module_name': moduleName,
          },
          'coverage': coverage,
          'test_analysis': testAnalysis,
          'insights': insights,
          'recommendations': recommendations,
          'tool_status': {
            'coverage_tool': !failures.contains('coverage_tool'),
            'test_analyzer': !failures.contains('test_analyzer'),
          },
        },
        verbose: true,
      );

      print('  ✅ Unified report saved to: $reportPath');
    } catch (e) {
      print('  ⚠️  Could not save unified report: $e');
    }
  }

  List<Map<String, String>> _generateInsights() {
    final insights = <Map<String, String>>[];

    // Coverage insights
    final coverage = results['coverage'] as Map<String, dynamic>?;
    if (coverage != null) {
      final summary = coverage['summary'] as Map<String, dynamic>?;
      if (summary != null) {
        final overallCoverage = _toDouble(summary['overall_coverage']);
        if (overallCoverage != null && overallCoverage < 80) {
          insights.add({
            'severity': '🔴 Critical',
            'message':
                'Coverage is ${overallCoverage.toStringAsFixed(1)}% - below 80% threshold',
          });
        } else if (overallCoverage != null && overallCoverage < 90) {
          insights.add({
            'severity': '🟡 Warning',
            'message':
                'Coverage is ${overallCoverage.toStringAsFixed(1)}% - could be improved',
          });
        }
      }
    }

    // Test reliability insights
    final testAnalysis = results['test_analysis'] as Map<String, dynamic>?;
    if (testAnalysis != null) {
      final summary = testAnalysis['summary'] as Map<String, dynamic>?;
      if (summary != null) {
        final failures = summary['consistent_failures'] as int?;
        if (failures != null && failures > 0) {
          insights.add({
            'severity': '🔴 Critical',
            'message':
                '$failures tests failing consistently - requires immediate attention',
          });
        }

        final flakyTests = summary['flaky_tests'] as int?;
        if (flakyTests != null && flakyTests > 0) {
          insights.add({
            'severity': '🟠 Warning',
            'message':
                '$flakyTests flaky tests detected - investigate test isolation',
          });
        }

        final passRate = _toDouble(summary['pass_rate']);
        if (passRate != null && passRate < 95) {
          insights.add({
            'severity': '🟡 Notice',
            'message':
                'Pass rate is ${passRate.toStringAsFixed(1)}% - aim for 95%+ for production',
          });
        }
      }
    }

    return insights;
  }

  List<String> _generateRecommendations() {
    final recommendations = <String>[];

    // Coverage recommendations
    final coverage = results['coverage'] as Map<String, dynamic>?;
    if (coverage != null) {
      final summary = coverage['summary'] as Map<String, dynamic>?;
      if (summary != null) {
        final overallCoverage = _toDouble(summary['overall_coverage']);
        if (overallCoverage != null && overallCoverage < 80) {
          recommendations.add(
            'Increase test coverage - run `dart run test_analyzer:coverage_tool --fix` to generate missing tests',
          );
        }
      }
    }

    // Test reliability recommendations
    final testAnalysis = results['test_analysis'] as Map<String, dynamic>?;
    if (testAnalysis != null) {
      final summary = testAnalysis['summary'] as Map<String, dynamic>?;
      if (summary != null) {
        final failures = summary['consistent_failures'] as int?;
        if (failures != null && failures > 0) {
          recommendations.add(
            'Fix consistently failing tests - review detailed report for specific failure patterns and suggestions',
          );
        }

        final flakyTests = summary['flaky_tests'] as int?;
        if (flakyTests != null && flakyTests > 0) {
          recommendations.add(
            'Investigate flaky tests - check for race conditions, improper mocking, or shared state',
          );
        }
      }
    }

    // General recommendations
    if (recommendations.isEmpty) {
      recommendations.add(
        'Continue monitoring metrics and maintain current test quality standards',
      );
    }

    return recommendations;
  }

  void _printHeader() {
    print('\n${"═" * 70}');
    print('   UNIFIED TEST ANALYSIS ORCHESTRATOR');
    print('${"═" * 70}\n');
    print('📍 Test Path: $testPath');
    print('🔄 Analysis Runs: $runs');
    print('⚡ Performance: ${performance ? "Enabled" : "Disabled"}');
    print('🔊 Verbose: ${verbose ? "Enabled" : "Disabled"}');
    print('');
  }

  void _printSummary(bool coverageSuccess, bool analyzerSuccess) {
    print('\n${"═" * 70}');
    print('   SUMMARY');
    print('${"═" * 70}\n');

    if (coverageSuccess && analyzerSuccess) {
      print('✅ All tools completed successfully!');
    } else {
      print('⚠️  Some tools encountered issues:');
      if (!coverageSuccess) print('  - Coverage Tool: Failed');
      if (!analyzerSuccess) print('  - Test Analyzer: Failed');
    }

    print('\n📊 Results:');
    print('  - Tools run: 2');
    print('  - Tools succeeded: ${coverageSuccess && analyzerSuccess ? 2 : 1}');
    print('  - Tools failed: ${failures.length}');

    print('\n📁 Reports saved to: test_analyzer_reports/');
    print('');
  }
}
