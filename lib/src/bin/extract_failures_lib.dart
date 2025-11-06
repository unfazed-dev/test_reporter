/// # Failed Test Extractor - Flutter/Dart Test Failure Analysis Tool
///
/// A specialized tool that extracts and reruns only failing tests from Flutter test suites.
/// Uses JSON reporter output to parse test results and identify failures for targeted re-execution.
///
/// ## Quick Start
/// ```bash
/// flutter pub run analyzer/failed_test_extractor.dart test/                  # Extract and rerun failed tests
/// flutter pub run analyzer/failed_test_extractor.dart test/auth --list      # List failed tests only
/// flutter pub run analyzer/failed_test_extractor.dart test/ --watch         # Continuous monitoring
/// flutter pub run analyzer/failed_test_extractor.dart test/ --save-results  # Save failure report
/// ```
///
/// ## Core Features
/// - **Failed Test Detection**: Runs tests with JSON reporter and extracts only failures
/// - **Smart Rerun Commands**: Generates optimized commands to rerun only failed tests
/// - **Batch Processing**: Groups failed tests by file for efficient re-execution
/// - **Watch Mode**: Continuously monitor and rerun failed tests on file changes
/// - **Detailed Reporting**: Provides comprehensive failure analysis and statistics
/// - **Integration Ready**: Works with existing analyzer framework and CI/CD pipelines
///
/// ## Output Sections
/// 1. **Test Execution Summary**: Total tests run, pass/fail counts, execution time
/// 2. **Failed Test List**: Detailed list of failed tests with file paths and reasons
/// 3. **Rerun Commands**: Copy-pasteable commands to rerun specific failed tests
/// 4. **Failure Analysis**: Pattern analysis of failure types and common issues
/// 5. **Recommendations**: Suggested fixes and next steps for addressing failures

import 'dart:async';
import 'dart:convert';
import 'dart:io';

// CLI argument parsing
import 'package:args/args.dart';
import 'package:test_reporter/src/utils/module_identifier.dart';
import 'package:test_reporter/src/utils/report_utils.dart';

/// Represents a failed test with detailed information
class FailedTest {
  FailedTest({
    required this.name,
    required this.filePath,
    required this.testId,
    this.group,
    this.error,
    this.stackTrace,
    this.runtime,
  });
  final String name;
  final String filePath;
  final String? group;
  final String? error;
  final String? stackTrace;
  final Duration? runtime;
  final String testId;

  @override
  String toString() => '$filePath: $name';
}

/// Represents test execution results
class TestResults {
  TestResults({
    required this.failedTests,
    required this.totalTests,
    required this.passedTests,
    required this.totalTime,
    required this.timestamp,
  });
  final List<FailedTest> failedTests;
  final int totalTests;
  final int passedTests;
  final Duration totalTime;
  final DateTime timestamp;

  int get failedCount => failedTests.length;
  double get successRate =>
      totalTests > 0 ? (passedTests / totalTests) * 100 : 0;
}

/// Main class for extracting and managing failed tests
class FailedTestExtractor {
  FailedTestExtractor() {
    _setupArgParser();
  }
  late ArgParser _parser;
  late ArgResults _args;

  final Map<String, String> _testIdToName = {};
  final Map<String, String> _testIdToFile = {};
  final Map<String, String?> _testIdToGroup = {};
  final Map<String, String> _suiteIdToPath = {};
  final List<FailedTest> _failedTests = [];

  int _totalTests = 0;
  int _passedTests = 0;
  Duration _totalTime = Duration.zero;

  void _setupArgParser() {
    _parser = ArgParser()
      ..addFlag(
        'help',
        abbr: 'h',
        help: 'Show usage information',
        negatable: false,
      )
      ..addFlag(
        'list-only',
        abbr: 'l',
        help: 'List failed tests without rerunning them',
        negatable: false,
      )
      ..addFlag(
        'auto-rerun',
        abbr: 'r',
        help: 'Automatically rerun failed tests after extraction',
        defaultsTo: true,
      )
      ..addFlag(
        'watch',
        abbr: 'w',
        help: 'Watch mode: continuously monitor and rerun failed tests',
        negatable: false,
      )
      ..addFlag(
        'save-results',
        abbr: 's',
        help: 'Save detailed failure report to file',
        negatable: false,
      )
      ..addOption(
        'output',
        abbr: 'o',
        help:
            'Output directory for reports (deprecated - now uses test_analyzer_reports/failed/)',
        defaultsTo: '',
      )
      ..addOption(
        'module-name',
        help: 'Override module name for reports (v3.0)',
      )
      ..addFlag(
        'verbose',
        abbr: 'v',
        help: 'Enable verbose output',
        negatable: false,
      )
      ..addFlag(
        'group-by-file',
        abbr: 'g',
        help: 'Group failed tests by file for batch rerun commands',
        negatable: false,
        defaultsTo: true,
      )
      ..addOption(
        'timeout',
        abbr: 't',
        help: 'Test timeout in seconds',
        defaultsTo: '120',
      )
      ..addFlag(
        'parallel',
        abbr: 'p',
        help: 'Run tests in parallel for faster execution',
        negatable: false,
      )
      ..addOption(
        'max-failures',
        help: 'Maximum number of failures to extract (0 = unlimited)',
        defaultsTo: '0',
      )
      ..addFlag(
        'checklist',
        help: 'Include actionable checklists in reports (default: enabled)',
        defaultsTo: true,
      )
      ..addFlag(
        'minimal-checklist',
        help: 'Generate compact checklist format',
        negatable: false,
      );
  }

  /// Main execution method
  Future<void> run(List<String> arguments) async {
    try {
      _args = _parser.parse(arguments);
    } catch (e) {
      print('❌ Error parsing arguments: $e\n');
      _showUsage();
      exit(1);
    }

    if (_args['help'] as bool) {
      _showUsage();
      return;
    }

    final testPaths = _args.rest;
    if (testPaths.isEmpty) {
      print('❌ Error: No test path specified\n');
      _showUsage();
      exit(1);
    }

    // Validate test paths exist
    final invalidPaths = <String>[];
    for (final testPath in testPaths) {
      final file = File(testPath);
      final dir = Directory(testPath);
      if (!file.existsSync() && !dir.existsSync()) {
        invalidPaths.add(testPath);
      }
    }

    if (invalidPaths.isNotEmpty) {
      print('❌ Error: Invalid test paths detected\n');
      print('The following paths do not exist:');
      for (final path in invalidPaths) {
        print('  ❌ $path');
      }
      print('');
      print('💡 Usage Examples:');
      print('  # Extract failures from all tests');
      print('  dart run test_reporter:extract_failures test/');
      print('');
      print('  # Extract from specific directory');
      print('  dart run test_reporter:extract_failures test/unit/');
      print('');
      print('  # List failures only (no rerun)');
      print('  dart run test_reporter:extract_failures test/ --list-only');
      print('');
      print('  # With module name override');
      print(
          '  dart run test_reporter:extract_failures test/ --module-name=my-tests');
      exit(2);
    }

    final testPath = testPaths.first;

    print('🔍 Failed Test Extractor - Analyzing test failures\n');

    if (_args['watch'] as bool) {
      await _runWatchMode(testPath);
    } else {
      await _runSingleExecution(testPath);
    }
  }

  /// Run in watch mode for continuous monitoring
  Future<void> _runWatchMode(String testPath) async {
    print('👀 Starting watch mode for: $testPath');
    print('   Press Ctrl+C to stop\n');

    // Initial run
    await _runSingleExecution(testPath);

    // Watch for file changes
    await for (final event in _watchDirectory(testPath)) {
      if (event.type == FileSystemEvent.modify &&
          event.path.endsWith('.dart')) {
        print('\n📝 File changed: ${event.path}');
        print('🔄 Re-running failed test extraction...\n');
        await _runSingleExecution(testPath);
      }
    }
  }

  /// Run single test execution and analysis
  Future<void> _runSingleExecution(String testPath) async {
    final stopwatch = Stopwatch()..start();

    // Clear previous results
    _failedTests.clear();
    _testIdToName.clear();
    _testIdToFile.clear();
    _testIdToGroup.clear();
    _suiteIdToPath.clear();
    _totalTests = 0;
    _passedTests = 0;

    print('🚀 Running tests with JSON reporter...');
    final results = await _runTestsWithJsonOutput(testPath);

    if (results == null) {
      print('❌ Failed to execute tests');
      return;
    }

    stopwatch.stop();
    _totalTime = stopwatch.elapsed;

    print('✅ Test execution completed in ${_formatDuration(_totalTime)}\n');

    // Display results
    await _displayResults(results);

    // Save results if requested
    if (_args['save-results'] as bool) {
      await _saveResults(results, testPath);
    }

    // Auto-rerun failed tests if requested and there are failures
    if (_args['auto-rerun'] as bool &&
        !(_args['list-only'] as bool) &&
        results.failedTests.isNotEmpty) {
      print('\n🔄 Auto-rerunning failed tests...\n');
      await _rerunFailedTests(results.failedTests);
    }
  }

  /// Run tests with JSON output and parse results
  Future<TestResults?> _runTestsWithJsonOutput(String testPath) async {
    final testArgs = <String>['test'];

    // Add test path
    testArgs.add(testPath);

    // Add JSON reporter
    testArgs.addAll(['--reporter', 'json']);

    // Add timeout if specified
    final timeout = int.tryParse(_args['timeout'] as String) ?? 120;
    if (timeout > 0) {
      testArgs.addAll(['--timeout', '${timeout}s']);
    }

    // Add parallel flag if specified
    if (_args['parallel'] as bool) {
      testArgs.add('--concurrency=4');
    }

    if (_args['verbose'] as bool) {
      print('🔧 Running: flutter ${testArgs.join(' ')}');
    }

    try {
      final process = await Process.start(
        'flutter',
        testArgs,
        workingDirectory: Directory.current.path,
      );

      final jsonOutput = <String>[];

      // Capture stdout (JSON events)
      process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(jsonOutput.add);

      // Capture stderr for debugging
      final stderrLines = <String>[];
      process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(stderrLines.add);

      await process.exitCode;

      if (_args['verbose'] as bool && stderrLines.isNotEmpty) {
        print('⚠️  Test stderr output:');
        stderrLines.forEach(print);
        print('');
      }

      // Parse JSON events
      await _parseJsonEvents(jsonOutput);

      return TestResults(
        failedTests: List.from(_failedTests),
        totalTests: _totalTests,
        passedTests: _passedTests,
        totalTime: _totalTime,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      print('❌ Error running tests: $e');
      return null;
    }
  }

  /// Parse JSON events from test output
  Future<void> _parseJsonEvents(List<String> jsonLines) async {
    for (final line in jsonLines) {
      if (line.trim().isEmpty) continue;

      try {
        final event = jsonDecode(line) as Map<String, dynamic>;
        await _processJsonEvent(event);
      } catch (e) {
        if (_args['verbose'] as bool) {
          print('⚠️  Failed to parse JSON line: $line');
          print('   Error: $e');
        }
      }
    }
  }

  /// Process individual JSON event
  Future<void> _processJsonEvent(Map<String, dynamic> event) async {
    final type = event['type'] as String?;

    switch (type) {
      case 'start':
        if (_args['verbose'] as bool) {
          print('🎬 Test suite started');
        }

      case 'suite':
        _handleSuite(event);

      case 'testStart':
        _handleTestStart(event);

      case 'testDone':
        _handleTestDone(event);

      case 'done':
        _handleDone(event);

      case 'error':
        _handleError(event);

      default:
        // Ignore other event types
        break;
    }
  }

  /// Handle suite event
  void _handleSuite(Map<String, dynamic> event) {
    final suite = event['suite'] as Map<String, dynamic>;
    final id = suite['id'] as int;
    final path = suite['path'] as String?;

    if (path != null) {
      _suiteIdToPath[id.toString()] = path;
      if (_args['verbose'] as bool) {
        print('📁 Suite $id: $path');
      }
    }
  }

  /// Handle testStart event
  void _handleTestStart(Map<String, dynamic> event) {
    final test = event['test'] as Map<String, dynamic>;
    final id = test['id'] as int;
    final name = test['name'] as String;
    final groupIDs = test['groupIDs'] as List<dynamic>?;
    final suiteID = test['suiteID'] as int?;

    _testIdToName[id.toString()] = name;

    // Get file path from suite info
    if (suiteID != null) {
      final suitePath = _suiteIdToPath[suiteID.toString()];
      if (suitePath != null) {
        _testIdToFile[id.toString()] = suitePath;
      } else {
        _testIdToFile[id.toString()] = 'unknown_file.dart';
      }
    } else {
      _testIdToFile[id.toString()] = 'unknown_file.dart';
    }

    if (groupIDs != null && groupIDs.isNotEmpty) {
      _testIdToGroup[id.toString()] = 'group_${groupIDs.first}';
    }
  }

  /// Handle testDone event
  void _handleTestDone(Map<String, dynamic> event) {
    // Handle both formats: newer format has testID, older format has test object
    int id;
    if (event.containsKey('testID')) {
      id = event['testID'] as int;
    } else if (event.containsKey('test')) {
      final test = event['test'] as Map<String, dynamic>;
      id = test['id'] as int;
    } else {
      if (_args['verbose'] as bool) {
        print('⚠️  testDone event missing testID and test fields');
      }
      return;
    }

    final result = event['result'] as String;
    final time = event['time'] as int?;

    _totalTests++;

    if (result == 'success') {
      _passedTests++;
    } else {
      // This is a failed test
      final name = _testIdToName[id.toString()] ?? 'Unknown Test';
      final filePath = _testIdToFile[id.toString()] ?? 'unknown_file.dart';
      final group = _testIdToGroup[id.toString()];

      final failedTest = FailedTest(
        name: name,
        filePath: filePath,
        group: group,
        error: event['error']?.toString(),
        stackTrace: event['stackTrace']?.toString(),
        runtime: time != null ? Duration(milliseconds: time) : null,
        testId: id.toString(),
      );

      _failedTests.add(failedTest);

      // Check max failures limit
      final maxFailures = int.tryParse(_args['max-failures'] as String) ?? 0;
      if (maxFailures > 0 && _failedTests.length >= maxFailures) {
        print('⚠️  Reached maximum failure limit ($maxFailures)');
      }
    }
  }

  /// Handle done event
  void _handleDone(Map<String, dynamic> event) {
    final success = event['success'] as bool? ?? false;
    if (_args['verbose'] as bool) {
      print('🏁 Test suite completed. Success: $success');
    }
  }

  /// Handle error event
  void _handleError(Map<String, dynamic> event) {
    final error = event['error'] as String? ?? 'Unknown error';
    if (_args['verbose'] as bool) {
      print('❌ Test error: $error');
    }
  }

  /// Display comprehensive test results
  Future<void> _displayResults(TestResults results) async {
    print('📊 TEST EXECUTION SUMMARY');
    print('=' * 50);
    print('Total Tests:      ${results.totalTests}');
    print('Passed:           ${results.passedTests}');
    print('Failed:           ${results.failedCount}');
    print('Success Rate:     ${results.successRate.toStringAsFixed(1)}%');
    print('Execution Time:   ${_formatDuration(results.totalTime)}');
    print('');

    if (results.failedTests.isEmpty) {
      print('🎉 All tests passed! No failed tests to rerun.');
      return;
    }

    print('❌ FAILED TESTS (${results.failedCount})');
    print('=' * 50);

    // Group by file if requested
    if (_args['group-by-file'] as bool) {
      final groupedTests = <String, List<FailedTest>>{};
      for (final test in results.failedTests) {
        groupedTests.putIfAbsent(test.filePath, () => []).add(test);
      }

      for (final entry in groupedTests.entries) {
        print('\n📁 ${entry.key} (${entry.value.length} failures)');
        for (final test in entry.value) {
          print('   • ${test.name}');
          if (test.error != null && _args['verbose'] as bool) {
            print('     Error: ${test.error}');
          }
        }
      }
    } else {
      for (var i = 0; i < results.failedTests.length; i++) {
        final test = results.failedTests[i];
        print('${i + 1}. ${test.filePath}: ${test.name}');
        if (test.error != null && _args['verbose'] as bool) {
          print('   Error: ${test.error}');
        }
      }
    }

    if (!(_args['list-only'] as bool)) {
      print('\n🔄 RERUN COMMANDS');
      print('=' * 50);
      _generateRerunCommands(results.failedTests);
    }
  }

  /// Generate optimized rerun commands for failed tests
  void _generateRerunCommands(List<FailedTest> failedTests) {
    if (_args['group-by-file'] as bool) {
      // Group by file and generate batch commands
      final groupedTests = <String, List<FailedTest>>{};
      for (final test in failedTests) {
        groupedTests.putIfAbsent(test.filePath, () => []).add(test);
      }

      for (final entry in groupedTests.entries) {
        final testNames = entry.value.map((t) => t.name).toList();
        final namePattern = testNames.map(_escapeRegex).join('|');

        print('\n# Rerun failed tests in ${entry.key}:');
        print('flutter test ${entry.key} --name "$namePattern"');
      }
    } else {
      // Generate individual commands
      for (var i = 0; i < failedTests.length; i++) {
        final test = failedTests[i];
        print('\n# Rerun test ${i + 1}:');
        print(
          'flutter test ${test.filePath} --name "${_escapeRegex(test.name)}"',
        );
      }
    }

    // Generate combined command for all failed tests
    if (failedTests.length > 1) {
      final allNames =
          failedTests.map((t) => _escapeRegex(t.name)).toSet().join('|');
      print('\n# Rerun ALL failed tests:');
      print('flutter test --name "$allNames"');
    }

    print(
      '\n💡 Tip: Copy and paste these commands to rerun specific failed tests',
    );
  }

  /// Automatically rerun failed tests
  Future<void> _rerunFailedTests(List<FailedTest> failedTests) async {
    if (failedTests.isEmpty) return;

    // Group by file for efficient re-execution
    final groupedTests = <String, List<FailedTest>>{};
    for (final test in failedTests) {
      groupedTests.putIfAbsent(test.filePath, () => []).add(test);
    }

    for (final entry in groupedTests.entries) {
      final testNames = entry.value.map((t) => t.name).toList();
      final namePattern = testNames.map(_escapeRegex).join('|');

      print('🔄 Rerunning ${testNames.length} failed tests in ${entry.key}...');

      final rerunArgs = [
        'test',
        entry.key,
        '--name',
        namePattern,
      ];

      try {
        final result = await Process.run(
          'flutter',
          rerunArgs,
          workingDirectory: Directory.current.path,
        );

        if (result.exitCode == 0) {
          print('✅ All retested failures now pass in ${entry.key}');
        } else {
          print('❌ Some tests still failing in ${entry.key}');
          if (_args['verbose'] as bool) {
            print('   Exit code: ${result.exitCode}');
            if (result.stderr.toString().isNotEmpty) {
              print('   Stderr: ${result.stderr}');
            }
          }
        }
      } catch (e) {
        print('❌ Error rerunning tests: $e');
      }
    }
  }

  /// Save detailed results to file
  Future<void> _saveResults(TestResults results, String testPath) async {
    final timestamp = results.timestamp;

    // Build JSON data
    final jsonData = {
      'metadata': {
        'tool': 'failed_test_extractor',
        'version': '2.0',
        'generated': timestamp.toIso8601String(),
        'test_path': testPath,
      },
      'summary': {
        'totalTests': results.totalTests,
        'passedTests': results.passedTests,
        'failedTests': results.failedCount,
        'successRate': results.successRate,
        'executionTime': results.totalTime.inMilliseconds,
      },
      'failedTests': results.failedTests
          .map(
            (test) => {
              'name': test.name,
              'filePath': test.filePath,
              'group': test.group,
              'error': test.error,
              'stackTrace': test.stackTrace,
              'runtime': test.runtime?.inMilliseconds,
              'testId': test.testId,
            },
          )
          .toList(),
    };

    // Build markdown report
    final markdown = StringBuffer();
    markdown.writeln('# 🔴 Failed Test Report');
    markdown.writeln();
    markdown.writeln('**Generated:** ${timestamp.toLocal()}');
    markdown.writeln('**Test Path:** `$testPath`');
    markdown.writeln();

    markdown.writeln('## 📊 Summary');
    markdown.writeln();
    markdown.writeln('| Metric | Value |');
    markdown.writeln('|--------|-------|');
    markdown.writeln('| Total Tests | ${results.totalTests} |');
    markdown.writeln('| Passed | ✅ ${results.passedTests} |');
    markdown.writeln('| Failed | ❌ ${results.failedCount} |');
    markdown.writeln(
        '| Success Rate | ${results.successRate.toStringAsFixed(1)}% |');
    markdown
        .writeln('| Execution Time | ${_formatDuration(results.totalTime)} |');
    markdown.writeln();

    if (results.failedTests.isNotEmpty) {
      markdown.writeln('## ❌ Failed Tests');
      markdown.writeln();

      // Group by file
      final groupedTests = <String, List<FailedTest>>{};
      for (final test in results.failedTests) {
        groupedTests.putIfAbsent(test.filePath, () => []).add(test);
      }

      for (final entry in groupedTests.entries) {
        markdown.writeln('### ${entry.key}');
        markdown.writeln();
        for (final test in entry.value) {
          markdown.writeln('#### ${test.name}');
          if (test.group != null) {
            markdown.writeln('**Group:** ${test.group}');
          }
          if (test.runtime != null) {
            markdown.writeln('**Runtime:** ${_formatDuration(test.runtime!)}');
          }
          if (test.error != null) {
            markdown.writeln();
            markdown.writeln('**Error:**');
            markdown.writeln('```');
            markdown.writeln(test.error);
            markdown.writeln('```');
          }
          if (test.stackTrace != null && _args['verbose'] as bool) {
            markdown.writeln();
            markdown.writeln('**Stack Trace:**');
            markdown.writeln('```');
            markdown.writeln(test.stackTrace);
            markdown.writeln('```');
          }
          markdown.writeln();
        }
      }

      // Add triage workflow checklist
      final enableChecklist = _args['checklist'] as bool;
      final minimalChecklist = _args['minimal-checklist'] as bool;
      if (enableChecklist) {
        markdown.writeln(
          _generateTriageChecklist(
            results,
            minimal: minimalChecklist,
          ),
        );
      }
    }

    // Extract qualified module name from test path (or use explicit override)
    final explicitModuleName = _args['module-name'] as String?;
    final moduleName =
        explicitModuleName ?? ModuleIdentifier.getQualifiedModuleName(testPath);

    // Format timestamp as HHMM_DDMMYY
    final simpleTimestamp =
        '${timestamp.hour.toString().padLeft(2, '0')}${timestamp.minute.toString().padLeft(2, '0')}_'
        '${timestamp.day.toString().padLeft(2, '0')}${timestamp.month.toString().padLeft(2, '0')}${timestamp.year.toString().substring(2)}';

    // Write unified report
    final reportPath = await ReportUtils.writeUnifiedReport(
      moduleName: moduleName,
      timestamp: simpleTimestamp,
      markdownContent: markdown.toString(),
      jsonData: jsonData,
      suffix: 'failures',
      verbose: _args['verbose'] as bool,
    );

    // Clean old reports (keep only latest per module)
    await ReportUtils.cleanOldReports(
      pathName: moduleName,
      prefixPatterns: ['report_failures'],
      subdirectory: 'failures',
      verbose: _args['verbose'] as bool,
    );

    print('💾 Results saved to: $reportPath');
  }

  /// Generate triage workflow checklist for failed tests
  String _generateTriageChecklist(
    TestResults results, {
    bool minimal = false,
  }) {
    final buffer = StringBuffer();

    buffer.writeln();
    buffer.writeln('## ✅ Failure Triage Workflow');
    buffer.writeln();

    // Group failures by file
    final groupedTests = <String, List<FailedTest>>{};
    for (final test in results.failedTests) {
      groupedTests.putIfAbsent(test.filePath, () => []).add(test);
    }

    if (minimal) {
      // Minimal mode: compact checklist
      buffer.writeln('Quick action items to fix failing tests:');
      buffer.writeln();

      for (final entry in groupedTests.entries) {
        final filePath = entry.key;
        final tests = entry.value;

        buffer.writeln('**File: `$filePath`**');
        for (final test in tests) {
          buffer.writeln('- [ ] Fix: ${test.name}');
        }
        buffer.writeln();
      }

      buffer.writeln('**Quick Command**: `dart test`');
      buffer.writeln();
      return buffer.toString();
    }

    // Full mode: detailed 3-step workflow
    buffer.writeln(
        'Follow this checklist to systematically fix each failing test:');
    buffer.writeln();

    for (final entry in groupedTests.entries) {
      final filePath = entry.key;
      final tests = entry.value;

      buffer.writeln('### File: `$filePath`');
      buffer.writeln();

      for (final test in tests) {
        // Main checkbox for the test
        buffer.writeln('- [ ] **Fix: ${test.name}**');

        // Step 1: Identify root cause
        buffer.writeln('  - [ ] **Step 1: Identify root cause**');

        // Add truncated error if available
        if (test.error != null) {
          final truncatedError = _truncateError(test.error!);
          buffer.writeln('    - Error: `$truncatedError`');
        }

        // Step 2: Apply fix
        buffer.writeln('  - [ ] **Step 2: Apply fix**');
        buffer.writeln('    - Modify test or implementation code');

        // Step 3: Verify
        buffer.writeln('  - [ ] **Step 3: Verify fix**');
        buffer
            .writeln('    - Run: `dart test $filePath --name="${test.name}"`');

        buffer.writeln();
      }
    }

    // Progress tracking
    buffer.writeln(
        '**Progress:** 0 of ${results.failedCount} failures triaged (0.0%)');
    buffer.writeln();

    // Quick commands section
    buffer.writeln('### 🚀 Quick Commands');
    buffer.writeln();
    buffer.writeln('```bash');
    buffer.writeln('# Rerun all failed tests');
    for (final entry in groupedTests.entries) {
      buffer.writeln('dart test ${entry.key}');
    }
    buffer.writeln('```');
    buffer.writeln();

    return buffer.toString();
  }

  /// Truncate error message to reasonable length
  String _truncateError(String error, {int maxLength = 200}) {
    if (error.length <= maxLength) return error;
    return '${error.substring(0, maxLength)}...';
  }

  /// Watch directory for file changes
  Stream<FileSystemEvent> _watchDirectory(String path) async* {
    final directory = Directory(path);
    await for (final event in directory.watch(recursive: true)) {
      yield event;
    }
  }

  /// Escape regex special characters
  String _escapeRegex(String input) {
    return input.replaceAllMapped(
      RegExp(r'[.*+?^${}()|[\]\\]'),
      (match) => '\\${match.group(0)}',
    );
  }

  /// Format duration for display
  String _formatDuration(Duration duration) {
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}.${(duration.inMilliseconds % 1000).toString().padLeft(3, '0')}s';
    }
  }

  /// Show usage information
  void _showUsage() {
    print('Failed Test Extractor - Extract and rerun only failing tests\n');
    print(
      'Usage: flutter pub run analyzer/failed_test_extractor.dart [options] <test_path>\n',
    );
    print('Options:');
    print(_parser.usage);
    print('\nExamples:');
    print('  flutter pub run analyzer/failed_test_extractor.dart test/');
    print(
      '  flutter pub run analyzer/failed_test_extractor.dart test/auth --list-only',
    );
    print(
      '  flutter pub run analyzer/failed_test_extractor.dart test/ --watch --save-results',
    );
  }
}
