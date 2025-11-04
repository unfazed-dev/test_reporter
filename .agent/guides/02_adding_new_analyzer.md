# SOP: Adding New Analyzer

**Estimated Time**: 3-4 hours
**Token Budget**: 120-150K tokens
**Difficulty**: Hard
**🔴🟢♻️ TDD**: MANDATORY - Follow red-green-refactor cycle

---

## Prerequisites

- [ ] Read `../knowledge/analyzer_architecture.md`
- [ ] Read `../knowledge/report_system.md`
- [ ] Read `../knowledge/tdd_methodology.md` (red-green-refactor cycle)
- [ ] Understand the analysis you want to perform
- [ ] Have a clear use case for the new analyzer

---

## Overview

This SOP guides you through creating a new CLI analyzer tool from scratch using **Test-Driven Development (TDD)**.

**Example**: Adding `analyze_dependencies` to analyze test dependency graphs

**TDD Workflow**:
1. 🔴 **RED**: Write failing integration test for analyzer
2. 🟢 **GREEN**: Implement analyzer minimally to pass test
3. ♻️ **REFACTOR**: Add features, clean code, keep tests green
4. 🔄 **META-TEST**: Run analyzer on itself

**CRITICAL**: Start with Step 0 (RED Phase) - write integration test FIRST!

---

## Step 0: 🔴 RED Phase - Write Failing Integration Test

### 0.1 Create Integration Test

**File**: `test/integration/analyzers/dependency_analyzer_test.dart`

```dart
import 'package:test/test.dart';
import 'package:test_reporter/src/bin/analyze_dependencies_lib.dart';

void main() {
  group('DependencyAnalyzer', () {
    test('should analyze test dependencies', () async {
      final analyzer = DependencyAnalyzer(targetPath: 'test/fixtures');
      final exitCode = await analyzer.run();

      // This will FAIL - DependencyAnalyzer doesn't exist yet!
      expect(exitCode, equals(0));
      expect(analyzer.results, isNotEmpty);
    });
  });
}
```

### 0.2 Run Test to Confirm RED

```bash
# Run test - it MUST fail
dart test test/integration/analyzers/dependency_analyzer_test.dart

# Expected: ❌ Class 'DependencyAnalyzer' isn't defined
```

**🚨 STOP**: If test doesn't fail, do NOT proceed!

---

## Step 1: 🟢 GREEN Phase - Create Entry Point

**File**: `bin/analyze_dependencies.dart`

```dart
#!/usr/bin/env dart

/// # Dependency Analyzer - Entry Point
///
/// Command-line entry point for the Dependency Analysis Tool.
/// All business logic is in lib/src/bin/analyze_dependencies_lib.dart

import 'package:test_reporter/src/bin/analyze_dependencies_lib.dart'
    as analyzer_lib;

void main(List<String> args) {
  analyzer_lib.main(args);
}
```

**Key points**:
- Minimal entry point (10-15 lines)
- Delegates to library implementation
- Includes shebang for direct execution
- Clear documentation comment

---

## Step 2: Create Implementation File

**File**: `lib/src/bin/analyze_dependencies_lib.dart`

Use the template from `.agent/templates/analyzer_template.dart` as a starting point.

### 2.1 Define Main Class

```dart
import 'dart:async';
import 'dart:io';
import 'package:args/args.dart';
import 'package:test_reporter/src/utils/report_utils.dart';

class DependencyAnalyzer {
  DependencyAnalyzer({
    required this.testPath,
    this.verbose = false,
    this.includeExternal = false,
    this.detectCircular = true,
  });

  final String testPath;
  final bool verbose;
  final bool includeExternal;
  final bool detectCircular;

  // Analysis results
  final Map<String, List<String>> dependencies = {};
  final List<List<String>> circularDeps = [];

  Future<int> run() async {
    try {
      await analyze();
      await generateReport();
      return 0;  // Success
    } catch (e) {
      print('❌ Analysis failed: $e');
      return 2;  // Error
    }
  }

  Future<void> analyze() async {
    // Implementation
  }

  Future<void> generateReport() async {
    // Implementation
  }
}
```

### 2.2 Implement CLI Argument Parsing

```dart
void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      'path',
      abbr: 'p',
      help: 'Test path to analyze',
      defaultsTo: 'test',
    )
    ..addFlag(
      'verbose',
      abbr: 'v',
      help: 'Verbose output',
      negatable: false,
    )
    ..addFlag(
      'include-external',
      help: 'Include external dependencies',
      negatable: false,
    )
    ..addFlag(
      'detect-circular',
      help: 'Detect circular dependencies',
      defaultsTo: true,
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
    print('Dependency Analyzer - Analyze test dependency graphs');
    print('\nUsage: dart analyze_dependencies.dart [options]\n');
    print(parser.usage);
    exit(0);
  }

  final analyzer = DependencyAnalyzer(
    testPath: args['path'] as String,
    verbose: args['verbose'] as bool,
    includeExternal: args['include-external'] as bool,
    detectCircular: args['detect-circular'] as bool,
  );

  final exitCode = await analyzer.run();
  exit(exitCode);
}
```

### 2.3 Implement Core Analysis Logic

```dart
Future<void> analyze() async {
  print('🔍 Analyzing dependencies in $testPath...');

  final testFiles = await findTestFiles(testPath);

  for (final file in testFiles) {
    final deps = await extractDependencies(file);
    dependencies[file] = deps;

    if (verbose) {
      print('  📄 $file: ${deps.length} dependencies');
    }
  }

  if (detectCircular) {
    circularDeps.addAll(findCircularDependencies());

    if (circularDeps.isNotEmpty) {
      print('⚠️  Found ${circularDeps.length} circular dependencies');
    }
  }
}

Future<List<String>> findTestFiles(String path) async {
  final dir = Directory(path);
  final files = <String>[];

  await for (final entity in dir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('_test.dart')) {
      files.add(entity.path);
    }
  }

  return files;
}

Future<List<String>> extractDependencies(String filePath) async {
  final file = File(filePath);
  final content = await file.readAsString();

  final imports = <String>[];
  final importPattern = RegExp(r"import\s+'(.+?)'");

  for (final match in importPattern.allMatches(content)) {
    final import = match.group(1)!;

    if (includeExternal || import.startsWith('package:test_reporter/')) {
      imports.add(import);
    }
  }

  return imports;
}

List<List<String>> findCircularDependencies() {
  // Implement cycle detection algorithm
  final cycles = <List<String>>[];

  // TODO: Implement graph cycle detection
  // Use DFS or Tarjan's algorithm

  return cycles;
}
```

### 2.4 Implement Report Generation

```dart
Future<void> generateReport() async {
  final moduleName = extractModuleName(testPath);
  final timestamp = generateTimestamp();

  // Clean old reports
  await ReportUtils.cleanOldReports(
    pathName: moduleName,
    prefixPatterns: ['dependencies'],
    subdirectory: 'dependencies',
    verbose: verbose,
  );

  // Generate markdown report
  final markdown = generateMarkdownReport();
  final json = generateJsonReport();

  // Save reports
  final reportDir = await ReportUtils.getReportDirectory();
  final depsDir = Directory('$reportDir/dependencies');
  if (!await depsDir.exists()) {
    await depsDir.create(recursive: true);
  }

  final mdPath = '$reportDir/dependencies/${moduleName}_dependencies@$timestamp.md';
  final jsonPath = '$reportDir/dependencies/${moduleName}_dependencies@$timestamp.json';

  await File(mdPath).writeAsString(markdown);
  await File(jsonPath).writeAsString(json);

  print('\n📝 Reports generated:');
  print('   Markdown: $mdPath');
  print('   JSON: $jsonPath');
}

String generateMarkdownReport() {
  final buffer = StringBuffer();

  buffer.writeln('# Dependency Analysis Report - $testPath');
  buffer.writeln();
  buffer.writeln('Generated: ${DateTime.now()}');
  buffer.writeln();

  buffer.writeln('## 📊 Summary');
  buffer.writeln();
  buffer.writeln('- **Total Test Files**: ${dependencies.length}');
  buffer.writeln('- **Total Dependencies**: ${dependencies.values.fold(0, (sum, deps) => sum + deps.length)}');
  buffer.writeln('- **Circular Dependencies**: ${circularDeps.length}');
  buffer.writeln();

  if (circularDeps.isNotEmpty) {
    buffer.writeln('## ⚠️ Circular Dependencies');
    buffer.writeln();

    for (final cycle in circularDeps) {
      buffer.writeln('- ${cycle.join(' → ')}');
    }

    buffer.writeln();
  }

  buffer.writeln('## 📦 Dependencies by File');
  buffer.writeln();

  for (final entry in dependencies.entries) {
    buffer.writeln('### ${entry.key}');
    buffer.writeln();

    if (entry.value.isEmpty) {
      buffer.writeln('No dependencies');
    } else {
      for (final dep in entry.value) {
        buffer.writeln('- `$dep`');
      }
    }

    buffer.writeln();
  }

  return buffer.toString();
}

String generateJsonReport() {
  return jsonEncode({
    'meta': {
      'tool': 'analyze_dependencies',
      'version': '2.0.0',
      'timestamp': DateTime.now().toIso8601String(),
      'testPath': testPath,
    },
    'summary': {
      'totalFiles': dependencies.length,
      'totalDependencies': dependencies.values.fold(0, (sum, deps) => sum + deps.length),
      'circularDependencies': circularDeps.length,
    },
    'circularDeps': circularDeps,
    'dependencies': dependencies,
  });
}

String extractModuleName(String path) {
  // Same logic as TestOrchestrator
  final normalized = path.replaceAll(r'\', '/').replaceAll(RegExp(r'/$'), '');
  final segments = normalized.split('/').where((s) => s.isNotEmpty).toList();

  if (segments.isEmpty) return 'all_tests-fo';

  var moduleName = segments.last;

  if (moduleName.endsWith('.dart')) {
    moduleName = moduleName.substring(0, moduleName.length - 5);
    if (moduleName.endsWith('_test')) {
      moduleName = moduleName.substring(0, moduleName.length - 5);
    }
    return '$moduleName-fi';
  }

  return '${moduleName}-fo';
}

String generateTimestamp() {
  final now = DateTime.now();
  final hour = now.hour.toString().padLeft(2, '0');
  final minute = now.minute.toString().padLeft(2, '0');
  final day = now.day.toString().padLeft(2, '0');
  final month = now.month.toString().padLeft(2, '0');
  final year = now.year.toString().substring(2);

  return '${hour}${minute}_$day$month$year';
}
```

---

## Step 3: Register Executable in pubspec.yaml

**File**: `pubspec.yaml`

Add your new executable to the executables section:

```yaml
executables:
  analyze_coverage:
  analyze_tests:
  extract_failures:
  analyze_suite:
  analyze_dependencies:    # ← NEW
```

---

## Step 4: Export from Library

**File**: `lib/test_reporter.dart`

Export your analyzer so it can be imported:

```dart
/// Comprehensive Flutter/Dart test reporting toolkit
library test_reporter;

// Export modern models with sealed classes and records
export 'src/models/failure_types.dart';
export 'src/models/result_types.dart';

// Export utilities
export 'src/utils/constants.dart';
export 'src/utils/extensions.dart';
export 'src/utils/formatting_utils.dart';
export 'src/utils/path_utils.dart';
export 'src/utils/report_utils.dart';

// Export analyzers (NEW)
export 'src/bin/analyze_dependencies_lib.dart';  // ← NEW
```

---

## Step 5: Create Report Subdirectory

**File**: `.gitignore`

Ensure the new report directory is ignored:

```
# Reports (generated)
reports/
tests_reports/     # ← Already there
```

The directory will be created automatically by `ReportUtils.getReportDirectory()`.

---

## Step 6: Test the Analyzer

### 6.1 Run Locally

```bash
# Install dependencies
dart pub get

# Test the analyzer
dart bin/analyze_dependencies.dart --help
dart bin/analyze_dependencies.dart test/ --verbose
```

### 6.2 Check Reports

```bash
# View generated report
cat tests_reports/dependencies/test-fo_dependencies@*.md

# Check JSON
cat tests_reports/dependencies/test-fo_dependencies@*.json | jq .
```

### 6.3 Test as Executable

```bash
# Activate globally
dart pub global activate --source path .

# Run as command
analyze_dependencies test/ --verbose
```

---

## Step 7: Update Documentation

### 7.1 Update README.md

Add your analyzer to the features and usage sections:

```markdown
### 🔗 Dependency Analyzer (`analyze_dependencies`)
- **Dependency Graph** - Visualize test dependencies
- **Circular Detection** - Find circular dependencies
- **Import Analysis** - Track external dependencies
- **Dependency Metrics** - Measure coupling

## Quick Start

\`\`\`bash
# Analyze dependencies
dart run test_reporter:analyze_dependencies test/
\`\`\`
```

### 7.2 Update CLAUDE.md

Add to the tools list:

```markdown
## Development Commands

### Running Tools (Development)

\`\`\`bash
dart bin/analyze_dependencies.dart --help
\`\`\`
```

### 7.3 Update .agent/README.md

Add to the contexts or prompts as needed.

---

## Step 8: Commit Changes

```bash
# Run quality checks
dart analyze
dart format .

# Test the new analyzer
dart run test_reporter:analyze_dependencies bin/

# Commit
git add bin/analyze_dependencies.dart
git add lib/src/bin/analyze_dependencies_lib.dart
git add lib/test_reporter.dart
git add pubspec.yaml
git add README.md
git add CLAUDE.md

git commit -m "feat: add dependency analyzer tool"
```

---

## Checklist

- [ ] Entry point created in `bin/`
- [ ] Implementation created in `lib/src/bin/`
- [ ] Main analyzer class with core logic
- [ ] CLI argument parsing
- [ ] Report generation (markdown + JSON)
- [ ] Executable registered in `pubspec.yaml`
- [ ] Exported from `lib/test_reporter.dart`
- [ ] Tested locally
- [ ] Documentation updated
- [ ] Code analyzed and formatted
- [ ] Changes committed

---

## Common Patterns

### Exit Codes
- **0**: Success
- **1**: Analysis found issues (optional)
- **2**: Error occurred

### Progress Indicators
```dart
print('🔍 Analyzing...');
print('✅ Complete');
print('❌ Failed');
print('⚠️ Warning');
```

### Report Cleanup
Always clean old reports:
```dart
await ReportUtils.cleanOldReports(
  pathName: moduleName,
  prefixPatterns: ['your_report_type'],
  subdirectory: 'your_subdir',
);
```

---

**Token usage for this SOP**: ~120-140K tokens (including templates and context)

**Next steps**: Integrate with `analyze_suite` orchestrator if needed
