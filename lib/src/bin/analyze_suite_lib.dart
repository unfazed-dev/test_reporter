/// # Analyze Suite - Unified Test Analysis Orchestrator
///
/// Runs all test reporter tools and generates a single comprehensive report.
///
/// ## Quick Start
/// ```bash
/// dart analyze_suite.dart                          # Run all tools with defaults
/// dart analyze_suite.dart --runs=5                 # Configure test runs
/// dart analyze_suite.dart --performance            # Enable performance analysis
/// dart analyze_suite.dart --path=test/mymodule     # Specific test path
/// dart analyze_suite.dart --verbose                # Detailed output
/// ```
///
/// ## What It Does
/// 1. Runs analyze_coverage to analyze test coverage
/// 2. Runs analyze_tests to detect flaky tests and patterns
/// 3. Combines results into a single comprehensive report
/// 4. Provides unified insights and recommendations
///
/// ## Report Output
/// - Saves to `tests_reports/`
/// - Format: `{module_name}_report@HHMM_DDMMYY.md`
/// - Includes both markdown (human-readable) and JSON (machine-parseable)
///
/// ## Exit Codes
/// - 0: All tools succeeded
/// - 1: At least one tool failed
/// - 2: Orchestrator error occurred

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test_reporter/src/utils/report_utils.dart';

/// Helper to safely convert numeric values to double
double? toDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
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
  final Map<String, String> reportPaths = {};

  /// Extract module name from test path for report naming
  String extractModuleName() {
    final path = testPath.replaceAll(r'\', '/').replaceAll(RegExp(r'/$'), '');
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();

    if (segments.isEmpty) return 'all_tests-fo';

    var moduleName = segments.last;
    String suffix;

    // If it's a file, extract the test name properly
    if (moduleName.endsWith('.dart')) {
      moduleName = moduleName.substring(0, moduleName.length - 5);
      if (moduleName.endsWith('_test')) {
        moduleName = moduleName.substring(0, moduleName.length - 5);
      }
      suffix = '-fi';
    } else if (moduleName == 'test') {
      return 'test-fo';
    } else {
      // It's a folder
      suffix = '-fo';
    }

    return '$moduleName$suffix';
  }

  Future<void> runAll() async {
    printHeader();

    // Step 1: Run coverage tool
    print('\n📊 Step 1/2: Analyzing test coverage...');
    final coverageSuccess = await runCoverageTool();

    // Step 2: Run test analyzer
    print('\n🧪 Step 2/2: Analyzing test reliability...');
    final analyzerSuccess = await runTestAnalyzer();

    // Step 3: Generate unified report
    print('\n📝 Generating unified report...');
    await generateUnifiedReport();

    // Summary
    printSummary(
        coverageSuccess: coverageSuccess, analyzerSuccess: analyzerSuccess);
  }

  Future<bool> runCoverageTool() async {
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
        'test_reporter:analyze_coverage',
        sourcePath,
        testPath, // Pass testPath for consistent naming
      ];

      if (verbose) {
        args.add('--verbose');
        print(
            '  [DEBUG] Running analyze_coverage with args: $sourcePath $testPath');
      }

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
        // Add small delay to ensure file is fully written
        await Future<void>.delayed(const Duration(milliseconds: 100));
        print('  ✅ Coverage analysis complete');

        // Extract coverage data from most recent report
        final coverageReport = await findLatestReport('report_coverage');
        if (verbose) print('  📊 Coverage report found: $coverageReport');

        if (coverageReport != null) {
          final jsonData = await ReportUtils.extractJsonFromReport(
            coverageReport,
          );

          if (verbose) {
            print(
                '  🔍 JSON extraction result: ${jsonData != null ? 'SUCCESS' : 'FAILED'}');
            if (jsonData != null) {
              print('  📋 JSON keys: ${jsonData.keys.toList()}');
              print('  📊 Coverage summary: ${jsonData['summary']}');
            }
          }

          if (jsonData != null) {
            results['coverage'] = jsonData;
            reportPaths['coverage'] = coverageReport;

            if (verbose) {
              print('  📄 Coverage report retained: $coverageReport');
            }
          } else {
            if (verbose)
              print('  ⚠️  Failed to extract JSON from coverage report');
          }
        } else {
          if (verbose) print('  ⚠️  No coverage report found');
        }

        return true;
      } else {
        print('  ❌ Coverage analysis failed with exit code $exitCode');
        failures.add('analyze_coverage');
        return false;
      }
    } catch (e) {
      print('  ❌ Coverage tool error: $e');
      failures.add('analyze_coverage');
      return false;
    }
  }

  Future<bool> runTestAnalyzer() async {
    try {
      // Determine test path for analyzer
      String actualTestPath = testPath;
      if (testPath.startsWith('lib')) {
        // If given lib path, derive test path
        actualTestPath = testPath.replaceFirst('lib', 'test');

        // If it's a specific file (ends with .dart but not _test.dart), add _test suffix
        if (actualTestPath.endsWith('.dart') &&
            !actualTestPath.endsWith('_test.dart')) {
          actualTestPath = actualTestPath.replaceFirst('.dart', '_test.dart');
        }
      } else if (!testPath.startsWith('test')) {
        // Default to 'test/' if ambiguous
        actualTestPath = 'test/';
      }

      final args = <String>[
        'run',
        'test_reporter:analyze_tests',
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
        final analyzerReport = await findLatestReport('report_tests');
        if (verbose) print('  📊 Analyzer report found: $analyzerReport');

        if (analyzerReport != null) {
          final jsonData = await ReportUtils.extractJsonFromReport(
            analyzerReport,
          );

          if (verbose) {
            print(
                '  🔍 JSON extraction result: ${jsonData != null ? 'SUCCESS' : 'FAILED'}');
            if (jsonData != null) {
              print('  📋 JSON keys: ${jsonData.keys.toList()}');
              print('  📊 Test analysis summary: ${jsonData['summary']}');
            }
          }

          if (jsonData != null) {
            results['test_analysis'] = jsonData;
            reportPaths['analyzer'] = analyzerReport;

            if (verbose) {
              print('  📄 Analyzer report retained: $analyzerReport');
            }
          } else {
            if (verbose)
              print('  ⚠️  Failed to extract JSON from analyzer report');
          }
        } else {
          if (verbose) print('  ⚠️  No analyzer report found');
        }

        return true;
      } else if (exitCode == 1) {
        print('  ⚠️  Test analysis complete with test failures');

        // Still extract data even if tests failed
        final analyzerReport = await findLatestReport('report_tests');
        if (verbose) print('  📊 Analyzer report found: $analyzerReport');

        if (analyzerReport != null) {
          final jsonData = await ReportUtils.extractJsonFromReport(
            analyzerReport,
          );

          if (verbose) {
            print(
                '  🔍 JSON extraction result: ${jsonData != null ? 'SUCCESS' : 'FAILED'}');
            if (jsonData != null) {
              print('  📋 JSON keys: ${jsonData.keys.toList()}');
            }
          }

          if (jsonData != null) {
            results['test_analysis'] = jsonData;
            reportPaths['analyzer'] = analyzerReport;
            if (verbose)
              print('  📄 Analyzer report retained: $analyzerReport');
          } else {
            if (verbose)
              print('  ⚠️  Failed to extract JSON from analyzer report');
          }
        } else {
          if (verbose) print('  ⚠️  No analyzer report found');
        }

        return true; // Don't consider test failures as tool failures
      } else {
        print('  ❌ Test analysis failed with exit code $exitCode');
        failures.add('analyze_tests');
        return false;
      }
    } catch (e) {
      print('  ❌ Test analyzer error: $e');
      failures.add('analyze_tests');
      return false;
    }
  }

  Future<String?> findLatestReport(String prefix) async {
    try {
      final reportDir = await ReportUtils.getReportDirectory();

      // Determine subdirectory based on prefix
      // prefix will be like 'report_coverage' or 'report_tests'
      final subdir = switch (prefix) {
        String s when s.contains('_coverage') => 'coverage',
        String s when s.contains('_tests') => 'tests',
        String s when s.contains('_failures') => 'failures',
        _ => 'suite',
      };

      final searchDir = p.join(reportDir, subdir);
      final dir = Directory(searchDir);

      if (verbose) {
        print('  🔍 Looking for reports with prefix: $prefix in $searchDir');
      }

      if (!await dir.exists()) {
        if (verbose) print('  ⚠️  Report directory does not exist: $searchDir');
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

  Future<void> generateUnifiedReport() async {
    final report = StringBuffer();
    final coverage = results['coverage'] as Map<String, dynamic>?;
    final testAnalysis = results['test_analysis'] as Map<String, dynamic>?;

    // Get summary data
    final coverageSummary = coverage?['summary'] as Map<String, dynamic>?;
    final testSummary = testAnalysis?['summary'] as Map<String, dynamic>?;
    final overallCoverage = toDouble(coverageSummary?['overall_coverage']);
    final passRate = toDouble(testSummary?['pass_rate']);
    final stabilityScore = toDouble(testSummary?['stability_score']);
    final totalTests = testSummary?['total_tests'] as int? ?? 0;
    final consistentFailures = testSummary?['consistent_failures'] as int? ?? 0;
    final flakyTests = testSummary?['flaky_tests'] as int? ?? 0;

    // Calculate overall health score
    final healthScore = calculateHealthScore(
      overallCoverage,
      passRate,
      stabilityScore,
    );
    final healthStatus = getHealthStatus(healthScore);

    // Header with health badge
    report.writeln('# 📊 Test Suite Health Dashboard');
    report.writeln();
    report.writeln(
        '> **Overall Health:** $healthStatus **${healthScore.toStringAsFixed(1)}%**');
    report.writeln();
    report.writeln('**Generated:** ${DateTime.now().toLocal()}');
    report.writeln('**Module:** `$testPath`');
    report.writeln('**Analysis Runs:** $runs');
    report.writeln();
    report.writeln('---');
    report.writeln();

    // At-a-Glance Summary
    report.writeln('## 🎯 At-a-Glance Summary');
    report.writeln();
    report.writeln('| Metric | Value | Status |');
    report.writeln('|--------|-------|--------|');
    report.writeln(
        '| **Test Coverage** | ${overallCoverage?.toStringAsFixed(1) ?? "N/A"}% | ${getCoverageStatus(overallCoverage)} |');
    report.writeln(
        '| **Pass Rate** | ${passRate?.toStringAsFixed(1) ?? "N/A"}% | ${getPassRateStatus(passRate)} |');
    report.writeln(
        '| **Stability** | ${stabilityScore?.toStringAsFixed(1) ?? "N/A"}% | ${getStabilityStatus(stabilityScore)} |');
    report.writeln(
        '| **Total Tests** | $totalTests | ${totalTests > 0 ? "✅" : "⚠️"} |');
    report.writeln(
        '| **Failures** | $consistentFailures | ${consistentFailures == 0 ? "✅" : "❌"} |');
    report.writeln(
        '| **Flaky Tests** | $flakyTests | ${flakyTests == 0 ? "✅" : "⚠️"} |');
    report.writeln();

    // Critical Issues First
    final insights = generateInsights();
    final criticalIssues =
        insights.where((i) => i['severity'] == '🔴 Critical').toList();
    final warnings =
        insights.where((i) => i['severity'] == '🟠 Warning').toList();

    if (criticalIssues.isNotEmpty || warnings.isNotEmpty) {
      report.writeln('## 🚨 Issues Requiring Attention');
      report.writeln();

      if (criticalIssues.isNotEmpty) {
        report.writeln('### 🔴 Critical');
        report.writeln();
        for (var i = 0; i < criticalIssues.length; i++) {
          report.writeln('${i + 1}. ${criticalIssues[i]['message']}');
        }
        report.writeln();
      }

      if (warnings.isNotEmpty) {
        report.writeln('### 🟠 Warnings');
        report.writeln();
        for (var i = 0; i < warnings.length; i++) {
          report.writeln('${i + 1}. ${warnings[i]['message']}');
        }
        report.writeln();
      }
    } else {
      report.writeln('## ✅ All Systems Green');
      report.writeln();
      report.writeln('No issues detected. Test suite is healthy!');
      report.writeln();
    }

    // Quick Actions
    report.writeln('## ⚡ Quick Actions');
    report.writeln();
    final recommendations = generateRecommendations();
    if (recommendations.isNotEmpty) {
      for (var i = 0; i < recommendations.length; i++) {
        report.writeln('${i + 1}. ${recommendations[i]}');
      }
      report.writeln();
    } else {
      report.writeln(
          '✅ No actions required. Continue maintaining current quality standards.');
      report.writeln();
    }

    // Detailed Metrics Breakdown
    report.writeln('## 📈 Detailed Metrics');
    report.writeln();

    // Coverage breakdown
    if (coverageSummary != null) {
      report.writeln('### Code Coverage');
      report.writeln();
      report.writeln('```');
      report.writeln(
          '├─ Overall:  ${overallCoverage?.toStringAsFixed(1) ?? "N/A"}%');
      report.writeln(
          '├─ Lines:    ${coverageSummary['covered_lines']}/${coverageSummary['total_lines']}');
      report
          .writeln('├─ Uncovered: ${coverageSummary['uncovered_lines']} lines');
      report.writeln(
          '└─ Files:    ${coverageSummary['files_analyzed']} analyzed');
      report.writeln('```');
      report.writeln();
    }

    // Test reliability breakdown
    if (testSummary != null) {
      report.writeln('### Test Reliability');
      report.writeln();
      report.writeln('```');
      report.writeln('├─ Total Tests:      $totalTests');
      report.writeln(
          '├─ Pass Rate:        ${passRate?.toStringAsFixed(1) ?? "N/A"}%');
      report.writeln(
          '├─ Stability Score:  ${stabilityScore?.toStringAsFixed(1) ?? "N/A"}%');
      report.writeln(
          '├─ Passed:           ${testSummary['passed_consistently']}');
      report.writeln('├─ Failed:           $consistentFailures');
      report.writeln('└─ Flaky:            $flakyTests');
      report.writeln('```');
      report.writeln();
    }

    // Related Reports with actual file links
    report.writeln('## 📑 Detailed Reports');
    report.writeln();
    report.writeln('For in-depth analysis, see specialized reports:');
    report.writeln();

    // Add links to actual report files
    if (reportPaths.containsKey('analyzer')) {
      final analyzerFile = p.basename(reportPaths['analyzer']!);
      report.writeln(
          '- 📊 **[Test Reliability Analysis](../analyzer/$analyzerFile)** - Flaky tests, performance metrics, test behavior');
    } else {
      report.writeln('- 📊 **Test Reliability Analysis** - ⚠️ Not available');
    }

    if (reportPaths.containsKey('failed')) {
      final failedFile = p.basename(reportPaths['failed']!);
      report.writeln(
          '- 🔴 **[Failed Tests Report](../failed/$failedFile)** - Failure triage, root causes, suggested fixes');
    } else if (flakyTests > 0 || consistentFailures > 0) {
      report.writeln(
          '- 🔴 **Failed Tests Report** - ⚠️ Not generated (check logs)');
    }

    if (reportPaths.containsKey('coverage')) {
      final coverageFile = p.basename(reportPaths['coverage']!);
      report.writeln(
          '- 📈 **[Coverage Analysis](../coverage/$coverageFile)** - Code coverage breakdown, untested code, testability');
    } else {
      report.writeln('- 📈 **Coverage Analysis** - ⚠️ Not available');
    }
    report.writeln();

    // Execution Info
    report.writeln('---');
    report.writeln();
    report.writeln('### 🔧 Execution Details');
    report.writeln();
    report.writeln('| Tool | Status |');
    report.writeln('|------|--------|');
    report.writeln(
        '| Coverage Analysis | ${failures.contains("analyze_coverage") ? "❌ Failed" : "✅ Success"} |');
    report.writeln(
        '| Test Reliability Analysis | ${failures.contains("analyze_tests") ? "❌ Failed" : "✅ Success"} |');
    report.writeln();
    report.writeln('*Generated by Unified Test Analysis Orchestrator*');
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

      final moduleName = extractModuleName();
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
            'analyze_coverage': !failures.contains('analyze_coverage'),
            'analyze_tests': !failures.contains('analyze_tests'),
          },
        },
        suffix: 'suite',
        verbose: true,
      );

      print('  ✅ Unified report saved to: $reportPath');

      // Check if there are failures to determine if we need a failed report
      final analysisData = results['test_analysis'] as Map<String, dynamic>?;
      final analysisSummary = analysisData?['summary'] as Map<String, dynamic>?;
      final numConsistentFailures =
          analysisSummary?['consistent_failures'] as int? ?? 0;
      final numFlakyTests = analysisSummary?['flaky_tests'] as int? ?? 0;
      final hasFailures = numConsistentFailures > 0 || numFlakyTests > 0;

      if (hasFailures) {
        // Generate failed report if there are failures or flaky tests
        await generateFailedReport(results, moduleName, timestamp);
      } else {
        // Delete any existing failed reports if no failures exist
        if (verbose)
          print('\n🧹 No failures - cleaning up old failed reports...');
        await ReportUtils.cleanOldReports(
          pathName: moduleName,
          prefixPatterns: ['report_failures'],
          verbose: verbose,
          keepLatest:
              false, // Delete all failed reports when there are no failures
        );

        // Delete the failures subdirectory if it's empty
        final reportDir = await ReportUtils.getReportDirectory();
        final failedDir = Directory(p.join(reportDir, 'failures'));
        if (await failedDir.exists()) {
          final isEmpty = await failedDir.list().isEmpty;
          if (isEmpty) {
            await failedDir.delete();
            if (verbose) print('  🗑️  Removed empty failed directory');
          }
        }
      }

      // Clean up old reports, keeping only the latest for each type
      if (verbose) print('\n🧹 Cleaning up old reports...');
      await ReportUtils.cleanOldReports(
        pathName: moduleName,
        prefixPatterns: [
          'report_coverage',
          'report_tests',
          'report_suite',
          'report_failures'
        ],
        verbose: verbose,
      );
      if (verbose) print('  ✅ Cleanup complete');
    } catch (e) {
      print('  ⚠️  Could not save unified report: $e');
    }
  }

  Future<void> generateFailedReport(
    Map<String, dynamic> results,
    String moduleName,
    String timestamp,
  ) async {
    final testAnalysis = results['test_analysis'] as Map<String, dynamic>?;
    if (testAnalysis == null) return;

    final summary = testAnalysis['summary'] as Map<String, dynamic>?;
    if (summary == null) return;

    final consistentFailures = summary['consistent_failures'] as int? ?? 0;
    final flakyTests = summary['flaky_tests'] as int? ?? 0;

    // Only generate failed report if there are issues
    if (consistentFailures == 0 && flakyTests == 0) return;

    print('\n📝 Generating failed test report...');

    final markdown = StringBuffer();
    markdown.writeln('# 🔴 Failed Test Report');
    markdown.writeln();
    markdown.writeln('**Generated:** ${DateTime.now().toLocal()}');
    markdown.writeln('**Test Path:** `$testPath`');
    markdown.writeln('**Source:** Unified Test Analysis Orchestrator');
    markdown.writeln();

    markdown.writeln('## 📊 Summary');
    markdown.writeln();
    markdown.writeln('| Metric | Value |');
    markdown.writeln('|--------|-------|');
    markdown.writeln('| Total Tests | ${summary['total_tests'] ?? 'N/A'} |');
    markdown.writeln(
        '| Passed Consistently | ${summary['passed_consistently'] ?? 'N/A'} |');
    markdown.writeln('| Consistent Failures | ❌ $consistentFailures |');
    markdown.writeln('| Flaky Tests | ⚠️ $flakyTests |');
    final passRate = summary['pass_rate'] as num?;
    markdown
        .writeln('| Pass Rate | ${passRate?.toStringAsFixed(1) ?? 'N/A'}% |');
    markdown.writeln();

    // Add consistent failures section
    if (consistentFailures > 0) {
      markdown.writeln('## ❌ Consistent Failures');
      markdown.writeln('*Tests that failed all runs*');
      markdown.writeln();

      final failures = testAnalysis['consistent_failures'] as List<dynamic>?;
      if (failures != null && failures.isNotEmpty) {
        for (final failure in failures) {
          final failureMap = failure as Map<String, dynamic>;
          final testName = failureMap['test_name'] ?? 'Unknown';
          final file = failureMap['file'] ?? 'Unknown';
          final failureType = failureMap['failure_type'] ?? 'Unknown';
          final category = failureMap['category'] ?? '';
          final suggestion = failureMap['suggestion'] ?? '';

          markdown.writeln('### $testName');
          markdown.writeln('**File:** `$file`');
          markdown.writeln('**Type:** $failureType');
          if (category is String && category.isNotEmpty) {
            markdown.writeln('**Category:** $category');
          }
          if (suggestion is String && suggestion.isNotEmpty) {
            markdown.writeln();
            markdown.writeln('**Suggested Fix:**');
            markdown.writeln('```');
            markdown.writeln(suggestion);
            markdown.writeln('```');
          }
          markdown.writeln();
        }
      }
    }

    // Add flaky tests section
    if (flakyTests > 0) {
      markdown.writeln('## ⚡ Flaky Tests');
      markdown.writeln('*Tests with intermittent failures*');
      markdown.writeln();

      final flaky = testAnalysis['flaky_tests'] as List<dynamic>?;
      if (flaky != null && flaky.isNotEmpty) {
        for (final test in flaky) {
          final testMap = test as Map<String, dynamic>;
          final testName = testMap['test_name'] ?? 'Unknown';
          final file = testMap['file'] ?? 'Unknown';
          final successRate = testMap['success_rate'] as num?;
          final runs = testMap['runs'] as Map<String, dynamic>?;

          markdown.writeln('### $testName');
          markdown.writeln('**File:** `$file`');
          if (successRate != null) {
            markdown.writeln(
                '**Success Rate:** ${successRate.toStringAsFixed(1)}%');
          }

          if (runs != null && runs.isNotEmpty) {
            markdown.writeln('**Run Results:**');
            for (final entry in runs.entries) {
              final status = entry.value == true ? '✅' : '❌';
              markdown.writeln('- ${entry.key}: $status');
            }
          }
          markdown.writeln();
        }
      }
    }

    // Add recommendations
    markdown.writeln('## 💡 Recommendations');
    markdown.writeln();
    if (consistentFailures > 0) {
      markdown.writeln(
          '1. **🔴 Critical:** Fix $consistentFailures consistently failing tests immediately');
    }
    if (flakyTests > 0) {
      markdown.writeln(
          '${consistentFailures > 0 ? '2' : '1'}. **⚠️ Important:** Investigate and stabilize $flakyTests flaky tests');
    }
    markdown.writeln();
    markdown.writeln(
        'For detailed analysis and stack traces, see the analyzer report.');

    // Build JSON data
    final jsonData = {
      'metadata': {
        'tool': 'run_all',
        'version': '1.0',
        'generated': DateTime.now().toIso8601String(),
        'test_path': testPath,
        'source': 'unified_orchestrator',
      },
      'summary': {
        'totalTests': summary['total_tests'] ?? 0,
        'passedConsistently': summary['passed_consistently'] ?? 0,
        'consistentFailures': consistentFailures,
        'flakyTests': flakyTests,
        'passRate': summary['pass_rate'] ?? 0.0,
      },
      'consistent_failures': testAnalysis['consistent_failures'] ?? <dynamic>[],
      'flaky_tests': testAnalysis['flaky_tests'] ?? <dynamic>[],
    };

    try {
      final failedReportPath = await ReportUtils.writeUnifiedReport(
        moduleName: moduleName,
        timestamp: timestamp,
        markdownContent: markdown.toString(),
        jsonData: jsonData,
        suffix: 'failures',
        verbose: verbose,
      );

      reportPaths['failed'] = failedReportPath;
      print('  ✅ Failed test report saved to: $failedReportPath');
    } catch (e) {
      print('  ⚠️  Could not save failed report: $e');
    }
  }

  List<Map<String, String>> generateInsights() {
    final insights = <Map<String, String>>[];

    // Coverage insights
    final coverage = results['coverage'] as Map<String, dynamic>?;
    if (coverage != null) {
      final summary = coverage['summary'] as Map<String, dynamic>?;
      if (summary != null) {
        final overallCoverage = toDouble(summary['overall_coverage']);
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

        final passRate = toDouble(summary['pass_rate']);
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

  List<String> generateRecommendations() {
    final recommendations = <String>[];

    // Coverage recommendations
    final coverage = results['coverage'] as Map<String, dynamic>?;
    if (coverage != null) {
      final summary = coverage['summary'] as Map<String, dynamic>?;
      if (summary != null) {
        final overallCoverage = toDouble(summary['overall_coverage']);
        if (overallCoverage != null && overallCoverage < 80) {
          recommendations.add(
            'Increase test coverage - run `dart run test_reporter:analyze_coverage --fix` to generate missing tests',
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

  void printHeader() {
    print('\n${"═" * 70}');
    print('   UNIFIED TEST ANALYSIS ORCHESTRATOR');
    print('${"═" * 70}\n');
    print('📍 Test Path: $testPath');
    print('🔄 Analysis Runs: $runs');
    print('⚡ Performance: ${performance ? "Enabled" : "Disabled"}');
    print('🔊 Verbose: ${verbose ? "Enabled" : "Disabled"}');
    print('');
  }

  void printSummary(
      {required bool coverageSuccess, required bool analyzerSuccess}) {
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

    print('\n📁 Reports saved to: tests_reports/');
    print('');
  }

  /// Calculate overall health score (0-100)
  double calculateHealthScore(
    double? coverage,
    double? passRate,
    double? stability,
  ) {
    final scores = <double>[];
    if (coverage != null) scores.add(coverage);
    if (passRate != null) scores.add(passRate);
    if (stability != null) scores.add(stability);

    if (scores.isEmpty) return 0.0;
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  /// Get health status badge
  String getHealthStatus(double healthScore) {
    if (healthScore >= 90) return '🟢 Excellent';
    if (healthScore >= 75) return '🟡 Good';
    if (healthScore >= 60) return '🟠 Fair';
    return '🔴 Poor';
  }

  /// Get coverage status indicator
  String getCoverageStatus(double? coverage) {
    if (coverage == null) return '❓';
    if (coverage >= 80) return '✅ Excellent';
    if (coverage >= 60) return '🟡 Adequate';
    if (coverage >= 40) return '🟠 Low';
    return '🔴 Critical';
  }

  /// Get pass rate status indicator
  String getPassRateStatus(double? passRate) {
    if (passRate == null) return '❓';
    if (passRate >= 95) return '✅ Excellent';
    if (passRate >= 85) return '🟡 Good';
    if (passRate >= 70) return '🟠 Fair';
    return '🔴 Poor';
  }

  /// Get stability status indicator
  String getStabilityStatus(double? stability) {
    if (stability == null) return '❓';
    if (stability >= 95) return '✅ Stable';
    if (stability >= 85) return '🟡 Mostly Stable';
    if (stability >= 70) return '🟠 Unstable';
    return '🔴 Very Unstable';
  }
}
