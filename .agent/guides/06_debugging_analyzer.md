# SOP: Debugging Analyzer

**Estimated Time**: Variable
**Token Budget**: 40-80K tokens
**Difficulty**: Medium
**🔴🟢♻️ TDD Note**: When fixing bugs, write failing test first!

---

## Overview

Strategies and techniques for debugging analyzer tools when they fail or produce incorrect results.

**TDD for Bug Fixes**:
1. 🔴 Write test that reproduces the bug (test should fail)
2. 🟢 Fix the bug (test should pass)
3. ♻️ Refactor if needed (test stays green)

See `.agent/knowledge/tdd_methodology.md` for bug fix TDD workflow.

---

## Common Issues

### 1. Analyzer Crashes

**Symptoms**:
- Exit code 2 (error)
- Stack trace printed
- Incomplete reports

**Debug steps**:

```bash
# Run with verbose output
dart run test_reporter:analyze_tests test/ --verbose

# Add try-catch debugging
try {
  await analyze();
} catch (e, stackTrace) {
  print('ERROR: $e');
  print('Stack trace:\n$stackTrace');
  rethrow;
}
```

### 2. Incorrect Pattern Detection

**Symptoms**:
- Failures classified as `UnknownFailure`
- Wrong failure type detected
- Missing data in failure objects

**Debug steps**:

```dart
// Add debug logging in detectFailureType()
FailureType detectFailureType(String output) {
  print('=== DETECTING FAILURE ===');
  print(output);
  print('========================');

  if (output.contains('Expected:')) {
    print('✅ Matched: AssertionFailure');
    return AssertionFailure(...);
  }

  print('⚠️ No pattern matched, returning UnknownFailure');
  return UnknownFailure(rawOutput: output);
}
```

**Test regex**:
```dart
final pattern = RegExp(r"Tried calling: (\w+)");
final output = "NoSuchMethodError: Tried calling: token";

print('Pattern matches: ${pattern.hasMatch(output)}');
print('Match: ${pattern.firstMatch(output)?.group(1)}');
```

### 3. Report Not Generated

**Symptoms**:
- No files in `tests_reports/`
- "Report generated" message but file missing

**Debug steps**:

```bash
# Check directory creation
ls -la tests_reports/

# Check permissions
ls -la tests_reports/tests/

# Run with verbose
dart run test_reporter:analyze_tests test/ --verbose
```

```dart
// Add debug logging
print('Report directory: $reportDir');
print('Report path: $reportPath');
print('File exists before write: ${await File(reportPath).exists()}');

await File(reportPath).writeAsString(content);

print('File exists after write: ${await File(reportPath).exists()}');
print('File size: ${await File(reportPath).length()} bytes');
```

### 4. Cleanup Deletes Wrong Files

**Symptoms**:
- Important reports deleted
- Wrong files kept

**Debug steps**:

```dart
await ReportUtils.cleanOldReports(
  pathName: moduleName,
  prefixPatterns: ['analysis'],
  subdirectory: 'tests',
  verbose: true,  // ← Enable verbose logging
);
```

Review output:
```
🔎 Checking file: auth_service-fo_analysis@1200_041125.md in tests
  Looking for: auth_service-fo_analysis@ OR authservicefo_analysis__
  ✅ MATCHED pattern: analysis
🗑️  Removed old report: auth_service-fo_analysis@1200_041125.md
```

### 5. Tests Not Found

**Symptoms**:
- "0 tests found"
- "No test files to analyze"

**Debug steps**:

```dart
// Add logging to file discovery
Future<List<String>> findTestFiles(String path) async {
  print('Searching for tests in: $path');

  final dir = Directory(path);
  print('Directory exists: ${await dir.exists()}');

  final files = <String>[];

  await for (final entity in dir.list(recursive: true)) {
    print('Found: ${entity.path}');

    if (entity is File && entity.path.endsWith('_test.dart')) {
      print('  ✅ Is test file');
      files.add(entity.path);
    }
  }

  print('Total test files: ${files.length}');
  return files;
}
```

---

## Debugging Tools

### 1. Dart DevTools

```bash
# Run with observatory
dart --observe bin/analyze_tests.dart test/

# Open DevTools in browser (URL printed)
```

### 2. Print Debugging

```dart
// Structured logging
void debug(String message, {Object? data}) {
  final timestamp = DateTime.now().toIso8601String();
  print('[$timestamp] DEBUG: $message');
  if (data != null) {
    print('  Data: $data');
  }
}

// Usage
debug('Starting analysis', data: {'path': testPath, 'runs': runCount});
```

### 3. Conditional Debugging

```dart
class TestAnalyzer {
  final bool debug;

  void log(String message) {
    if (debug) print('[DEBUG] $message');
  }
}

// Usage
final analyzer = TestAnalyzer(debug: true);
analyzer.log('Test run completed');
```

---

## Testing Strategies

### 1. Isolated Component Testing

```dart
// Test individual components
void main() {
  final output = '''
NoSuchMethodError: The getter 'token' was called on null.
Receiver: null
Tried calling: token
''';

  final failure = detectFailureType(output);

  print('Type: ${failure.runtimeType}');
  print('Category: ${failure.category}');

  if (failure is NullError) {
    print('Variable: ${failure.variableName}');
  }
}
```

### 2. End-to-End Testing

```bash
# Create minimal test case
echo 'import "package:test/test.dart";
void main() {
  test("fails", () {
    expect(1, equals(2));
  });
}' > test/debug_test.dart

# Run analyzer on it
dart run test_reporter:analyze_tests test/debug_test.dart --verbose

# Check output
cat tests_reports/tests/debug_test-fi_analysis@*.md
```

### 3. Regression Testing

```bash
# Save known-good output
dart run test_reporter:analyze_tests test/ > expected_output.txt

# After changes, compare
dart run test_reporter:analyze_tests test/ > actual_output.txt
diff expected_output.txt actual_output.txt
```

---

## Performance Debugging

### 1. Slow Analysis

```dart
Future<void> analyze() async {
  final stopwatch = Stopwatch()..start();

  print('Starting analysis...');

  final finding = Stopwatch()..start();
  final files = await findTestFiles(testPath);
  finding.stop();
  print('Finding files took: ${finding.elapsedMilliseconds}ms');

  final running = Stopwatch()..start();
  await runTests(files);
  running.stop();
  print('Running tests took: ${running.elapsedMilliseconds}ms');

  stopwatch.stop();
  print('Total analysis took: ${stopwatch.elapsedMilliseconds}ms');
}
```

### 2. Memory Usage

```bash
# Monitor memory during execution
dart --observe bin/analyze_tests.dart test/

# Check in DevTools → Memory tab
```

---

## Common Fixes

### Fix 1: Escape Special Regex Characters

```dart
// ❌ Wrong - . matches any character
final pattern = RegExp(r'test.dart');

// ✅ Correct - \. matches literal dot
final pattern = RegExp(r'test\.dart');
```

### Fix 2: Handle Missing Matches

```dart
// ❌ Wrong - can throw if no match
final match = pattern.firstMatch(output);
final value = match.group(1)!;  // ← Might be null!

// ✅ Correct - safe handling
final match = pattern.firstMatch(output);
final value = match?.group(1) ?? 'default';
```

### Fix 3: Path Normalization

```dart
// ❌ Wrong - platform-specific separators
final testPath = 'test\\integration';

// ✅ Correct - normalized paths
final testPath = 'test/integration'.replaceAll(r'\', '/');
```

---

## Checklist

When debugging:

- [ ] Enable verbose output (`--verbose`)
- [ ] Add print statements at key points
- [ ] Test with minimal example
- [ ] Check file permissions
- [ ] Verify regex patterns
- [ ] Review error messages carefully
- [ ] Check for null values
- [ ] Validate input paths
- [ ] Test cleanup logic separately
- [ ] Compare with known-good output

---

**Token usage**: ~40-60K tokens
**Next steps**: Document the bug and fix in CHANGELOG
