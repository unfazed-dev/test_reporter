# Report System - test_reporter

**Last Updated**: November 2025
**Purpose**: Understanding report generation, naming, and management
**Token Estimate**: ~8-10K tokens

---

## Report Directory Structure

All reports are generated in the `tests_reports/` directory:

```
tests_reports/
├── tests/          # TestAnalyzer reports
│   ├── auth_service-fo_analysis@1435_041125.md
│   ├── auth_service-fo_analysis@1435_041125.json
│   └── user_test-fi_analysis@0920_041125.md
│
├── coverage/       # CoverageAnalyzer reports
│   ├── auth_service-fo_coverage@1230_041125.md
│   ├── auth_service-fo_coverage@1230_041125.json
│   └── utils-fo_coverage@1445_041125.md
│
├── failures/       # FailedTestExtractor reports
│   ├── integration-fo_failures@1000_041125.md
│   └── integration-fo_failures@1000_041125.json
│
└── suite/          # TestOrchestrator unified reports
    ├── all_tests-fo_suite@1500_041125.md
    └── all_tests-fo_suite@1500_041125.json
```

---

## Naming Convention

### Pattern

```
{module_name}_{report_type}@{timestamp}.{format}
```

**Components**:
- **module_name**: Extracted from test path with suffix
- **report_type**: Type of analysis (analysis, coverage, failures, suite)
- **timestamp**: `HHMM_DDMMYY` format
- **format**: `md` (markdown) or `json` (machine-readable)

### Module Name Extraction

**Rules**:
1. Extract last segment from path
2. Add suffix based on type:
   - `-fo` (folder): Analyzing a directory
   - `-fi` (file): Analyzing a specific file

**Examples**:

| Input Path | Module Name | Reasoning |
|------------|-------------|-----------|
| `test/` | `test-fo` | Root test folder |
| `test/integration/` | `integration-fo` | Integration folder |
| `test/unit/` | `unit-fo` | Unit tests folder |
| `test/my_test.dart` | `my_test-fi` | Specific test file |
| `test/auth/auth_service_test.dart` | `auth_service-fi` | Specific test file (strips `_test`) |

**Implementation** (from `TestOrchestrator.extractModuleName()`):

```dart
String extractModuleName() {
  final path = testPath
      .replaceAll(r'\', '/')
      .replaceAll(RegExp(r'/$'), '');

  final segments = path.split('/').where((s) => s.isNotEmpty).toList();

  if (segments.isEmpty) return 'all_tests-fo';

  var moduleName = segments.last;
  String suffix;

  // Determine if it's a file or folder
  if (moduleName.endsWith('.dart')) {
    // It's a file
    moduleName = moduleName.substring(0, moduleName.length - 5);

    // Remove _test suffix if present
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
```

### Timestamp Format

**Format**: `HHMM_DDMMYY`

- **HH**: Hour (24-hour format)
- **MM**: Minute
- **DD**: Day
- **MM**: Month
- **YY**: Year (2 digits)

**Example**: `1435_041125` = November 4, 2025 at 14:35

**Generation**:
```dart
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

## Report Formats

### Markdown Reports (*.md)

**Purpose**: Human-readable documentation

**Features**:
- Formatted tables
- Code blocks
- Emoji indicators (🟢 ✅ ❌ ⚠️)
- Section headers
- Lists and bullets
- Color-coded output (ANSI codes)

**Example Structure**:

```markdown
# Test Analysis Report - auth_service-fo

Generated: 2025-01-04 14:35:22

## 📊 Summary

- **Total Tests**: 42
- **Passed**: 38 ✅
- **Failed**: 4 ❌
- **Success Rate**: 90.5%

## 🔴 Consistent Failures

### test/auth/service_test.dart: "should validate token"

**Failure Type**: NullError

**Pattern**: Null reference on variable `authToken`

**Suggested Fix**:
- Add null check before accessing `authToken`
- Initialize `authToken` in setup
- Use null-aware operators (`?.`)

## ⚡ Flaky Tests

### test/auth/login_test.dart: "should login successfully"

**Reliability**: 66.7% (2/3 runs passed)

**Failures**: Run 2

**Suggested Fix**:
- Add delays for async operations
- Mock external dependencies
- Check for race conditions

## 📈 Performance Metrics

| Test | Average | Min | Max | Status |
|------|---------|-----|-----|--------|
| should validate token | 0.8s | 0.7s | 1.0s | 🟢 Normal |
| should login successfully | 2.3s | 2.1s | 2.5s | 🟠 Slow |

## 🎯 Actionable Insights

1. **Fix consistent failures first** - 4 tests always fail
2. **Address flaky tests** - 2 tests have intermittent failures
3. **Optimize slow tests** - 3 tests exceed 1.0s threshold
```

### JSON Reports (*.json)

**Purpose**: Machine-parseable for CI/CD integration

**Features**:
- Structured data
- Complete metrics
- Programmatic access
- CI/CD integration

**Example Structure**:

```json
{
  "meta": {
    "tool": "analyze_tests",
    "version": "2.0.0",
    "timestamp": "2025-01-04T14:35:22Z",
    "testPath": "test/auth",
    "moduleName": "auth_service-fo"
  },
  "summary": {
    "totalTests": 42,
    "passedTests": 38,
    "failedTests": 4,
    "skippedTests": 0,
    "successRate": 90.5,
    "totalDuration": "12.5s"
  },
  "consistentFailures": [
    {
      "testName": "should validate token",
      "testFile": "test/auth/service_test.dart",
      "failureType": "NullError",
      "errorMessage": "NoSuchMethodError: The getter 'token' was called on null",
      "failureCount": 3,
      "suggestion": "Add null check before accessing authToken"
    }
  ],
  "flakyTests": [
    {
      "testName": "should login successfully",
      "testFile": "test/auth/login_test.dart",
      "reliability": 66.7,
      "runsPass": 2,
      "runsTotal": 3,
      "failures": [
        {
          "run": 2,
          "error": "TimeoutException",
          "duration": "5.2s"
        }
      ]
    }
  ],
  "performance": {
    "slowTests": [
      {
        "testName": "should login successfully",
        "average": "2.3s",
        "min": "2.1s",
        "max": "2.5s"
      }
    ],
    "threshold": "1.0s"
  }
}
```

---

## ReportUtils API

**File**: `lib/src/utils/report_utils.dart`

### `getReportDirectory()`

Returns the path to the reports directory, creating it if needed.

```dart
static Future<String> getReportDirectory() async {
  final currentDir = Directory.current;
  final reportDir = Directory(p.join(currentDir.path, 'tests_reports'));

  if (!await reportDir.exists()) {
    await reportDir.create(recursive: true);
  }

  return reportDir.path;
}
```

**Usage**:
```dart
final reportDir = await ReportUtils.getReportDirectory();
// Returns: /path/to/project/tests_reports
```

### `cleanOldReports()`

Removes old reports for a specific path pattern, keeping only the latest.

```dart
static Future<void> cleanOldReports({
  required String pathName,           // e.g., "auth_service-fo"
  required List<String> prefixPatterns, // e.g., ["analysis", "coverage"]
  String? subdirectory,               // e.g., "tests" or null for all
  bool verbose = false,
  bool keepLatest = true,
}) async {
  final reportDir = await getReportDirectory();

  // Determine subdirectories to clean
  final subdirs = subdirectory != null
      ? [subdirectory]
      : ['tests', 'coverage', 'failures', 'suite'];

  for (final subdir in subdirs) {
    final dir = Directory(p.join(reportDir, subdir));
    if (!await dir.exists()) continue;

    // Group files by pattern
    final filesByPattern = <String, List<File>>{};

    await for (final file in dir.list()) {
      if (file is! File) continue;

      final fileName = file.path.split('/').last;

      for (final pattern in prefixPatterns) {
        // Match: {pathName}_{pattern}@ or {pathName}_{pattern}__
        final match1 = '${pathName}_$pattern@';
        final match2 = '${pathName.replaceAll('_', '')}_${pattern}__';

        if (fileName.startsWith(match1) || fileName.startsWith(match2)) {
          filesByPattern.putIfAbsent(pattern, () => []).add(file);
          break;
        }
      }
    }

    // For each pattern, keep the latest and delete the rest
    for (final entry in filesByPattern.entries) {
      final files = entry.value;
      if (files.isEmpty) continue;

      // Sort by filename (timestamp is in the filename)
      files.sort((a, b) => b.path.compareTo(a.path)); // Descending

      // Keep the latest (first after sort), delete the rest
      final filesToDelete = keepLatest ? files.skip(1) : files;

      for (final file in filesToDelete) {
        try {
          await file.delete();
          if (verbose) {
            print('  🗑️  Removed old report: ${file.path.split('/').last}');
          }
        } catch (e) {
          if (verbose) {
            print('  ⚠️  Failed to delete ${file.path.split('/').last}: $e');
          }
        }
      }
    }
  }
}
```

**Usage Example**:

```dart
// Before generating new reports
await ReportUtils.cleanOldReports(
  pathName: 'auth_service-fo',
  prefixPatterns: ['analysis', 'coverage'],
  subdirectory: 'tests',  // Only clean tests/ subdirectory
  verbose: true,          // Show deletion messages
  keepLatest: true,       // Keep the newest report
);

// Generates output like:
//   🗑️  Removed old report: auth_service-fo_analysis@1200_041125.md
//   🗑️  Removed old report: auth_service-fo_analysis@1200_041125.json
//   🗑️  Removed old report: auth_service-fo_coverage@1130_041125.md
```

---

## Report Generation Pattern

All analyzers follow this pattern:

### 1. Clean Old Reports

```dart
final moduleName = extractModuleName(testPath);

await ReportUtils.cleanOldReports(
  pathName: moduleName,
  prefixPatterns: ['analysis', 'coverage', 'failures', 'suite'],
  subdirectory: 'tests',  // or 'coverage', 'failures', 'suite'
  verbose: verbose,
);
```

### 2. Generate Report Content

```dart
final timestamp = generateTimestamp();
final markdown = generateMarkdownReport();
final json = generateJsonReport();
```

### 3. Write Reports

```dart
final reportDir = await ReportUtils.getReportDirectory();
final subdir = 'tests';  // or appropriate subdirectory

final mdPath = '$reportDir/$subdir/${moduleName}_analysis@$timestamp.md';
final jsonPath = '$reportDir/$subdir/${moduleName}_analysis@$timestamp.json';

await File(mdPath).writeAsString(markdown);
await File(jsonPath).writeAsString(json);

print('📝 Reports generated:');
print('   Markdown: $mdPath');
print('   JSON: $jsonPath');
```

---

## Subdirectory Organization

### tests/

**Contains**: TestAnalyzer reports
**Pattern**: `{module}_analysis@{timestamp}.{md|json}`

**Generated by**:
- `dart run test_reporter:analyze_tests`

### coverage/

**Contains**: CoverageAnalyzer reports
**Pattern**: `{module}_coverage@{timestamp}.{md|json}`

**Generated by**:
- `dart run test_reporter:analyze_coverage`

### failures/

**Contains**: FailedTestExtractor reports
**Pattern**: `{module}_failures@{timestamp}.{md|json}`

**Generated by**:
- `dart run test_reporter:extract_failures`

### suite/

**Contains**: TestOrchestrator unified reports
**Pattern**: `{module}_suite@{timestamp}.{md|json}`

**Generated by**:
- `dart run test_reporter:analyze_suite`

---

## Report Retention Strategy

### Default Behavior

- **Keep latest**: Only the most recent report per pattern is kept
- **Delete older**: All older reports for the same pattern are removed
- **Per subdirectory**: Cleanup happens within each subdirectory

### Why This Matters

Without cleanup:
```
tests_reports/tests/
├── auth_service-fo_analysis@1200_041125.md  (older)
├── auth_service-fo_analysis@1300_041125.md  (older)
├── auth_service-fo_analysis@1400_041125.md  (latest) ← KEPT
└── ... potentially hundreds of old reports
```

With cleanup:
```
tests_reports/tests/
└── auth_service-fo_analysis@1400_041125.md  (latest) ← KEPT
```

### Customizing Retention

You can modify `cleanOldReports()` to:

**Keep N latest reports**:
```dart
final filesToDelete = keepLatest ? files.skip(3) : files;  // Keep 3 latest
```

**Never delete**:
```dart
await ReportUtils.cleanOldReports(
  pathName: moduleName,
  prefixPatterns: [],  // Empty list = no cleanup
);
```

**Custom retention logic**:
```dart
// Delete reports older than 7 days
final cutoff = DateTime.now().subtract(Duration(days: 7));
final filesToDelete = files.where((f) {
  final timestamp = extractTimestampFromFilename(f.path);
  return timestamp.isBefore(cutoff);
});
```

---

## Report Content Guidelines

### Executive Summary Section

Every report should start with:
- Tool name and version
- Generation timestamp
- Test path analyzed
- High-level statistics

### Core Metrics Section

Include quantitative metrics:
- Pass/fail counts
- Success rates
- Performance timings
- Coverage percentages

### Detailed Findings Section

Break down by category:
- Consistent failures
- Flaky tests
- Performance issues
- Coverage gaps

### Actionable Insights Section

End with prioritized recommendations:
1. Critical issues (blocking)
2. Important issues (should fix)
3. Improvements (nice to have)

---

## Integration with CI/CD

### Using JSON Reports

```bash
# Run analysis
dart run test_reporter:analyze_suite test/

# Parse JSON in CI script
COVERAGE=$(jq '.summary.coverage' tests_reports/suite/test-fo_suite@*.json)
if (( $(echo "$COVERAGE < 80" | bc -l) )); then
  echo "Coverage $COVERAGE% below threshold 80%"
  exit 1
fi
```

### Exit Codes

All tools return:
- **0**: Success
- **1**: Failure (tests failed, coverage low, etc.)
- **2**: Error (crash, invalid args, etc.)

```bash
# Fail CI if tests fail or coverage is low
dart run test_reporter:analyze_suite || exit 1
```

---

## Token Usage Guidance

**Loading this file**: ~8-10K tokens

**Best used for**:
- Modifying report generation
- Understanding cleanup logic
- Adding new report formats
- Customizing report content

**Recommended pairings**:
- With `03_adding_report_type.md` SOP
- With `analyzer_architecture.md` for context
- With `report_format_template.md` template

---

## Common Report Operations

### Find latest report for a module

```bash
ls -t tests_reports/tests/auth_service-fo_* | head -1
```

### View report in terminal with colors

```bash
cat tests_reports/tests/auth_service-fo_analysis@1435_041125.md
```

### Parse JSON for specific metric

```bash
jq '.summary.successRate' tests_reports/tests/auth_service-fo_analysis@1435_041125.json
```

### Archive all reports

```bash
tar -czf reports-backup-$(date +%Y%m%d).tar.gz tests_reports/
```

### Clean all reports manually

```bash
rm -rf tests_reports/*
```

---

## Actionable Checklists

**Since**: v2.1.0 (November 2025)
**Feature**: Interactive GitHub-flavored markdown checklists in all reports

### Overview

All 4 analyzers generate actionable checklists using GitHub-flavored markdown:
- **Coverage Analyzer**: Checklist of files needing tests with line ranges
- **Test Analyzer**: 3-tier priority checklists (🔴 failing, 🟠 flaky, 🟡 slow)
- **Failure Extractor**: 3-step triage workflow per failing test
- **Suite Orchestrator**: Master workflow combining all action items

### CLI Flags

**Available on all 4 tools**:

| Flag | Description | Default |
|------|-------------|---------|
| `--no-checklist` | Disable checklist sections entirely | Checklists enabled |
| `--minimal-checklist` | Generate compact checklist format | Full detailed format |

**Examples**:

```bash
# Default: Full detailed checklists
dart run test_reporter:analyze_coverage lib/src

# Disable checklists entirely
dart run test_reporter:analyze_tests test/ --no-checklist

# Minimal compact checklists
dart run test_reporter:extract_failures test/ --minimal-checklist

# Suite orchestrator with minimal checklists
dart run test_reporter:analyze_suite test/ --minimal-checklist
```

### Checklist Format

**Full Mode** (default):
- Detailed sub-items with steps
- Tips and suggestions
- Verification commands
- Progress tracking

**Minimal Mode** (`--minimal-checklist`):
- Compact single-line items
- File grouping
- Quick command section only
- No sub-items or tips

**Example - Coverage Report Checklist** (full mode):

```markdown
## ✅ Coverage Action Items

### `auth_service.dart`

- [ ] Add tests for lines 45-67 (authenticate method)
  - [ ] Open `test/unit/services/auth_service_test.dart`
  - [ ] Write test cases covering the logic
  - [ ] Run: `dart test test/unit/services/auth_service_test.dart`
  - 💡 Tip: Focus on edge cases and error conditions

### 🚀 Quick Commands

\`\`\`bash
# Run all tests
dart test

# Run tests with coverage
dart test --coverage=coverage

# Generate coverage report
dart run test_reporter:analyze_coverage lib/src
\`\`\`

### 📊 Progress Tracking

- [ ] **0 of 3** test groups complete
- [ ] Mark items above as you complete them to track progress
```

**Example - Test Reliability Checklist** (full mode):

```markdown
## ✅ Test Reliability Action Items

### 🔴 Priority 1: Fix Failing Tests

- [ ] Fix: `authenticates user with valid credentials`
  - File: `test/unit/auth/auth_service_test.dart`
  - Failure Type: Null Error
  - 💡 Fix: Check for null before accessing properties
  - Verify: `dart test test/unit/auth/auth_service_test.dart --name="authenticates user"`

**Progress: 0 of 2 failing tests fixed**

### 🟠 Priority 2: Stabilize Flaky Tests

- [ ] Stabilize: `loads user profile` (66.7% reliable)
  - File: `test/integration/profile_test.dart`
  - Common causes:
    - [ ] Race conditions or timing issues
    - [ ] Shared mutable state between tests
    - [ ] External dependencies (network, file system)
    - [ ] Improper async/await handling
  - Verify stability: `for i in {1..10}; do dart test ... || break; done`

**Progress: 0 of 1 flaky tests stabilized**

### 🚀 Quick Commands

\`\`\`bash
# Run all tests multiple times to verify fixes
dart test --runs=3

# Run specific test file
dart test test/unit/auth/auth_service_test.dart
\`\`\`
```

**Example - Failure Triage Checklist** (full mode):

```markdown
## ✅ Failure Triage Workflow

### File: `test/integration/auth_test.dart`

- [ ] **Fix: login with valid credentials**
  - [ ] **Step 1: Identify root cause**
    - Error: `NoSuchMethodError: The getter 'token' was called on null`
  - [ ] **Step 2: Apply fix**
    - Modify test or implementation code
  - [ ] **Step 3: Verify fix**
    - Run: `dart test test/integration/auth_test.dart --name="login with valid credentials"`

**Progress:** 0 of 4 failures triaged (0.0%)

### 🚀 Quick Commands

\`\`\`bash
# Rerun all failed tests
dart test test/integration/auth_test.dart
dart test test/unit/services/user_test.dart
\`\`\`
```

**Example - Master Workflow Checklist** (full mode):

```markdown
## ✅ Recommended Workflow

Follow this 3-phase approach to improve your test suite:

### 🔴 Phase 1: Critical Issues

- [ ] Fix 2 failing tests
  - 💡 Tip: These tests fail consistently. Priority: High
  - Command: `dart test --name="<test_name>"`

- [ ] Increase test coverage by 12.3%
  - 💡 Tip: Current: 67.7%, Target: 80%
  - Command: `dart run test_reporter:analyze_coverage lib/src --fix`

**Progress:** 0 of 2 critical issues resolved

### 🟠 Phase 2: Stability

- [ ] Stabilize 1 flaky test
  - 💡 Tip: These tests pass sometimes and fail other times
  - Command: `dart run test_reporter:analyze_tests test/ --runs=10`

**Progress:** 0 of 1 stability issues resolved

### 🟡 Phase 3: Optimization

- [ ] Optimize 3 slow tests
  - 💡 Tip: These tests exceed 1.0s threshold
  - Command: `dart test --name="<test_name>"`

**Progress:** 0 of 3 optimization tasks complete
```

### Implementation Details

**Checklist Utilities** (`lib/src/utils/checklist_utils.dart`):

```dart
// Core classes for checklist generation
class ChecklistItem {
  final String text;
  final List<ChecklistItem> subItems;
  final String? tip;
  final String? command;

  String toMarkdown();
}

enum ChecklistPriority { critical, important, optional }

class ChecklistSection {
  final String title;
  final String? subtitle;
  final List<ChecklistItem> items;
  final ChecklistPriority priority;

  String toMarkdown();
}

// Helper functions
String formatLineRangeDescription(String filePath, List<int> lines);
String suggestTestFile(String sourcePath);
List<TestCase> groupLinesIntoTestCases(String filePath, List<int> lines);
```

### Best Practices

1. **Interactive Tracking**: Check off items as you complete them in VS Code or GitHub
2. **Progress Monitoring**: Update progress counters to track completion
3. **Command Execution**: Copy-paste commands directly from checklists
4. **Priority Order**: Follow the priority indicators (🔴 → 🟠 → 🟡)
5. **Minimal Mode**: Use `--minimal-checklist` for quick overviews or CI/CD

### GitHub Integration

Checklists work seamlessly with GitHub:
- ✅ Interactive checkboxes in PR descriptions
- ✅ Clickable checkboxes in issues
- ✅ Copy-paste directly from reports
- ✅ Track completion percentage visually

**Example workflow**:
1. Run analyzer: `dart run test_reporter:analyze_suite test/`
2. Open report: `tests_reports/suite/all-fo_suite@1435_041125.md`
3. Copy checklist section
4. Paste into GitHub issue or PR description
5. Team members check off items as they complete tasks

---

This report system enables:
- ✅ Consistent naming across all tools
- ✅ Automatic cleanup of old reports
- ✅ Both human and machine-readable formats
- ✅ Organized subdirectory structure
- ✅ Interactive actionable checklists (v2.1.0+)
- ✅ CI/CD integration readiness
