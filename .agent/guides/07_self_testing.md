# SOP: Self-Testing Strategy

**Estimated Time**: 1 hour
**Token Budget**: 40-50K tokens
**Difficulty**: Medium
**🔴🟢♻️ TDD Integration**: Meta-testing is the 🔄 META-TEST phase of TDD

---

## Overview

test_reporter uses a **meta-testing** strategy where the test analysis tools test themselves. This is the final phase of our TDD workflow.

**Meta-Testing in TDD**:
- Part of the 🔄 META-TEST phase (after RED-GREEN-REFACTOR)
- Validates that changes work in real-world usage
- Tools test themselves (dogfooding)

See `.agent/knowledge/tdd_methodology.md` for how META-TEST fits into TDD cycle.

---

## Philosophy

**Dogfooding**: The best way to test testing tools is to use them on themselves.

**Benefits**:
- Real-world validation as part of TDD cycle
- Catches integration issues before commit
- Ensures tools work on complex codebases
- Builds confidence in the tools
- Completes the TDD workflow

---

## Running Self-Tests

### 1. Analyze the Analyzers

```bash
# Run test analyzer on its own code
dart run test_reporter:analyze_tests bin/ --runs=3

# Run coverage analyzer on itself
dart run test_reporter:analyze_coverage lib/src

# Run suite analyzer on everything
dart run test_reporter:analyze_suite bin/
```

### 2. Interpret Results

**Expected**:
- ✅ No consistent failures
- ✅ 0 flaky tests
- ✅ High reliability scores

**If failures occur**:
- Real bugs in the analyzers
- Edge cases not handled
- Performance issues

---

## Fixture Generation

### Creating Test Fixtures

**Purpose**: Generate consistent test cases for integration testing

**File**: `scripts/fixture_generator.dart`

```dart
import 'dart:io';

void main() async {
  print('Generating test fixtures...');

  await generatePassingTest();
  await generateFailingTest();
  await generateFlakyTest();
  await generateSlowTest();

  print('✅ Fixtures generated');
}

Future<void> generatePassingTest() async {
  final content = '''
import 'package:test/test.dart';

void main() {
  test('always passes', () {
    expect(1 + 1, equals(2));
  });
}
''';

  await File('test/fixtures/passing_test.dart').writeAsString(content);
}

Future<void> generateFailingTest() async {
  final content = '''
import 'package:test/test.dart';

void main() {
  test('always fails', () {
    expect(1 + 1, equals(3));
  });
}
''';

  await File('test/fixtures/failing_test.dart').writeAsString(content);
}

Future<void> generateFlakyTest() async {
  final content = '''
import 'dart:math';
import 'package:test/test.dart';

void main() {
  test('flaky test', () {
    final random = Random();
    final value = random.nextBool();
    expect(value, isTrue);  // 50% chance of failure
  });
}
''';

  await File('test/fixtures/flaky_test.dart').writeAsString(content);
}

Future<void> generateSlowTest() async {
  final content = '''
import 'package:test/test.dart';

void main() {
  test('slow test', () async {
    await Future.delayed(Duration(seconds: 2));
    expect(true, isTrue);
  });
}
''';

  await File('test/fixtures/slow_test.dart').writeAsString(content);
}
```

### Running Fixture Tests

```bash
# Generate fixtures
dart run scripts/fixture_generator.dart

# Test with fixtures
dart run test_reporter:analyze_tests test/fixtures/ --runs=5

# Should detect:
# - 1 consistent failure
# - 1 flaky test
# - 1 slow test
```

---

## Integration Test Generation

**File**: `scripts/generate_integration_tests.dart`

```dart
import 'dart:io';

void main() async {
  print('Generating integration tests...');

  final analyzers = [
    'analyze_tests',
    'analyze_coverage',
    'extract_failures',
    'analyze_suite',
  ];

  for (final analyzer in analyzers) {
    await generateIntegrationTest(analyzer);
  }

  print('✅ Integration tests generated');
}

Future<void> generateIntegrationTest(String analyzer) async {
  final content = '''
import 'dart:io';
import 'package:test/test.dart';

void main() {
  group('$analyzer integration tests', () {
    test('runs without errors', () async {
      final result = await Process.run(
        'dart',
        ['run', 'test_reporter:$analyzer', 'test/fixtures/', '--help'],
      );

      expect(result.exitCode, equals(0));
    });

    test('generates report', () async {
      final result = await Process.run(
        'dart',
        ['run', 'test_reporter:$analyzer', 'test/fixtures/'],
      );

      expect(result.exitCode, isIn([0, 1]));  // Success or failure, not error

      // Check report was generated
      final reportDir = Directory('tests_reports');
      expect(await reportDir.exists(), isTrue);
    });
  });
}
''';

  await File('test/integration/${analyzer}_integration_test.dart')
      .create(recursive: true)
      .then((f) => f.writeAsString(content));
}
```

---

## Validation Strategy

### 1. Baseline Testing

Create known-good baseline:

```bash
# Run analyzers and save results
dart run test_reporter:analyze_suite bin/ > baseline_output.txt

# Save reports
cp -r tests_reports tests_reports_baseline
```

### 2. Regression Detection

After changes:

```bash
# Run analyzers again
dart run test_reporter:analyze_suite bin/ > current_output.txt

# Compare
diff baseline_output.txt current_output.txt

# Compare reports
diff -r tests_reports_baseline tests_reports
```

### 3. Expected Behaviors

**analyze_tests on bin/**:
- Should find 0 tests (bin/ has no tests)
- Should complete without errors
- Should generate empty report

**analyze_coverage on lib/src**:
- Should show coverage percentage
- Should identify uncovered lines
- Should not crash

**analyze_suite on bin/**:
- Should run both tools
- Should generate unified report
- Should complete successfully

---

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Self-Test

on: [push, pull_request]

jobs:
  self-test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - uses: dart-lang/setup-dart@v1

      - name: Install dependencies
        run: dart pub get

      - name: Generate fixtures
        run: dart run scripts/fixture_generator.dart

      - name: Self-test analyzers
        run: dart run test_reporter:analyze_suite bin/

      - name: Verify reports generated
        run: |
          ls -la tests_reports/suite/
          test -f tests_reports/suite/bin-fo_suite@*.md

      - name: Run integration tests
        run: dart test
```

---

## Smoke Testing

Quick verification that tools work:

```bash
#!/bin/bash

echo "🔥 Running smoke tests..."

# Test 1: analyze_tests
echo "Testing analyze_tests..."
dart run test_reporter:analyze_tests test/ --runs=1 || exit 1

# Test 2: analyze_coverage
echo "Testing analyze_coverage..."
dart run test_reporter:analyze_coverage lib/src || exit 1

# Test 3: extract_failures
echo "Testing extract_failures..."
dart run test_reporter:extract_failures test/ --list-only || exit 1

# Test 4: analyze_suite
echo "Testing analyze_suite..."
dart run test_reporter:analyze_suite test/ || exit 1

echo "✅ All smoke tests passed!"
```

---

## Benchmarking

Track performance over time:

```bash
#!/bin/bash

echo "⏱️ Benchmarking analyzers..."

# Benchmark analyze_tests
time dart run test_reporter:analyze_tests bin/ --runs=3

# Benchmark analyze_coverage
time dart run test_reporter:analyze_coverage lib/src

# Save timing
echo "$(date): analyze_tests completed in X seconds" >> benchmark.log
```

---

## Checklist

Self-testing setup:

- [ ] Fixture generator script created
- [ ] Integration tests generated
- [ ] Baseline output saved
- [ ] Smoke test script created
- [ ] CI/CD workflow configured
- [ ] Benchmarking in place
- [ ] All analyzers self-test successfully

---

## Troubleshooting

**"No tests found"**:
- Fixtures not generated
- Wrong path specified
- Fixture directory missing

**"Reports not generated"**:
- Permissions issue
- Path incorrect
- Analyzer crashed before report generation

**"Integration tests fail"**:
- Tools not in PATH
- Dependencies not installed
- Fixtures missing

---

**Token usage**: ~40-45K tokens
**Next steps**: Add self-tests to pre-commit hooks
