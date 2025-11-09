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
/// ```
///
/// ## Core Features
/// - **Flaky Test Detection**: Runs tests multiple times to identify intermittent failures
/// - **Pattern Recognition**: Detects null errors, timeouts, assertions, type errors, etc.
/// - **Performance Profiling**: Identifies slow tests and performance bottlenecks
/// - **Interactive Debugging**: Deep dive into specific test failures with source viewing
/// - **Parallel Execution**: Run tests in parallel with configurable worker pool
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

import 'package:args/args.dart';
import 'package:test_reporter/src/utils/module_identifier.dart';
import 'package:test_reporter/src/utils/report_utils.dart';

/// Enum representing different types of test failure patterns
enum FailurePatternType {
  assertion,
  nullError,
  timeout,
  rangeError,
  typeError,
  fileSystemError,
  networkError,
  unknown,
}

/// Result of failure pattern detection
class FailureDetectionResult {
  FailureDetectionResult({
    required this.type,
    required this.errorMessage,
    this.stackTrace,
    this.details = const {},
  });

  final FailurePatternType type;
  final String errorMessage;
  final String? stackTrace;
  final Map<String, String> details;
}

/// Tracks occurrences of a specific failure pattern
class FailurePattern {
  FailurePattern({
    required this.type,
    String? category,
    this.count = 1,
    List<String>? testNames,
    this.errorMessage,
    this.stackTrace,
    this.suggestion,
    Map<String, String>? details,
  })  : category = category ?? _deriveCategoryFromType(type),
        testNames = testNames ?? [],
        details = details ?? {};

  final FailurePatternType type;
  final String category;
  int count;
  final List<String> testNames;
  final String? errorMessage;
  final String? stackTrace;
  final String? suggestion;
  final Map<String, String> details;

  void incrementCount() {
    count++;
  }

  void addTestName(String name) {
    if (!testNames.contains(name)) {
      testNames.add(name);
    }
  }

  static String _deriveCategoryFromType(FailurePatternType type) {
    switch (type) {
      case FailurePatternType.assertion:
        return 'Assertion Failure';
      case FailurePatternType.nullError:
        return 'Null Error';
      case FailurePatternType.timeout:
        return 'Timeout';
      case FailurePatternType.rangeError:
        return 'Range Error';
      case FailurePatternType.typeError:
        return 'Type Error';
      case FailurePatternType.fileSystemError:
        return 'File System Error';
      case FailurePatternType.networkError:
        return 'Network Error';
      case FailurePatternType.unknown:
        return 'Unknown Error';
    }
  }
}

class TestAnalyzer {
  TestAnalyzer({
    this.runCount = 3,
    this.verbose = false,
    this.interactive = false,
    this.performanceMode = false,
    bool? watchMode,
    this.generateFixes = true,
    this.generateReport = true,
    this.slowTestThreshold = 1.0, // seconds
    this.targetFiles = const [],
    this.parallel = false,
    this.maxWorkers = 4,
    this.enableChecklist = true,
    this.minimalChecklist = false,
    this.explicitModuleName,
    this.includeFixtures = false,
  }) : watch = watchMode ?? false;
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

  /// Whether to generate and display test analysis reports.
  /// When false (via --no-report flag), suppresses both stdout output and file creation.
  /// This provides a clean way to run tests multiple times for reliability checks
  /// without cluttering the console or generating report files.
  final bool generateReport;

  final double slowTestThreshold;
  final List<String> targetFiles;
  final bool parallel;
  final int maxWorkers;
  final bool enableChecklist;
  final bool minimalChecklist;
  final String? explicitModuleName;
  final bool includeFixtures;

  // Pattern registry for tracking failure patterns by type
  final Map<FailurePatternType, FailurePattern> _patternRegistry = {};

  // Watch mode tracking
  final List<String> _changedFiles = [];

  // Getter for watchMode (alias for watch)
  bool get watchMode => watch;

  /// Detects failure type from test output string
  FailureDetectionResult detectFailureType(String output) {
    final lowerOutput = output.toLowerCase();
    FailurePatternType type = FailurePatternType.unknown;
    String errorMessage = '';
    String? stackTrace;
    Map<String, String> details = {};

    // Extract stack trace
    final stackTraceMatch = RegExp(r'#\d+.*?\n', multiLine: true);
    final stackMatches = stackTraceMatch.allMatches(output);
    if (stackMatches.isNotEmpty) {
      stackTrace = stackMatches.map((m) => m.group(0)).join();
    }

    // Check for specific exception types first (before generic patterns)
    final firstLine = output.split('\n').first;

    // Detect range errors
    if (lowerOutput.contains('rangeerror')) {
      type = FailurePatternType.rangeError;
      // Match pattern like "range 0..2: 5" - capture the number after the colon
      final indexMatch =
          RegExp(r'range\s+\d+\.\.\d+:\s*(\d+)').firstMatch(output);
      errorMessage = firstLine;
      if (indexMatch != null) {
        details['index'] = indexMatch.group(1)!;
      }
    }
    // Detect file system errors
    else if (lowerOutput.contains('filesystemexception') ||
        lowerOutput.contains('cannot open file')) {
      type = FailurePatternType.fileSystemError;
      final pathMatch = RegExp(r"path\s*=\s*'([^']+)'").firstMatch(output);
      errorMessage = firstLine;
      if (pathMatch != null) {
        details['path'] = pathMatch.group(1)!;
      }
    }
    // Detect network errors
    else if (lowerOutput.contains('socketexception')) {
      type = FailurePatternType.networkError;
      final urlMatch =
          RegExp(r"'([^']+\.(com|org|net|io))'").firstMatch(output);
      errorMessage = firstLine;
      if (urlMatch != null) {
        details['url'] = urlMatch.group(1)!;
      }
    }
    // Detect null errors
    else if (lowerOutput.contains('nosuchmethoderror') &&
        lowerOutput.contains('null')) {
      type = FailurePatternType.nullError;
      final varMatch = RegExp(r"'(\w+)' was called on null").firstMatch(output);
      errorMessage = firstLine;
      if (varMatch != null) {
        details['variableName'] = varMatch.group(1)!;
      }
      final locationMatch = RegExp(r'at (\S+\.dart:\d+)').firstMatch(output);
      if (locationMatch != null) {
        details['location'] = locationMatch.group(1)!;
      }
    }
    // Detect timeout failures
    else if (lowerOutput.contains('timeout') ||
        lowerOutput.contains('timed out')) {
      type = FailurePatternType.timeout;
      final durationMatch = RegExp(r'(\d+)\s*seconds?').firstMatch(output);
      errorMessage = output.split('\n').firstWhere(
          (line) => line.toLowerCase().contains('timeout'),
          orElse: () => firstLine);
      if (durationMatch != null) {
        details['duration'] = durationMatch.group(1)!;
      }
    }
    // Detect type errors
    else if (lowerOutput.contains('type') &&
        (lowerOutput.contains('subtype') || lowerOutput.contains('cast'))) {
      type = FailurePatternType.typeError;
      final typeMatch =
          RegExp(r"type '(\w+)' is not a subtype.*?'(\w+)'").firstMatch(output);
      errorMessage = firstLine;
      if (typeMatch != null) {
        details['actualType'] = typeMatch.group(1)!;
        details['expectedType'] = typeMatch.group(2)!;
      }
    }
    // Detect assertion failures (check last to avoid false positives)
    else if ((lowerOutput.contains('expected:') &&
            lowerOutput.contains('actual:')) ||
        (lowerOutput.contains('expected user'))) {
      type = FailurePatternType.assertion;
      final expectedMatch =
          RegExp(r'Expected[:\s]+([^\n]+)', caseSensitive: false)
              .firstMatch(output);
      final actualMatch = RegExp(r'Actual[:\s]+([^\n]+)', caseSensitive: false)
          .firstMatch(output);
      errorMessage = output.split('\n').firstWhere(
          (line) => line.contains('Expected'),
          orElse: () => firstLine);
      if (expectedMatch != null)
        details['expected'] = expectedMatch.group(1)?.trim() ?? '';
      if (actualMatch != null)
        details['actual'] = actualMatch.group(1)?.trim() ?? '';
    }
    // Unknown error - use first line
    else {
      type = FailurePatternType.unknown;
      errorMessage = firstLine;
    }

    return FailureDetectionResult(
      type: type,
      errorMessage: errorMessage,
      stackTrace: stackTrace,
      details: details,
    );
  }

  /// Adds a detected failure to the pattern registry
  void addDetectedFailure({
    required FailurePatternType type,
    required String testName,
    required String errorMessage,
  }) {
    if (_patternRegistry.containsKey(type)) {
      _patternRegistry[type]!.incrementCount();
      _patternRegistry[type]!.addTestName(testName);
    } else {
      final category = _getCategoryForType(type);
      _patternRegistry[type] = FailurePattern(
        type: type,
        category: category,
        count: 1,
        testNames: [testName],
        errorMessage: errorMessage,
      );
    }
  }

  /// Gets all detected patterns
  List<FailurePattern> get detectedPatterns => _patternRegistry.values.toList();

  /// Gets patterns ranked by frequency (most common first)
  List<FailurePattern> getRankedPatterns() {
    final patternsList = _patternRegistry.values.toList();
    patternsList.sort((a, b) => b.count.compareTo(a.count));
    return patternsList;
  }

  /// Generates smart suggestion for a failure pattern
  String generateSuggestion(FailurePattern pattern) {
    switch (pattern.type) {
      case FailurePatternType.assertion:
        return 'Verify the test assertions and ensure expected values match actual behavior';

      case FailurePatternType.nullError:
        final varName = pattern.details['variableName'] ?? 'variable';
        final location = pattern.details['location'] ?? '';
        var suggestion =
            'Add null checks for $varName before accessing properties';
        if (location.isNotEmpty) {
          suggestion += ' at $location';
        }
        if (varName.isNotEmpty) {
          suggestion += '\n\nConsider:\n';
          suggestion += 'if ($varName != null) { ... }\n';
          suggestion += 'or use: $varName?.property\n';
          suggestion += 'or use: $varName ?? defaultValue';
        }
        return suggestion;

      case FailurePatternType.timeout:
        final duration = pattern.details['duration'] ?? 'timeout';
        return 'Test timed out. Consider:\n'
            '- Increasing timeout duration with Timeout($duration + buffer)\n'
            '- Optimizing slow operations\n'
            '- Mocking expensive external calls';

      case FailurePatternType.rangeError:
        return 'Check array/list bounds before accessing elements:\n'
            '- Verify collection length\n'
            '- Add bounds checking: if (index < list.length) { ... }';

      case FailurePatternType.typeError:
        final expectedType = pattern.details['expectedType'] ?? 'Expected';
        final actualType = pattern.details['actualType'] ?? 'Actual';
        return 'Type mismatch: $actualType is not compatible with $expectedType\n'
            '- Add type conversion: value.toString(), int.parse(), etc.\n'
            '- Check generic type parameters\n'
            '- Use type-safe casting with as or is';

      case FailurePatternType.fileSystemError:
        return 'File system error. Ensure:\n'
            '- Test files and resources exist\n'
            '- Paths are correct and accessible\n'
            '- Proper file permissions are set';

      case FailurePatternType.networkError:
        return 'Network error detected. Consider:\n'
            '- Mocking network calls in tests\n'
            '- Using test fixtures instead of real API calls\n'
            '- Checking if test server is running';

      case FailurePatternType.unknown:
        return 'Unable to determine specific fix. Review error message and stack trace';
    }
  }

  String _getCategoryForType(FailurePatternType type) {
    switch (type) {
      case FailurePatternType.assertion:
        return 'Assertion Failure';
      case FailurePatternType.nullError:
        return 'Null Error';
      case FailurePatternType.timeout:
        return 'Timeout';
      case FailurePatternType.rangeError:
        return 'Range Error';
      case FailurePatternType.typeError:
        return 'Type Error';
      case FailurePatternType.fileSystemError:
        return 'File System Error';
      case FailurePatternType.networkError:
        return 'Network Error';
      case FailurePatternType.unknown:
        return 'Unknown Error';
    }
  }

  Future<void> run() async {
    _printHeader();

    try {
      // Step 1: Discover test files
      final testFiles = await _discoverTestFiles();

      // EXIT EARLY: No test files found - don't generate reports
      if (testFiles.isEmpty) {
        print('\n$red✗ No test files found$reset');
        print('  ${gray}Please specify a valid test file or directory$reset');
        exit(2);
      }

      // Step 2: Run tests multiple times
      await _runTestsMultipleTimes(testFiles);

      // Step 3: Analyze failures and patterns
      _analyzeFailures();

      // Step 4: Track performance metrics
      if (performanceMode) {
        _analyzePerformance();
      }

      // Step 5: Generate comprehensive report (if enabled)
      // When --no-report is specified, skip all report generation
      if (generateReport) {
        await _generateReport();
      }

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
      // Validate and use specified files/directories
      for (final target in targetFiles) {
        final file = File(target);
        final dir = Directory(target);

        if (await file.exists()) {
          // Single test file
          testFiles.add(target);
        } else if (await dir.exists()) {
          // Directory - discover test files within it
          await for (final entity in dir.list(recursive: true)) {
            if (entity is File && entity.path.endsWith('_test.dart')) {
              testFiles.add(entity.path);
            }
          }
        } else {
          // File/directory doesn't exist - skip it
          print('  $yellow⚠$reset  Skipping non-existent: $target');
        }
      }
    } else {
      // Discover all test files in 'test' directory
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

    // Build test arguments - exclude fixtures by default unless --include-fixtures is used
    final testArgs = ['test', '--reporter=json', '--run-skipped'];
    if (!includeFixtures) {
      testArgs.add('--exclude-tags=fixture');
    }
    testArgs.add(testFile);

    final result = await Process.run(
      isFlutterProject ? 'flutter' : 'dart',
      testArgs,
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
    FailurePatternType? type;
    String? category;
    String? suggestion;

    if (error.contains('assertion') || error.contains('expect')) {
      type = FailurePatternType.assertion;
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
      type = FailurePatternType.nullError;
      category = 'Null Reference Error';

      // Extract the property/method that was null
      final propertyMatch =
          RegExp(r"'(\w+)' was called on null").firstMatch(failure.error);
      if (propertyMatch != null) {
        suggestion =
            'Add null check for ${propertyMatch.group(1)} or ensure proper initialization';
      }
    } else if (error.contains('timeout')) {
      type = FailurePatternType.timeout;
      category = 'Timeout';
      suggestion = 'Increase timeout duration or optimize test performance';
    } else if (error.contains('rangeError') || error.contains('index')) {
      type = FailurePatternType.rangeError;
      category = 'Range/Index Error';

      // Extract index information
      final indexMatch = RegExp(r'index[: ]+(\d+)').firstMatch(failure.error);
      if (indexMatch != null) {
        suggestion =
            'Check array bounds before accessing index ${indexMatch.group(1)}';
      }
    } else if (error.contains('type') || error.contains('cast')) {
      type = FailurePatternType.typeError;
      category = 'Type Error';
      suggestion = 'Verify type conversions and generic type parameters';
    } else if (error.contains('file') || error.contains('io')) {
      type = FailurePatternType.fileSystemError;
      category = 'I/O Error';
      suggestion =
          'Ensure test files/resources exist and have proper permissions';
    } else if (error.contains('network') || error.contains('socket')) {
      type = FailurePatternType.networkError;
      category = 'Network Error';
      suggestion = 'Mock network calls or ensure test server is running';
    } else {
      type = FailurePatternType.unknown;
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

  /// Get total number of test runs performed
  int get totalRuns {
    if (testRuns.isEmpty) return 0;
    // All tests should have the same number of runs (runCount)
    return testRuns.values.first.results.length;
  }

  /// Get flaky tests ranked by severity (highest flakiness rate first)
  List<TestRun> getRankedFlakyTests() {
    final flakyTestRuns = testRuns.values.where((run) => run.isFlaky).toList();
    flakyTestRuns.sort((a, b) => b.flakinessRate.compareTo(a.flakinessRate));
    return flakyTestRuns;
  }

  /// Generate a report specifically for flaky tests
  String generateFlakyTestReport() {
    final report = StringBuffer();
    report.writeln('# Flaky Test Report');
    report.writeln();

    final rankedFlaky = getRankedFlakyTests();

    if (rankedFlaky.isEmpty) {
      report.writeln('No flaky tests detected.');
      return report.toString();
    }

    report.writeln('## Summary');
    report.writeln('Total flaky tests: ${rankedFlaky.length}');
    report.writeln();

    report.writeln('## Flaky Tests (Ranked by Severity)');
    report.writeln();

    for (final testRun in rankedFlaky) {
      final flakinessPercent = (testRun.flakinessRate * 100).toStringAsFixed(0);
      report.writeln('### ${testRun.testName}');
      report.writeln('- **File**: ${testRun.testFile}');
      report.writeln('- **Flakiness**: $flakinessPercent%');
      report.writeln(
          '- **Pass Rate**: ${(testRun.passRate * 100).toStringAsFixed(0)}%');
      report.writeln();
    }

    return report.toString();
  }

  /// Get slow tests that exceed the threshold
  List<TestPerformance> getSlowTests() {
    return performance.values
        .where((perf) => perf.averageDuration > slowTestThreshold)
        .toList();
  }

  /// Generate performance report
  String generatePerformanceReport() {
    final report = StringBuffer();
    report.writeln('# Performance Report');
    report.writeln();

    if (performance.isEmpty) {
      report.writeln('No performance data available.');
      return report.toString();
    }

    report.writeln('## Performance Summary');
    report.writeln();

    // Sort by average duration (slowest first)
    final sortedTests = performance.values.toList()
      ..sort((a, b) => b.averageDuration.compareTo(a.averageDuration));

    for (final perf in sortedTests) {
      report.writeln('### ${perf.testName}');
      report.writeln(
          '- **Average Duration**: ${perf.averageDuration.toStringAsFixed(2)}s');
      report.writeln(
          '- **Min Duration**: ${perf.minDuration.toStringAsFixed(2)}s');
      report.writeln(
          '- **Max Duration**: ${perf.maxDuration.toStringAsFixed(2)}s');
      report.writeln();
    }

    return report.toString();
  }

  /// Get timing breakdown for a specific test
  Map<String, double> getTimingBreakdown(String testId) {
    final perf = performance[testId];
    if (perf == null) return {};

    return {
      'average': perf.averageDuration,
      'min': perf.minDuration,
      'max': perf.maxDuration,
      'stdDev': perf.standardDeviation,
    };
  }

  /// Identify performance bottlenecks (tests above the given percentile)
  List<TestPerformance> identifyBottlenecks({required int percentile}) {
    if (performance.isEmpty) return [];

    // Sort all tests by average duration
    final sorted = performance.values.toList()
      ..sort((a, b) => a.averageDuration.compareTo(b.averageDuration));

    // Calculate index for the percentile
    final index = ((percentile / 100) * sorted.length).floor();
    if (index >= sorted.length) return [];

    // Return tests above the percentile threshold
    final threshold = sorted[index].averageDuration;
    return sorted.where((perf) => perf.averageDuration >= threshold).toList();
  }

  /// Generate markdown report with test results
  String generateMarkdownReport() {
    final report = StringBuffer();
    report.writeln('# Test Analysis Report');
    report.writeln();

    // Summary
    report.writeln('## Summary');
    final totalTests = testRuns.length;
    final passingTests = testRuns.values.where((t) => t.passRate == 1.0).length;
    report.writeln('- Total Tests: $totalTests');
    report.writeln('- Passing: $passingTests');
    report.writeln();

    // Test list
    report.writeln('## Tests');
    for (final testRun in testRuns.values) {
      report.writeln('- **${testRun.testName}** (${testRun.testFile})');
    }
    report.writeln();

    // Flaky tests section
    final flakyTestsList = testRuns.values.where((t) => t.isFlaky).toList();
    if (flakyTestsList.isNotEmpty) {
      report.writeln('## Flaky Tests');
      for (final test in flakyTestsList) {
        report.writeln('- ${test.testName}');
      }
      report.writeln();
    }

    // Failure patterns section
    if (_patternRegistry.isNotEmpty) {
      report.writeln('## Failure Patterns');
      for (final pattern in _patternRegistry.values) {
        report
            .writeln('- **${pattern.category}**: ${pattern.count} occurrences');
      }
      report.writeln();
    }

    // Performance section
    if (performanceMode && performance.isNotEmpty) {
      report.writeln('## Performance Metrics');
      for (final perf in performance.values) {
        report.writeln(
            '- **${perf.testName}**: ${perf.averageDuration.toStringAsFixed(2)}s avg');
      }
      report.writeln();
    }

    return report.toString();
  }

  /// Generate JSON report with test results
  String generateJsonReport() {
    final totalTests = testRuns.length;
    final passingTests = testRuns.values.where((t) => t.passRate == 1.0).length;
    final flakyTests = testRuns.values.where((t) => t.isFlaky).length;

    // Simple JSON encoding (minimal implementation)
    final json = StringBuffer();
    json.writeln('{');
    json.writeln('  "summary": {');
    json.writeln('    "totalTests": $totalTests,');
    json.writeln('    "passingTests": $passingTests,');
    json.writeln('    "flakyTests": $flakyTests');
    json.writeln('  },');
    json.writeln('  "tests": [');

    final testList = testRuns.values.toList();
    for (var i = 0; i < testList.length; i++) {
      final test = testList[i];
      json.write('    {');
      json.write('"testName": "${test.testName}", ');
      json.write('"testFile": "${test.testFile}", ');
      json.write('"passRate": ${test.passRate}, ');
      json.write('"isFlaky": ${test.isFlaky}');
      json.write('}');
      if (i < testList.length - 1) json.write(',');
      json.writeln();
    }
    json.writeln('  ]');
    json.writeln('}');

    return json.toString();
  }

  /// Generate failures report in markdown format
  String generateFailuresReport() {
    final report = StringBuffer();
    report.writeln('# Test Failures Report');
    report.writeln();

    // Consistent failures
    if (consistentFailures.isNotEmpty) {
      report.writeln('## Consistent Failures');
      for (final testId in consistentFailures) {
        final testRun = testRuns[testId];
        if (testRun != null) {
          report.writeln('### ${testRun.testName}');
          report.writeln('- **File**: ${testRun.testFile}');

          // Include failure details if available
          final testFailures = failures[testId];
          if (testFailures != null && testFailures.isNotEmpty) {
            final firstFailure = testFailures.first;
            report.writeln('- **Error**: ${firstFailure.error}');
            report.writeln('- **Stack Trace**: ${firstFailure.stackTrace}');
          }

          report.writeln();
        }
      }
    }

    // Include suggestions from patterns
    if (_patternRegistry.isNotEmpty) {
      report.writeln('## Suggested Fixes');
      for (final pattern in _patternRegistry.values) {
        final suggestion = generateSuggestion(pattern);
        report.writeln('### ${pattern.category}');
        report.writeln(suggestion);
        report.writeln();
      }
    }

    // Rerun commands
    if (consistentFailures.isNotEmpty) {
      report.writeln('## Rerun Commands');
      for (final testId in consistentFailures) {
        final testRun = testRuns[testId];
        if (testRun != null) {
          report.writeln('```bash');
          report.writeln('dart test ${testRun.testFile}');
          report.writeln('```');
        }
      }
    }

    return report.toString();
  }

  /// Generate failures report in JSON format
  String generateFailuresJsonReport() {
    final json = StringBuffer();
    json.writeln('{');
    json.writeln('  "failures": [');

    final failureList = <String>[];
    for (final testId in consistentFailures) {
      final testRun = testRuns[testId];
      if (testRun != null) {
        failureList.add(
            '    {"testName": "${testRun.testName}", "testFile": "${testRun.testFile}"}');
      }
    }

    json.writeln(failureList.join(',\n'));
    json.writeln('  ]');
    json.writeln('}');

    return json.toString();
  }

  /// Get all passing tests (100% pass rate)
  List<TestRun> getAllPassingTests() {
    return testRuns.values.where((test) => test.passRate == 1.0).toList();
  }

  /// Get all failing tests (consistent failures)
  List<TestRun> getAllFailingTests() {
    return testRuns.values.where((test) => test.isConsistentFailure).toList();
  }

  /// Find duplicate test names across different files
  List<String> findDuplicateTestNames() {
    final nameToFiles = <String, List<String>>{};

    // Group tests by name
    for (final test in testRuns.values) {
      nameToFiles.putIfAbsent(test.testName, () => []).add(test.testFile);
    }

    // Find names with multiple files
    final duplicates = <String>[];
    for (final entry in nameToFiles.entries) {
      if (entry.value.length > 1) {
        duplicates.add(entry.key);
      }
    }

    return duplicates;
  }

  /// Add a file change for watch mode
  void addFileChange(String filePath) {
    if (!_changedFiles.contains(filePath)) {
      _changedFiles.add(filePath);
    }
  }

  /// Get list of changed files in watch mode
  List<String> getChangedFiles() {
    return List.unmodifiable(_changedFiles);
  }

  /// Get tests that need to be rerun based on file changes
  List<TestRun> getTestsToRerun() {
    final testsToRerun = <TestRun>[];

    for (final changedFile in _changedFiles) {
      // Find tests whose test file matches the changed file
      for (final test in testRuns.values) {
        if (test.testFile == changedFile) {
          testsToRerun.add(test);
        }
      }
    }

    return testsToRerun;
  }

  /// Handle user input in interactive mode
  String handleUserInput(String input) {
    final normalized = input.trim().toLowerCase();

    switch (normalized) {
      case 'r':
      case 'rerun':
        return 'rerun';
      case 'a':
      case 'all':
        return 'rerunAll';
      case 'q':
      case 'quit':
        return 'quit';
      case 'h':
      case 'help':
        return 'help';
      default:
        return 'unknown';
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
        final priority = pattern?.type == FailurePatternType.nullError ||
                pattern?.type == FailurePatternType.assertion
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

      final patternsByType = <FailurePatternType, int>{};
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
    final nullErrors = patterns.values
        .where((p) => p.type == FailurePatternType.nullError)
        .length;
    if (nullErrors > 3) {
      insights['🔍 Pattern'] =
          'Multiple null reference errors detected - review initialization logic';
    }

    final timeouts = patterns.values
        .where((p) => p.type == FailurePatternType.timeout)
        .length;
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

    // ✅ Test Reliability Action Items Section
    if (enableChecklist) {
      _generateReliabilityChecklist(
        report,
        consistentFailures,
        flakyTests,
        minimal: minimalChecklist,
      );
    }

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

      // Extract qualified module name from test path (or use explicit override)
      // If explicit name provided, qualify it based on path type
      final inferredPath = targetFiles.isNotEmpty ? targetFiles.first : 'test/';
      final moduleName = explicitModuleName != null
          ? ModuleIdentifier.qualifyManualModuleName(
              explicitModuleName!, inferredPath)
          : ModuleIdentifier.getQualifiedModuleName(inferredPath);

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
                  run.results.entries
                      .map((e) => MapEntry('run_${e.key}', e.value)),
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
        final patternsByType = <FailurePatternType, int>{};
        for (final pattern in patterns.values) {
          patternsByType[pattern.type] =
              (patternsByType[pattern.type] ?? 0) + 1;
        }

        jsonData['failure_patterns'] = Map<String, int>.fromEntries(
          patternsByType.entries.map(
            (entry) =>
                MapEntry(entry.key.toString().split('.').last, entry.value),
          ),
        );
      }

      // Write unified report
      final reportPath = await ReportUtils.writeUnifiedReport(
        moduleName: moduleName,
        timestamp: timestamp,
        markdownContent: report.toString(),
        jsonData: jsonData,
        suffix: 'tests',
        verbose: true,
      );

      print('$green✅ Report saved to: $reportPath$reset');

      // REMOVED: Failed report generation (v3.0 fix - namespace collision)
      // The failures/ subdirectory is exclusively for extract_failures tool
      // analyze_tests now only writes to reliability/ subdirectory
      // Ref: https://github.com/unfazed-dev/test_reporter/issues/XXX
      //
      // if (consistentFailures.isNotEmpty || flakyTests.isNotEmpty) {
      //   await _saveFailedReport(timestamp, moduleName, jsonData);
      // }

      // Clean up old reports AFTER generating new ones
      await _cleanupOldReports();
    } catch (e, stackTrace) {
      print('\n$yellow⚠️ Could not save report to file: $e$reset');
      if (verbose) {
        print('  Error details: $stackTrace');
      }
    }
  }

  // REMOVED: _saveFailedReport method (v3.0 fix - namespace collision)
  //
  // This method previously generated reports in tests_reports/failures/ which
  // conflicts with extract_failures tool. The analyze_tests tool now only writes
  // to tests_reports/reliability/ subdirectory.
  //
  // If you need a failed-tests-only report, use extract_failures tool instead:
  //   dart run test_reporter:extract_failures test/ --save-results
  //
  // The full reliability report still contains all failure information in the
  // "Consistent Failures" and "Flaky Tests" sections.

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
    final patternsByType = <FailurePatternType, int>{};
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
    final nullErrors = patterns.values
        .where((p) => p.type == FailurePatternType.nullError)
        .length;
    if (nullErrors > 3) {
      insights.add(
        'Multiple null reference errors detected - review initialization logic',
      );
    }

    final timeouts = patterns.values
        .where((p) => p.type == FailurePatternType.timeout)
        .length;
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
    if (patterns.values.any((p) => p.type == FailurePatternType.timeout)) {
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

  /// Clean up old reports - keeps only the latest report for each module
  Future<void> _cleanupOldReports() async {
    // Extract qualified module name from test path (or use explicit override)
    final moduleName = explicitModuleName ??
        (targetFiles.isNotEmpty
            ? ModuleIdentifier.getQualifiedModuleName(targetFiles.first)
            : 'test-fo');

    // Clean old reports - keep only latest report per module
    if (verbose) {
      print('  [DEBUG] Cleaning old reports for moduleName=$moduleName');
    }

    // Clean test reports in reliability/ subdirectory
    await ReportUtils.cleanOldReports(
      pathName: moduleName,
      prefixPatterns: [
        'report_tests', // Current format: modulename-fi_report_tests@timestamp
      ],
      subdirectory: 'reliability',
      verbose: verbose,
    );

    // REMOVED: failures/ subdirectory cleanup (v3.0 fix - namespace collision)
    // The failures/ subdirectory is exclusively owned by extract_failures tool.
    // analyze_tests no longer writes to or cleans up failures/ subdirectory.
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

  /// Generate actionable checklist for test reliability improvements
  void _generateReliabilityChecklist(
    StringBuffer report,
    List<String> consistentFailures,
    List<String> flakyTests, {
    bool minimal = false,
  }) {
    report.writeln('## ✅ Test Reliability Action Items');
    report.writeln();

    if (minimal) {
      // Minimal mode: compact checklist
      report.writeln('Quick action items to improve test reliability:');
      report.writeln();

      if (consistentFailures.isNotEmpty) {
        report.writeln('**🔴 Critical - Fix failing tests:**');
        for (final testId in consistentFailures) {
          final parts = testId.split('::');
          final testName = parts.length > 1 ? parts[1] : testId;
          report.writeln('- [ ] Fix: `$testName`');
        }
        report.writeln();
      }

      if (flakyTests.isNotEmpty) {
        report.writeln('**🟠 Important - Stabilize flaky tests:**');
        for (final testId in flakyTests) {
          final parts = testId.split('::');
          final testName = parts.length > 1 ? parts[1] : testId;
          final testRun = testRuns[testId];
          final passCount = testRun?.results.values.where((r) => r).length ?? 0;
          final reliability = (passCount / runCount * 100).toStringAsFixed(1);
          report
              .writeln('- [ ] Stabilize: `$testName` ($reliability% reliable)');
        }
        report.writeln();
      }

      report.writeln('**Quick Command**: `dart test --runs=$runCount`');
      report.writeln();
      return;
    }

    // Full mode: detailed checklist
    report.writeln(
      'This section provides a prioritized checklist to improve test reliability. '
      'Check off items as you complete them.',
    );
    report.writeln();

    var totalItems = 0;

    // Priority 1: Fix Failing Tests (Critical)
    if (consistentFailures.isNotEmpty) {
      report.writeln('### 🔴 Priority 1: Fix Failing Tests');
      report.writeln(
          '*Critical - These tests fail consistently and block CI/CD*');
      report.writeln();

      for (final testId in consistentFailures) {
        final parts = testId.split('::');
        final testName = parts.length > 1 ? parts[1] : testId;
        final testFile =
            parts.isNotEmpty ? _getRelativePath(parts[0]) : 'unknown';
        final pattern = patterns[testId];
        final category = pattern?.category ?? 'Unknown';
        final suggestion = pattern?.suggestion ?? 'Review test implementation';

        report.writeln('- [ ] Fix: `$testName`');
        report.writeln('  - File: `$testFile`');
        report.writeln('  - Failure Type: $category');
        report.writeln('  - 💡 Fix: $suggestion');
        report.writeln(
          '  - Verify: `dart test $testFile --name="${testName.replaceAll('"', '\\"')}"`',
        );
        report.writeln();
        totalItems++;
      }

      report.writeln(
        '**Progress: 0 of ${consistentFailures.length} failing tests fixed**',
      );
      report.writeln();
    }

    // Priority 2: Fix Flaky Tests (Important)
    if (flakyTests.isNotEmpty) {
      report.writeln('### 🟠 Priority 2: Stabilize Flaky Tests');
      report.writeln('*Important - These tests pass inconsistently*');
      report.writeln();

      for (final testId in flakyTests) {
        final parts = testId.split('::');
        final testName = parts.length > 1 ? parts[1] : testId;
        final testFile =
            parts.isNotEmpty ? _getRelativePath(parts[0]) : 'unknown';

        // Calculate reliability percentage
        final testRun = testRuns[testId];
        final passCount = testRun?.results.values.where((r) => r).length ?? 0;
        final reliability = (passCount / runCount * 100).toStringAsFixed(1);

        report
            .writeln('- [ ] Stabilize: `$testName` (${reliability}% reliable)');
        report.writeln('  - File: `$testFile`');
        report.writeln('  - Common causes:');
        report.writeln('    - [ ] Race conditions or timing issues');
        report.writeln('    - [ ] Shared mutable state between tests');
        report
            .writeln('    - [ ] External dependencies (network, file system)');
        report.writeln('    - [ ] Improper async/await handling');
        report.writeln(
          '  - Verify stability: `for i in {1..10}; do dart test $testFile --name="${testName.replaceAll('"', '\\"')}" || break; done`',
        );
        report.writeln();
        totalItems++;
      }

      report.writeln(
        '**Progress: 0 of ${flakyTests.length} flaky tests stabilized**',
      );
      report.writeln();
    }

    // Priority 3: Optimize Slow Tests (Optional)
    if (performanceMode && performance.isNotEmpty) {
      final slowTests = performance.entries
          .where((e) => e.value.averageDuration > slowTestThreshold * 1000)
          .toList();

      if (slowTests.isNotEmpty) {
        report.writeln('### 🟡 Priority 3: Optimize Slow Tests');
        report.writeln(
          '*Optional - These tests exceed ${slowTestThreshold}s threshold*',
        );
        report.writeln();

        for (final entry in slowTests.take(10)) {
          final testId = entry.key;
          final perf = entry.value;
          final parts = testId.split('::');
          final testName = parts.length > 1 ? parts[1] : testId;
          final testFile =
              parts.isNotEmpty ? _getRelativePath(parts[0]) : 'unknown';
          final avgTime = (perf.averageDuration / 1000).toStringAsFixed(2);

          report.writeln('- [ ] Optimize: `$testName` (avg: ${avgTime}s)');
          report.writeln('  - File: `$testFile`');
          report.writeln('  - Optimization strategies:');
          report.writeln('    - [ ] Mock expensive operations');
          report.writeln('    - [ ] Reduce test scope');
          report.writeln('    - [ ] Share setup across tests');
          report.writeln('    - [ ] Use parallel execution');
          report.writeln();
          totalItems++;
        }

        report.writeln(
          '**Progress: 0 of ${slowTests.length} slow tests optimized**',
        );
        report.writeln();
      }
    }

    // Quick Commands Section
    if (totalItems > 0) {
      report.writeln('### 🚀 Quick Commands');
      report.writeln();
      report.writeln('```bash');
      report.writeln('# Run all tests multiple times to verify fixes');
      report.writeln('dart test --runs=$runCount');
      report.writeln();
      report.writeln('# Run specific test file');
      if (consistentFailures.isNotEmpty) {
        final firstFailure = consistentFailures.first.split('::');
        if (firstFailure.isNotEmpty) {
          report.writeln('dart test ${_getRelativePath(firstFailure[0])}');
        }
      }
      report.writeln();
      report.writeln('# Run with performance profiling');
      report.writeln('dart run test_reporter:analyze_tests --performance');
      report.writeln('```');
      report.writeln();

      // Overall Progress
      report.writeln('---');
      report.writeln(
          '**Overall Progress: 0 of $totalItems action items completed**');
      report.writeln();
    } else {
      report.writeln('✅ **All tests are passing reliably! No action items.**');
      report.writeln();
    }
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

  /// Add a test result for a specific run
  void addResult(int runNumber,
      {required bool passed, required int durationMs}) {
    results[runNumber] = passed;
    durations[runNumber] = durationMs;
  }

  /// Calculate pass rate (0.0 to 1.0)
  double get passRate {
    if (results.isEmpty) return 0.0;
    final passCount = results.values.where((passed) => passed).length;
    return passCount / results.length;
  }

  /// Check if test is flaky (has both passes and failures)
  bool get isFlaky {
    if (results.isEmpty) return false;
    final hasPassed = results.values.any((passed) => passed);
    final hasFailed = results.values.any((passed) => !passed);
    return hasPassed && hasFailed;
  }

  /// Calculate flakiness rate (failure rate for flaky tests)
  double get flakinessRate {
    if (results.isEmpty) return 0.0;
    final failCount = results.values.where((passed) => !passed).length;
    return failCount / results.length;
  }

  /// Check if test fails consistently (all runs failed)
  bool get isConsistentFailure {
    if (results.isEmpty) return false;
    return results.values.every((passed) => !passed);
  }

  /// Calculate average test duration in milliseconds
  double get averageDuration {
    if (durations.isEmpty) return 0.0;
    final sum = durations.values.fold(0, (sum, d) => sum + d);
    return sum / durations.length;
  }

  /// Get minimum test duration in milliseconds
  int get minDuration {
    if (durations.isEmpty) return 0;
    return durations.values.reduce(math.min);
  }

  /// Get maximum test duration in milliseconds
  int get maxDuration {
    if (durations.isEmpty) return 0;
    return durations.values.reduce(math.max);
  }
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

  // Timing breakdown fields
  double? setupTime;
  double? teardownTime;
  double? executionTime;

  double get averageDuration => durations.isEmpty
      ? 0
      : durations.reduce((a, b) => a + b) / durations.length;

  double get maxDuration => durations.isEmpty ? 0 : durations.reduce(math.max);

  double get minDuration => durations.isEmpty ? 0 : durations.reduce(math.min);

  double get totalDuration => durations.fold(0, (sum, d) => sum + d);

  /// Calculate standard deviation of durations
  double get standardDeviation {
    if (durations.isEmpty) return 0;
    final mean = averageDuration;
    final variance =
        durations.map((d) => math.pow(d - mean, 2)).reduce((a, b) => a + b) /
            durations.length;
    return math.sqrt(variance);
  }

  /// Total time including setup, execution, and teardown
  double get totalTime {
    return (setupTime ?? 0) + (executionTime ?? 0) + (teardownTime ?? 0);
  }

  void addDuration(double duration) {
    durations.add(duration);
  }

  /// Record setup time for performance profiling
  void recordSetupTime(double time) {
    setupTime = time;
  }

  /// Record teardown time for performance profiling
  void recordTeardownTime(double time) {
    teardownTime = time;
  }

  /// Record execution time for performance profiling
  void recordExecutionTime(double time) {
    executionTime = time;
  }

  /// Check if there's a performance regression
  /// Compares last duration to average of previous durations
  bool hasPerformanceRegression({required double threshold}) {
    if (durations.length < 2) return false;

    final lastDuration = durations.last;
    final previousDurations = durations.sublist(0, durations.length - 1);
    final previousAverage =
        previousDurations.reduce((a, b) => a + b) / previousDurations.length;

    // Check if last duration is significantly higher than previous average
    return lastDuration > (previousAverage * threshold);
  }
}

/// Creates and configures the ArgParser for analyze_tests
///
/// Defines all CLI flags and options with their defaults, help text, and validation.
/// This replaces the manual string parsing previously used.
ArgParser _createArgParser() {
  return ArgParser()
    // Output control flags
    ..addFlag(
      'verbose',
      abbr: 'v',
      help: 'Show detailed output and stack traces',
      negatable: false,
    )
    ..addFlag(
      'report',
      help: 'Generate and display test analysis reports',
      defaultsTo: true,
      negatable: true,
    )
    ..addFlag(
      'fixes',
      help: 'Generate fix suggestions for failures',
      defaultsTo: true,
      negatable: true,
    )
    ..addFlag(
      'checklist',
      help: 'Generate actionable checklists',
      defaultsTo: true,
      negatable: true,
    )
    ..addFlag(
      'minimal-checklist',
      help: 'Generate compact checklist format',
      negatable: false,
    )
    // Mode flags
    ..addFlag(
      'interactive',
      abbr: 'i',
      help: 'Enter interactive debug mode for failed tests',
      negatable: false,
    )
    ..addFlag(
      'performance',
      abbr: 'p',
      help: 'Track and report test performance metrics',
      negatable: false,
    )
    ..addFlag(
      'watch',
      abbr: 'w',
      help: 'Watch for changes and re-run analysis',
      negatable: false,
    )
    ..addFlag(
      'parallel',
      help: 'Run tests in parallel for faster execution',
      negatable: false,
    )
    // Other flags
    ..addFlag(
      'include-fixtures',
      help: 'Include fixture tests (excluded by default)',
      negatable: false,
    )
    ..addFlag(
      'help',
      abbr: 'h',
      help: 'Show this help message',
      negatable: false,
    )
    // Configuration options
    ..addOption(
      'runs',
      help: 'Number of test runs',
      defaultsTo: '3',
    )
    ..addOption(
      'slow',
      help: 'Slow test threshold in seconds',
      defaultsTo: '1.0',
    )
    ..addOption(
      'workers',
      help: 'Max parallel workers',
      defaultsTo: '4',
    )
    ..addOption(
      'module-name',
      help:
          'Override module name for reports (auto-qualified with -fo/-fi)',
    );
}

/// Main entry point
void main(List<String> args) async {
  // Create and use ArgParser for consistent, validated flag parsing
  final parser = _createArgParser();

  // Parse arguments with error handling
  late final ArgResults results;
  try {
    results = parser.parse(args);
  } on FormatException catch (e) {
    print('${TestAnalyzer.red}Error: ${e.message}${TestAnalyzer.reset}');
    print('');
    _printUsage(parser);
    exit(2);
  }

  // Extract flag values from parsed results
  final verbose = results['verbose'] as bool;
  final interactive = results['interactive'] as bool;
  final performance = results['performance'] as bool;
  final watch = results['watch'] as bool;
  final generateFixes = results['fixes'] as bool;
  final generateReport = results['report'] as bool;
  final help = results['help'] as bool;
  final parallel = results['parallel'] as bool;
  final enableChecklist = results['checklist'] as bool;
  final minimalChecklist = results['minimal-checklist'] as bool;
  final includeFixtures = results['include-fixtures'] as bool;

  // Parse numeric options with validation
  final runCount = int.tryParse(results['runs'] as String) ?? 3;
  final slowThreshold = double.tryParse(results['slow'] as String) ?? 1.0;
  final maxWorkers = int.tryParse(results['workers'] as String) ?? 4;

  // Get module name override (optional)
  final explicitModuleName = results['module-name'] as String?;

  if (help) {
    _printUsage(parser);
    return;
  }

  // Get target files (rest arguments after flags)
  final targetFiles = results.rest;

  // Validate target files/directories exist
  if (targetFiles.isNotEmpty) {
    final invalidPaths = <String>[];
    for (final target in targetFiles) {
      final file = File(target);
      final dir = Directory(target);
      if (!file.existsSync() && !dir.existsSync()) {
        invalidPaths.add(target);
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
      print('  # Analyze all tests');
      print('  dart run test_reporter:analyze_tests');
      print('');
      print('  # Analyze specific directory');
      print('  dart run test_reporter:analyze_tests test/unit');
      print('');
      print('  # Analyze specific file');
      print('  dart run test_reporter:analyze_tests test/my_test.dart');
      print('');
      print('  # With module name override');
      print(
          '  dart run test_reporter:analyze_tests test/ --module-name=my-tests');
      exit(2);
    }
  }

  final analyzer = TestAnalyzer(
    runCount: runCount,
    verbose: verbose,
    interactive: interactive,
    performanceMode: performance,
    watchMode: watch,
    generateFixes: generateFixes,
    generateReport: generateReport,
    slowTestThreshold: slowThreshold,
    targetFiles: targetFiles,
    parallel: parallel,
    maxWorkers: maxWorkers,
    enableChecklist: enableChecklist,
    minimalChecklist: minimalChecklist,
    explicitModuleName: explicitModuleName,
    includeFixtures: includeFixtures,
  );

  await analyzer.run();
}

/// Prints usage information with ArgParser-generated help text
void _printUsage(ArgParser parser) {
  print('''
${TestAnalyzer.cyan}Flutter/Dart Test Analyzer${TestAnalyzer.reset}

Usage: dart test_analyzer.dart [options] [test_files...]

Options:
${parser.usage}

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
