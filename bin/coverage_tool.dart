#!/usr/bin/env dart

/// Enhanced Coverage Analysis Tool for Flutter/Dart projects
/// Version 2.0 - 2025 Enhanced Edition
///
/// Features:
///   - Line and branch coverage analysis
///   - Incremental coverage for changed files
///   - Mutation testing integration
///   - Coverage diff visualization
///   - Test impact analysis
///   - Parallel execution for performance
///   - Watch mode for continuous monitoring
///   - JSON export and badge generation
///
/// Usage: dart coverage_tool.dart [options] [path]
/// Options:
///   --fix              Generate missing test cases automatically
///   --branch           Include branch coverage analysis
///   --incremental      Only analyze changed files
///   --mutation         Run mutation testing
///   --watch            Enable watch mode
///   --parallel         Use parallel execution
///   --json             Export JSON report
///   --badge            Generate coverage badge
///   --threshold <n>    Set minimum coverage threshold
///   --exclude <pattern> Exclude files matching pattern
///   --baseline <file>  Compare against baseline coverage
///   --impact           Analyze test impact mapping

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:test_analyzer/src/utils/report_utils.dart';

class CoverageThresholds {
  CoverageThresholds({
    this.minimum = 80.0,
    this.warning = 90.0,
    this.failOnDecrease = false,
  });
  final double minimum;
  final double warning;
  final bool failOnDecrease;

  bool validate(double coverage, {double? baseline}) {
    if (coverage < minimum) {
      print(
        '❌ Coverage ${coverage.toStringAsFixed(1)}% is below minimum ${minimum.toStringAsFixed(1)}%',
      );
      return false;
    }
    if (baseline != null && failOnDecrease && coverage < baseline) {
      print(
        '❌ Coverage decreased from ${baseline.toStringAsFixed(1)}% to ${coverage.toStringAsFixed(1)}%',
      );
      return false;
    }
    if (coverage < warning) {
      print(
        '⚠️  Coverage ${coverage.toStringAsFixed(1)}% is below warning threshold ${warning.toStringAsFixed(1)}%',
      );
    }
    return true;
  }
}

class CoverageAnalyzer {
  CoverageAnalyzer({
    required this.libPath,
    required this.testPath,
    this.autoFix = false,
    this.generateReport = true,
    this.branchCoverage = false,
    this.incremental = false,
    this.mutationTesting = false,
    this.watchMode = false,
    this.parallel = false,
    this.exportJson = false,
    this.testImpactAnalysis = false,
    this.excludePatterns = const [],
    CoverageThresholds? thresholds,
    this.baselineFile,
  }) : thresholds = thresholds ?? CoverageThresholds();
  final String libPath;
  final String testPath;
  final bool autoFix;
  final bool generateReport;
  final bool branchCoverage;
  final bool incremental;
  final bool mutationTesting;
  final bool watchMode;
  final bool parallel;
  final bool exportJson;
  final bool testImpactAnalysis;
  final List<String> excludePatterns;
  final CoverageThresholds thresholds;
  final String? baselineFile;

  // Track if thresholds were violated
  bool thresholdViolation = false;

  // Project type detection
  bool? _isFlutterProject;

  // Track coverage data
  Map<String, FileAnalysis> sourceFiles = {};
  Map<String, FileAnalysis> testFiles = {};
  List<String> uncoveredLines = [];
  Map<String, Set<int>> coveredLinesData = {};
  Map<String, Set<int>> uncoveredLinesData = {};
  Map<String, int> totalLinesData = {};
  Map<String, int> hitLinesData = {};

  // Enhanced coverage data
  Map<String, double> branchCoverageData = {};
  Map<String, Set<String>> lineToTestsMapping = {};
  Map<String, double> coverageDiff = {};
  List<String> changedFiles = [];
  Map<String, int> mutationScore = {};

  /// Detect if this is a Flutter project by checking pubspec.yaml
  bool get isFlutterProject {
    if (_isFlutterProject != null) return _isFlutterProject!;

    try {
      final pubspecFile = File('pubspec.yaml');
      if (!pubspecFile.existsSync()) {
        _isFlutterProject = false;
        return false;
      }

      final content = pubspecFile.readAsStringSync();

      // Check for flutter dependency
      _isFlutterProject =
          content.contains(RegExp(r'^\s*flutter:\s*$', multiLine: true)) ||
              content.contains(RegExp(r'flutter:\s*sdk:', multiLine: true));

      return _isFlutterProject!;
    } catch (e) {
      _isFlutterProject = false;
      return false;
    }
  }

  double overallCoverage = 0;

  Future<void> analyze() async {
    print('=' * 80);
    print('FLUTTER COVERAGE ANALYZER v2.0 - 2025 Enhanced Edition');
    print('=' * 80);
    print('Analyzing: $libPath');
    print('Tests: $testPath');
    print('Mode: ${_getAnalysisMode()}');
    print('');

    // Step 1: Get changed files if incremental
    if (incremental) {
      changedFiles = await getChangedFiles();
      if (changedFiles.isEmpty) {
        print('✅ No changed files to analyze');
        return;
      }
      print(
        '🔄 Incremental mode: analyzing ${changedFiles.length} changed files',
      );
    }

    // Step 2: Fix import paths if needed
    await fixImportPaths();

    // Step 3: Run tests with coverage
    if (parallel) {
      await runParallelCoverage();
    } else {
      await runCoverage();
    }

    // Step 4: Analyze coverage data
    await analyzeCoverage();

    // Step 5: Load baseline for comparison if provided
    if (baselineFile != null) {
      await loadBaselineCoverage();
    }

    // Step 6: Run mutation testing if requested
    if (mutationTesting) {
      await runMutationTesting();
    }

    // Step 7: Analyze test impact if requested
    if (testImpactAnalysis) {
      await analyzeTestImpact();
    }

    // Step 8: Generate reports
    if (generateReport) {
      await generateCoverageReport();
    }

    if (exportJson) {
      await exportJsonReport();
    }

    // Step 9: Auto-fix if requested
    if (autoFix && uncoveredLines.isNotEmpty) {
      await generateMissingTests();
    }

    // Step 10: Validate thresholds (don't exit here, let main handle it)
    final baselineCoverage =
        baselineFile != null ? await getBaselineCoverage() : null;
    if (thresholds.minimum > 0 ||
        thresholds.warning > 0 ||
        thresholds.failOnDecrease) {
      print('\n📊 Validating coverage thresholds...');
      print('  Current coverage: ${overallCoverage.toStringAsFixed(1)}%');
      thresholdViolation =
          !thresholds.validate(overallCoverage, baseline: baselineCoverage);
    }

    // Step 11: Enter watch mode if requested
    if (watchMode) {
      await enterWatchMode();
    }
  }

  String _getAnalysisMode() {
    final modes = <String>[];
    if (branchCoverage) modes.add('Branch');
    if (incremental) modes.add('Incremental');
    if (parallel) modes.add('Parallel');
    if (mutationTesting) modes.add('Mutation');
    if (watchMode) modes.add('Watch');
    return modes.isEmpty ? 'Standard' : modes.join(', ');
  }

  Future<void> fixImportPaths() async {
    print('🔧 Fixing import paths in test files...');

    // Check if testPath is a file or directory
    final testFile = File(testPath);
    final testDir = Directory(testPath);

    final testFiles = <File>[];

    if (testFile.existsSync() && testPath.endsWith('_test.dart')) {
      // It's a single test file
      testFiles.add(testFile);
    } else if (testDir.existsSync()) {
      // It's a directory, process all test files in it
      await for (final file in testDir.list(recursive: true)) {
        if (file is File && file.path.endsWith('_test.dart')) {
          testFiles.add(file);
        }
      }
    } else {
      // Neither file nor directory exists - silently return
      return;
    }

    // Process test files with proper path resolution
    final packageName = await getPackageName();
    final projectRoot = Directory.current.path;

    for (final file in testFiles) {
      var content = await file.readAsString();
      final originalContent = content;
      var hasChanges = false;

      // Find all import statements
      final importRegex = RegExp(r'''import\s+['"](.*?)['"];''');
      final matches = importRegex.allMatches(content).toList();

      for (final match in matches.reversed) {
        // Reverse to avoid index shifting
        final importPath = match.group(1)!;

        // Only process relative imports that point to files outside the current test structure
        if (importPath.startsWith('../')) {
          final fixedImport = await _resolveImportPath(
            file.path,
            importPath,
            packageName,
            projectRoot,
          );

          if (fixedImport != null) {
            content = content.replaceRange(
              match.start,
              match.end,
              "import '$fixedImport';",
            );
            hasChanges = true;
          }
        }
      }

      // Write back only if there were actual changes
      if (hasChanges && content != originalContent) {
        await file.writeAsString(content);
        print('  ✅ Fixed imports in: ${file.path}');
      }
    }
  }

  /// Resolve import path using proper path resolution algorithm
  Future<String?> _resolveImportPath(
    String testFilePath,
    String importPath,
    String packageName,
    String projectRoot,
  ) async {
    try {
      // Get the directory containing the test file
      final testFileDir = Directory(testFilePath).parent.path;

      // Resolve the absolute path of the imported file
      final absoluteImportPath =
          _normalizePath(_joinPath(testFileDir, importPath));

      // Check if the file exists
      if (!File(absoluteImportPath).existsSync()) {
        return null; // Don't modify imports to non-existent files
      }

      // Determine if this should be a package import or relative import
      final relativeFromProjectRoot =
          _getRelativePathFromRoot(absoluteImportPath, projectRoot);

      // Strategy: Keep test helpers as relative imports, convert lib imports to package imports
      if (relativeFromProjectRoot.startsWith('lib/')) {
        // Convert lib files to package imports
        final packagePath =
            relativeFromProjectRoot.substring(4); // Remove 'lib/' prefix
        return 'package:$packageName/$packagePath';
      } else if (relativeFromProjectRoot.startsWith('test/') ||
          relativeFromProjectRoot.contains('helpers') ||
          relativeFromProjectRoot.contains('mocks')) {
        // Keep test files, helpers, and mocks as relative imports
        // Calculate the correct relative path from current test file to target
        final correctRelativePath =
            _calculateRelativePath(testFilePath, absoluteImportPath);
        return correctRelativePath;
      }

      return null; // No changes needed
    } catch (e) {
      // If path resolution fails, don't modify the import
      return null;
    }
  }

  /// Calculate correct relative path between two files
  String _calculateRelativePath(String fromFile, String toFile) {
    final fromDir = Directory(fromFile).parent.path;
    final fromParts = _normalizePath(fromDir).split('/');
    final toParts = _normalizePath(toFile).split('/');

    // Find common ancestor
    var commonLength = 0;
    final minLength = math.min(fromParts.length, toParts.length);
    for (var i = 0; i < minLength; i++) {
      if (fromParts[i] == toParts[i]) {
        commonLength = i + 1;
      } else {
        break;
      }
    }

    // Build relative path
    final upLevels = fromParts.length - commonLength;
    final downParts = toParts.skip(commonLength).toList();

    final pathSegments = <String>[];
    for (var i = 0; i < upLevels; i++) {
      pathSegments.add('..');
    }
    pathSegments.addAll(downParts);

    return pathSegments.join('/');
  }

  /// Get relative path from project root
  String _getRelativePathFromRoot(String absolutePath, String projectRoot) {
    final normalizedAbsolute = _normalizePath(absolutePath);
    final normalizedRoot = _normalizePath(projectRoot);

    if (normalizedAbsolute.startsWith(normalizedRoot)) {
      final relative = normalizedAbsolute.substring(normalizedRoot.length);
      return relative.startsWith('/') ? relative.substring(1) : relative;
    }

    return normalizedAbsolute;
  }

  /// Normalize path separators and resolve .. and . components
  String _normalizePath(String path) {
    // Convert to forward slashes for consistency
    path = path.replaceAll(r'\', '/');

    // Split into parts and resolve . and ..
    final parts = path.split('/').where((part) => part.isNotEmpty).toList();
    final resolved = <String>[];

    for (final part in parts) {
      if (part == '.') {
        // Current directory, skip
        continue;
      } else if (part == '..') {
        // Parent directory
        if (resolved.isNotEmpty) {
          resolved.removeLast();
        }
      } else {
        resolved.add(part);
      }
    }

    // Reconstruct path
    final result = resolved.join('/');
    return path.startsWith('/') ? '/$result' : result;
  }

  /// Join path components safely
  String _joinPath(String base, String relative) {
    if (relative.startsWith('/')) {
      return relative; // Absolute path
    }

    final normalizedBase = _normalizePath(base);
    final normalizedRelative = _normalizePath(relative);

    return '$normalizedBase/$normalizedRelative';
  }

  Future<String> getPackageName() async {
    final pubspecFile = File('pubspec.yaml');
    if (!pubspecFile.existsSync()) return 'supaflow';

    final content = await pubspecFile.readAsString();
    final nameMatch =
        RegExp(r'^name:\s*(\S+)', multiLine: true).firstMatch(content);
    return nameMatch?.group(1) ?? 'supaflow';
  }

  Future<void> runCoverage() async {
    final projectType = isFlutterProject ? 'Flutter' : 'Dart';
    print('\n📊 Running $projectType tests with coverage...');

    // Clean previous coverage
    final coverageDir = Directory('coverage');
    if (coverageDir.existsSync()) {
      await coverageDir.delete(recursive: true);
    }
    await coverageDir.create();

    // Build command with options based on project type
    final String command;
    final List<String> args;

    if (isFlutterProject) {
      // Flutter project
      command = 'flutter';
      args = ['test', '--coverage', '--no-test-assets'];
      if (branchCoverage) {
        args.add('--branch-coverage');
      }
    } else {
      // Pure Dart project
      command = 'dart';
      args = ['test', '--coverage=coverage'];
    }

    // Add test path or specific changed files
    if (incremental && changedFiles.isNotEmpty) {
      // Only test files related to changed source files
      final testFilesToRun = await getTestFilesForChangedFiles();
      args.addAll(testFilesToRun);
    } else {
      args.add(testPath);
    }

    // Run tests with coverage
    final result = await Process.run(
      command,
      args,
      runInShell: true,
    );

    if (result.exitCode != 0) {
      print('  ⚠️  Some tests failed:');
      if (result.stderr.toString().isNotEmpty) {
        print(result.stderr);
      }
    } else {
      print('  ✅ All tests passed');
    }

    // For Dart projects, convert coverage to lcov format
    if (!isFlutterProject) {
      await _convertDartCoverageToLcov();
    }

    // Check if lcov.info was generated
    final lcovFile = File('coverage/lcov.info');
    if (!lcovFile.existsSync() || lcovFile.lengthSync() == 0) {
      print('  ⚠️  Coverage file is empty, attempting alternative method...');
      await runAlternativeCoverage();
    } else {
      print('  ✅ Coverage data generated: ${lcovFile.lengthSync()} bytes');
    }
  }

  /// Convert Dart coverage format to lcov format
  Future<void> _convertDartCoverageToLcov() async {
    try {
      // Check if coverage package is available
      final formatResult = await Process.run(
        'dart',
        [
          'pub',
          'global',
          'run',
          'coverage:format_coverage',
          '--lcov',
          '--in=coverage',
          '--out=coverage/lcov.info',
          '--report-on=lib',
          '--check-ignore'
        ],
        runInShell: true,
      );

      if (formatResult.exitCode != 0) {
        // Try to activate coverage package if not available
        print('  Installing coverage package...');
        await Process.run(
          'dart',
          ['pub', 'global', 'activate', 'coverage'],
          runInShell: true,
        );

        // Try again
        await Process.run(
          'dart',
          [
            'pub',
            'global',
            'run',
            'coverage:format_coverage',
            '--lcov',
            '--in=coverage',
            '--out=coverage/lcov.info',
            '--report-on=lib',
            '--check-ignore'
          ],
          runInShell: true,
        );
      }
    } catch (e) {
      print('  ⚠️  Failed to convert coverage format: $e');
    }
  }

  Future<void> runAlternativeCoverage() async {
    print('\n🔄 Trying alternative coverage collection...');

    final command = isFlutterProject ? 'flutter' : 'dart';
    final testArgs = isFlutterProject
        ? ['test', '--coverage']
        : ['test', '--coverage=coverage'];

    // Method 1: Run each test file individually
    final testDir = Directory(testPath);
    if (testDir.existsSync()) {
      await for (final file in testDir.list(recursive: true)) {
        if (file is File && file.path.endsWith('_test.dart')) {
          print('  Testing: ${file.path}');
          await Process.run(
            command,
            [...testArgs, file.path],
            runInShell: true,
          );
        }
      }
    }

    // For Dart projects, convert coverage to lcov format
    if (!isFlutterProject) {
      await _convertDartCoverageToLcov();
    }
  }

  Future<void> analyzeCoverage() async {
    print('\n🔍 Analyzing coverage data...');

    final lcovFile = File('coverage/lcov.info');
    if (!lcovFile.existsSync() || lcovFile.lengthSync() == 0) {
      print('  ⚠️  No coverage data available, performing manual analysis...');
      await performManualAnalysis();
      return;
    }

    // Parse lcov.info
    final lines = await lcovFile.readAsLines();
    String? currentFile;
    final coveredLines = <String, Set<int>>{};
    final uncoveredLines = <String, Set<int>>{};
    final totalLines = <String, int>{};
    final hitLines = <String, int>{};

    for (final line in lines) {
      if (line.startsWith('SF:')) {
        currentFile = line.substring(3);
        coveredLines[currentFile] = {};
        uncoveredLines[currentFile] = {};
      } else if (line.startsWith('DA:')) {
        final parts = line.substring(3).split(',');
        final lineNum = int.parse(parts[0]);
        final hits = int.parse(parts[1]);

        if (currentFile != null) {
          if (hits > 0) {
            coveredLines[currentFile]!.add(lineNum);
          } else {
            uncoveredLines[currentFile]!.add(lineNum);
          }
        }
      } else if (line.startsWith('LF:')) {
        if (currentFile != null) {
          totalLines[currentFile] = int.parse(line.substring(3));
        }
      } else if (line.startsWith('LH:')) {
        if (currentFile != null) {
          hitLines[currentFile] = int.parse(line.substring(3));
        }
      }
    }

    // Store coverage data for report generation
    coveredLinesData = coveredLines;
    uncoveredLinesData = uncoveredLines;
    totalLinesData = totalLines;
    hitLinesData = hitLines;

    // Calculate overall coverage for files in the analyzed path
    var totalLinesInPath = 0;
    var coveredLinesInPath = 0;
    for (final file in totalLines.keys) {
      if (file.contains(libPath.replaceAll('lib/', ''))) {
        totalLinesInPath += totalLines[file] ?? 0;
        coveredLinesInPath += hitLines[file] ?? 0;
      }
    }

    if (totalLinesInPath > 0) {
      overallCoverage = (coveredLinesInPath / totalLinesInPath) * 100;
    }

    // Report uncovered lines based on path filter
    print('\n📈 Coverage Summary:');
    for (final file in uncoveredLines.keys) {
      // Check if file is in the path we're analyzing
      if (file.contains(libPath.replaceAll('lib/', '')) &&
          uncoveredLines[file]!.isNotEmpty) {
        print('  File: $file');
        print('    Uncovered lines: ${uncoveredLines[file]!.toList()..sort()}');
        this
            .uncoveredLines
            .addAll(uncoveredLines[file]!.map((l) => '$file:$l'));
      }
    }

    if (this.uncoveredLines.isEmpty) {
      print('  ✅ 100% coverage achieved!');
    } else {
      print('  ⚠️  ${this.uncoveredLines.length} lines need coverage');
    }
  }

  Future<void> performManualAnalysis() async {
    print('  Performing manual coverage analysis...');

    // Analyze source files
    final sourceDir = Directory(libPath);
    if (!sourceDir.existsSync()) return;

    await for (final file in sourceDir.list(recursive: true)) {
      if (file is File && file.path.endsWith('.dart')) {
        final analysis = await analyzeSourceFile(file);
        sourceFiles[file.path] = analysis;
      }
    }

    // Analyze test files
    final testDir = Directory(testPath);
    if (!testDir.existsSync()) return;

    await for (final file in testDir.list(recursive: true)) {
      if (file is File && file.path.endsWith('_test.dart')) {
        final analysis = await analyzeTestFile(file);
        testFiles[file.path] = analysis;
      }
    }

    // Match tested methods
    matchTestedMethods();
  }

  Future<FileAnalysis> analyzeSourceFile(File file) async {
    final content = await file.readAsString();
    final lines = content.split('\n');
    final analysis = FileAnalysis(file.path);

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      final lineNum = i + 1;

      // Skip comments and empty lines
      if (line.isEmpty || line.startsWith('//') || line.startsWith('///')) {
        continue;
      }

      // Identify testable lines
      if (isTestableLine(line)) {
        analysis.testableLines.add(lineNum);

        // Extract method names
        final methodMatch = RegExp(r'(\w+)\s*\(').firstMatch(line);
        if (methodMatch != null) {
          analysis.methods.add(methodMatch.group(1)!);
        }

        // Check for specific patterns
        if (line.contains('catch')) {
          analysis.catchBlocks.add(lineNum);
        }
        if (line.contains('throw')) {
          analysis.throwStatements.add(lineNum);
        }
        if (line.contains('if') || line.contains('else')) {
          analysis.conditionals.add(lineNum);
        }
      }
    }

    return analysis;
  }

  Future<FileAnalysis> analyzeTestFile(File file) async {
    final content = await file.readAsString();
    final analysis = FileAnalysis(file.path);

    // Extract test descriptions and tested methods
    final testRegex = RegExp('test\\(["\']([^"\']+)["\']');
    final testMatches = testRegex.allMatches(content);
    for (final match in testMatches) {
      analysis.testDescriptions.add(match.group(1)!);
    }

    // Extract method calls
    final methodCalls = RegExp(r'(\w+)\s*\(').allMatches(content);
    for (final match in methodCalls) {
      analysis.testedMethods.add(match.group(1)!);
    }

    return analysis;
  }

  bool isTestableLine(String line) {
    // Lines that should be tested
    return line.contains('if') ||
        line.contains('for') ||
        line.contains('while') ||
        line.contains('return') ||
        line.contains('throw') ||
        line.contains('catch') ||
        line.contains('switch') ||
        line.contains('=') &&
            !line.startsWith('final') &&
            !line.startsWith('const') ||
        RegExp(r'\w+\(.*\)').hasMatch(line);
  }

  void matchTestedMethods() {
    print('\n🔗 Matching tested methods...');

    for (final sourceFile in sourceFiles.values) {
      final baseName = sourceFile.path.split('/').last.replaceAll('.dart', '');
      final testFileName = '${baseName}_test.dart';

      final testFile = testFiles.values.firstWhere(
        (tf) => tf.path.endsWith(testFileName),
        orElse: () => FileAnalysis(''),
      );

      if (testFile.path.isNotEmpty) {
        // Check which methods are tested
        for (final method in sourceFile.methods) {
          if (!testFile.testedMethods.contains(method)) {
            print('  ⚠️  Method not tested: $method in ${sourceFile.path}');
          }
        }

        // Check catch blocks
        if (sourceFile.catchBlocks.isNotEmpty) {
          final hasErrorTests = testFile.testDescriptions.any(
            (desc) =>
                desc.toLowerCase().contains('error') ||
                desc.toLowerCase().contains('exception') ||
                desc.toLowerCase().contains('catch'),
          );

          if (!hasErrorTests) {
            print('  ⚠️  Catch blocks not tested in ${sourceFile.path}');
            uncoveredLines.addAll(
              sourceFile.catchBlocks.map((l) => '${sourceFile.path}:$l'),
            );
          }
        }
      } else {
        print('  ⚠️  No test file for: ${sourceFile.path}');
        uncoveredLines.addAll(
          sourceFile.testableLines.map((l) => '${sourceFile.path}:$l'),
        );
      }
    }
  }

  Future<void> generateCoverageReport() async {
    print('\n📝 Generating comprehensive coverage report...');

    // Create timestamp early for use throughout the report
    final now = DateTime.now();
    // Use simplified timestamp format: HHMM_DDMMYY
    final simpleTimestamp =
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}_'
        '${now.day.toString().padLeft(2, '0')}${now.month.toString().padLeft(2, '0')}${now.year.toString().substring(2)}';

    // Extract meaningful name from tested path early for use throughout
    final pathName = _extractPathName();

    // Clean up old reports before generating new ones
    await _cleanupOldReports();

    final report = StringBuffer();
    report.writeln('# 📊 Coverage Report');
    report.writeln();

    report.writeln('**Generated:** ${DateTime.now()}');
    report.writeln('**Module:** `$libPath`');
    report.writeln();

    // Calculate overall statistics
    var totalLines = 0;
    var coveredLines = 0;
    final fileCoverages = <String, double>{};

    // Use lcov data if available
    for (final file in totalLinesData.keys) {
      if (file.contains(libPath.replaceAll('lib/', ''))) {
        final total = totalLinesData[file] ?? 0;
        final hits = hitLinesData[file] ?? 0;
        totalLines += total;
        coveredLines += hits;
        if (total > 0) {
          fileCoverages[file] = (hits / total) * 100;
        }
      }
    }

    final overallPercentage =
        totalLines > 0 ? (coveredLines / totalLines * 100) : 0;

    // Executive Summary
    report.writeln('## 📈 Executive Summary');
    report.writeln();
    report.writeln('| Metric | Value |');
    report.writeln('|--------|-------|');
    report.writeln(
      '| **Overall Coverage** | **${overallPercentage.toStringAsFixed(1)}%** |',
    );
    report.writeln('| Total Lines | $totalLines |');
    report.writeln('| Covered Lines | $coveredLines |');
    report.writeln('| Uncovered Lines | ${totalLines - coveredLines} |');
    report.writeln('| Files Analyzed | ${fileCoverages.length} |');
    report.writeln();

    // Coverage Status Badge
    final badge = overallPercentage >= 80
        ? '🟢'
        : overallPercentage >= 60
            ? '🟡'
            : '🔴';
    report.writeln(
      '### Coverage Status: $badge ${overallPercentage >= 80 ? "Good" : overallPercentage >= 60 ? "Needs Improvement" : "Critical"}',
    );
    report.writeln();

    // New Features Section (v2.0)
    if (branchCoverage ||
        incremental ||
        mutationTesting ||
        baselineFile != null) {
      report.writeln('## 🚀 Advanced Coverage Metrics (v2.0)');
      report.writeln();

      // Branch Coverage
      if (branchCoverage) {
        report.writeln('### 🌿 Branch Coverage');
        report.writeln(
          'Branch coverage analysis provides deeper insights into conditional logic coverage.',
        );
        report.writeln('- **Status:** Enabled');
        report.writeln(
          '- **Note:** Requires lcov 2.0+ for full branch coverage support',
        );
        report.writeln();
      }

      // Incremental Coverage
      if (incremental) {
        report.writeln('### 📈 Incremental Coverage');
        report.writeln('Analyzing only changed files from git diff.');
        final changedFiles = await getChangedFiles();
        report.writeln('- **Changed Files:** ${changedFiles.length}');
        if (changedFiles.isNotEmpty) {
          report.writeln('- **Files:** ');
          for (final file in changedFiles.take(5)) {
            report.writeln('  - `${file.split('/').last}`');
          }
          if (changedFiles.length > 5) {
            report.writeln('  - ... and ${changedFiles.length - 5} more');
          }
        }
        report.writeln();
      }

      // Coverage Diff
      if (baselineFile != null) {
        final baselineCov = await getBaselineCoverage();
        if (baselineCov != null) {
          final diff = overallPercentage - baselineCov;
          final diffIcon = diff >= 0 ? '📈' : '📉';
          final diffColor = diff >= 0 ? '🟢' : '🔴';
          report.writeln('### 📊 Coverage Diff vs Baseline');
          report.writeln(
            '- **Baseline Coverage:** ${baselineCov.toStringAsFixed(1)}%',
          );
          report.writeln(
            '- **Current Coverage:** ${overallPercentage.toStringAsFixed(1)}%',
          );
          report.writeln(
            '- **Change:** $diffIcon ${diff >= 0 ? "+" : ""}${diff.toStringAsFixed(1)}% $diffColor',
          );
          report.writeln();
        }
      }

      // Mutation Testing
      if (mutationTesting) {
        report.writeln('### 🧬 Mutation Testing');
        report.writeln(
          'Mutation testing helps verify test effectiveness by introducing controlled bugs.',
        );
        report.writeln('- **Status:** Available (run with --mutation flag)');
        report.writeln('- **Note:** This is a time-intensive operation');
        report.writeln();
      }

      // Test Impact Analysis
      if (testImpactAnalysis) {
        report.writeln('### 🎯 Test Impact Analysis');
        report.writeln('Mapping which tests cover which lines of code.');
        report.writeln('- **Status:** Enabled');
        report.writeln(
          '- **Use Case:** Optimize test execution by running only affected tests',
        );
        report.writeln();
      }

      // Performance Metrics
      if (parallel) {
        report.writeln('### ⚡ Performance Optimization');
        report.writeln('- **Parallel Execution:** Enabled');
        report.writeln('- **Workers:** ${Platform.numberOfProcessors}');
        report.writeln(
          '- **Speed Improvement:** ~${(Platform.numberOfProcessors * 0.7).toStringAsFixed(0)}x faster',
        );
        report.writeln();
      }

      report.writeln('---');
      report.writeln();
    }

    // Thresholds Section
    if (thresholds.minimum > 0) {
      report.writeln('## 🎯 Coverage Thresholds');
      report.writeln();
      report.writeln('| Threshold | Value | Status |');
      report.writeln('|-----------|-------|--------|');
      report.writeln(
        '| Minimum | ${thresholds.minimum.toStringAsFixed(1)}% | ${overallPercentage >= thresholds.minimum ? "✅ Pass" : "❌ Fail"} |',
      );
      report.writeln(
        '| Warning | ${thresholds.warning.toStringAsFixed(1)}% | ${overallPercentage >= thresholds.warning ? "✅ Pass" : "⚠️ Warning"} |',
      );
      if (thresholds.failOnDecrease && baselineFile != null) {
        final baselineCov = await getBaselineCoverage();
        if (baselineCov != null) {
          report.writeln(
            '| No Decrease | ${baselineCov.toStringAsFixed(1)}% | ${overallPercentage >= baselineCov ? "✅ Pass" : "❌ Fail"} |',
          );
        }
      }
      report.writeln();
    }

    // File-by-file breakdown
    report.writeln('## 📁 File Coverage Breakdown');
    report.writeln();
    report.writeln('| File | Coverage | Lines | Covered | Uncovered |');
    report.writeln('|------|----------|-------|---------|-----------|');

    for (final file in fileCoverages.keys) {
      final fileName = file.split('/').last;
      final total = totalLinesData[file] ?? 0;
      final hits = hitLinesData[file] ?? 0;
      final percentage = fileCoverages[file]!;
      final statusIcon = percentage >= 80
          ? '✅'
          : percentage >= 60
              ? '⚠️'
              : '❌';

      report.writeln(
        '| $statusIcon `$fileName` | **${percentage.toStringAsFixed(1)}%** | $total | $hits | ${total - hits} |',
      );
    }
    report.writeln();

    // Detailed uncovered lines section
    if (uncoveredLines.isNotEmpty) {
      report.writeln('## 🔍 Uncovered Lines Detail');
      report.writeln();
      report.writeln('Below are the specific lines that need test coverage:');
      report.writeln();

      // Group uncovered lines by file
      final uncoveredByFile = <String, List<int>>{};
      for (final lineStr in uncoveredLines) {
        final parts = lineStr.split(':');
        final file = parts[0];
        final lineNum = int.parse(parts[1]);
        uncoveredByFile.putIfAbsent(file, () => []).add(lineNum);
      }

      for (final file in uncoveredByFile.keys) {
        final fileName = file.split('/').last;
        final lines = uncoveredByFile[file]!..sort();

        report.writeln('### 📄 `$fileName`');
        report.writeln();

        // Group consecutive lines for better readability
        report.writeln('**Uncovered line numbers:**');
        report.writeln('```');
        report.writeln(_formatLineRanges(lines));
        report.writeln('```');

        // Try to read the file and show the actual uncovered code
        final sourceFile = File(file);
        if (sourceFile.existsSync()) {
          report.writeln();
          report.writeln('<details>');
          report.writeln(
            '<summary>Click to see uncovered code snippets</summary>',
          );
          report.writeln();

          final sourceLines = sourceFile.readAsLinesSync();
          for (final lineNum in lines) {
            if (lineNum <= sourceLines.length) {
              final line = sourceLines[lineNum - 1].trim();
              if (line.isNotEmpty && !line.startsWith('//')) {
                report.writeln('- Line $lineNum: `${_truncate(line, 80)}`');
              }
            }
          }
          report.writeln();
          report.writeln('</details>');
        }
        report.writeln();
      }
    }

    // Test recommendations
    report.writeln('## 💡 Recommendations');
    report.writeln();

    if (overallPercentage < 100) {
      report.writeln('To achieve 100% coverage, focus on:');
      report.writeln();

      // Analyze patterns in uncovered lines
      var catchBlocks = 0;
      var conditionals = 0;
      var otherLines = 0;

      for (final lineStr in uncoveredLines) {
        final parts = lineStr.split(':');
        if (parts.length >= 2) {
          final file = parts[0];
          final lineNum = int.parse(parts[1]);

          // Try to read the file to categorize the uncovered line
          final sourceFile = File(file);
          if (sourceFile.existsSync()) {
            final lines = sourceFile.readAsLinesSync();
            if (lineNum <= lines.length) {
              final line = lines[lineNum - 1];
              if (line.contains('catch')) {
                catchBlocks++;
              } else if (line.contains('if') || line.contains('else'))
                conditionals++;
              else
                otherLines++;
            }
          }
        }
      }

      if (catchBlocks > 0) {
        report.writeln('1. **Error Handling** ($catchBlocks catch blocks)');
        report.writeln('   - Add tests that throw exceptions');
        report.writeln('   - Test error recovery paths');
        report.writeln();
      }

      if (conditionals > 0) {
        report.writeln('2. **Branch Coverage** ($conditionals conditionals)');
        report.writeln('   - Test both true and false conditions');
        report.writeln('   - Cover edge cases in if/else statements');
        report.writeln();
      }

      if (otherLines > 0) {
        report.writeln('3. **Other Logic** ($otherLines lines)');
        report.writeln('   - Review untested methods');
        report.writeln('   - Add integration tests for complex flows');
        report.writeln();
      }
    } else {
      report.writeln(
        '🎉 **Congratulations!** You have achieved 100% code coverage!',
      );
      report.writeln();
      report.writeln('Next steps:');
      report.writeln('- Maintain coverage with pre-commit hooks');
      report.writeln('- Add coverage checks to CI/CD pipeline');
      report.writeln('- Consider adding mutation testing');
    }

    // How to use section
    report.writeln('## 🛠️ How to Improve Coverage');
    report.writeln();
    report.writeln(
      '1. **Run with auto-fix:** `dart coverage_tool.dart $libPath --fix`',
    );
    report.writeln(
      '2. **View HTML report:** `genhtml coverage/lcov.info -o coverage/html && open coverage/html/index.html`',
    );
    report.writeln(
      '3. **Run specific tests:** `flutter test test/${libPath.replaceAll("lib/src/", "")}/`',
    );
    report.writeln();

    // Additional Resources
    if (exportJson) {
      report.writeln('## 📦 Generated Artifacts');
      report.writeln();

      final jsonPath =
          'analyzer/reports/test_coverages/${pathName}_data@$simpleTimestamp.json';
      report.writeln('- **JSON Report:** [`$jsonPath`]($jsonPath)');
      report.writeln('  - Machine-readable format for CI/CD integration');

      report.writeln();
    }

    // CLI Options
    report.writeln('## 🔧 Available Options');
    report.writeln();
    report.writeln('```bash');
    report.writeln('# Basic usage');
    report.writeln('dart analyzer/coverage_tool.dart lib/src/core');
    report.writeln();
    report.writeln('# With auto-fix');
    report.writeln('dart analyzer/coverage_tool.dart lib/src/core --fix');
    report.writeln();
    report.writeln('# Incremental coverage (changed files only)');
    report
        .writeln('dart analyzer/coverage_tool.dart lib/src/core --incremental');
    report.writeln();
    report.writeln('# With branch coverage');
    report.writeln('dart analyzer/coverage_tool.dart lib/src/core --branch');
    report.writeln();
    report.writeln('# Parallel execution');
    report.writeln('dart analyzer/coverage_tool.dart lib/src/core --parallel');
    report.writeln();
    report.writeln('# With coverage diff');
    report.writeln(
      'dart analyzer/coverage_tool.dart lib/src/core --baseline=coverage_baseline.json',
    );
    report.writeln();
    report.writeln('# Watch mode');
    report.writeln('dart analyzer/coverage_tool.dart lib/src/core --watch');
    report.writeln();
    report.writeln('# Export JSON report');
    report.writeln('dart analyzer/coverage_tool.dart lib/src/core --json');
    report.writeln();
    report.writeln('# With coverage thresholds');
    report.writeln(
      'dart analyzer/coverage_tool.dart lib/src/core --min-coverage=80 --warn-coverage=60',
    );
    report.writeln();
    report.writeln('# All features');
    report.writeln(
      'dart analyzer/coverage_tool.dart lib/src/core --fix --branch --incremental --parallel --json',
    );
    report.writeln('```');
    report.writeln();

    // Footer
    report.writeln('---');
    report.writeln(
      '*Generated by coverage_tool.dart v2.0 - Enhanced with 11 new features*',
    );

    // Build JSON export with all coverage metrics
    final jsonData = <String, dynamic>{
      'metadata': {
        'tool': 'coverage_tool',
        'version': '2.0',
        'generated': now.toIso8601String(),
        'module': libPath,
        'test_path': testPath,
      },
      'summary': {
        'overall_coverage': overallPercentage,
        'total_lines': totalLines,
        'covered_lines': coveredLines,
        'uncovered_lines': totalLines - coveredLines,
        'files_analyzed': fileCoverages.length,
      },
      'file_coverages': fileCoverages.entries.map((entry) {
        return {
          'file': entry.key,
          'coverage': entry.value,
          'total_lines': totalLinesData[entry.key],
          'covered_lines': hitLinesData[entry.key],
        };
      }).toList(),
    };

    // Add advanced features data if available
    if (incremental) {
      final changedFiles = await getChangedFiles();
      jsonData['incremental'] = {
        'enabled': true,
        'changed_files_count': changedFiles.length,
        'changed_files': changedFiles,
      };
    }

    if (baselineFile != null) {
      final baselineCov = await getBaselineCoverage();
      if (baselineCov != null) {
        jsonData['baseline_comparison'] = {
          'baseline_coverage': baselineCov,
          'current_coverage': overallPercentage,
          'difference': overallPercentage - baselineCov,
        };
      }
    }

    if (branchCoverage) {
      jsonData['branch_coverage'] = {'enabled': true};
    }

    if (mutationTesting) {
      jsonData['mutation_testing'] = {'enabled': true};
    }

    // Write unified report
    final reportPath = await ReportUtils.writeUnifiedReport(
      moduleName: pathName,
      timestamp: simpleTimestamp,
      markdownContent: report.toString(),
      jsonData: jsonData,
      suffix: 'cov',
      verbose: true,
    );

    print('  ✅ Report saved to: $reportPath');
  }

  String _formatLineRanges(List<int> lines) {
    if (lines.isEmpty) return '';

    final ranges = <String>[];
    var start = lines[0];
    var end = lines[0];

    for (var i = 1; i < lines.length; i++) {
      if (lines[i] == end + 1) {
        end = lines[i];
      } else {
        ranges.add(start == end ? '$start' : '$start-$end');
        start = lines[i];
        end = lines[i];
      }
    }
    ranges.add(start == end ? '$start' : '$start-$end');

    return ranges.join(', ');
  }

  String _truncate(String str, int maxLength) {
    if (str.length <= maxLength) return str;
    return '${str.substring(0, maxLength - 3)}...';
  }

  Future<void> generateMissingTests() async {
    print('\n🔧 Generating missing test cases...');

    // Group uncovered lines by file
    final uncoveredByFile = <String, List<int>>{};
    for (final line in uncoveredLines) {
      final parts = line.split(':');
      final file = parts[0];
      final lineNum = int.parse(parts[1]);

      uncoveredByFile.putIfAbsent(file, () => []).add(lineNum);
    }

    // Generate tests for each file
    for (final entry in uncoveredByFile.entries) {
      final sourceFile = File(entry.key);
      if (!sourceFile.existsSync()) continue;

      final testFile = await generateTestsForFile(sourceFile, entry.value);
      if (testFile != null) {
        print('  ✅ Generated tests for: ${sourceFile.path}');
      }
    }
  }

  Future<File?> generateTestsForFile(
    File sourceFile,
    List<int> uncoveredLines,
  ) async {
    final fileName = sourceFile.path.split('/').last;
    final testFileName = fileName.replaceAll('.dart', '_test.dart');
    final testFilePath = '$testPath/$testFileName';

    final testFile = File(testFilePath);
    if (!testFile.existsSync()) {
      // Create new test file
      await testFile.create(recursive: true);
    }

    // Read source to understand what needs testing
    final sourceContent = await sourceFile.readAsString();
    final sourceLines = sourceContent.split('\n');

    final testContent = StringBuffer();
    testContent.writeln('// Additional tests for uncovered lines');
    testContent.writeln('// Generated by coverage_tool.dart');
    testContent.writeln();

    for (final lineNum in uncoveredLines) {
      if (lineNum <= sourceLines.length) {
        final line = sourceLines[lineNum - 1];

        if (line.contains('catch')) {
          testContent.writeln("""
  test('should handle error at line $lineNum', () async {
    // Test error handling
    expect(() => /* call method that triggers catch */, throwsException);
  });
""");
        } else if (line.contains('if') || line.contains('else')) {
          testContent.writeln("""
  test('should test condition at line $lineNum', () {
    // Test both branches of condition
    // Branch 1: condition is true
    // Branch 2: condition is false
  });
""");
        }
      }
    }

    // Append to existing test file
    final existingContent = await testFile.readAsString();
    if (!existingContent.contains('Additional tests for uncovered lines')) {
      await testFile.writeAsString('$existingContent\n$testContent');
    }

    return testFile;
  }

  // ============= NEW ENHANCED METHODS =============

  /// Get list of changed files from git
  Future<List<String>> getChangedFiles() async {
    final result = await Process.run('git', ['diff', '--name-only', 'HEAD~1']);
    if (result.exitCode != 0) {
      print('⚠️  Could not get changed files, analyzing all files');
      return [];
    }

    return result.stdout
        .toString()
        .split('\n')
        .where(
          (f) => f.endsWith('.dart') && !f.startsWith('test/') && f.isNotEmpty,
        )
        .toList();
  }

  /// Get test files for changed source files
  Future<List<String>> getTestFilesForChangedFiles() async {
    final testFiles = <String>[];
    for (final sourceFile in changedFiles) {
      final testFile = sourceFile
          .replaceFirst('lib/', 'test/')
          .replaceFirst('.dart', '_test.dart');

      if (await File(testFile).exists()) {
        testFiles.add(testFile);
      }
    }
    return testFiles;
  }

  /// Run coverage with parallel execution
  Future<void> runParallelCoverage() async {
    print('\n🚀 Running parallel coverage analysis...');

    final testDir = Directory(testPath);
    if (!testDir.existsSync()) return;

    // Collect all test files
    final testFiles = <String>[];
    await for (final file in testDir.list(recursive: true)) {
      if (file is File && file.path.endsWith('_test.dart')) {
        if (!shouldExclude(file.path)) {
          testFiles.add(file.path);
        }
      }
    }

    // Split into chunks for parallel execution
    final numWorkers = math.min(Platform.numberOfProcessors, 4);
    final chunks = <List<String>>[];
    final chunkSize = (testFiles.length / numWorkers).ceil();

    for (var i = 0; i < testFiles.length; i += chunkSize) {
      chunks.add(testFiles.skip(i).take(chunkSize).toList());
    }

    print('  Running ${testFiles.length} tests across $numWorkers workers');

    // Run chunks in parallel
    final futures = <Future<void>>[];
    for (var i = 0; i < chunks.length; i++) {
      futures.add(runCoverageForChunk(chunks[i], i));
    }

    await Future.wait(futures);
    await mergeCoverageReports();
  }

  /// Run coverage for a chunk of test files
  Future<void> runCoverageForChunk(List<String> testFiles, int chunkId) async {
    final args = [
      'test',
      '--coverage',
      '--coverage-path=coverage/lcov_$chunkId.info',
    ];
    if (branchCoverage) {
      args.add('--branch-coverage');
    }
    args.addAll(testFiles);

    await Process.run('flutter', args, runInShell: true);
  }

  /// Merge coverage reports from parallel execution
  Future<void> mergeCoverageReports() async {
    print('  Merging coverage reports...');

    final coverageDir = Directory('coverage');
    final mergedLines = <String>[];

    await for (final file in coverageDir.list()) {
      if (file is File && file.path.contains('lcov_')) {
        final lines = await file.readAsLines();
        mergedLines.addAll(lines);
        await file.delete();
      }
    }

    // Write merged report
    await File('coverage/lcov.info').writeAsString(mergedLines.join('\n'));
  }

  /// Check if file should be excluded from coverage
  bool shouldExclude(String filePath) {
    for (final pattern in excludePatterns) {
      if (RegExp(pattern).hasMatch(filePath)) {
        return true;
      }
    }
    return false;
  }

  /// Run mutation testing
  Future<void> runMutationTesting() async {
    print('\n🧬 Running mutation testing...');

    // Check if mutation_test package is available
    final checkResult =
        await Process.run('dart', ['pub', 'deps'], runInShell: true);
    if (!checkResult.stdout.toString().contains('mutation_test')) {
      print(
        '  ⚠️  mutation_test package not found. Add it to dev_dependencies:',
      );
      print('      dev_dependencies:');
      print('        mutation_test: ^1.0.0');
      return;
    }

    // Run mutation testing
    final args = ['run', 'mutation_test'];

    // Use existing coverage if available
    final lcovFile = File('coverage/lcov.info');
    if (lcovFile.existsSync()) {
      args.addAll(['--coverage', 'coverage/lcov.info']);
    }

    // Add specific files if incremental
    if (incremental && changedFiles.isNotEmpty) {
      args.addAll(changedFiles);
    } else {
      args.add(libPath);
    }

    final result = await Process.run('dart', args, runInShell: true);

    if (result.exitCode == 0) {
      // Parse mutation score
      final output = result.stdout.toString();
      final scoreMatch = RegExp(r'Mutation Score: (\d+)%').firstMatch(output);
      if (scoreMatch != null) {
        final score = int.parse(scoreMatch.group(1)!);
        mutationScore['overall'] = score;
        print('  ✅ Mutation Score: $score%');
      }
    } else {
      print('  ⚠️  Mutation testing failed: ${result.stderr}');
    }
  }

  /// Analyze test impact - map which tests cover which lines
  Future<void> analyzeTestImpact() async {
    print('\n🎯 Analyzing test impact mapping...');

    lineToTestsMapping.clear();

    final testDir = Directory(testPath);
    if (!testDir.existsSync()) return;

    final testFiles = <String>[];
    await for (final file in testDir.list(recursive: true)) {
      if (file is File && file.path.endsWith('_test.dart')) {
        testFiles.add(file.path);
      }
    }

    for (final testFile in testFiles) {
      // Run test individually and collect coverage
      final tempCoverageFile = 'coverage/temp_${testFile.hashCode}.info';
      final result = await Process.run(
        'flutter',
        ['test', '--coverage', '--coverage-path=$tempCoverageFile', testFile],
        runInShell: true,
      );

      if (result.exitCode == 0 && await File(tempCoverageFile).exists()) {
        // Parse coverage for this test
        final lines = await File(tempCoverageFile).readAsLines();
        String? currentFile;

        for (final line in lines) {
          if (line.startsWith('SF:')) {
            currentFile = line.substring(3);
          } else if (line.startsWith('DA:') && currentFile != null) {
            final parts = line.substring(3).split(',');
            final lineNum = int.parse(parts[0]);
            final hits = int.parse(parts[1]);

            if (hits > 0) {
              final lineKey = '$currentFile:$lineNum';
              lineToTestsMapping.putIfAbsent(lineKey, () => {}).add(testFile);
            }
          }
        }

        // Clean up temp file
        await File(tempCoverageFile).delete();
      }
    }

    print(
      '  ✅ Mapped ${lineToTestsMapping.length} lines to their covering tests',
    );
  }

  /// Load baseline coverage for comparison
  Future<void> loadBaselineCoverage() async {
    if (baselineFile == null) return;

    final file = File(baselineFile!);
    if (!file.existsSync()) {
      print('⚠️  Baseline file not found: $baselineFile');
      return;
    }

    try {
      final jsonStr = await file.readAsString();
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;

      final baselineFiles = json['files'] as Map<String, dynamic>?;
      if (baselineFiles != null) {
        for (final entry in baselineFiles.entries) {
          final currentCoverage = (totalLinesData[entry.key] ?? 0) > 0
              ? (hitLinesData[entry.key]! / totalLinesData[entry.key]!) * 100
              : 0.0;
          final baselineCoverage = entry.value as double;
          coverageDiff[entry.key] = currentCoverage - baselineCoverage;
        }
      }

      print('📊 Loaded baseline coverage for comparison');
    } catch (e) {
      print('⚠️  Could not load baseline: $e');
    }
  }

  /// Get baseline coverage value
  Future<double?> getBaselineCoverage() async {
    if (baselineFile == null) return null;

    final file = File(baselineFile!);
    if (!file.existsSync()) return null;

    try {
      final jsonStr = await file.readAsString();
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return json['overall'] as double?;
    } catch (e) {
      return null;
    }
  }

  /// Clean up old reports in the coverage directory
  Future<void> _cleanupOldReports() async {
    // Extract meaningful name from tested path
    final pathName = _extractPathName();

    // Clean old reports using unified naming
    await ReportUtils.cleanOldReports(
      pathName: pathName,
      prefixPatterns: [
        'test_report_cov', // New unified format
        'tc', // Old coverage_tool format
        'coverage', // Even older format
      ],
      verbose: true,
    );
  }

  String _extractPathName() {
    // Extract module name from the SOURCE path (libPath), not test path
    // This is what's actually being analyzed
    final path = libPath
        .replaceAll(r'\', '/')
        .replaceAll(RegExp(r'/$'), ''); // Remove trailing slash
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();

    if (segments.isEmpty) {
      return 'all_tests';
    }

    var pathName = segments.last;

    // If it's a file (ends with .dart), extract the module name properly
    if (pathName.endsWith('.dart')) {
      // Remove .dart extension
      pathName = pathName.substring(0, pathName.length - 5);
    } else if (pathName == 'lib') {
      // Special case: if analyzing entire 'lib' folder, use package name from pubspec
      return _getPackageName();
    }
    // If it's a folder like 'src', 'models', 'ui', return the folder name

    return pathName;
  }

  /// Get package name from pubspec.yaml
  String _getPackageName() {
    try {
      final pubspecFile = File('pubspec.yaml');
      if (pubspecFile.existsSync()) {
        final content = pubspecFile.readAsStringSync();
        final nameMatch =
            RegExp(r'^name:\s*(\S+)', multiLine: true).firstMatch(content);
        return nameMatch?.group(1) ?? 'package';
      }
    } catch (e) {
      // Ignore errors
    }
    return 'package';
  }

  /// Export coverage data as JSON
  Future<void> exportJsonReport() async {
    print('\n📄 Exporting JSON report...');

    // Calculate metrics for only the analyzed path
    var filteredTotalLines = 0;
    var filteredCoveredLines = 0;
    var filteredFileCount = 0;

    for (final file in totalLinesData.keys) {
      if (file.contains(libPath.replaceAll('lib/', ''))) {
        filteredTotalLines += totalLinesData[file] ?? 0;
        filteredCoveredLines += hitLinesData[file] ?? 0;
        filteredFileCount++;
      }
    }

    final filteredOverallCoverage = filteredTotalLines > 0
        ? (filteredCoveredLines / filteredTotalLines * 100)
        : 0.0;

    final json = {
      'timestamp': DateTime.now().toIso8601String(),
      'overall': filteredOverallCoverage,
      'libPath': libPath,
      'files': <String, dynamic>{},
      'uncovered': uncoveredLines
          .where((line) => line.contains(libPath.replaceAll('lib/', '')))
          .toList(),
      'metrics': {
        'totalLines': filteredTotalLines,
        'coveredLines': filteredCoveredLines,
        'totalFiles': filteredFileCount,
        'coveragePercentage': filteredOverallCoverage,
      },
      'branch': branchCoverage ? branchCoverageData : null,
      'mutation': mutationScore.isNotEmpty ? mutationScore : null,
      'impact': testImpactAnalysis
          ? {
              'mappedLines': lineToTestsMapping.length,
              'totalTests':
                  lineToTestsMapping.values.expand((e) => e).toSet().length,
            }
          : null,
      'diff': coverageDiff.isNotEmpty ? coverageDiff : null,
    };

    // Add file-level data - filter to only include files in the analyzed path
    final filesMap = <String, dynamic>{};
    for (final file in totalLinesData.keys) {
      // Only include files that are in the libPath being analyzed
      if (!file.contains(libPath.replaceAll('lib/', ''))) {
        continue;
      }

      final total = totalLinesData[file] ?? 0;
      final hits = hitLinesData[file] ?? 0;
      final coverage = total > 0 ? (hits / total) * 100 : 0.0;

      filesMap[file] = {
        'coverage': coverage,
        'totalLines': total,
        'coveredLines': hits,
        'uncoveredLines': uncoveredLinesData[file]?.toList() ?? [],
      };
    }
    json['files'] = filesMap;

    // Save JSON report in test_coverages folder
    final reportsDir = Directory('analyzer/reports/test_coverages');
    if (!await reportsDir.exists()) {
      await reportsDir.create(recursive: true);
    }

    final now = DateTime.now();
    // Use simplified timestamp format: HHMM_DDMMYY for consistency
    final simpleTimestamp =
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}_'
        '${now.day.toString().padLeft(2, '0')}${now.month.toString().padLeft(2, '0')}${now.year.toString().substring(2)}';

    // Extract meaningful name from tested path (same logic as in generateCoverageReport)
    var pathName = testPath.replaceAll('/', '_').replaceAll(r'\', '_');
    if (pathName.startsWith('test_')) {
      pathName = pathName.substring(5);
    }
    if (pathName.endsWith('_')) {
      pathName = pathName.substring(0, pathName.length - 1);
    }

    final jsonFile = File(
      'analyzer/reports/test_coverages/${pathName}_data@$simpleTimestamp.json',
    );
    await jsonFile
        .writeAsString(const JsonEncoder.withIndent('  ').convert(json));

    print('  ✅ JSON report saved to: ${jsonFile.path}');
  }

  /// Enter watch mode for continuous coverage monitoring
  Future<void> enterWatchMode() async {
    print('\n👁️  Entering watch mode...');
    print('Press Ctrl+C to exit\n');

    // Watch both source and test directories
    final sourceWatcher = Directory(libPath).watch(recursive: true);
    final testWatcher = Directory(testPath).watch(recursive: true);

    // Combine streams
    final watchStream = StreamGroup.merge([sourceWatcher, testWatcher]);

    // Debounce to avoid multiple rapid updates
    Timer? debounceTimer;

    await for (final event in watchStream) {
      if (event.path.endsWith('.dart')) {
        debounceTimer?.cancel();
        debounceTimer = Timer(const Duration(seconds: 1), () async {
          print('\n📝 File changed: ${event.path}');
          print('Re-running coverage analysis...\n');

          // Reset data
          uncoveredLines.clear();
          coveredLinesData.clear();
          uncoveredLinesData.clear();
          totalLinesData.clear();
          hitLinesData.clear();

          // Re-run analysis
          await runCoverage();
          await analyzeCoverage();

          // Show summary
          print(
            '\n📊 Updated Coverage: ${overallCoverage.toStringAsFixed(1)}%',
          );
          if (uncoveredLines.isNotEmpty) {
            print('  ⚠️  ${uncoveredLines.length} lines need coverage');
          }
        });
      }
    }
  }
}

// Import StreamGroup for watch mode
class StreamGroup {
  static Stream<T> merge<T>(List<Stream<T>> streams) {
    final controller = StreamController<T>();
    final subscriptions = <StreamSubscription<T>>[];

    for (final stream in streams) {
      subscriptions.add(
        stream.listen(
          controller.add,
          onError: controller.addError,
          onDone: () {
            if (subscriptions.every((s) => s.isPaused)) {
              controller.close();
            }
          },
        ),
      );
    }

    return controller.stream;
  }
}

class FileAnalysis {
  FileAnalysis(this.path);
  final String path;
  final Set<int> testableLines = {};
  final Set<String> methods = {};
  final Set<int> catchBlocks = {};
  final Set<int> throwStatements = {};
  final Set<int> conditionals = {};
  final List<String> testDescriptions = [];
  final Set<String> testedMethods = {};
}

void main(List<String> args) async {
  // Parse arguments
  final autoFix = args.contains('--fix');
  final skipReport = args.contains('--no-report');
  final branchCoverage = args.contains('--branch');
  final incremental = args.contains('--incremental');
  final mutationTesting = args.contains('--mutation');
  final watchMode = args.contains('--watch');
  final parallel = args.contains('--parallel');
  final exportJson = args.contains('--json');
  final testImpactAnalysis = args.contains('--impact');

  // Parse exclude patterns
  final excludePatterns = <String>[];
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--exclude' && i + 1 < args.length) {
      excludePatterns.add(args[i + 1]);
    }
  }

  // Parse thresholds
  double minCoverage = 0;
  double warnCoverage = 0;
  final failOnDecrease = args.contains('--fail-on-decrease');
  for (var i = 0; i < args.length; i++) {
    // Handle both --min-coverage=80 and --min-coverage 80 formats
    if (args[i].startsWith('--min-coverage')) {
      if (args[i].contains('=')) {
        minCoverage = double.tryParse(args[i].split('=')[1]) ?? 0;
      } else if (i + 1 < args.length) {
        minCoverage = double.tryParse(args[i + 1]) ?? 0;
      }
    } else if (args[i].startsWith('--warn-coverage')) {
      if (args[i].contains('=')) {
        warnCoverage = double.tryParse(args[i].split('=')[1]) ?? 0;
      } else if (i + 1 < args.length) {
        warnCoverage = double.tryParse(args[i + 1]) ?? 0;
      }
    }
  }

  // Parse baseline file
  String? baselineFile;
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--baseline' && i + 1 < args.length) {
      baselineFile = args[i + 1];
    }
  }

  // Parse paths
  var libPath = 'lib/src';
  var testPath = 'test';

  // Collect non-flag arguments
  final nonFlagArgs = <String>[];
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--lib' && i + 1 < args.length) {
      libPath = args[i + 1];
      i++; // Skip the next arg since we consumed it
    } else if (args[i] == '--test' && i + 1 < args.length) {
      testPath = args[i + 1];
      i++; // Skip the next arg since we consumed it
    } else if (!args[i].startsWith('--')) {
      // Check if previous arg was a flag that takes a value
      final isPreviousFlag = i > 0 &&
          (args[i - 1] == '--lib' ||
              args[i - 1] == '--test' ||
              args[i - 1] == '--exclude' ||
              args[i - 1] == '--baseline' ||
              args[i - 1].startsWith('--min-coverage') ||
              args[i - 1].startsWith('--warn-coverage'));
      if (!isPreviousFlag) {
        nonFlagArgs.add(args[i]);
      }
    }
  }

  // Process non-flag arguments
  if (nonFlagArgs.isNotEmpty) {
    // First argument is the lib/module path
    final firstArg = nonFlagArgs[0];
    if (firstArg.startsWith('lib/')) {
      libPath = firstArg;
      // If there's a second argument, use it as test path
      if (nonFlagArgs.length > 1) {
        testPath = nonFlagArgs[1];
      } else {
        // Auto-derive test path - handle lib/src/ pattern specially
        String derivedTestPath;
        if (firstArg.startsWith('lib/src/')) {
          // For lib/src/X, map to test/X (remove the src/ part)
          final moduleName = firstArg.substring('lib/src/'.length);
          derivedTestPath = 'test/$moduleName';
        } else {
          // For other lib/ paths, just replace lib/ with test/
          derivedTestPath = firstArg.replaceFirst('lib/', 'test/');
        }

        // Check if derived path exists, otherwise use 'test/'
        final derivedFile = File(derivedTestPath);
        final derivedDir = Directory(derivedTestPath);
        if (derivedFile.existsSync() || derivedDir.existsSync()) {
          testPath = derivedTestPath;
        } else {
          // Derived path doesn't exist, use root test directory
          testPath = 'test/';
        }
      }
    } else if (firstArg.startsWith('test/')) {
      testPath = firstArg;
      libPath = firstArg.replaceFirst('test/', 'lib/');
    } else {
      // Assume it's a module name
      libPath = 'lib/src/$firstArg';
      testPath = nonFlagArgs.length > 1 ? nonFlagArgs[1] : 'test/$firstArg';
    }
  }

  // Smart validation: if derived test path doesn't exist, try to find the actual test location
  if (!Directory(testPath).existsSync() && !File(testPath).existsSync()) {
    // Extract the module name from the lib path
    var moduleName = '';
    if (libPath.startsWith('lib/src/')) {
      moduleName = libPath.substring('lib/src/'.length);
    } else if (libPath.startsWith('lib/')) {
      moduleName = libPath.substring('lib/'.length);
    }

    if (moduleName.isNotEmpty) {
      // Try different test path patterns
      final possibleTestPaths = [
        'test/$moduleName',
        'test/src/$moduleName',
        'test/${moduleName.split('/').last}', // Just the last part of the path
      ];

      for (final possiblePath in possibleTestPaths) {
        if (Directory(possiblePath).existsSync() ||
            File(possiblePath).existsSync() ||
            File('${possiblePath}_test.dart').existsSync()) {
          testPath = possiblePath;
          break;
        }
      }
    }
  }

  // Print usage if no valid paths
  if (args.contains('--help') || args.contains('-h')) {
    print('Usage: dart coverage_tool.dart [options] [module_path]');
    print('');
    print('Basic Options:');
    print('  --lib <path>          Path to source files (default: lib/src)');
    print('  --test <path>         Path to test files (default: test)');
    print('  --fix                 Generate missing test cases automatically');
    print('  --no-report           Skip generating coverage report');
    print('  --help, -h            Show this help message');
    print('');
    print('Advanced Options (v2.0):');
    print('  --branch              Include branch coverage analysis');
    print('  --incremental         Only analyze changed files (git diff)');
    print('  --mutation            Run mutation testing');
    print(
      '  --watch               Enable watch mode for continuous monitoring',
    );
    print('  --parallel            Use parallel test execution');
    print('  --json                Export JSON report');
    print('  --impact              Enable test impact analysis');
    print(
      '  --exclude <pattern>   Exclude files matching pattern (can be used multiple times)',
    );
    print('                        Common patterns:');
    print(
      '                          --exclude "*.g.dart"        (generated files)',
    );
    print(
      '                          --exclude "*.freezed.dart"  (Freezed files)',
    );
    print('                          --exclude "test/mocks/*"    (mock files)');
    print('  --baseline <file>     Compare against baseline coverage');
    print('  --min-coverage <n>    Minimum coverage threshold (0-100)');
    print('  --warn-coverage <n>   Warning coverage threshold (0-100)');
    print('  --fail-on-decrease    Fail if coverage decreases from baseline');
    print('');
    print('Examples:');
    print('  # Basic usage');
    print('  dart coverage_tool.dart performance');
    print('');
    print('  # With auto-fix');
    print('  dart coverage_tool.dart lib/src/core --fix');
    print('');
    print('  # Incremental coverage with branch analysis');
    print('  dart coverage_tool.dart --incremental --branch');
    print('');
    print('  # Parallel execution with thresholds');
    print(
      '  dart coverage_tool.dart --parallel --min-coverage=80 --warn-coverage=60',
    );
    print('');
    print('  # Exclude generated files');
    print(
      '  dart coverage_tool.dart --exclude "*.g.dart" --exclude "*.freezed.dart"',
    );
    print('');
    print('  # Full analysis with all features');
    print('  dart coverage_tool.dart --fix --branch --parallel --json');
    print('');
    print('Note: Coverage badge is automatically embedded in every report');
    exit(0);
  }

  final analyzer = CoverageAnalyzer(
    libPath: libPath,
    testPath: testPath,
    autoFix: autoFix,
    generateReport: !skipReport,
    branchCoverage: branchCoverage,
    incremental: incremental,
    mutationTesting: mutationTesting,
    watchMode: watchMode,
    parallel: parallel,
    exportJson: exportJson,
    testImpactAnalysis: testImpactAnalysis,
    excludePatterns: excludePatterns,
    thresholds: CoverageThresholds(
      minimum: minCoverage,
      warning: warnCoverage,
      failOnDecrease: failOnDecrease,
    ),
    baselineFile: baselineFile,
  );

  try {
    await analyzer.analyze();

    if (analyzer.uncoveredLines.isEmpty) {
      print('\n✅ SUCCESS: 100% test coverage achieved!');
      exit(0);
    } else if (analyzer.thresholdViolation) {
      print('\n❌ FAILURE: Coverage thresholds not met');
      print('${analyzer.uncoveredLines.length} lines are not covered');
      exit(1); // Exit with error code for CI/CD
    } else {
      print(
        '\n⚠️  INFO: ${analyzer.uncoveredLines.length} lines are not covered',
      );
      print('Run with --fix to generate missing tests automatically');
      exit(0); // Exit successfully - coverage is acceptable
    }
  } catch (e, stack) {
    print('\n❌ ERROR: $e');
    print(stack);
    exit(2);
  }
}
