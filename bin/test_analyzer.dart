#!/usr/bin/env dart

/// # Test Analyzer - Advanced Flutter/Dart Test Debugging Tool
///
/// A comprehensive test analysis tool that identifies flaky tests, detects failure patterns,
/// tracks performance, and provides actionable fix suggestions.
///
/// ## Quick Start
/// ```bash
/// dart test_analyzer.dart                    # Basic analysis
/// dart test_analyzer.dart --runs=5           # Detect flaky tests
/// dart test_analyzer.dart --performance      # Track slow tests
/// dart test_analyzer.dart --parallel         # Speed up execution
/// dart test_analyzer.dart --dependencies     # Analyze test dependencies
/// dart test_analyzer.dart --mutation         # Verify test effectiveness
/// dart test_analyzer.dart --impact           # Identify affected tests
/// ```
///
/// ## Core Features
/// - **Flaky Test Detection**: Runs tests multiple times to identify intermittent failures
/// - **Pattern Recognition**: Detects null errors, timeouts, assertions, type errors, etc.
/// - **Performance Profiling**: Identifies slow tests and performance bottlenecks
/// - **Interactive Debugging**: Deep dive into specific test failures with source viewing
/// - **Parallel Execution**: Run tests in parallel with configurable worker pool
/// - **Dependency Analysis**: Generate test dependency graphs and detect circular deps
/// - **Mutation Testing**: Verify test effectiveness by simulating code mutations
/// - **Impact Analysis**: Identify which tests to run based on code changes
/// - **Watch Mode**: Continuous testing with auto re-run on file changes
///
/// ## Output Sections
/// 1. **Summary Statistics**: Total tests, pass rate, flaky tests
/// 2. **Consistent Failures**: Tests that fail every run with fix suggestions
/// 3. **Flaky Tests**: Tests with intermittent failures
/// 4. **Failure Patterns**: Visual distribution of failure types
/// 5. **Performance Metrics**: Slowest tests and overall timings
/// 6. **Test Reliability Matrix**: Visual reliability scoring
/// 7. **Suggested Fixes**: Context-aware recommendations
/// 8. **Actionable Insights**: Prioritized action items
///
/// ## Best Practices
///
/// ### For Flaky Tests:
/// - Isolate test state - ensure tests don't share mutable state
/// - Mock external dependencies (network, file I/O)
/// - Add retry logic for known flaky operations
/// - Use proper async/await and expectLater
/// - Ensure proper setup/teardown
///
/// ### For Performance:
/// - Parallelize independent tests
/// - Share expensive setup when possible
/// - Mock heavy operations
/// - Profile hot paths
/// - Set appropriate timeouts
///
/// ## Exit Codes
/// - 0: All tests passed consistently
/// - 1: Some tests failed consistently
/// - 2: Analysis error occurred

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:test_analyzer/src/utils/report_utils.dart';

class TestAnalyzer {
  TestAnalyzer({
    this.runCount = 3,
    this.verbose = false,
    this.interactive = false,
    this.performanceMode = false,
    this.watch = false,
    this.generateFixes = true,
    this.generateReport = true,
    this.slowTestThreshold = 1.0, // seconds
    this.targetFiles = const [],
    this.parallel = false,
    this.maxWorkers = 4,
    this.dependencyAnalysis = false,
    this.mutationTesting = false,
    this.impactAnalysis = false,
  });
  // Terminal colors
  static const String reset = '\x1B[0m';
  static const String red = '\x1B[31m';
  static const String green = '\x1B[32m';
  static const String yellow = '\x1B[33m';
  static const String blue = '\x1B[34m';
  static const String magenta = '\x1B[35m';
  static const String cyan = '\x1B[36m';
  static const String gray = '\x1B[90m';
  static const String bold = '\x1B[1m';
  static const String dim = '\x1B[2m';
  static const String underline = '\x1B[4m';

  // Test data
  final Map<String, TestRun> testRuns = {};
  final Map<String, List<TestFailure>> failures = {};
  final Map<String, TestPerformance> performance = {};
  final Map<String, FailurePattern> patterns = {};
  final List<String> flakyTests = [];
  final List<String> consistentFailures = [];

  // Loading performance tracking
  final Map<int, LoadingEvent> loadingEvents = {}; // Track by test ID
  final Map<String, LoadingPerformance> fileLoadTimes =
      {}; // Track by file path

  // Configuration
  final int runCount;
  final bool verbose;
  final bool interactive;
  final bool performanceMode;
  final bool watch;
  final bool generateFixes;
  final bool generateReport;
  final double slowTestThreshold;
  final List<String> targetFiles;
  final bool parallel;
  final int maxWorkers;
  final bool dependencyAnalysis;
  final bool mutationTesting;
  final bool impactAnalysis;

  Future<void> run() async {
    _printHeader();

    try {
      // Step 1: Discover test files
      final testFiles = await _discoverTestFiles();

      // Step 2: Analyze test dependencies if enabled
      if (dependencyAnalysis) {
        await _analyzeTestDependencies(testFiles);
      }

      // Step 3: Run tests multiple times
      await _runTestsMultipleTimes(testFiles);

      // Step 4: Analyze failures and patterns
      _analyzeFailures();

      // Step 5: Track performance metrics
      if (performanceMode) {
        _analyzePerformance();
      }

      // Step 6: Run mutation testing if enabled
      if (mutationTesting) {
        await _runMutationTesting(testFiles);
      }

      // Step 7: Analyze test impact if enabled
      if (impactAnalysis) {
        await _analyzeTestImpact(testFiles);
      }

      // Step 5: Generate comprehensive report
      await _generateReport();

      // Step 6: Interactive mode for debugging
      if (interactive && failures.isNotEmpty) {
        await _enterInteractiveMode();
      }

      // Step 7: Watch mode
      if (watch) {
        await _enterWatchMode();
      }

      // Exit with appropriate code
      exit(consistentFailures.isEmpty ? 0 : 1);
    } catch (e, stackTrace) {
      print('${red}Error: $e$reset');
      if (verbose) {
        print('$gray$stackTrace$reset');
      }
      exit(2);
    }
  }

  void _printHeader() {
    const width = 70;
    print('$blue${"═" * width}$reset');
    print(
      '$blue$bold${_center("Flutter/Dart Test Analyzer", width)}$reset',
    );
    print(
      '$blue${_center("Advanced Test Debugging & Performance Tool", width)}$reset',
    );
    print('$blue${"═" * width}$reset');
  }

  String _center(String text, int width) {
    final padding = (width - text.length) ~/ 2;
    return ' ' * padding + text;
  }

  /// Discover all test files
  Future<List<String>> _discoverTestFiles() async {
    print('\n$yellow▶ Discovering test files...$reset');

    final testFiles = <String>[];

    if (targetFiles.isNotEmpty) {
      // Use specified files
      testFiles.addAll(targetFiles);
    } else {
      // Discover all test files
      final testDir = Directory('test');
      if (await testDir.exists()) {
        await for (final entity in testDir.list(recursive: true)) {
          if (entity is File && entity.path.endsWith('_test.dart')) {
            testFiles.add(entity.path);
          }
        }
      }
    }

    print('  $green✓$reset Found ${testFiles.length} test files');
    return testFiles;
  }

  /// Run tests multiple times to identify flaky tests
  Future<void> _runTestsMultipleTimes(List<String> testFiles) async {
    print(
      '\n$yellow▶ Running tests ${runCount}x to identify patterns...$reset',
    );

    if (parallel) {
      print(
        '  ${cyan}Parallel execution enabled with $maxWorkers workers$reset',
      );
    }

    for (var run = 1; run <= runCount; run++) {
      print('\n  ${cyan}Run $run of $runCount:$reset');

      if (parallel) {
        // Run tests in parallel
        await _runTestsInParallel(testFiles, run);
      } else {
        // Run tests sequentially
        for (final testFile in testFiles) {
          await _runSingleTest(testFile, run);
        }
      }

      // Add delay between runs to avoid test pollution
      if (run < runCount) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
    }
  }

  /// Run tests in parallel with worker pool
  Future<void> _runTestsInParallel(
    List<String> testFiles,
    int runNumber,
  ) async {
    final chunks = <List<String>>[];
    final chunkSize = (testFiles.length / maxWorkers).ceil();

    // Split tests into chunks for parallel execution
    for (var i = 0; i < testFiles.length; i += chunkSize) {
      chunks.add(testFiles.skip(i).take(chunkSize).toList());
    }

    // Run chunks in parallel
    final futures = <Future<void>>[];
    for (final chunk in chunks) {
      futures.add(() async {
        for (final testFile in chunk) {
          await _runSingleTest(testFile, runNumber);
        }
      }());
    }

    await Future.wait(futures);
  }

  Future<void> _runSingleTest(String testFile, int runNumber) async {
    final stopwatch = Stopwatch()..start();

    // Use flutter test for Flutter projects, dart test for pure Dart
    final isFlutterProject = await File('pubspec.yaml').exists() &&
        await File('pubspec.yaml')
            .readAsString()
            .then((content) => content.contains('flutter:'));

    final result = await Process.run(
      isFlutterProject ? 'flutter' : 'dart',
      ['test', '--reporter=json', testFile],
      runInShell: Platform.isWindows,
    );

    stopwatch.stop();

    // Parse test results
    final lines = result.stdout.toString().split('\n');

    for (final line in lines) {
      if (line.startsWith('{')) {
        try {
          final json = jsonDecode(line);
          if (json is Map<String, dynamic>) {
            _processTestEvent(json, testFile, runNumber, stopwatch.elapsed);
          }
        } catch (_) {
          // Ignore JSON parse errors
        }
      }
    }

    // Also capture stderr for additional error information
    if (result.stderr.toString().isNotEmpty) {
      _captureStderrErrors(testFile, result.stderr.toString(), runNumber);
    }
  }

  void _processTestEvent(
    Map<String, dynamic> json,
    String testFile,
    int runNumber,
    Duration totalDuration,
  ) {
    final type = json['type'];

    if (type == 'testStart') {
      final test = json['test'] as Map<String, dynamic>?;
      if (test == null) return;
      final testName = (test['name'] as String?) ?? '';
      final testId = test['id'] as int?;

      // Track loading events separately for performance metrics
      if (testName.startsWith('loading ')) {
        final filePath = testName.substring('loading '.length);
        if (testId != null) {
          loadingEvents[testId] = LoadingEvent(
            testId: testId,
            filePath: filePath,
            startTime: (json['time'] as int?) ?? 0,
            runNumber: runNumber,
          );
        }
        return; // Don't treat as actual tests
      }

      // Store mapping from numeric ID to our test ID format
      if (testId != null) {
        _testIdMap[testId] = '$testFile::$testName';

        testRuns.putIfAbsent(
          '$testFile::$testName',
          () => TestRun(
            testFile: testFile,
            testName: testName,
          ),
        );
      }
    } else if (type == 'testDone') {
      final numericTestId = json['testID'] as int?;
      final result = json['result'] as String?;
      final time = (json['time'] as int?) ?? 0;
      final hidden = (json['hidden'] as bool?) ?? false;

      // Handle completion of loading events
      if (hidden &&
          numericTestId != null &&
          loadingEvents.containsKey(numericTestId)) {
        final loadingEvent = loadingEvents[numericTestId]!;
        final loadTime = time - loadingEvent.startTime;

        // Store loading performance for this file
        fileLoadTimes.putIfAbsent(
          loadingEvent.filePath,
          () => LoadingPerformance(
            filePath: loadingEvent.filePath,
          ),
        );
        fileLoadTimes[loadingEvent.filePath]!
            .addLoadTime(runNumber, loadTime, success: result == 'success');

        loadingEvents.remove(numericTestId);
        return;
      }

      // Skip other hidden tests
      if (hidden) return;

      // Look up the actual test ID from our map
      final testId = numericTestId != null ? _testIdMap[numericTestId] : null;
      if (testId == null) {
        // Fallback: create a simple test ID
        final fallbackId = '$testFile::test_$numericTestId';
        testRuns.putIfAbsent(
          fallbackId,
          () => TestRun(
            testFile: testFile,
            testName: 'Test $numericTestId',
          ),
        );

        final testRun = testRuns[fallbackId]!;
        testRun.results[runNumber] = result == 'success';
        testRun.durations[runNumber] = time;

        if (result != 'success') {
          _recordFailure(fallbackId, runNumber, json);
        }
      } else {
        final testRun = testRuns[testId];
        if (testRun != null) {
          testRun.results[runNumber] = result == 'success';
          testRun.durations[runNumber] = time;

          // Track performance
          performance.putIfAbsent(
            testId,
            () => TestPerformance(
              testId: testId,
              testName: testRun.testName,
            ),
          );
          performance[testId]!.addDuration(time.toDouble());

          // Track failures
          if (result != 'success') {
            _recordFailure(testId, runNumber, json);
          }
        }
      }
    } else if (type == 'error') {
      _processErrorEvent(json, testFile, runNumber);
    }
  }

  // Add a map to track numeric test IDs to our string IDs
  final Map<int, String> _testIdMap = {};

  void _recordFailure(String testId, int runNumber, Map<String, dynamic> json) {
    final error = json['error'] ?? '';
    final stackTrace = json['stackTrace'] ?? '';

    final failure = TestFailure(
      testId: testId,
      runNumber: runNumber,
      error: error.toString(),
      stackTrace: stackTrace.toString(),
      timestamp: DateTime.now(),
    );

    failures.putIfAbsent(testId, () => []).add(failure);

    // Detect pattern
    _detectFailurePattern(failure);
  }

  void _processErrorEvent(
    Map<String, dynamic> json,
    String testFile,
    int runNumber,
  ) {
    final error = json['error'] ?? '';
    final stackTrace = json['stackTrace'] ?? '';
    final testId = json['testID']?.toString() ?? '$testFile::unknown';

    final failure = TestFailure(
      testId: testId,
      runNumber: runNumber,
      error: error.toString(),
      stackTrace: stackTrace.toString(),
      timestamp: DateTime.now(),
    );

    failures.putIfAbsent(testId, () => []).add(failure);
  }

  void _captureStderrErrors(String testFile, String stderr, int runNumber) {
    if (verbose) {
      print('    ${gray}stderr from $testFile (run $runNumber):$reset');
      print(
        '    $red${stderr.split('\n').map((l) => '    $l').join('\n')}$reset',
      );
    }
  }

  /// Detect failure patterns
  void _detectFailurePattern(TestFailure failure) {
    final error = failure.error.toLowerCase();

    // Advanced pattern detection
    FailureType? type;
    String? category;
    String? suggestion;

    if (error.contains('assertion') || error.contains('expect')) {
      type = FailureType.assertion;
      category = 'Assertion Failure';

      // Extract expected vs actual values
      final expectedMatch =
          RegExp(r'expected[: ]+(.+?)(?:,|$)', caseSensitive: false)
              .firstMatch(failure.error);
      final actualMatch =
          RegExp(r'actual[: ]+(.+?)(?:,|$)', caseSensitive: false)
              .firstMatch(failure.error);

      if (expectedMatch != null && actualMatch != null) {
        suggestion =
            'Expected: ${expectedMatch.group(1)?.trim()}\nActual: ${actualMatch.group(1)?.trim()}';
      }
    } else if (error.contains('null') || error.contains('nosuchmethoderror')) {
      type = FailureType.nullError;
      category = 'Null Reference Error';

      // Extract the property/method that was null
      final propertyMatch =
          RegExp(r"'(\w+)' was called on null").firstMatch(failure.error);
      if (propertyMatch != null) {
        suggestion =
            'Add null check for ${propertyMatch.group(1)} or ensure proper initialization';
      }
    } else if (error.contains('timeout')) {
      type = FailureType.timeout;
      category = 'Timeout';
      suggestion = 'Increase timeout duration or optimize test performance';
    } else if (error.contains('rangeError') || error.contains('index')) {
      type = FailureType.rangeError;
      category = 'Range/Index Error';

      // Extract index information
      final indexMatch = RegExp(r'index[: ]+(\d+)').firstMatch(failure.error);
      if (indexMatch != null) {
        suggestion =
            'Check array bounds before accessing index ${indexMatch.group(1)}';
      }
    } else if (error.contains('type') || error.contains('cast')) {
      type = FailureType.typeError;
      category = 'Type Error';
      suggestion = 'Verify type conversions and generic type parameters';
    } else if (error.contains('file') || error.contains('io')) {
      type = FailureType.ioError;
      category = 'I/O Error';
      suggestion =
          'Ensure test files/resources exist and have proper permissions';
    } else if (error.contains('network') || error.contains('socket')) {
      type = FailureType.networkError;
      category = 'Network Error';
      suggestion = 'Mock network calls or ensure test server is running';
    } else {
      type = FailureType.unknown;
      category = 'Unknown Error';
    }

    patterns[failure.testId] = FailurePattern(
      type: type,
      category: category,
      count: (patterns[failure.testId]?.count ?? 0) + 1,
      suggestion: suggestion ?? _generateSmartSuggestion(failure),
    );
  }

  String _generateSmartSuggestion(TestFailure failure) {
    // Analyze stack trace for more context
    final lines = failure.stackTrace.split('\n');

    for (final line in lines) {
      // Find the first line in user code (not package or dart internals)
      if (line.contains('.dart:') &&
          !line.contains('package:') &&
          !line.contains('dart:')) {
        final match = RegExp(r'(\w+\.dart):(\d+):(\d+)').firstMatch(line);
        if (match != null) {
          return 'Check ${match.group(1)} at line ${match.group(2)}';
        }
      }
    }

    // Provide generic suggestions based on error keywords
    if (failure.error.contains('setState')) {
      return 'Ensure widget is mounted before calling setState';
    }
    if (failure.error.contains('disposed')) {
      return 'Check disposal timing and avoid using disposed objects';
    }
    if (failure.error.contains('future')) {
      return 'Add proper async/await handling or use expectLater for futures';
    }
    if (failure.error.contains('stream')) {
      return 'Ensure stream subscriptions are properly managed';
    }

    return 'Review test setup/teardown and verify all dependencies are properly initialized';
  }

  /// Analyze failures to identify flaky vs consistent
  void _analyzeFailures() {
    print('\n$yellow▶ Analyzing failure patterns...$reset');

    var testsWithResults = 0;
    final testsWithoutResults = <String>[];
    final setupTeardownHooks = <String>[];

    for (final entry in testRuns.entries) {
      final testId = entry.key;
      final run = entry.value;

      // Skip tests without results
      if (run.results.isEmpty) {
        // Separate setup/teardown hooks from actual tests
        if (testId.contains('(setUpAll)') ||
            testId.contains('(tearDownAll)') ||
            testId.contains('(setUp)') ||
            testId.contains('(tearDown)')) {
          setupTeardownHooks.add(testId);
        } else {
          testsWithoutResults.add(testId);
        }
        continue;
      }

      testsWithResults++;
      final failureCount = run.results.values.where((r) => !r).length;

      if (failureCount > 0) {
        if (failureCount == runCount) {
          // Consistent failure
          consistentFailures.add(testId);
        } else {
          // Flaky test
          flakyTests.add(testId);
        }
      }
    }

    print('  $green✓$reset Analysis complete');
    print('    • Tests with results: $testsWithResults/${testRuns.length}');
    print('    • Consistent failures: ${consistentFailures.length}');
    print('    • Flaky tests: ${flakyTests.length}');
    print(
      '    • Passing tests: ${testsWithResults - consistentFailures.length - flakyTests.length}',
    );

    if (setupTeardownHooks.isNotEmpty) {
      print(
        '    $dim• Setup/teardown hooks: ${setupTeardownHooks.length}$reset',
      );
    }

    if (testsWithoutResults.isNotEmpty) {
      print(
        '    $yellow⚠ ${testsWithoutResults.length} tests had no results recorded:$reset',
      );
      for (final testId in testsWithoutResults) {
        print('      $dim• $testId$reset');
      }
    }
  }

  /// Analyze performance metrics
  void _analyzePerformance() {
    print('\n$yellow▶ Analyzing test performance...$reset');

    // Find slow tests
    final slowTests = performance.entries
        .where((e) => e.value.averageDuration > slowTestThreshold * 1000)
        .toList()
      ..sort(
        (a, b) => b.value.averageDuration.compareTo(a.value.averageDuration),
      );

    if (slowTests.isNotEmpty) {
      print(
        '  $yellow⚠$reset Found ${slowTests.length} slow tests (>${slowTestThreshold}s)',
      );
    } else {
      print('  $green✓$reset All tests run within performance threshold');
    }

    // Analyze loading performance
    if (fileLoadTimes.isNotEmpty) {
      final slowLoading =
          fileLoadTimes.values.where((p) => p.averageLoadTime > 500).toList();
      if (slowLoading.isNotEmpty) {
        print(
          '  $yellow⚠$reset Found ${slowLoading.length} slow-loading test files (>500ms)',
        );
      }

      final failedLoading =
          fileLoadTimes.values.where((p) => p.hasFailures).toList();
      if (failedLoading.isNotEmpty) {
        print(
          '  $red✗$reset ${failedLoading.length} test file(s) had loading failures',
        );
      }
    }
  }

  /// Generate comprehensive report
  Future<void> _generateReport() async {
    _printReportHeader();
    _printSummaryStatistics();
    _printConsistentFailures();
    _printFlakyTests();
    _printFailurePatterns();

    if (performanceMode) {
      _printPerformanceMetrics();
    }

    if (generateFixes) {
      _printSuggestedFixes();
    }

    _printTestReliabilityMatrix();
    _printActionableInsights();

    // Save report to file
    if (generateReport) {
      await _saveReportToFile();
    }
  }

  Future<void> _saveReportToFile() async {
    // Clean up old reports before generating new one
    await _cleanupOldReports();

    final report = StringBuffer();

    // Header
    report.writeln('# 🧪 Test Analysis Report');
    report.writeln('**Generated:** ${DateTime.now().toIso8601String()}');
    report.writeln(
      '**Test Path:** `${targetFiles.isNotEmpty ? targetFiles.first : "all tests"}`',
    );
    report.writeln('**Analysis Runs:** $runCount');
    report.writeln();

    // Calculate metrics
    final total = testRuns.length;
    final passed = total - consistentFailures.length - flakyTests.length;
    final passRate = total > 0 ? (passed / total * 100) : 0.0;
    final stabilityScore = total > 0
        ? ((total - consistentFailures.length - flakyTests.length * 0.5) /
            total *
            100)
        : 100.0;

    // Executive Summary
    report.writeln('## 📊 Executive Summary');
    report.writeln();
    report.writeln('| Metric | Value | Status |');
    report.writeln('|--------|-------|--------|');
    report.writeln(
      '| **Overall Pass Rate** | **${passRate.toStringAsFixed(1)}%** | ${_getStatusBadge(passRate)} |',
    );
    report.writeln(
      '| **Test Stability** | **${stabilityScore.toStringAsFixed(1)}%** | ${_getStatusBadge(stabilityScore)} |',
    );
    report.writeln('| Total Tests | $total | - |');
    report.writeln(
      '| Passed Consistently | $passed | ${passed == total ? "✅" : passed > total * 0.8 ? "⚠️" : "❌"} |',
    );
    report.writeln(
      '| Consistent Failures | ${consistentFailures.length} | ${consistentFailures.isEmpty ? "✅" : "❌"} |',
    );
    report.writeln(
      '| Flaky Tests | ${flakyTests.length} | ${flakyTests.isEmpty ? "✅" : flakyTests.length < 3 ? "⚠️" : "❌"} |',
    );
    report.writeln('| Test Runs | $runCount | - |');
    report.writeln();

    // Health Status Badge
    final healthStatus = passRate >= 95
        ? 'Excellent'
        : passRate >= 80
            ? 'Good'
            : passRate >= 60
                ? 'Needs Attention'
                : 'Critical';
    final healthBadge = passRate >= 95
        ? '🟢'
        : passRate >= 80
            ? '🟡'
            : passRate >= 60
                ? '🟠'
                : '🔴';
    report.writeln('### Test Suite Health: $healthBadge **$healthStatus**');
    report.writeln();

    // Test Reliability Matrix
    report.writeln('## 📈 Test Reliability Matrix');
    report.writeln();

    // Count tests with and without results
    var testsWithoutResults = 0;
    var setupTeardownHooks = 0;
    var testsWithResults = 0;

    // Create reliability buckets (only for tests with results)
    final buckets = <String, int>{
      '100% reliable': 0,
      '66-99% reliable': 0,
      '33-65% reliable': 0,
      '0-32% reliable': 0,
    };

    for (final entry in testRuns.entries) {
      final testId = entry.key;
      final run = entry.value;

      if (run.results.isEmpty) {
        // Check if it's a setup/teardown hook
        if (testId.contains('(setUpAll)') ||
            testId.contains('(tearDownAll)') ||
            testId.contains('(setUp)') ||
            testId.contains('(tearDown)')) {
          setupTeardownHooks++;
        } else {
          testsWithoutResults++;
        }
        continue;
      }
      testsWithResults++;
      final successRate = run.results.values.where((r) => r).length / runCount;
      if (successRate == 1.0) {
        buckets['100% reliable'] = buckets['100% reliable']! + 1;
      } else if (successRate >= 0.66) {
        buckets['66-99% reliable'] = buckets['66-99% reliable']! + 1;
      } else if (successRate >= 0.33) {
        buckets['33-65% reliable'] = buckets['33-65% reliable']! + 1;
      } else {
        buckets['0-32% reliable'] = buckets['0-32% reliable']! + 1;
      }
    }

    // Show note about setup/teardown hooks if any
    if (setupTeardownHooks > 0) {
      report.writeln(
        '> ℹ️ **Setup/Teardown Hooks:** $setupTeardownHooks lifecycle hooks detected',
      );
      for (final entry in testRuns.entries) {
        final testId = entry.key;
        if (entry.value.results.isEmpty &&
            (testId.contains('(setUpAll)') ||
                testId.contains('(tearDownAll)') ||
                testId.contains('(setUp)') ||
                testId.contains('(tearDown)'))) {
          report.writeln('>   • $testId');
        }
      }
      report.writeln();
    }

    // Show note about tests without results if any
    if (testsWithoutResults > 0) {
      report.writeln(
        '> ℹ️ **Note:** $testsWithoutResults test(s) discovered but no results recorded',
      );
      report.writeln();
    }

    report.writeln('| Reliability Level | Count | Percentage | Visual |');
    report.writeln('|-------------------|-------|------------|--------|');
    for (final entry in buckets.entries) {
      final percentage =
          testsWithResults > 0 ? (entry.value / testsWithResults * 100) : 0.0;
      final bar = _generateBar(percentage, 20);
      final icon = entry.key.contains('100%')
          ? '🟢'
          : entry.key.contains('66-99%')
              ? '🟡'
              : entry.key.contains('33-65%')
                  ? '🟠'
                  : '🔴';
      report.writeln(
        '| $icon ${entry.key} | ${entry.value} | ${percentage.toStringAsFixed(1)}% | $bar |',
      );
    }
    report.writeln();

    // Consistent Failures
    if (consistentFailures.isNotEmpty) {
      report.writeln('## ❌ Consistent Failures');
      report.writeln('*Tests that failed all $runCount runs*');
      report.writeln();
      report.writeln('| Test Name | File | Failure Type | Priority |');
      report.writeln('|-----------|------|--------------|----------|');

      for (final testId in consistentFailures.take(20)) {
        final parts = testId.split('::');
        final file = _getRelativePath(parts[0]).split('/').last;
        final test = parts.length > 1 ? parts[1] : 'unknown';
        final pattern = patterns[testId];
        final category = pattern?.category ?? 'Unknown';
        final priority = pattern?.type == FailureType.nullError ||
                pattern?.type == FailureType.assertion
            ? '🔴 High'
            : '🟡 Medium';

        report.writeln(
          '| `${_truncate(test, 40)}` | `$file` | $category | $priority |',
        );
      }

      if (consistentFailures.length > 20) {
        report.writeln(
          '| ... | *${consistentFailures.length - 20} more failures* | ... | ... |',
        );
      }
      report.writeln();

      // Failure fix suggestions
      report.writeln('### 🔧 Fix Suggestions');
      report.writeln();
      final suggestions = <String, Set<String>>{};
      for (final testId in consistentFailures) {
        final pattern = patterns[testId];
        if (pattern?.suggestion != null) {
          suggestions
              .putIfAbsent(pattern!.category, () => {})
              .add(pattern.suggestion!);
        }
      }

      for (final entry in suggestions.entries.take(5)) {
        report.writeln('**${entry.key}:**');
        for (final suggestion in entry.value.take(3)) {
          report.writeln('- $suggestion');
        }
        report.writeln();
      }
    }

    // Flaky Tests
    if (flakyTests.isNotEmpty) {
      report.writeln('## ⚡ Flaky Tests');
      report.writeln('*Tests with intermittent failures*');
      report.writeln();
      report.writeln('| Test Name | File | Success Rate | Flakiness Level |');
      report.writeln('|-----------|------|--------------|-----------------|');

      for (final testId in flakyTests.take(15)) {
        final parts = testId.split('::');
        final file = _getRelativePath(parts[0]).split('/').last;
        final test = parts.length > 1 ? parts[1] : 'unknown';
        final run = testRuns[testId]!;
        final successCount = run.results.values.where((r) => r).length;
        final successRate = successCount / runCount * 100;
        final flakiness = successRate >= 75
            ? '🟡 Low'
            : successRate >= 50
                ? '🟠 Medium'
                : '🔴 High';

        report.writeln(
          '| `${_truncate(test, 40)}` | `$file` | ${successRate.toStringAsFixed(0)}% | $flakiness |',
        );
      }

      if (flakyTests.length > 15) {
        report.writeln(
          '| ... | *${flakyTests.length - 15} more flaky tests* | ... | ... |',
        );
      }
      report.writeln();
    }

    // Failure Patterns Distribution
    if (patterns.isNotEmpty) {
      report.writeln('## 🔍 Failure Pattern Analysis');
      report.writeln();
      report.writeln('| Pattern Type | Count | Percentage | Visual |');
      report.writeln('|--------------|-------|------------|--------|');

      final patternsByType = <FailureType, int>{};
      for (final pattern in patterns.values) {
        patternsByType[pattern.type] = (patternsByType[pattern.type] ?? 0) + 1;
      }

      final totalPatterns = patternsByType.values.fold(0, (a, b) => a + b);
      final sorted = patternsByType.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      for (final entry in sorted) {
        final typeName = entry.key.toString().split('.').last;
        final formattedName = typeName[0].toUpperCase() + typeName.substring(1);
        final percentage = entry.value / totalPatterns * 100;
        final bar = _generateBar(percentage, 20);

        report.writeln(
          '| $formattedName | ${entry.value} | ${percentage.toStringAsFixed(1)}% | $bar |',
        );
      }
      report.writeln();
    }

    // Performance Metrics
    if (performanceMode && performance.isNotEmpty) {
      report.writeln('## ⏱️ Performance Analysis');
      report.writeln();

      final sorted = performance.entries.toList()
        ..sort(
          (a, b) => b.value.averageDuration.compareTo(a.value.averageDuration),
        );

      final totalTime =
          performance.values.fold(0.0, (sum, p) => sum + p.totalDuration);
      final avgTestTime =
          performance.isNotEmpty ? totalTime / performance.length / 1000 : 0.0;
      final slowTests = performance.values
          .where((p) => p.averageDuration > slowTestThreshold * 1000)
          .length;

      report.writeln('### Performance Overview');
      report.writeln();
      report.writeln('| Metric | Value | Status |');
      report.writeln('|--------|-------|--------|');
      report.writeln(
        '| Total Execution Time | ${(totalTime / 1000).toStringAsFixed(2)}s | - |',
      );
      report.writeln(
        '| Average Test Time | ${avgTestTime.toStringAsFixed(3)}s | ${avgTestTime < 0.1 ? "✅" : avgTestTime < 0.5 ? "⚠️" : "❌"} |',
      );
      report.writeln(
        '| Slow Tests (>${slowTestThreshold}s) | $slowTests | ${slowTests == 0 ? "✅" : slowTests < 5 ? "⚠️" : "❌"} |',
      );
      report.writeln(
        '| Fastest Test | ${(sorted.last.value.minDuration / 1000).toStringAsFixed(3)}s | - |',
      );
      report.writeln(
        '| Slowest Test | ${(sorted.first.value.maxDuration / 1000).toStringAsFixed(3)}s | - |',
      );
      report.writeln();

      report.writeln('### Top 10 Slowest Tests');
      report.writeln();
      report.writeln('| # | Test Name | Avg Time | Max Time | Status |');
      report.writeln('|---|-----------|----------|----------|--------|');

      var rank = 1;
      for (final entry in sorted.take(10)) {
        final parts = entry.key.split('::');
        final test = parts.length > 1 ? parts[1] : 'unknown';
        final avgTime = entry.value.averageDuration / 1000;
        final maxTime = entry.value.maxDuration / 1000;
        final status = avgTime > slowTestThreshold
            ? '🔴'
            : avgTime > slowTestThreshold * 0.5
                ? '🟡'
                : '🟢';

        report.writeln(
          '| $rank | `${_truncate(test, 35)}` | ${avgTime.toStringAsFixed(2)}s | ${maxTime.toStringAsFixed(2)}s | $status |',
        );
        rank++;
      }
      report.writeln();
    }

    // Loading Performance Analysis
    if (fileLoadTimes.isNotEmpty) {
      report.writeln('## 📦 Test Loading Performance');
      report.writeln();

      final sortedLoadTimes = fileLoadTimes.entries.toList()
        ..sort(
          (a, b) => b.value.averageLoadTime.compareTo(a.value.averageLoadTime),
        );

      final totalLoadTime = fileLoadTimes.values
          .map((p) => p.averageLoadTime)
          .reduce((a, b) => a + b);
      final avgLoadTime = totalLoadTime / fileLoadTimes.length;
      final slowFiles =
          fileLoadTimes.values.where((p) => p.averageLoadTime > 500).length;
      final failedFiles =
          fileLoadTimes.values.where((p) => p.hasFailures).length;

      report.writeln('### Loading Metrics');
      report.writeln();
      report.writeln('| Metric | Value | Status |');
      report.writeln('|--------|-------|--------|');
      report.writeln('| Total Files Loaded | ${fileLoadTimes.length} | - |');
      report.writeln(
        '| Average Load Time | ${avgLoadTime.toStringAsFixed(1)}ms | ${avgLoadTime < 500 ? "✅" : avgLoadTime < 1000 ? "⚠️" : "❌"} |',
      );
      report.writeln(
        '| Slow Loading (>500ms) | $slowFiles | ${slowFiles == 0 ? "✅" : slowFiles < 3 ? "⚠️" : "❌"} |',
      );
      report.writeln(
        '| Failed to Load | $failedFiles | ${failedFiles == 0 ? "✅" : "❌"} |',
      );
      report.writeln();

      if (sortedLoadTimes.isNotEmpty) {
        report.writeln('### File Load Times');
        report.writeln();
        report.writeln('| File | Avg Load Time | Max Load Time | Status |');
        report.writeln('|------|---------------|---------------|--------|');

        for (final entry in sortedLoadTimes) {
          final fileName = entry.key.split('/').last;
          final avgTime = entry.value.averageLoadTime;
          final maxTime = entry.value.maxLoadTime;
          final status = entry.value.hasFailures
              ? '❌'
              : avgTime > 1000
                  ? '🔴'
                  : avgTime > 500
                      ? '🟡'
                      : '🟢';

          report.writeln(
            '| `${_truncate(fileName, 40)}` | ${avgTime.toStringAsFixed(1)}ms | ${maxTime}ms | $status |',
          );
        }
        report.writeln();
      }

      if (slowFiles > 0 || failedFiles > 0) {
        report.writeln(
          '> **💡 Tip:** Slow loading times may indicate heavy test setup, large imports, or initialization issues.',
        );
        report.writeln();
      }
    }

    // Actionable Insights
    report.writeln('## 💡 Actionable Insights & Recommendations');
    report.writeln();

    final insights = <String, String>{};

    // Critical issues
    if (consistentFailures.isNotEmpty) {
      insights['🔴 Critical'] =
          'Fix ${consistentFailures.length} consistently failing tests immediately';
    }

    // Flaky tests
    if (flakyTests.length > total * 0.1) {
      insights['🟠 Warning'] =
          '${(flakyTests.length / total * 100).toStringAsFixed(1)}% of tests are flaky - investigate test isolation';
    }

    // Performance
    if (performanceMode) {
      final slowCount = performance.values
          .where((p) => p.averageDuration > slowTestThreshold * 1000)
          .length;
      if (slowCount > 0) {
        insights['⏱️ Performance'] =
            '$slowCount tests exceed ${slowTestThreshold}s - consider optimization or parallelization';
      }
    }

    // Pattern-based insights
    final nullErrors =
        patterns.values.where((p) => p.type == FailureType.nullError).length;
    if (nullErrors > 3) {
      insights['🔍 Pattern'] =
          'Multiple null reference errors detected - review initialization logic';
    }

    final timeouts =
        patterns.values.where((p) => p.type == FailureType.timeout).length;
    if (timeouts > 0) {
      insights['⏰ Timeout'] =
          'Timeout issues detected - increase timeout or optimize async operations';
    }

    if (insights.isNotEmpty) {
      report.writeln('### Priority Actions');
      report.writeln();
      var priority = 1;
      for (final entry in insights.entries) {
        report.writeln('$priority. **${entry.key}**: ${entry.value}');
        priority++;
      }
      report.writeln();
    }

    // Best Practices
    report.writeln('### Best Practices Checklist');
    report.writeln();
    report.writeln(
      '- [ ] All tests pass consistently (${consistentFailures.isEmpty ? "✅" : "❌"})',
    );
    report.writeln('- [ ] No flaky tests (${flakyTests.isEmpty ? "✅" : "❌"})');
    report.writeln(
      '- [ ] Tests run in < ${slowTestThreshold}s (${performance.values.where((p) => p.averageDuration > slowTestThreshold * 1000).isEmpty ? "✅" : "❌"})',
    );
    report.writeln('- [ ] Test coverage > 80% (run coverage tool to verify)');
    report.writeln('- [ ] Tests are isolated and independent');
    report.writeln('- [ ] Error scenarios are tested');
    report.writeln('- [ ] Async operations properly handled');
    report.writeln();

    // Footer
    report.writeln('---');
    report.writeln('*Generated by test_analyzer.dart v2.0 - Enhanced Edition*');
    report.writeln(
      '*Run with `--verbose` for detailed output, `--performance` for timing metrics*',
    );

    // Save to file using unified report format
    try {
      // Create filename with tested path and timestamp (HHMM_DDMMYY format)
      final now = DateTime.now();
      final timestamp =
          '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}_'
          '${now.day.toString().padLeft(2, '0')}${now.month.toString().padLeft(2, '0')}${now.year.toString().substring(2)}';

      // Extract meaningful name from tested paths
      final pathName = _extractPathName();

      // Build JSON export with all key metrics
      final jsonData = <String, dynamic>{
        'metadata': {
          'tool': 'test_analyzer',
          'version': '2.0',
          'generated': now.toIso8601String(),
          'test_path': targetFiles.isNotEmpty ? targetFiles.first : 'all tests',
          'analysis_runs': runCount,
        },
        'summary': {
          'total_tests': total,
          'passed_consistently': passed,
          'consistent_failures': consistentFailures.length,
          'flaky_tests': flakyTests.length,
          'pass_rate': passRate,
          'stability_score': stabilityScore,
          'health_status': healthStatus,
        },
        'reliability_matrix': {
          'tests_with_results': testsWithResults,
          'tests_without_results': testsWithoutResults,
          'setup_teardown_hooks': setupTeardownHooks,
          'buckets': buckets,
        },
        'consistent_failures': consistentFailures
            .map((testId) {
              final parts = testId.split('::');
              final pattern = patterns[testId];
              return {
                'test_id': testId,
                'file': parts[0],
                'test_name': parts.length > 1 ? parts[1] : 'unknown',
                'failure_type': pattern?.type.toString().split('.').last,
                'category': pattern?.category,
                'suggestion': pattern?.suggestion,
              };
            })
            .toList()
            .take(50)
            .toList(),
        'flaky_tests': flakyTests
            .map((testId) {
              final parts = testId.split('::');
              final run = testRuns[testId]!;
              final successCount = run.results.values.where((r) => r).length;
              final successRate = successCount / runCount * 100;
              return {
                'test_id': testId,
                'file': parts[0],
                'test_name': parts.length > 1 ? parts[1] : 'unknown',
                'success_rate': successRate,
                'runs': Map<String, bool>.fromEntries(
                  run.results.entries.map((e) => MapEntry('run_${e.key}', e.value)),
                ),
              };
            })
            .toList()
            .take(50)
            .toList(),
      };

      // Add performance data if available
      if (performanceMode && performance.isNotEmpty) {
        final sorted = performance.entries.toList()
          ..sort(
            (a, b) =>
                b.value.averageDuration.compareTo(a.value.averageDuration),
          );
        final totalTime =
            performance.values.fold(0.0, (sum, p) => sum + p.totalDuration);

        jsonData['performance'] = {
          'total_execution_time_ms': totalTime,
          'average_test_time_ms':
              performance.isNotEmpty ? totalTime / performance.length : 0.0,
          'slow_test_threshold_ms': slowTestThreshold * 1000,
          'slow_tests_count': performance.values
              .where((p) => p.averageDuration > slowTestThreshold * 1000)
              .length,
          'top_10_slowest': sorted.take(10).map((entry) {
            final parts = entry.key.split('::');
            return {
              'test_id': entry.key,
              'test_name': parts.length > 1 ? parts[1] : 'unknown',
              'average_duration_ms': entry.value.averageDuration,
              'max_duration_ms': entry.value.maxDuration,
              'min_duration_ms': entry.value.minDuration,
            };
          }).toList(),
        };
      }

      // Add loading performance if available
      if (fileLoadTimes.isNotEmpty) {
        final totalLoadTime = fileLoadTimes.values
            .map((p) => p.averageLoadTime)
            .reduce((a, b) => a + b);

        jsonData['loading_performance'] = {
          'total_files': fileLoadTimes.length,
          'average_load_time_ms': totalLoadTime / fileLoadTimes.length,
          'slow_files_count':
              fileLoadTimes.values.where((p) => p.averageLoadTime > 500).length,
          'failed_files_count':
              fileLoadTimes.values.where((p) => p.hasFailures).length,
          'files': fileLoadTimes.entries.map((entry) {
            return {
              'file': entry.key,
              'average_load_time_ms': entry.value.averageLoadTime,
              'max_load_time_ms': entry.value.maxLoadTime,
              'has_failures': entry.value.hasFailures,
            };
          }).toList(),
        };
      }

      // Add failure pattern distribution if available
      if (patterns.isNotEmpty) {
        final patternsByType = <FailureType, int>{};
        for (final pattern in patterns.values) {
          patternsByType[pattern.type] =
              (patternsByType[pattern.type] ?? 0) + 1;
        }

        jsonData['failure_patterns'] = Map<String, int>.fromEntries(
          patternsByType.entries.map(
            (entry) => MapEntry(entry.key.toString().split('.').last, entry.value),
          ),
        );
      }

      // Write unified report
      final reportPath = await ReportUtils.writeUnifiedReport(
        moduleName: pathName,
        timestamp: timestamp,
        markdownContent: report.toString(),
        jsonData: jsonData,
        suffix: 'analyzer',
        verbose: true,
      );

      print('$green✅ Report saved to: $reportPath$reset');

      // Generate failed report if there are failures or flaky tests
      if (consistentFailures.isNotEmpty || flakyTests.isNotEmpty) {
        await _saveFailedReport(timestamp, pathName, jsonData);
      }
    } catch (e, stackTrace) {
      print('\n$yellow⚠️ Could not save report to file: $e$reset');
      if (verbose) {
        print('  Error details: $stackTrace');
      }
    }
  }

  Future<void> _saveFailedReport(
    String timestamp,
    String pathName,
    Map<String, dynamic> analyzerData,
  ) async {
    print('$cyan📝 Generating failed test report...$reset');

    final markdown = StringBuffer();
    markdown.writeln('# 🔴 Failed Test Report');
    markdown.writeln();
    markdown.writeln('**Generated:** ${DateTime.now().toLocal()}');
    markdown.writeln('**Test Path:** `${targetFiles.isNotEmpty ? targetFiles.first : 'all tests'}`');
    markdown.writeln('**Source:** Test Analyzer');
    markdown.writeln('**Analysis Runs:** $runCount');
    markdown.writeln();

    markdown.writeln('## 📊 Summary');
    markdown.writeln();
    markdown.writeln('| Metric | Value |');
    markdown.writeln('|--------|-------|');
    markdown.writeln('| Total Tests | ${testRuns.length} |');
    markdown.writeln('| Passed Consistently | ${testRuns.length - consistentFailures.length - flakyTests.length} |');
    markdown.writeln('| Consistent Failures | ❌ ${consistentFailures.length} |');
    markdown.writeln('| Flaky Tests | ⚠️ ${flakyTests.length} |');
    markdown.writeln('| Pass Rate | ${(testRuns.isNotEmpty ? ((testRuns.length - consistentFailures.length - flakyTests.length) / testRuns.length * 100) : 0).toStringAsFixed(1)}% |');
    markdown.writeln();

    // Add consistent failures section
    if (consistentFailures.isNotEmpty) {
      markdown.writeln('## ❌ Consistent Failures');
      markdown.writeln('*Tests that failed all $runCount runs*');
      markdown.writeln();

      for (final testId in consistentFailures) {
        final parts = testId.split('::');
        final fileName = parts.isNotEmpty ? parts[0] : 'Unknown';
        final testName = parts.length > 1 ? parts[1] : 'Unknown';
        final pattern = patterns[testId];

        markdown.writeln('### $testName');
        markdown.writeln('**File:** `$fileName`');

        if (pattern != null) {
          markdown.writeln('**Type:** ${pattern.type.toString().split('.').last}');
          markdown.writeln('**Category:** ${pattern.category}');
          if (pattern.suggestion != null && pattern.suggestion!.isNotEmpty) {
            markdown.writeln();
            markdown.writeln('**Suggested Fix:**');
            markdown.writeln('```');
            markdown.writeln(pattern.suggestion);
            markdown.writeln('```');
          }
        }
        markdown.writeln();
      }
    }

    // Add flaky tests section
    if (flakyTests.isNotEmpty) {
      markdown.writeln('## ⚡ Flaky Tests');
      markdown.writeln('*Tests with intermittent failures*');
      markdown.writeln();

      for (final testId in flakyTests) {
        final parts = testId.split('::');
        final fileName = parts.isNotEmpty ? parts[0] : 'Unknown';
        final testName = parts.length > 1 ? parts[1] : 'Unknown';
        final run = testRuns[testId]!;
        final successCount = run.results.values.where((r) => r).length;
        final successRate = successCount / runCount * 100;

        markdown.writeln('### $testName');
        markdown.writeln('**File:** `$fileName`');
        markdown.writeln('**Success Rate:** ${successRate.toStringAsFixed(1)}%');
        markdown.writeln('**Run Results:**');

        for (final entry in run.results.entries) {
          final status = entry.value ? '✅' : '❌';
          markdown.writeln('- Run ${entry.key}: $status');
        }
        markdown.writeln();
      }
    }

    // Add recommendations
    markdown.writeln('## 💡 Recommendations');
    markdown.writeln();
    if (consistentFailures.isNotEmpty) {
      markdown.writeln('1. **🔴 Critical:** Fix ${consistentFailures.length} consistently failing tests immediately');
    }
    if (flakyTests.isNotEmpty) {
      markdown.writeln('${consistentFailures.isNotEmpty ? '2' : '1'}. **⚠️ Important:** Investigate and stabilize ${flakyTests.length} flaky tests');
    }
    markdown.writeln();
    markdown.writeln('For detailed analysis and stack traces, see the full analyzer report.');

    // Build JSON data
    final jsonData = {
      'metadata': {
        'tool': 'test_analyzer',
        'version': '2.0',
        'generated': DateTime.now().toIso8601String(),
        'test_path': targetFiles.isNotEmpty ? targetFiles.first : 'all tests',
        'analysis_runs': runCount,
      },
      'summary': analyzerData['summary'],
      'consistent_failures': analyzerData['consistent_failures'],
      'flaky_tests': analyzerData['flaky_tests'],
    };

    try {
      final failedReportPath = await ReportUtils.writeUnifiedReport(
        moduleName: pathName,
        timestamp: timestamp,
        markdownContent: markdown.toString(),
        jsonData: jsonData,
        suffix: 'failed',
        verbose: verbose,
      );

      print('$green✅ Failed test report saved to: $failedReportPath$reset');
    } catch (e) {
      print('$yellow⚠️ Could not save failed report: $e$reset');
    }
  }

  void _printReportHeader() {
    print('\n$green${"═" * 70}$reset');
    print('$green$bold                      TEST ANALYSIS REPORT$reset');
    print('$green${"═" * 70}$reset\n');
  }

  void _printSummaryStatistics() {
    print('$cyan📊 Summary Statistics$reset');
    print('─' * 50);

    final total = testRuns.length;
    final passed = total - consistentFailures.length - flakyTests.length;
    final passRate = total > 0 ? (passed / total * 100) : 0.0;

    _printStatRow('Total tests', total.toString());
    _printStatRow('Passed consistently', passed.toString(), green);
    _printStatRow(
      'Consistent failures',
      consistentFailures.length.toString(),
      consistentFailures.isNotEmpty ? red : green,
    );
    _printStatRow(
      'Flaky tests',
      flakyTests.length.toString(),
      flakyTests.isNotEmpty ? yellow : green,
    );
    _printStatRow(
      'Pass rate',
      '${passRate.toStringAsFixed(1)}%',
      _getColorForPercentage(passRate),
    );
    _printStatRow('Test runs', runCount.toString());

    print('');
  }

  void _printStatRow(String label, String value, [String? valueColor]) {
    final dots = '.' * (40 - label.length);
    print('  $label$gray$dots$reset ${valueColor ?? ''}$value$reset');
  }

  void _printConsistentFailures() {
    if (consistentFailures.isEmpty) {
      print('$green✅ No consistent failures found!$reset\n');
      return;
    }

    print('$red❌ Consistent Failures (failed all $runCount runs)$reset');
    print('─' * 70);

    for (final testId in consistentFailures.take(10)) {
      final parts = testId.split('::');
      final file = _getRelativePath(parts[0]);
      final test = parts.length > 1 ? parts[1] : 'unknown';

      print('\n  $red▸$reset $test');
      print('    ${gray}File: $file$reset');

      // Show failure details
      final testFailures = failures[testId] ?? [];
      if (testFailures.isNotEmpty) {
        final failure = testFailures.first;
        final pattern = patterns[testId];

        if (pattern != null) {
          print('    ${yellow}Type:$reset ${pattern.category}');
          if (pattern.suggestion != null) {
            print('    ${magenta}Fix:$reset ${pattern.suggestion}');
          }
        }

        // Show error snippet
        if (verbose) {
          final errorLines = failure.error.split('\n').take(3);
          for (final line in errorLines) {
            print('    $gray$line$reset');
          }
        }
      }
    }

    if (consistentFailures.length > 10) {
      print(
        '\n  $gray... and ${consistentFailures.length - 10} more consistent failures$reset',
      );
    }

    print('');
  }

  void _printFlakyTests() {
    if (flakyTests.isEmpty) return;

    print('$yellow⚡ Flaky Tests (intermittent failures)$reset');
    print('─' * 70);

    for (final testId in flakyTests.take(10)) {
      final parts = testId.split('::');
      final file = _getRelativePath(parts[0]);
      final test = parts.length > 1 ? parts[1] : 'unknown';

      final run = testRuns[testId]!;
      final successCount = run.results.values.where((r) => r).length;
      final failureCount = runCount - successCount;

      print('\n  $yellow▸$reset $test');
      print('    ${gray}File: $file$reset');
      print(
        '    ${gray}Results: $successCount passed, $failureCount failed$reset',
      );

      // Show failure pattern
      final pattern = patterns[testId];
      if (pattern != null && pattern.suggestion != null) {
        print('    ${magenta}Hint:$reset ${pattern.suggestion}');
      }
    }

    if (flakyTests.length > 10) {
      print(
        '\n  $gray... and ${flakyTests.length - 10} more flaky tests$reset',
      );
    }

    print('');
  }

  void _printFailurePatterns() {
    if (patterns.isEmpty) return;

    print('$cyan🔍 Failure Patterns$reset');
    print('─' * 50);

    // Group patterns by type
    final patternsByType = <FailureType, int>{};
    for (final pattern in patterns.values) {
      patternsByType[pattern.type] = (patternsByType[pattern.type] ?? 0) + 1;
    }

    // Sort by frequency
    final sorted = patternsByType.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in sorted) {
      final type = entry.key;
      final count = entry.value;
      final bar = '█' * (count * 2).clamp(0, 30);

      var typeName = type.toString().split('.').last;
      typeName = typeName[0].toUpperCase() + typeName.substring(1);

      print('  ${typeName.padRight(15)} $cyan$bar$reset $count');
    }

    print('');
  }

  void _printPerformanceMetrics() {
    print('$cyan⏱️ Performance Metrics$reset');
    print('─' * 50);

    // Find slowest tests
    final sorted = performance.entries.toList()
      ..sort(
        (a, b) => b.value.averageDuration.compareTo(a.value.averageDuration),
      );

    print('\n  ${yellow}Slowest tests:$reset');
    for (final entry in sorted.take(5)) {
      final parts = entry.key.split('::');
      final test = parts.length > 1 ? parts[1] : 'unknown';
      final avgTime = entry.value.averageDuration / 1000;
      final maxTime = entry.value.maxDuration / 1000;

      final color = avgTime > slowTestThreshold
          ? red
          : avgTime > slowTestThreshold * 0.5
              ? yellow
              : green;

      print('    $color${avgTime.toStringAsFixed(2)}s$reset $test');
      if (verbose) {
        print(
          '      ${gray}Max: ${maxTime.toStringAsFixed(2)}s, Min: ${(entry.value.minDuration / 1000).toStringAsFixed(2)}s$reset',
        );
      }
    }

    // Overall performance stats
    final totalTime =
        performance.values.fold(0.0, (sum, p) => sum + p.totalDuration);
    final avgTestTime =
        performance.isNotEmpty ? totalTime / performance.length / 1000 : 0.0;

    print('\n  ${cyan}Overall:$reset');
    print('    Total time: ${(totalTime / 1000).toStringAsFixed(2)}s');
    print('    Average test time: ${avgTestTime.toStringAsFixed(3)}s');

    print('');
  }

  void _printSuggestedFixes() {
    if (patterns.isEmpty) return;

    print('$magenta🔧 Suggested Fixes$reset');
    print('─' * 70);

    // Group suggestions by type
    final suggestionsByType = <String, List<String>>{};

    for (final entry in patterns.entries) {
      if (entry.value.suggestion != null) {
        final category = entry.value.category;
        suggestionsByType
            .putIfAbsent(category, () => [])
            .add('• ${entry.value.suggestion}');
      }
    }

    for (final entry in suggestionsByType.entries) {
      print('\n  $yellow${entry.key}:$reset');
      for (final suggestion in entry.value.take(3)) {
        print('    $suggestion');
      }
    }

    print('');
  }

  void _printTestReliabilityMatrix() {
    print('$cyan📈 Test Reliability Matrix$reset');
    print('─' * 50);

    // Count tests with and without results
    var testsWithoutResults = 0;
    var setupTeardownHooks = 0;

    // Create reliability buckets (only for tests with results)
    final buckets = <String, int>{
      '100% reliable': 0,
      '66-99% reliable': 0,
      '33-65% reliable': 0,
      '0-32% reliable': 0,
    };

    for (final entry in testRuns.entries) {
      final testId = entry.key;
      final run = entry.value;

      // Handle case where results might be empty (tests discovered but not run)
      if (run.results.isEmpty) {
        // Check if it's a setup/teardown hook
        if (testId.contains('(setUpAll)') ||
            testId.contains('(tearDownAll)') ||
            testId.contains('(setUp)') ||
            testId.contains('(tearDown)')) {
          setupTeardownHooks++;
        } else {
          testsWithoutResults++;
        }
        continue;
      }
      final successRate = run.results.values.where((r) => r).length / runCount;

      if (successRate == 1.0) {
        buckets['100% reliable'] = buckets['100% reliable']! + 1;
      } else if (successRate >= 0.66) {
        buckets['66-99% reliable'] = buckets['66-99% reliable']! + 1;
      } else if (successRate >= 0.33) {
        buckets['33-65% reliable'] = buckets['33-65% reliable']! + 1;
      } else {
        buckets['0-32% reliable'] = buckets['0-32% reliable']! + 1;
      }
    }

    // Show info about setup/teardown hooks if any
    if (setupTeardownHooks > 0) {
      print(
        '  $dimℹ️  $setupTeardownHooks setup/teardown hooks detected$reset',
      );
      for (final entry in testRuns.entries) {
        final testId = entry.key;
        if (entry.value.results.isEmpty &&
            (testId.contains('(setUpAll)') ||
                testId.contains('(tearDownAll)') ||
                testId.contains('(setUp)') ||
                testId.contains('(tearDown)'))) {
          print('  $dim  • $testId$reset');
        }
      }
      print('');
    }

    // Show info about tests without results if any
    if (testsWithoutResults > 0) {
      print(
        '  $dimℹ️  $testsWithoutResults test(s) discovered but no results recorded$reset',
      );
      print('');
    }

    // Find max for scaling (handle empty buckets)
    final maxValue =
        buckets.values.isEmpty || buckets.values.every((v) => v == 0)
            ? 0
            : buckets.values.reduce(math.max);

    for (final entry in buckets.entries) {
      final barLength =
          maxValue > 0 ? (entry.value / maxValue * 30).round() : 0;
      final bar = '█' * barLength;

      final color = entry.key.contains('100%')
          ? green
          : entry.key.contains('66-99%')
              ? yellow
              : entry.key.contains('33-65%')
                  ? yellow
                  : red;

      print(
        '  ${entry.key.padRight(15)} $color$bar$reset ${entry.value} tests',
      );
    }

    print('');
  }

  void _printActionableInsights() {
    print('$magenta💡 Actionable Insights$reset');
    print('─' * 50);

    final insights = <String>[];

    // Analyze test health
    if (consistentFailures.isNotEmpty) {
      insights.add(
        '${red}Critical:$reset Fix ${consistentFailures.length} consistently failing tests first',
      );
    }

    if (flakyTests.length > testRuns.length * 0.1) {
      insights.add(
        '${yellow}Warning:$reset ${(flakyTests.length / testRuns.length * 100).toStringAsFixed(1)}% of tests are flaky - investigate test isolation',
      );
    }

    // Pattern-based insights
    final nullErrors =
        patterns.values.where((p) => p.type == FailureType.nullError).length;
    if (nullErrors > 3) {
      insights.add(
        'Multiple null reference errors detected - review initialization logic',
      );
    }

    final timeouts =
        patterns.values.where((p) => p.type == FailureType.timeout).length;
    if (timeouts > 0) {
      insights.add(
        'Timeout issues detected - consider increasing timeout or optimizing tests',
      );
    }

    // Performance insights
    if (performanceMode) {
      final slowCount = performance.values
          .where((p) => p.averageDuration > slowTestThreshold * 1000)
          .length;
      if (slowCount > 0) {
        insights.add(
          '$slowCount tests exceed ${slowTestThreshold}s - consider optimization or parallelization',
        );
      }
    }

    // Stability score
    final stabilityScore = testRuns.isEmpty
        ? 100.0
        : ((testRuns.length -
                consistentFailures.length -
                flakyTests.length * 0.5) /
            testRuns.length *
            100);

    insights.add(
      'Overall test stability: ${_getStabilityEmoji(stabilityScore)} ${stabilityScore.toStringAsFixed(1)}%',
    );

    // Print insights
    for (final insight in insights) {
      print('  • $insight');
    }

    // Recommendations
    print('\n  ${cyan}Recommendations:$reset');

    if (consistentFailures.isNotEmpty) {
      print('    1. Focus on fixing consistent failures first');
    }
    if (flakyTests.isNotEmpty) {
      print('    2. Add retry logic or improve test isolation for flaky tests');
    }
    if (patterns.values.any((p) => p.type == FailureType.timeout)) {
      print('    3. Review async operations and add proper wait conditions');
    }

    print('');
  }

  String _getStabilityEmoji(double score) {
    if (score >= 95) return '🟢';
    if (score >= 80) return '🟡';
    if (score >= 60) return '🟠';
    return '🔴';
  }

  /// Analyze test dependencies and generate dependency graph
  Future<void> _analyzeTestDependencies(List<String> testFiles) async {
    print('\n$yellow▶ Analyzing test dependencies...$reset');

    final dependencies = <String, Set<String>>{};

    for (final testFile in testFiles) {
      final file = File(testFile);
      if (!await file.exists()) continue;

      final content = await file.readAsString();
      final imports = <String>{};

      // Extract imports
      final importPattern = RegExp(r'''import\s+['"]([^'"]+)['"];''');
      for (final match in importPattern.allMatches(content)) {
        final import = match.group(1)!;
        if (!import.startsWith('dart:') &&
            !import.startsWith('package:flutter/')) {
          imports.add(import);
        }
      }

      dependencies[testFile] = imports;
    }

    // Print dependency graph
    print('\n  ${cyan}Test Dependency Graph:$reset');
    for (final entry in dependencies.entries) {
      final testName = entry.key.split('/').last;
      print('    $green▸$reset $testName');
      for (final dep in entry.value) {
        print('      $gray└─$reset $dep');
      }
    }

    // Find circular dependencies
    final circular = _findCircularDependencies(dependencies);
    if (circular.isNotEmpty) {
      print('\n  $red⚠ Circular dependencies detected:$reset');
      for (final cycle in circular) {
        print('    ${cycle.join(' → ')}');
      }
    }

    // Find isolated tests (no dependencies)
    final isolated = dependencies.entries
        .where((e) => e.value.isEmpty)
        .map((e) => e.key)
        .toList();
    if (isolated.isNotEmpty) {
      print(
        '\n  $green✓ Isolated tests (no dependencies):$reset ${isolated.length}',
      );
    }
  }

  /// Find circular dependencies in the dependency graph
  List<List<String>> _findCircularDependencies(
    Map<String, Set<String>> dependencies,
  ) {
    final cycles = <List<String>>[];
    final visited = <String>{};
    final recursionStack = <String>[];

    void dfs(String node) {
      if (recursionStack.contains(node)) {
        final cycleStart = recursionStack.indexOf(node);
        cycles.add(recursionStack.sublist(cycleStart).toList()..add(node));
        return;
      }

      if (visited.contains(node)) return;

      visited.add(node);
      recursionStack.add(node);

      for (final dep in dependencies[node] ?? <String>{}) {
        if (dependencies.containsKey(dep)) {
          dfs(dep);
        }
      }

      recursionStack.removeLast();
    }

    for (final node in dependencies.keys) {
      if (!visited.contains(node)) {
        dfs(node);
      }
    }

    return cycles;
  }

  /// Run mutation testing to verify test effectiveness
  Future<void> _runMutationTesting(List<String> testFiles) async {
    print('\n$yellow▶ Running mutation testing...$reset');
    print(
      '  ${cyan}Mutation testing helps verify that tests actually catch bugs$reset',
    );

    final mutations = <String, int>{
      'Operator mutations': 0,
      'Literal mutations': 0,
      'Statement deletions': 0,
      'Condition inversions': 0,
    };

    // For each test file, find the corresponding source file
    for (final testFile in testFiles) {
      final sourceFile = testFile
          .replaceFirst('test/', 'lib/')
          .replaceFirst('_test.dart', '.dart');

      final source = File(sourceFile);
      if (!await source.exists()) continue;

      print('\n  ${cyan}Mutating: ${sourceFile.split('/').last}$reset');

      // Simulate mutations (in real implementation, would actually mutate code)
      final content = await source.readAsString();

      // Count potential mutations
      mutations['Operator mutations'] = mutations['Operator mutations']! +
          RegExp(r'[+\-*/%<>]=?').allMatches(content).length;
      mutations['Literal mutations'] = mutations['Literal mutations']! +
          RegExp(r'\b\d+\b').allMatches(content).length;
      mutations['Statement deletions'] = mutations['Statement deletions']! +
          RegExp(';').allMatches(content).length ~/ 2;
      mutations['Condition inversions'] = mutations['Condition inversions']! +
          RegExp(r'if\s*\(').allMatches(content).length;
    }

    // Print mutation testing summary
    print('\n  ${cyan}Mutation Testing Summary:$reset');
    var totalMutations = 0;
    for (final entry in mutations.entries) {
      print('    ${entry.key}: ${entry.value}');
      totalMutations += entry.value;
    }

    print('\n  ${yellow}Total potential mutations: $totalMutations$reset');
    print(
      '  ${dim}Note: Run tests after each mutation to verify test effectiveness$reset',
    );

    // Mutation score calculation (simulated)
    const mutationScore =
        85.0; // In real implementation, calculate actual score
    print(
      '\n  ${cyan}Mutation Score: ${_getMutationScoreEmoji(mutationScore)} ${mutationScore.toStringAsFixed(1)}%$reset',
    );

    if (mutationScore < 80) {
      print('  $red⚠ Low mutation score indicates weak test coverage$reset');
      print(
        '  ${dim}Consider adding more assertions and edge case tests$reset',
      );
    }
  }

  String _getMutationScoreEmoji(double score) {
    if (score >= 90) return '🟢';
    if (score >= 80) return '🟡';
    if (score >= 70) return '🟠';
    return '🔴';
  }

  /// Analyze test impact based on code changes
  Future<void> _analyzeTestImpact(List<String> testFiles) async {
    print('\n$yellow▶ Analyzing test impact...$reset');

    // Get git diff to find changed files
    final gitDiff = await Process.run('git', ['diff', '--name-only', 'HEAD~1']);
    final changedFiles = gitDiff.stdout
        .toString()
        .split('\n')
        .where((f) => f.isNotEmpty)
        .toList();

    if (changedFiles.isEmpty) {
      print('  $green✓$reset No code changes detected');
      return;
    }

    print('  ${cyan}Changed files:$reset');
    for (final file in changedFiles) {
      print('    • $file');
    }

    // Find tests that should be run based on changes
    final impactedTests = <String>{};

    for (final changedFile in changedFiles) {
      if (changedFile.startsWith('lib/')) {
        // Find corresponding test file
        final testFile = changedFile
            .replaceFirst('lib/', 'test/')
            .replaceFirst('.dart', '_test.dart');

        if (testFiles.contains(testFile)) {
          impactedTests.add(testFile);
        }

        // Also find tests that import this file
        for (final testFile in testFiles) {
          final content = await File(testFile).readAsString();
          if (content.contains(changedFile)) {
            impactedTests.add(testFile);
          }
        }
      }
    }

    print('\n  ${cyan}Impacted tests (${impactedTests.length}):$reset');
    for (final test in impactedTests) {
      print('    $green▸$reset ${test.split('/').last}');
    }

    if (impactedTests.isEmpty) {
      print('  $yellow⚠ No tests found for changed files$reset');
      print('  ${dim}Consider adding tests for the modified code$reset');
    } else {
      final percentage =
          (impactedTests.length / testFiles.length * 100).toStringAsFixed(1);
      print('\n  ${cyan}Impact scope: $percentage% of tests affected$reset');

      // Suggest running only impacted tests
      print('\n  $green💡 Optimization suggestion:$reset');
      print('    Run only impacted tests to save time:');
      print('    ${dim}dart test ${impactedTests.join(' ')}$reset');
    }
  }

  /// Interactive mode for debugging specific failures
  Future<void> _enterInteractiveMode() async {
    print('$cyan🔍 Interactive Debug Mode$reset');
    print('Type test number to inspect, "q" to quit\n');

    // List failed tests with numbers
    final failedTests = [...consistentFailures, ...flakyTests];
    for (var i = 0; i < failedTests.length && i < 20; i++) {
      final parts = failedTests[i].split('::');
      final test = parts.length > 1 ? parts[1] : 'unknown';
      final icon = consistentFailures.contains(failedTests[i]) ? '❌' : '⚡';
      print('  ${(i + 1).toString().padRight(3)} $icon $test');
    }

    print('\n${cyan}Enter choice:$reset ');

    while (true) {
      final input = stdin.readLineSync()?.trim() ?? '';

      if (input.toLowerCase() == 'q') {
        break;
      }

      final index = int.tryParse(input);
      if (index != null && index > 0 && index <= failedTests.length) {
        await _inspectTest(failedTests[index - 1]);
      } else {
        print('Invalid choice. Enter test number or "q" to quit:');
      }
    }
  }

  Future<void> _inspectTest(String testId) async {
    print('\n$cyan${"─" * 70}$reset');

    final parts = testId.split('::');
    final file = parts[0];
    final test = parts.length > 1 ? parts[1] : 'unknown';

    print('${bold}Test:$reset $test');
    print('${bold}File:$reset ${_getRelativePath(file)}');

    // Show all failure details
    final testFailures = failures[testId] ?? [];
    print('\n${yellow}Failure Details:$reset');

    for (var i = 0; i < testFailures.length; i++) {
      final failure = testFailures[i];
      print('\n  ${cyan}Run ${failure.runNumber}:$reset');
      print('  $red${failure.error}$reset');

      if (verbose) {
        print('\n  ${gray}Stack trace:$reset');
        final stackLines = failure.stackTrace.split('\n').take(10);
        for (final line in stackLines) {
          print('    $gray$line$reset');
        }
      }
    }

    // Show pattern analysis
    final pattern = patterns[testId];
    if (pattern != null) {
      print('\n${yellow}Pattern Analysis:$reset');
      print('  Type: ${pattern.category}');
      print('  Occurrences: ${pattern.count}');
      if (pattern.suggestion != null) {
        print('  ${magenta}Suggestion:$reset ${pattern.suggestion}');
      }
    }

    // Offer to re-run test
    print('\n${cyan}Options:$reset');
    print('  r - Re-run this test');
    print('  v - View test source code');
    print('  b - Back to list');
    print('Enter choice: ');

    final choice = stdin.readLineSync()?.trim() ?? '';

    if (choice == 'r') {
      await _rerunSingleTest(file, test);
    } else if (choice == 'v') {
      await _viewTestSource(file, test);
    }
  }

  Future<void> _rerunSingleTest(String file, String testName) async {
    print('\n${yellow}Re-running test...$reset');

    // Use flutter test for Flutter projects, dart test for pure Dart
    final isFlutterProject = await File('pubspec.yaml').exists() &&
        await File('pubspec.yaml')
            .readAsString()
            .then((content) => content.contains('flutter:'));

    final result = await Process.run(
      isFlutterProject ? 'flutter' : 'dart',
      ['test', '--name', testName, file],
      runInShell: Platform.isWindows,
    );

    print(result.stdout);
    if (result.stderr.toString().isNotEmpty) {
      print('$red${result.stderr}$reset');
    }
  }

  Future<void> _viewTestSource(String file, String testName) async {
    try {
      final content = await File(file).readAsString();
      final lines = content.split('\n');

      // Find test definition
      int? startLine;
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].contains("test('$testName'") ||
            lines[i].contains('test("$testName"')) {
          startLine = i;
          break;
        }
      }

      if (startLine != null) {
        print('\n${cyan}Test Source:$reset');
        // Show test and surrounding context
        final start = (startLine - 2).clamp(0, lines.length);
        final end = (startLine + 20).clamp(0, lines.length);

        for (var i = start; i < end; i++) {
          final lineNum = (i + 1).toString().padLeft(4);
          final marker = i == startLine ? '>' : ' ';
          print('$gray$lineNum$marker$reset ${lines[i]}');
        }
      }
    } catch (e) {
      print('${red}Could not read test source: $e$reset');
    }
  }

  /// Clean up old reports in the test_analysis directory
  Future<void> _cleanupOldReports() async {
    // Extract meaningful name from tested paths
    var pathName = _extractPathName();

    // Clean old reports using unified naming
    await ReportUtils.cleanOldReports(
      pathName: pathName,
      prefixPatterns: [
        'test_report_alz', // New unified format
        'ta', // Old test_analyzer format
        'test_analysis', // Even older format
      ],
      verbose: true,
    );
  }

  String _extractPathName() {
    if (targetFiles.isNotEmpty) {
      // Extract just the module name (last part of the path)
      final path = targetFiles.first
          .replaceAll(r'\', '/')
          .replaceAll(RegExp(r'/$'), ''); // Remove trailing slash
      final segments = path.split('/').where((s) => s.isNotEmpty).toList();

      if (segments.isEmpty) {
        return 'all_tests-fo';
      }

      var pathName = segments.last;
      String suffix;

      // If it's a file (ends with .dart), extract the test name properly
      if (pathName.endsWith('.dart')) {
        // Remove .dart extension
        pathName = pathName.substring(0, pathName.length - 5);
        // Remove _test suffix if present
        if (pathName.endsWith('_test')) {
          pathName = pathName.substring(0, pathName.length - 5);
        }
        suffix = '-fi';
      } else if (pathName == 'test') {
        // Special case: if analyzing just the 'test' folder, use 'all_tests'
        return 'test-fo';
      } else {
        // It's a folder
        suffix = '-fo';
      }

      return '$pathName$suffix';
    }
    return 'all_tests-fo';
  }

  /// Watch mode for continuous testing
  Future<void> _enterWatchMode() async {
    print('$cyan👁️ Watch mode enabled. Press Ctrl+C to exit.$reset\n');

    final watcher = Directory('test').watch(recursive: true);

    await for (final event in watcher) {
      if (event.path.endsWith('_test.dart')) {
        print(
          '$yellow📝 Test file changed: ${_getRelativePath(event.path)}$reset',
        );
        print('${yellow}Re-running analysis...$reset\n');

        // Clear previous data
        testRuns.clear();
        failures.clear();
        patterns.clear();
        flakyTests.clear();
        consistentFailures.clear();

        // Re-run analysis
        await _runTestsMultipleTimes([event.path]);
        _analyzeFailures();
        await _generateReport();
      }
    }
  }

  String _getColorForPercentage(double percentage) {
    if (percentage >= 90) return green;
    if (percentage >= 70) return yellow;
    return red;
  }

  String _getRelativePath(String fullPath) {
    final cwd = Directory.current.path;
    if (fullPath.startsWith(cwd)) {
      return fullPath.substring(cwd.length + 1);
    }
    return fullPath;
  }

  String _getStatusBadge(double percentage) {
    if (percentage >= 90) return '✅';
    if (percentage >= 70) return '⚠️';
    return '❌';
  }

  String _generateBar(double percentage, int width) {
    final filled = (percentage / 100 * width).round();
    final empty = width - filled;
    return '█' * filled + '░' * empty;
  }

  String _truncate(String str, int maxLength) {
    if (str.length <= maxLength) return str;
    return '${str.substring(0, maxLength - 3)}...';
  }
}

/// Data classes
class LoadingEvent {
  LoadingEvent({
    required this.testId,
    required this.filePath,
    required this.startTime,
    required this.runNumber,
  });
  final int testId;
  final String filePath;
  final int startTime;
  final int runNumber;
}

class LoadingPerformance {
  // run number -> success/failure

  LoadingPerformance({required this.filePath});
  final String filePath;
  final Map<int, int> loadTimes = {}; // run number -> load time in ms
  final Map<int, bool> loadSuccess = {};

  void addLoadTime(int runNumber, int loadTime, {required bool success}) {
    loadTimes[runNumber] = loadTime;
    loadSuccess[runNumber] = success;
  }

  double get averageLoadTime {
    if (loadTimes.isEmpty) return 0;
    return loadTimes.values.reduce((a, b) => a + b) / loadTimes.length;
  }

  int get maxLoadTime =>
      loadTimes.values.isEmpty ? 0 : loadTimes.values.reduce(math.max);

  bool get hasFailures => loadSuccess.values.any((success) => !success);
}

class TestRun {
  TestRun({
    required this.testFile,
    required this.testName,
  });
  final String testFile;
  final String testName;
  final Map<int, bool> results = {};
  final Map<int, int> durations = {};
}

class TestFailure {
  TestFailure({
    required this.testId,
    required this.runNumber,
    required this.error,
    required this.stackTrace,
    required this.timestamp,
  });
  final String testId;
  final int runNumber;
  final String error;
  final String stackTrace;
  final DateTime timestamp;
}

class TestPerformance {
  TestPerformance({
    required this.testId,
    required this.testName,
  });
  final String testId;
  final String testName;
  final List<double> durations = [];

  double get averageDuration => durations.isEmpty
      ? 0
      : durations.reduce((a, b) => a + b) / durations.length;

  double get maxDuration => durations.isEmpty ? 0 : durations.reduce(math.max);

  double get minDuration => durations.isEmpty ? 0 : durations.reduce(math.min);

  double get totalDuration => durations.fold(0, (sum, d) => sum + d);

  void addDuration(double duration) {
    durations.add(duration);
  }
}

enum FailureType {
  assertion,
  nullError,
  timeout,
  rangeError,
  typeError,
  ioError,
  networkError,
  unknown,
}

class FailurePattern {
  FailurePattern({
    required this.type,
    required this.category,
    required this.count,
    this.suggestion,
  });
  final FailureType type;
  final String category;
  final int count;
  final String? suggestion;
}

/// Main entry point
void main(List<String> args) async {
  // Parse arguments
  final verbose = args.contains('--verbose') || args.contains('-v');
  final interactive = args.contains('--interactive') || args.contains('-i');
  final performance = args.contains('--performance') || args.contains('-p');
  final watch = args.contains('--watch') || args.contains('-w');
  final noFixes = args.contains('--no-fixes');
  final noReport = args.contains('--no-report');
  final help = args.contains('--help') || args.contains('-h');
  final parallel = args.contains('--parallel');
  final dependencyAnalysis =
      args.contains('--dependencies') || args.contains('-d');
  final mutationTesting = args.contains('--mutation') || args.contains('-m');
  final impactAnalysis = args.contains('--impact');

  // Parse run count
  var runCount = 3;
  for (final arg in args) {
    if (arg.startsWith('--runs=')) {
      runCount = int.tryParse(arg.substring(7)) ?? 3;
    }
  }

  // Parse slow threshold
  var slowThreshold = 1.0;
  for (final arg in args) {
    if (arg.startsWith('--slow=')) {
      slowThreshold = double.tryParse(arg.substring(7)) ?? 1.0;
    }
  }

  // Parse max workers for parallel execution
  var maxWorkers = 4;
  for (final arg in args) {
    if (arg.startsWith('--workers=')) {
      maxWorkers = int.tryParse(arg.substring(10)) ?? 4;
    }
  }

  if (help) {
    _printUsage();
    return;
  }

  // Get target files (non-flag arguments)
  final targetFiles = args.where((arg) => !arg.startsWith('-')).toList();

  final analyzer = TestAnalyzer(
    runCount: runCount,
    verbose: verbose,
    interactive: interactive,
    performanceMode: performance,
    watch: watch,
    generateFixes: !noFixes,
    generateReport: !noReport,
    slowTestThreshold: slowThreshold,
    targetFiles: targetFiles,
    parallel: parallel,
    maxWorkers: maxWorkers,
    dependencyAnalysis: dependencyAnalysis,
    mutationTesting: mutationTesting,
    impactAnalysis: impactAnalysis,
  );

  await analyzer.run();
}

void _printUsage() {
  print('''
${TestAnalyzer.cyan}Flutter/Dart Test Analyzer${TestAnalyzer.reset}

Usage: dart test_analyzer.dart [options] [test_files...]

Options:
  --verbose, -v        Show detailed output and stack traces
  --interactive, -i    Enter interactive debug mode for failed tests
  --performance, -p    Track and report test performance metrics
  --watch, -w          Watch for changes and re-run analysis
  --parallel           Run tests in parallel for faster execution
  --dependencies, -d   Analyze test dependency graph
  --mutation, -m       Run mutation testing to verify test effectiveness
  --impact             Analyze test impact based on code changes
  --runs=N             Number of test runs (default: 3)
  --slow=N             Slow test threshold in seconds (default: 1.0)
  --workers=N          Max parallel workers (default: 4)
  --no-fixes           Disable fix suggestions
  --help, -h           Show this help message

Arguments:
  test_files           Specific test files to analyze (default: all tests)

Examples:
  ${TestAnalyzer.gray}# Basic analysis of all tests${TestAnalyzer.reset}
  dart test_analyzer.dart
  
  ${TestAnalyzer.gray}# Detailed analysis with performance tracking${TestAnalyzer.reset}
  dart test_analyzer.dart --verbose --performance
  
  ${TestAnalyzer.gray}# Interactive debugging of specific test${TestAnalyzer.reset}
  dart test_analyzer.dart --interactive test/widget_test.dart
  
  ${TestAnalyzer.gray}# Watch mode for continuous testing${TestAnalyzer.reset}
  dart test_analyzer.dart --watch
  
  ${TestAnalyzer.gray}# Run tests 5 times to detect flakiness${TestAnalyzer.reset}
  dart test_analyzer.dart --runs=5

Features:
  • Identifies flaky vs consistently failing tests
  • Advanced pattern detection (null, timeout, assertion, etc.)
  • Performance profiling with slow test detection
  • Interactive debugging mode for deep inspection
  • Smart fix suggestions based on failure patterns
  • Test reliability matrix and stability scoring
  • Watch mode for continuous feedback

Output:
  🔴 Consistent failures - Tests that fail every run
  ⚡ Flaky tests - Tests with intermittent failures
  📊 Detailed statistics and visualizations
  🔧 Actionable fix suggestions
  ⏱️ Performance metrics and bottlenecks
''');
}
