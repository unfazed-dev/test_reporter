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
import 'package:test_reporter/src/utils/checklist_utils.dart';
import 'package:test_reporter/src/utils/module_identifier.dart';
import 'package:test_reporter/src/utils/path_resolver.dart';
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
    this.enableChecklist = true,
    this.minimalChecklist = false,
    this.explicitModuleName,
    this.testPathOverride,
    this.sourcePathOverride,
  });

  final String testPath;
  final int runs;
  final bool performance;
  final bool verbose;
  final bool parallel;
  final bool enableChecklist;
  final bool minimalChecklist;
  final String? explicitModuleName;
  final String? testPathOverride;
  final String? sourcePathOverride;

  final Map<String, dynamic> results = {};
  final List<String> failures = [];
  final Map<String, String> reportPaths = {};

  /// Extract module name from test path for report naming (or use explicit override)
  String extractModuleName() {
    return explicitModuleName ??
        ModuleIdentifier.getQualifiedModuleName(testPath);
  }

  /// Detect source path from test path for coverage analysis
  ///
  /// Maps test paths to their corresponding source paths using PathResolver.
  /// This ensures coverage analysis runs on SOURCE code, not test files.
  String detectSourcePath(String inputPath) {
    return PathResolver.inferSourcePath(inputPath) ?? 'lib/src';
  }

  /// Detect test path from source path for test analysis
  ///
  /// Maps source paths to their corresponding test paths using PathResolver.
  String detectTestPath(String inputPath) {
    return PathResolver.inferTestPath(inputPath) ?? 'test/';
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
      // Detect source path from test path for coverage analysis
      final sourcePath = detectSourcePath(testPath);

      if (verbose) {
        print('  [INFO] Test path: $testPath');
        print('  [INFO] Source path for coverage: $sourcePath');
      }

      final args = <String>[
        'run',
        'test_reporter:analyze_coverage',
        sourcePath,
      ];

      if (verbose) {
        args.add('--verbose');
        print('  [DEBUG] Running analyze_coverage on: $sourcePath');
      }

      if (!enableChecklist) {
        args.add('--no-checklist');
      } else if (minimalChecklist) {
        args.add('--minimal-checklist');
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
      // Detect test path from input for test analysis
      final actualTestPath = detectTestPath(testPath);

      if (verbose) {
        print('  [INFO] Input path: $testPath');
        print('  [INFO] Test path for analysis: $actualTestPath');
      }

      final args = <String>[
        'run',
        'test_reporter:analyze_tests',
        actualTestPath,
        '--runs=$runs',
      ];

      if (performance) args.add('--performance');
      if (verbose) {
        args.add('--verbose');
        print('  [DEBUG] Running analyze_tests on: $actualTestPath');
      }
      if (parallel) args.add('--parallel');

      if (!enableChecklist) {
        args.add('--no-checklist');
      } else if (minimalChecklist) {
        args.add('--minimal-checklist');
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
        String s when s.contains('_coverage') => 'quality',
        String s when s.contains('_tests') => 'reliability',
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

    // Master Workflow Checklist
    if (enableChecklist) {
      report.writeln(_generateMasterWorkflow(minimal: minimalChecklist));
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
          '- 📊 **[Test Reliability Analysis](../reliability/$analyzerFile)** - Flaky tests, performance metrics, test behavior');
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
          '- 📈 **[Coverage Analysis](../quality/$coverageFile)** - Code coverage breakdown, untested code, testability');
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

      // Delete intermediate reports (coverage and tests)
      // The suite report already contains all their data in embedded JSON
      // NOTE: We keep the detailed coverage and reliability reports
      // The unified suite report is just a summary - users need the detailed reports

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
      }

      // Clean up old suite and failures reports
      if (verbose) print('\n🧹 Cleaning up old suite reports...');
      await ReportUtils.cleanOldReports(
        pathName: moduleName,
        prefixPatterns: [
          'report_suite',
          'report_failures',
        ],
        verbose: verbose,
      );

      // Clean up ALL empty subdirectories
      if (verbose) print('\n🧹 Cleaning up empty report directories...');
      await _cleanupEmptyDirectories(verbose);

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

  /// Generate master workflow checklist combining all action items
  ///
  /// Creates a 3-phase workflow:
  /// - Phase 1: Critical Issues (failing tests, low coverage)
  /// - Phase 2: Stability Issues (flaky tests)
  /// - Phase 3: Optimization (slow tests)
  String _generateMasterWorkflow({bool minimal = false}) {
    final buffer = StringBuffer();

    buffer.writeln('## ✅ Recommended Workflow');
    buffer.writeln();

    // Extract data from results
    final coverageData = results['coverage'] as Map<String, dynamic>?;
    final testData = results['test_analysis'] as Map<String, dynamic>?;

    final coverageSummary = coverageData?['summary'] as Map<String, dynamic>?;
    final testSummary = testData?['summary'] as Map<String, dynamic>?;

    final consistentFailures =
        (testSummary?['consistent_failures'] as int?) ?? 0;
    final flakyTests = (testSummary?['flaky_tests'] as int?) ?? 0;
    final slowTests = (testSummary?['slow_tests'] as int?) ?? 0;
    final overallCoverage =
        toDouble(coverageSummary?['overall_coverage']) ?? 100.0;

    if (minimal) {
      // Minimal mode: compact checklist
      buffer.writeln('Quick action items to improve test suite:');
      buffer.writeln();

      if (consistentFailures > 0) {
        buffer.writeln(
            '- [ ] 🔴 Fix $consistentFailures failing test${consistentFailures == 1 ? '' : 's'}');
      }
      if (overallCoverage < 80) {
        buffer.writeln(
            '- [ ] 🔴 Increase coverage to 80% (current: ${overallCoverage.toStringAsFixed(1)}%)');
      }
      if (flakyTests > 0) {
        buffer.writeln(
            '- [ ] 🟠 Stabilize $flakyTests flaky test${flakyTests == 1 ? '' : 's'}');
      }
      if (slowTests > 0) {
        buffer.writeln(
            '- [ ] 🟡 Optimize $slowTests slow test${slowTests == 1 ? '' : 's'}');
      }

      buffer.writeln();
      buffer.writeln(
          '**Quick Command**: `dart run test_reporter:analyze_suite test/`');
      buffer.writeln();
      return buffer.toString();
    }

    // Full mode: detailed 3-phase workflow
    buffer.writeln('Follow this 3-phase approach to improve your test suite:');
    buffer.writeln();

    // Phase 1: Critical Issues
    final phase1Items = <ChecklistItem>[];

    if (consistentFailures > 0) {
      phase1Items.add(ChecklistItem(
        text:
            'Fix $consistentFailures failing test${consistentFailures == 1 ? '' : 's'}',
        tip: 'These tests fail consistently. Priority: High',
        command: 'dart test --name="<test_name>"',
      ));
    }

    if (overallCoverage < 80) {
      final missingCoverage = (80 - overallCoverage).toStringAsFixed(1);
      phase1Items.add(ChecklistItem(
        text: 'Increase test coverage by $missingCoverage%',
        tip: 'Current: ${overallCoverage.toStringAsFixed(1)}%, Target: 80%',
        command: 'dart run test_reporter:analyze_coverage lib/src --fix',
      ));
    }

    if (phase1Items.isNotEmpty) {
      final phase1 = ChecklistSection(
        title: '### 🔴 Phase 1: Critical Issues',
        subtitle:
            'Address these issues first - they directly impact functionality',
        items: phase1Items,
        priority: ChecklistPriority.critical,
      );
      buffer.writeln(phase1.toMarkdown());
      buffer.writeln(
          '**Progress:** 0 of ${phase1Items.length} critical issues resolved');
      buffer.writeln();
    }

    // Phase 2: Stability Issues
    final phase2Items = <ChecklistItem>[];

    if (flakyTests > 0) {
      phase2Items.add(ChecklistItem(
        text: 'Stabilize $flakyTests flaky test${flakyTests == 1 ? '' : 's'}',
        tip: 'These tests pass sometimes and fail other times',
        command: 'dart run test_reporter:analyze_tests test/ --runs=10',
      ));
    }

    if (phase2Items.isNotEmpty) {
      final phase2 = ChecklistSection(
        title: '### 🟠 Phase 2: Stability',
        subtitle: 'Improve test reliability and consistency',
        items: phase2Items,
        priority: ChecklistPriority.important,
      );
      buffer.writeln(phase2.toMarkdown());
      buffer.writeln(
          '**Progress:** 0 of ${phase2Items.length} stability issues resolved');
      buffer.writeln();
    }

    // Phase 3: Optimization
    final phase3Items = <ChecklistItem>[];

    if (slowTests > 0) {
      phase3Items.add(ChecklistItem(
        text: 'Optimize $slowTests slow test${slowTests == 1 ? '' : 's'}',
        tip: 'Improve test execution time for faster feedback',
        command: 'dart run test_reporter:analyze_tests test/ --performance',
      ));
    }

    if (phase3Items.isNotEmpty) {
      final phase3 = ChecklistSection(
        title: '### 🟡 Phase 3: Optimization',
        subtitle: 'Enhance performance and developer experience',
        items: phase3Items,
        priority: ChecklistPriority.optional,
      );
      buffer.writeln(phase3.toMarkdown());
      buffer.writeln(
          '**Progress:** 0 of ${phase3Items.length} optimizations completed');
      buffer.writeln();
    }

    // Overall progress tracker
    final totalItems =
        phase1Items.length + phase2Items.length + phase3Items.length;
    if (totalItems > 0) {
      buffer.writeln('---');
      buffer.writeln();
      buffer.writeln(
          '**Overall Progress:** 0 of $totalItems items completed (0.0%)');
      buffer.writeln();

      // Links to detailed reports
      buffer.writeln('**📄 Detailed Reports:**');
      if (reportPaths['coverage'] != null) {
        buffer.writeln('- Coverage: `${reportPaths['coverage']}`');
      }
      if (reportPaths['analyzer'] != null) {
        buffer.writeln('- Test Reliability: `${reportPaths['analyzer']}`');
      }
      buffer.writeln();
    } else {
      buffer.writeln('**🎉 All clear!** No action items at this time.');
      buffer.writeln();
      buffer.writeln('Continue maintaining your excellent test suite quality.');
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Clean up all empty report subdirectories
  ///
  /// Checks reliability/, quality/, failures/, and suite/ subdirectories
  /// and deletes them if they contain no reports
  Future<void> _cleanupEmptyDirectories(bool verbose) async {
    try {
      final reportDir = await ReportUtils.getReportDirectory();
      final subdirs = ['reliability', 'quality', 'failures', 'suite'];

      for (final subdir in subdirs) {
        final dir = Directory(p.join(reportDir, subdir));
        if (await dir.exists()) {
          final isEmpty = await dir.list().isEmpty;
          if (isEmpty) {
            await dir.delete();
            if (verbose) print('  🗑️  Removed empty $subdir/ directory');
          }
        }
      }
    } catch (e) {
      if (verbose) print('  ⚠️  Error cleaning up directories: $e');
    }
  }
}
