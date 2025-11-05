# Test Reporter v3.0 Re-engineering Plan

**Status**: In Progress
**Created**: 2025-11-04
**Author**: Claude (dart-dev agent)
**Estimated Effort**: 16-21 hours over 2-3 weeks

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Current State Analysis](#current-state-analysis)
3. [Research Findings](#research-findings)
4. [Architecture Design](#architecture-design)
5. [Implementation Plan](#implementation-plan)
6. [Success Criteria](#success-criteria)
7. [Risk Assessment](#risk-assessment)

---

## Executive Summary

### Objective

Re-architect test_reporter from the ground up to provide:
- **Automatic path detection**: Tools intelligently map between test/ and lib/ directories
- **Unified report management**: Single source of truth for all report operations
- **Consistent naming**: One module identification system across all tools
- **Zero manual cleanup**: Lifecycle managed by framework, not individual tools

### Approach

**Clean slate re-engineering** - not incremental bug fixes. The current implementation has architectural flaws that cannot be fixed with patches. We need to rebuild the foundation with proper abstractions.

### Key Changes

| Before (v2.x) | After (v3.0) |
|---------------|--------------|
| Manual path specification | Automatic path inference |
| 3 different module extractors | 1 centralized ModuleIdentifier |
| Distributed cleanup logic | Unified ReportManager |
| Report naming: `module_report_type@time` | New: `module_tool_type@YYYYMMDD-HHMM` |
| Manual file deletion in orchestrator | Atomic lifecycle management |

### Breaking Changes

✅ Report naming format changes (sortable, includes tool name)
✅ CLI arguments simplified (coverage no longer requires 2 paths)
✅ API changes to ReportUtils (replaced by ReportManager)

---

## Current State Analysis

### Architectural Problems Identified

#### 1. No Centralized Path Management

**Problem**: Path correlation logic duplicated across 3 files

**Evidence**:
- `analyze_tests_lib.dart` (lines 2361-2396): `_extractPathName()` from test path
- `analyze_coverage_lib.dart` (lines 1743-1776): `_extractPathName()` from test path (should use source!)
- `analyze_suite_lib.dart` (lines 66-90): `extractModuleName()` identical logic

**Impact**:
- Code duplication ~100 lines total
- Inconsistencies if one implementation diverges
- No shared validation or edge case handling

#### 2. Inconsistent Module Naming

**Problem**: Each tool independently extracts module names

**Evidence**:
```dart
// analyze_coverage uses TEST path name (BUG!)
final pathName = _extractPathName(); // From testPath, not libPath

// analyze_tests uses TEST path name (correct)
final pathName = _extractPathName(); // From targetFiles (test paths)

// analyze_suite uses TEST path name
final moduleName = extractModuleName(); // From testPath parameter
```

**Impact**:
- Coverage reports named after test paths, not source paths
- Module name must match exactly for cleanup to work
- No guarantee tools agree on naming

#### 3. Distributed Report Cleanup

**Problem**: Three different cleanup strategies

**Evidence**:

```dart
// analyze_coverage: Cleans AFTER writing
await ReportUtils.writeUnifiedReport(...);
await ReportUtils.cleanOldReports(
  pathName: pathName,
  prefixPatterns: ['report_coverage'],
  subdirectory: 'quality',
);

// analyze_tests: Cleans in separate method
await _cleanupOldReports(pathName);
// Which calls cleanOldReports twice (tests + failures)

// analyze_suite: Manual deletion + cleanup
if (reportPaths.containsKey('coverage')) {
  await File(reportPaths['coverage']!).delete();  // Manual!
}
await ReportUtils.cleanOldReports(...);
```

**Impact**:
- Timing issues (when to clean?)
- Race conditions possible
- Manual file operations error-prone
- Orphaned files if cleanup skipped

#### 4. No Automatic Path Detection

**Problem**: Users must know internal structure

**Current UX**:
```bash
# Coverage requires BOTH paths
dart run test_reporter:analyze_coverage lib/src/auth test/auth

# Tests only needs test path
dart run test_reporter:analyze_tests test/auth

# Suite only needs test path (but derives source internally)
dart run test_reporter:analyze_suite test/auth
```

**Evidence**: `analyze_suite_lib.dart` has path detection (lines 100-156) but it's not exposed to individual tools

**Impact**:
- Confusing UX - why does coverage need 2 paths?
- Hidden capability - suite knows how to derive, tools don't
- Error-prone - users forget second path

#### 5. Fragile Orchestration

**Problem**: Suite analyzer manually orchestrates lifecycle

**Evidence** (lines 689-761):
```dart
// Generate unified report
await ReportUtils.writeUnifiedReport(...);

// Manually delete intermediate reports
if (reportPaths.containsKey('coverage')) {
  final coverageFile = File(reportPaths['coverage']!);
  if (await coverageFile.exists()) {
    await coverageFile.delete();  // Manual deletion
  }
}

if (reportPaths.containsKey('analyzer')) {
  final analyzerFile = File(reportPaths['analyzer']!);
  if (await analyzerFile.exists()) {
    await analyzerFile.delete();  // Manual deletion
  }
}

// Then clean old reports
await ReportUtils.cleanOldReports(
  pathName: moduleName,
  prefixPatterns: ['report_suite', 'report_failures'],
);
```

**Impact**:
- Manual file operations mixed with utility calls
- No atomicity guarantees
- Hard to maintain
- Doesn't handle errors well

### Code Statistics

| Component | Lines | Duplication | Issues |
|-----------|-------|-------------|--------|
| `analyze_coverage_lib.dart` | 2,199 | Module extraction, cleanup | Uses test path for coverage name |
| `analyze_tests_lib.dart` | 2,663 | Module extraction, cleanup | Two cleanup calls |
| `analyze_suite_lib.dart` | 1,046 | Module extraction, path detection | Manual file deletion |
| `extract_failures_lib.dart` | 791 | Module extraction | Inconsistent with others |
| **Total** | **6,699** | ~300 lines | Multiple architectural flaws |

---

## Research Findings

### Industry Best Practices (from web search)

#### 1. CLI Path Detection Best Practices

**Source**: Modern CLI tools (Roboflow Inference, YOLO, Node.js CLI Best Practices)

**Key Findings**:
- ✅ **Auto-detect environment**: Modern CLIs automatically detect device, platform, capabilities
- ✅ **Infer from context**: YOLO infers task from model type when not specified
- ✅ **Accept multiple formats**: Tools accept both local paths and URLs
- ✅ **Graceful degradation**: Provide manual overrides when auto-detection fails
- ✅ **POSIX compliance**: Use standard argument syntax

**Application to test_reporter**:
```dart
// Accept EITHER test or source path, infer the other
dart run test_reporter:analyze_coverage test/auth/  // Infers lib/src/auth/
dart run test_reporter:analyze_coverage lib/src/auth/  // Infers test/auth/

// With explicit override if needed
dart run test_reporter:analyze_coverage lib/src/auth/ --test-path=test/integration/auth/
```

#### 2. Dart Coverage Path Mapping

**Source**: Dart test package documentation, Stack Overflow

**Key Findings**:
- ⚠️ **Common issue**: Coverage only shows test files, not lib files
- ✅ **Solution**: Use `--report-on=lib` flag with format_coverage
- ✅ **Requires**: `--packages` argument for package URI resolution
- 🔧 **Proper command**:
  ```bash
  dart test --coverage=coverage
  dart run coverage:format_coverage \
    --in=coverage \
    --out=lcov.info \
    --packages=.dart_tool/package_config.json \
    --report-on=lib  # Critical!
  ```

**Application to test_reporter**:
- Our coverage analyzer already uses `--report-on` correctly
- Issue is naming the report after test path instead of source path
- Fix: Use source path for module naming

#### 3. File Naming Conventions Best Practices

**Source**: University research data management guidelines, IT documentation standards

**Key Principles**:
- ✅ **Use standard date format**: YYYY-MM-DD (ISO 8601) for sorting
- ✅ **Avoid special characters**: Use hyphens or underscores only
- ✅ **Include version/type info**: Make file purpose clear from name
- ✅ **Keep names concise**: Long names don't work well with all software
- ✅ **Establish convention before starting**: Document in README

**Application to test_reporter**:

**Current format** (v2.x):
```
flaky-fi_report_tests@2153_041125.md
auth_service-fo_report_coverage@1435_041125.md
```

**Issues**:
- Time format: HHMM_DDMMYY (not sortable)
- Redundant "report_" prefix
- No tool identifier
- Underscore mix with hyphens

**New format** (v3.0):
```
auth-service-fo_analyze-coverage_quality@20251104-1435.md
flaky-fi_analyze-tests_reliability@20251104-2153.md
all-tests-pr_analyze-suite_suite@20251104-1600.md
```

**Benefits**:
- ✅ Sortable by date: YYYYMMDD-HHMM
- ✅ Tool-identifiable: analyze-coverage, analyze-tests
- ✅ Type-identifiable: quality, reliability, suite
- ✅ Consistent separators: underscores between major components, hyphens within

#### 4. Single Source of Truth (SSoT)

**Source**: Data governance, project management best practices

**Key Principles**:
- ✅ **Unique identifiers**: Every document needs unique name and location
- ✅ **Transparency**: Clear where to find information
- ✅ **Consistency**: Naming conventions and style guides
- ✅ **Centralized management**: One system handles all operations

**Application to test_reporter**:
- Create `ReportManager` as single source of truth
- All report operations go through manager
- Manager enforces naming, handles cleanup, prevents conflicts
- Tools don't manage reports directly

---

## Architecture Design

### New Utilities Overview

```
lib/src/utils/
├── path_resolver.dart      # NEW: Bidirectional test ↔ source mapping
├── module_identifier.dart  # NEW: Centralized module naming
├── report_manager.dart     # NEW: Unified report lifecycle
├── report_utils.dart       # REPLACED: Replaced by report_manager
├── formatting_utils.dart   # UNCHANGED: Output formatting
├── path_utils.dart         # ENHANCED: Add PathResolver logic
├── extensions.dart         # UNCHANGED: Extension methods
└── constants.dart          # ENHANCED: Add new constants
```

---

### 1. PathResolver Utility

**File**: `lib/src/utils/path_resolver.dart`

**Purpose**: Single source of truth for test ↔ source path mapping

#### API Specification

```dart
/// Resolves bidirectional mappings between test and source paths
class PathResolver {
  /// Infer source path from test path
  ///
  /// Examples:
  /// - test/ → lib/
  /// - test/auth/ → lib/src/auth/ or lib/auth/
  /// - test/auth_test.dart → lib/src/auth.dart or lib/auth.dart
  ///
  /// Returns null if inference fails
  static String? inferSourcePath(String testPath);

  /// Infer test path from source path
  ///
  /// Examples:
  /// - lib/ → test/
  /// - lib/src/auth/ → test/auth/
  /// - lib/auth.dart → test/auth_test.dart
  ///
  /// Returns null if inference fails
  static String? inferTestPath(String sourcePath);

  /// Validate that paths exist on filesystem
  static bool validatePaths(String? testPath, String? sourcePath);

  /// Smart resolution - accepts either path, returns both
  ///
  /// If only inputPath provided:
  /// - Infers the other path automatically
  /// - Validates both paths exist
  ///
  /// If explicit paths provided:
  /// - Uses them directly
  /// - Still validates
  ///
  /// Throws ArgumentError if paths invalid
  static ({String testPath, String sourcePath}) resolvePaths(
    String inputPath, {
    String? explicitTestPath,
    String? explicitSourcePath,
  });

  /// Determine if path is test or source
  static PathCategory categorizePath(String path);
}

enum PathCategory {
  test,      // Path starts with test/
  source,    // Path starts with lib/
  unknown,   // Neither
}
```

#### Detection Rules

**Test → Source Inference**:

| Test Path | Inferred Source Path | Priority |
|-----------|---------------------|----------|
| `test/` | `lib/` | 1 |
| `test/auth/` | `lib/src/auth/` | 1 (check first) |
| `test/auth/` | `lib/auth/` | 2 (fallback) |
| `test/auth_test.dart` | `lib/src/auth.dart` | 1 (check first) |
| `test/auth_test.dart` | `lib/auth.dart` | 2 (fallback) |
| `test/integration/auth_test.dart` | `lib/src/auth.dart` | 1 (strip integration/) |

**Source → Test Inference**:

| Source Path | Inferred Test Path | Priority |
|-------------|-------------------|----------|
| `lib/` | `test/` | 1 |
| `lib/src/auth/` | `test/auth/` | 1 |
| `lib/auth/` | `test/auth/` | 1 |
| `lib/src/auth.dart` | `test/auth_test.dart` | 1 |
| `lib/auth.dart` | `test/auth_test.dart` | 1 |

**Validation**:
- Both paths must exist on filesystem
- Warns if paths exist but are empty directories
- Returns null if inference impossible

#### TDD Test Cases

```dart
// test/unit/utils/path_resolver_test.dart
group('PathResolver', () {
  group('inferSourcePath', () {
    test('should infer lib/src/ from test/ folder', () {
      expect(
        PathResolver.inferSourcePath('test/auth/'),
        equals('lib/src/auth/'),
      );
    });

    test('should handle test file to source file', () {
      expect(
        PathResolver.inferSourcePath('test/auth_test.dart'),
        equals('lib/src/auth.dart'),
      );
    });

    test('should return null for invalid test path', () {
      expect(
        PathResolver.inferSourcePath('invalid/path/'),
        isNull,
      );
    });
  });

  group('resolvePaths', () {
    test('should resolve from test path input', () {
      final result = PathResolver.resolvePaths('test/auth/');

      expect(result.testPath, equals('test/auth/'));
      expect(result.sourcePath, equals('lib/src/auth/'));
    });

    test('should resolve from source path input', () {
      final result = PathResolver.resolvePaths('lib/src/auth/');

      expect(result.testPath, equals('test/auth/'));
      expect(result.sourcePath, equals('lib/src/auth/'));
    });

    test('should use explicit overrides', () {
      final result = PathResolver.resolvePaths(
        'lib/src/auth/',
        explicitTestPath: 'test/integration/auth/',
      );

      expect(result.testPath, equals('test/integration/auth/'));
      expect(result.sourcePath, equals('lib/src/auth/'));
    });
  });
});
```

---

### 2. ModuleIdentifier Utility

**File**: `lib/src/utils/module_identifier.dart`

**Purpose**: Single source of truth for module naming across all tools

#### API Specification

```dart
/// Extracts and generates consistent module names
class ModuleIdentifier {
  /// Extract base module name from any path
  ///
  /// Examples:
  /// - test/auth/ → auth
  /// - lib/src/auth/ → auth
  /// - test/services/auth_service.dart → auth_service
  /// - test/ → all_tests
  ///
  /// Returns base name without suffix
  static String extractModuleName(String path, {PathType? type});

  /// Generate qualified name with type suffix
  ///
  /// Examples:
  /// - (auth, folder) → auth-fo
  /// - (auth_service, file) → auth_service-fi
  /// - (all_tests, project) → all_tests-pr
  static String generateQualifiedName(String baseName, PathType type);

  /// Extract qualified name directly (combines above)
  static String getQualifiedModuleName(String path);

  /// Validate module name format
  static bool isValidModuleName(String name);

  /// Parse qualified name back to components
  static ({String baseName, PathType type})? parseQualifiedName(String qualifiedName);
}

enum PathType {
  file,      // Single file - adds -fi suffix
  folder,    // Directory - adds -fo suffix
  project,   // Root/all - adds -pr suffix
}
```

#### Naming Rules

**Base Name Extraction**:

| Input Path | Base Name | Logic |
|------------|-----------|-------|
| `test/auth/` | `auth` | Last segment of path |
| `test/auth_service/` | `auth_service` | Last segment |
| `lib/src/auth/` | `auth` | Last segment |
| `test/auth_test.dart` | `auth` | Remove _test.dart suffix |
| `lib/src/auth_service.dart` | `auth_service` | Remove .dart suffix |
| `test/` | `all_tests` | Special case: root test directory |
| `lib/` | `all_sources` | Special case: root lib directory |

**Type Detection**:

| Path Characteristics | PathType | Suffix |
|---------------------|----------|--------|
| Ends with `.dart` | `file` | `-fi` |
| Directory (no extension) | `folder` | `-fo` |
| Root directory (`test/`, `lib/`) | `project` | `-pr` |

**Special Cases**:

| Input | Output | Reason |
|-------|--------|--------|
| `test/` | `all-tests-pr` | Root test directory |
| `lib/` | `all-sources-pr` | Root source directory |
| `test/integration/` | `integration-fo` | Integration tests |
| `test/unit/` | `unit-fo` | Unit tests |

**Character Rules**:
- Replace underscores with hyphens in output: `auth_service` → `auth-service`
- Keep hyphens as-is
- Lowercase all names
- No special characters except hyphens

#### TDD Test Cases

```dart
// test/unit/utils/module_identifier_test.dart
group('ModuleIdentifier', () {
  group('extractModuleName', () {
    test('should extract from test folder path', () {
      expect(
        ModuleIdentifier.extractModuleName('test/auth/'),
        equals('auth'),
      );
    });

    test('should extract from source folder path', () {
      expect(
        ModuleIdentifier.extractModuleName('lib/src/auth/'),
        equals('auth'),
      );
    });

    test('should handle special case: test root', () {
      expect(
        ModuleIdentifier.extractModuleName('test/'),
        equals('all_tests'),
      );
    });
  });

  group('generateQualifiedName', () {
    test('should add -fo suffix for folders', () {
      expect(
        ModuleIdentifier.generateQualifiedName('auth', PathType.folder),
        equals('auth-fo'),
      );
    });

    test('should add -fi suffix for files', () {
      expect(
        ModuleIdentifier.generateQualifiedName('auth_test', PathType.file),
        equals('auth-test-fi'),
      );
    });

    test('should replace underscores with hyphens', () {
      expect(
        ModuleIdentifier.generateQualifiedName('auth_service', PathType.folder),
        equals('auth-service-fo'),
      );
    });
  });

  group('getQualifiedModuleName', () {
    test('should generate qualified name from path', () {
      expect(
        ModuleIdentifier.getQualifiedModuleName('test/auth/'),
        equals('auth-fo'),
      );
    });
  });

  group('parseQualifiedName', () {
    test('should parse qualified name back to components', () {
      final result = ModuleIdentifier.parseQualifiedName('auth-service-fo');

      expect(result?.baseName, equals('auth-service'));
      expect(result?.type, equals(PathType.folder));
    });
  });
});
```

---

### 3. ReportManager Utility

**File**: `lib/src/utils/report_manager.dart`

**Purpose**: Single source of truth for report lifecycle management

#### API Specification

```dart
/// Manages complete report lifecycle with atomic operations
class ReportManager {
  /// Start a report generation context
  ///
  /// Returns context for tracking this report through lifecycle
  static ReportContext startReport({
    required String moduleName,
    required ReportType type,
    required String toolName,
  });

  /// Write report with automatic cleanup
  ///
  /// Steps:
  /// 1. Generate unique filename with timestamp
  /// 2. Write markdown file
  /// 3. Write JSON file
  /// 4. Clean old reports (keep latest N)
  /// 5. Register in session registry
  ///
  /// Returns path to markdown report
  static Future<String> writeReport(
    ReportContext context, {
    required String markdownContent,
    required Map<String, dynamic> jsonData,
    int keepCount = 1,
  });

  /// Find latest report matching criteria
  ///
  /// Useful for orchestrator to read reports from other tools
  static Future<String?> findLatestReport({
    required String moduleName,
    required ReportType type,
    String? toolName,
  });

  /// Manual cleanup (usually not needed - writeReport does this)
  static Future<void> cleanupReports({
    required String moduleName,
    required ReportType type,
    int keepCount = 1,
    bool dryRun = false,
  });

  /// Get report directory for a type
  static String getReportDirectory(ReportType type);

  /// Generate filename from context
  static String generateFilename(ReportContext context, String extension);

  /// Extract JSON from markdown report (for orchestrator)
  static Future<Map<String, dynamic>?> extractJsonFromReport(String reportPath);
}

/// Report generation context
class ReportContext {
  final String moduleName;      // Qualified name (e.g., auth-service-fo)
  final ReportType type;        // coverage, tests, failures, suite
  final String toolName;        // analyze-coverage, analyze-tests, etc.
  final DateTime timestamp;     // Generation time
  final String reportId;        // Unique identifier

  ReportContext({...});

  /// Get subdirectory for this report type
  String get subdirectory;

  /// Get base filename without extension
  String get baseFilename;
}

/// Report types with subdirectories
enum ReportType {
  coverage,      // → quality/
  tests,         // → reliability/
  failures,      // → failures/
  suite,         // → suite/
}
```

#### Report Naming Convention

**Format**: `{moduleName}_{toolName}_{type}@{YYYYMMDD-HHMM}.{ext}`

**Components**:
- `{moduleName}`: From ModuleIdentifier (e.g., `auth-service-fo`)
- `{toolName}`: Tool identifier (e.g., `analyze-coverage`, `analyze-tests`)
- `{type}`: Report type subdirectory name (e.g., `quality`, `reliability`)
- `{YYYYMMDD-HHMM}`: ISO date + time (sortable)
- `{ext}`: `md` or `json`

**Examples**:
```
tests_reports/
├── quality/
│   ├── auth-service-fo_analyze-coverage_quality@20251104-1435.md
│   └── auth-service-fo_analyze-coverage_quality@20251104-1435.json
├── reliability/
│   ├── auth-service-fo_analyze-tests_reliability@20251104-1445.md
│   └── auth-service-fo_analyze-tests_reliability@20251104-1445.json
├── failures/
│   └── auth-service-fo_analyze-tests_failures@20251104-1445.md
└── suite/
    ├── auth-service-fo_analyze-suite_suite@20251104-1500.md
    └── auth-service-fo_analyze-suite_suite@20251104-1500.json
```

**Benefits**:
- ✅ Sortable by date (YYYYMMDD first)
- ✅ Unique per tool run (timestamp to minute)
- ✅ Tool-identifiable (can filter by tool)
- ✅ Type-identifiable (matches subdirectory)
- ✅ Module-identifiable (can find all reports for a module)

#### Cleanup Strategy

**Default**: Keep latest 1 report per (module, type, tool) combination

**Logic**:
1. List all files in subdirectory
2. Group by module name
3. Sort by timestamp (descending)
4. Keep newest N (default 1)
5. Delete older reports

**Safety**:
- Never delete reports less than 1 hour old (prevent race conditions)
- Verify file exists before deletion
- Log all deletions when verbose
- Provide dry-run mode for testing

#### TDD Test Cases

```dart
// test/unit/utils/report_manager_test.dart
group('ReportManager', () {
  late Directory testReportDir;

  setUp(() async {
    // Create temporary report directory
    testReportDir = await Directory.systemTemp.createTemp('test_reports');
  });

  tearDown(() async {
    // Clean up
    await testReportDir.delete(recursive: true);
  });

  group('startReport', () {
    test('should create report context', () {
      final context = ReportManager.startReport(
        moduleName: 'auth-service-fo',
        type: ReportType.coverage,
        toolName: 'analyze-coverage',
      );

      expect(context.moduleName, equals('auth-service-fo'));
      expect(context.type, equals(ReportType.coverage));
      expect(context.toolName, equals('analyze-coverage'));
      expect(context.reportId, isNotEmpty);
    });
  });

  group('writeReport', () {
    test('should write markdown and JSON files', () async {
      final context = ReportManager.startReport(
        moduleName: 'auth-fo',
        type: ReportType.tests,
        toolName: 'analyze-tests',
      );

      final reportPath = await ReportManager.writeReport(
        context,
        markdownContent: '# Test Report',
        jsonData: {'success': true},
      );

      expect(await File(reportPath).exists(), isTrue);

      final jsonPath = reportPath.replaceAll('.md', '.json');
      expect(await File(jsonPath).exists(), isTrue);
    });

    test('should cleanup old reports when writing new one', () async {
      // Write first report
      final context1 = ReportManager.startReport(
        moduleName: 'auth-fo',
        type: ReportType.tests,
        toolName: 'analyze-tests',
      );
      await ReportManager.writeReport(context1, ...);

      // Write second report (should delete first)
      final context2 = ReportManager.startReport(
        moduleName: 'auth-fo',
        type: ReportType.tests,
        toolName: 'analyze-tests',
      );
      await ReportManager.writeReport(context2, ..., keepCount: 1);

      // Should only have 1 report
      final reports = await ReportManager.findLatestReport(...);
      expect(reports, hasLength(1));
    });
  });

  group('generateFilename', () {
    test('should generate correct filename format', () {
      final context = ReportContext(
        moduleName: 'auth-service-fo',
        type: ReportType.coverage,
        toolName: 'analyze-coverage',
        timestamp: DateTime(2025, 11, 4, 14, 35),
        reportId: 'test-id',
      );

      final filename = ReportManager.generateFilename(context, 'md');

      expect(
        filename,
        equals('auth-service-fo_analyze-coverage_quality@20251104-1435.md'),
      );
    });
  });
});
```

---

## Implementation Plan

### Phase 1: Foundation Utilities (5-6 hours)

#### Day 1: PathResolver (2 hours)

**🔴 RED Phase** (30 min):
```dart
// test/unit/utils/path_resolver_test.dart
test('should infer source path from test path', () {
  expect(PathResolver.inferSourcePath('test/auth/'),
         equals('lib/src/auth/'));
});

test('should infer test path from source path', () {
  expect(PathResolver.inferTestPath('lib/src/auth/'),
         equals('test/auth/'));
});

test('should resolve paths from either input', () {
  final result = PathResolver.resolvePaths('test/auth/');
  expect(result.testPath, equals('test/auth/'));
  expect(result.sourcePath, equals('lib/src/auth/'));
});
```

**Run**: `dart test test/unit/utils/path_resolver_test.dart`
**Expected**: ❌ Tests fail - PathResolver doesn't exist

**🟢 GREEN Phase** (1 hour):
- Create `lib/src/utils/path_resolver.dart`
- Implement minimal logic to pass tests
- Handle basic test/ ↔ lib/src/ mapping

**Run**: `dart test test/unit/utils/path_resolver_test.dart`
**Expected**: ✅ Tests pass

**♻️ REFACTOR Phase** (30 min):
- Add edge case handling (lib/ vs lib/src/)
- Add validation logic
- Extract constants for path patterns
- Run `dart analyze` and `dart format`

**Expected**: ✅ All tests still pass, 0 analyzer warnings

#### Day 2: ModuleIdentifier (2 hours)

**🔴 RED Phase** (30 min):
```dart
// test/unit/utils/module_identifier_test.dart
test('should extract module name from path', () {
  expect(ModuleIdentifier.extractModuleName('test/auth/'),
         equals('auth'));
});

test('should generate qualified name with suffix', () {
  expect(ModuleIdentifier.generateQualifiedName('auth', PathType.folder),
         equals('auth-fo'));
});

test('should handle special case: test root', () {
  expect(ModuleIdentifier.getQualifiedModuleName('test/'),
         equals('all-tests-pr'));
});
```

**Run**: `dart test test/unit/utils/module_identifier_test.dart`
**Expected**: ❌ Tests fail - ModuleIdentifier doesn't exist

**🟢 GREEN Phase** (1 hour):
- Create `lib/src/utils/module_identifier.dart`
- Implement extraction and qualification logic
- Handle special cases (test/, lib/)

**Run**: `dart test test/unit/utils/module_identifier_test.dart`
**Expected**: ✅ Tests pass

**♻️ REFACTOR Phase** (30 min):
- Add parseQualifiedName() for bidirectional parsing
- Add validation logic
- Ensure consistency with PathResolver
- Run `dart analyze` and `dart format`

**Expected**: ✅ All tests still pass, 0 analyzer warnings

#### Day 3: ReportManager (2-3 hours)

**🔴 RED Phase** (1 hour):
```dart
// test/unit/utils/report_manager_test.dart
test('should create report context', () {
  final context = ReportManager.startReport(...);
  expect(context.moduleName, equals('auth-fo'));
  expect(context.reportId, isNotEmpty);
});

test('should write markdown and JSON files', () async {
  final path = await ReportManager.writeReport(...);
  expect(await File(path).exists(), isTrue);
});

test('should cleanup old reports', () async {
  // Write 2 reports, keep 1
  await ReportManager.writeReport(context1, ...);
  await ReportManager.writeReport(context2, ..., keepCount: 1);

  // Should only have latest
  final files = Directory('tests_reports/quality/').listSync();
  expect(files.length, equals(2)); // md + json
});
```

**Run**: `dart test test/unit/utils/report_manager_test.dart`
**Expected**: ❌ Tests fail - ReportManager doesn't exist

**🟢 GREEN Phase** (1-1.5 hours):
- Create `lib/src/utils/report_manager.dart`
- Implement ReportContext class
- Implement startReport() and writeReport()
- Implement basic cleanup logic

**Run**: `dart test test/unit/utils/report_manager_test.dart`
**Expected**: ✅ Tests pass

**♻️ REFACTOR Phase** (30-45 min):
- Add safety checks (1 hour minimum age for cleanup)
- Add dry-run mode
- Add findLatestReport() for orchestrator
- Add extractJsonFromReport()
- Run `dart analyze` and `dart format`

**Expected**: ✅ All tests still pass, 0 analyzer warnings

**🔄 META-TEST Phase** (30 min):
- Run `dart test` (all unit tests)
- Verify all 3 utilities work together
- Check coverage with `dart test --coverage`

**Expected**: ✅ All tests pass, >80% coverage on utilities

---

### Phase 2: Tool Refactoring (8-10 hours)

#### Day 4: Refactor analyze_coverage_lib.dart (2-2.5 hours)

**🔴 RED Phase** (30 min):
```dart
// test/integration/analyzers/coverage_analyzer_test.dart
test('should accept test path and auto-resolve source path', () async {
  final analyzer = CoverageAnalyzer(inputPath: 'test/fixtures/');
  final exitCode = await analyzer.run();

  expect(exitCode, equals(0));
  expect(analyzer.sourcePath, equals('lib/src/fixtures/'));
  expect(analyzer.testPath, equals('test/fixtures/'));
});

test('should generate report with new naming', () async {
  final analyzer = CoverageAnalyzer(inputPath: 'test/fixtures/');
  await analyzer.run();

  final reportFile = File('tests_reports/quality/fixtures-fo_analyze-coverage_quality@*.md');
  expect(await reportFile.exists(), isTrue);
});
```

**Run**: `dart test test/integration/analyzers/coverage_analyzer_test.dart`
**Expected**: ❌ Tests fail - old implementation doesn't match

**🟢 GREEN Phase** (1-1.5 hours):

**Changes to `lib/src/bin/analyze_coverage_lib.dart`**:

1. **Update argument parsing** (lines ~2012-2090):
```dart
// OLD: Required 2 paths
final libPath = nonFlagArgs[0];
final testPath = nonFlagArgs.length > 1 ? nonFlagArgs[1] : derivedTestPath;

// NEW: Accept 1 path, auto-resolve
final inputPath = nonFlagArgs[0];
final paths = PathResolver.resolvePaths(
  inputPath,
  explicitTestPath: args['test-path'],
  explicitSourcePath: args['source-path'],
);
final libPath = paths.sourcePath;
final testPath = paths.testPath;
```

2. **Update module name extraction** (lines ~1743-1776):
```dart
// OLD: Custom _extractPathName()
String _extractPathName() {
  // ... 35 lines of logic
}

// NEW: Use ModuleIdentifier
final moduleName = ModuleIdentifier.getQualifiedModuleName(libPath);
// Remove _extractPathName() method entirely
```

3. **Update report generation** (lines ~1345-1349):
```dart
// OLD: Manual ReportUtils calls
await ReportUtils.writeUnifiedReport(...);
await ReportUtils.cleanOldReports(...);

// NEW: Use ReportManager
final context = ReportManager.startReport(
  moduleName: moduleName,
  type: ReportType.coverage,
  toolName: 'analyze-coverage',
);

await ReportManager.writeReport(
  context,
  markdownContent: markdownReport,
  jsonData: coverageData,
);
// Cleanup happens automatically in writeReport()
```

**Run**: `dart test test/integration/analyzers/coverage_analyzer_test.dart`
**Expected**: ✅ Tests pass

**♻️ REFACTOR Phase** (30-45 min):
- Remove old _extractPathName() method (~35 lines)
- Add verbose output showing path resolution
- Update help text with new CLI usage
- Run `dart analyze` and `dart format`

**Expected**: ✅ Tests pass, code is cleaner

**🔄 META-TEST Phase** (15 min):
- Run: `dart run test_reporter:analyze_coverage test/`
- Verify report generated with new naming
- Check path resolution works
- Verify old reports cleaned up

**Expected**: ✅ Tool works on itself

#### Day 5: Refactor analyze_tests_lib.dart (2-2.5 hours)

**🔴 RED Phase** (30 min):
```dart
// test/integration/analyzers/test_analyzer_test.dart
test('should use consistent module naming with coverage', () async {
  // Run both tools on same paths
  final coverageAnalyzer = CoverageAnalyzer(inputPath: 'test/fixtures/');
  await coverageAnalyzer.run();

  final testAnalyzer = TestAnalyzer(targetPath: 'test/fixtures/');
  await testAnalyzer.run();

  // Module names should match
  expect(coverageAnalyzer.moduleName, equals(testAnalyzer.moduleName));
});

test('should generate reports with new naming', () async {
  final analyzer = TestAnalyzer(targetPath: 'test/fixtures/');
  await analyzer.run();

  // Check tests report
  final testsReport = File('tests_reports/reliability/fixtures-fo_analyze-tests_reliability@*.md');
  expect(await testsReport.exists(), isTrue);
});
```

**Run**: `dart test test/integration/analyzers/test_analyzer_test.dart`
**Expected**: ❌ Tests fail - module names don't match yet

**🟢 GREEN Phase** (1-1.5 hours):

**Changes to `lib/src/bin/analyze_tests_lib.dart`**:

1. **Update module name extraction** (lines ~2361-2396):
```dart
// OLD: Custom _extractPathName()
String _extractPathName() {
  // ... 35 lines of logic
}

// NEW: Use ModuleIdentifier
final moduleName = ModuleIdentifier.getQualifiedModuleName(targetFiles.first);
// Remove _extractPathName() method entirely
```

2. **Update report generation** (lines ~2341-2358):
```dart
// OLD: Custom cleanup calls
await _cleanupOldReports(pathName);

// NEW: Use ReportManager for tests report
final testsContext = ReportManager.startReport(
  moduleName: moduleName,
  type: ReportType.tests,
  toolName: 'analyze-tests',
);

await ReportManager.writeReport(
  testsContext,
  markdownContent: testsReport,
  jsonData: testsData,
);

// NEW: Use ReportManager for failures report (if any)
if (hasFailures) {
  final failuresContext = ReportManager.startReport(
    moduleName: moduleName,
    type: ReportType.failures,
    toolName: 'analyze-tests',
  );

  await ReportManager.writeReport(
    failuresContext,
    markdownContent: failuresReport,
    jsonData: failuresData,
  );
}
// Remove _cleanupOldReports() method entirely
```

3. **Add path resolution** (optional, for context):
```dart
// After getting targetFiles
final paths = PathResolver.resolvePaths(targetFiles.first);
if (verbose) {
  print('✓ Test path: ${paths.testPath}');
  print('✓ Source path: ${paths.sourcePath}');
}
```

**Run**: `dart test test/integration/analyzers/test_analyzer_test.dart`
**Expected**: ✅ Tests pass

**♻️ REFACTOR Phase** (30-45 min):
- Remove old _extractPathName() (~35 lines)
- Remove old _cleanupOldReports() (~20 lines)
- Update help text
- Run `dart analyze` and `dart format`

**Expected**: ✅ Tests pass, ~55 lines removed

**🔄 META-TEST Phase** (15 min):
- Run: `dart run test_reporter:analyze_tests test/`
- Verify reports generated with new naming
- Check module name consistency

**Expected**: ✅ Tool works on itself

#### Day 6: Refactor analyze_suite_lib.dart (2-2.5 hours)

**🔴 RED Phase** (30 min):
```dart
// test/integration/analyzers/suite_analyzer_test.dart
test('should not manually delete intermediate reports', () async {
  final orchestrator = TestOrchestrator(testPath: 'test/fixtures/');
  await orchestrator.runAll();

  // Intermediate reports should be cleaned by ReportManager
  // Not manually deleted by orchestrator

  // Suite report should exist
  final suiteReport = File('tests_reports/suite/fixtures-fo_analyze-suite_suite@*.md');
  expect(await suiteReport.exists(), isTrue);
});

test('should use consistent module naming across all tools', () async {
  final orchestrator = TestOrchestrator(testPath: 'test/fixtures/');
  await orchestrator.runAll();

  // All reports should use same module name
  final reports = Directory('tests_reports/').listSync(recursive: true);
  final reportNames = reports
      .where((f) => f.path.endsWith('.md'))
      .map((f) => path.basename(f.path))
      .toList();

  // All should start with same module name
  expect(reportNames.every((name) => name.startsWith('fixtures-fo_')), isTrue);
});
```

**Run**: `dart test test/integration/analyzers/suite_analyzer_test.dart`
**Expected**: ❌ Tests fail - manual deletion still happening

**🟢 GREEN Phase** (1-1.5 hours):

**Changes to `lib/src/bin/analyze_suite_lib.dart`**:

1. **Replace internal path detection** (lines ~100-156):
```dart
// OLD: detectSourcePath() and detectTestPath() methods
String detectSourcePath(String inputPath) {
  // ... ~30 lines
}

String detectTestPath(String inputPath) {
  // ... ~20 lines
}

// NEW: Use PathResolver
// Remove both methods entirely
// Use PathResolver.resolvePaths() in runAll()
```

2. **Update module name extraction** (lines ~66-90):
```dart
// OLD: extractModuleName()
String extractModuleName() {
  // ... 25 lines
}

// NEW: Use ModuleIdentifier
final moduleName = ModuleIdentifier.getQualifiedModuleName(testPath);
// Remove extractModuleName() method entirely
```

3. **Simplify orchestration** (lines ~158-176):
```dart
// OLD: Complex flow with manual path detection
Future<void> runAll() async {
  final sourcePath = detectSourcePath(testPath);
  await runCoverageTool();
  await runTestAnalyzer();
  await generateUnifiedReport();
}

// NEW: Simple flow using PathResolver
Future<void> runAll() async {
  // Resolve paths once at start
  final paths = PathResolver.resolvePaths(testPath);

  if (verbose) {
    print('✓ Test path: ${paths.testPath}');
    print('✓ Source path: ${paths.sourcePath}');
  }

  // Run tools with proper paths
  await runCoverageTool(paths.sourcePath);
  await runTestAnalyzer(paths.testPath);

  // Generate unified report
  await generateUnifiedReport();
}
```

4. **Remove manual file deletion** (lines ~689-761):
```dart
// OLD: Manual deletion + cleanup
if (reportPaths.containsKey('coverage')) {
  final coverageFile = File(reportPaths['coverage']!);
  if (await coverageFile.exists()) {
    await coverageFile.delete();  // REMOVE THIS
  }
}

await ReportUtils.cleanOldReports(...);

// NEW: Just use ReportManager
final context = ReportManager.startReport(
  moduleName: moduleName,
  type: ReportType.suite,
  toolName: 'analyze-suite',
);

await ReportManager.writeReport(
  context,
  markdownContent: unifiedReport,
  jsonData: suiteData,
);

// Intermediate reports already cleaned by their tools
// No manual deletion needed!
```

**Run**: `dart test test/integration/analyzers/suite_analyzer_test.dart`
**Expected**: ✅ Tests pass

**♻️ REFACTOR Phase** (30-45 min):
- Remove detectSourcePath() (~30 lines)
- Remove detectTestPath() (~20 lines)
- Remove extractModuleName() (~25 lines)
- Remove manual file deletion (~30 lines)
- Total: ~105 lines removed!
- Run `dart analyze` and `dart format`

**Expected**: ✅ Tests pass, much simpler code

**🔄 META-TEST Phase** (15 min):
- Run: `dart run test_reporter:analyze_suite test/`
- Verify suite report generated
- Check no manual deletions
- Verify module name consistency

**Expected**: ✅ Tool works on itself

#### Day 7: Refactor extract_failures_lib.dart (1.5-2 hours)

**🔴 RED Phase** (30 min):
```dart
// test/integration/analyzers/failures_extractor_test.dart
test('should use consistent module naming', () async {
  final extractor = FailedTestExtractor(testPath: 'test/fixtures/');
  await extractor.run();

  final report = File('tests_reports/failures/fixtures-fo_extract-failures_failures@*.md');
  expect(await report.exists(), isTrue);
});
```

**Run**: `dart test test/integration/analyzers/failures_extractor_test.dart`
**Expected**: ❌ Tests fail - new naming not used yet

**🟢 GREEN Phase** (45-60 min):

**Changes to `lib/src/bin/extract_failures_lib.dart`**:

1. **Add module name extraction**:
```dart
// Use ModuleIdentifier
final moduleName = ModuleIdentifier.getQualifiedModuleName(testPath);
```

2. **Update report generation**:
```dart
// Use ReportManager
final context = ReportManager.startReport(
  moduleName: moduleName,
  type: ReportType.failures,
  toolName: 'extract-failures',
);

await ReportManager.writeReport(
  context,
  markdownContent: failuresReport,
  jsonData: failuresData,
);
```

3. **Add path resolution** (optional):
```dart
final paths = PathResolver.resolvePaths(testPath);
```

**Run**: `dart test test/integration/analyzers/failures_extractor_test.dart`
**Expected**: ✅ Tests pass

**♻️ REFACTOR Phase** (30 min):
- Update help text
- Add verbose output
- Run `dart analyze` and `dart format`

**Expected**: ✅ Tests pass

**🔄 META-TEST Phase** (15 min):
- Run: `dart run test_reporter:extract_failures test/`
- Verify report naming consistent

**Expected**: ✅ Tool works on itself

---

### Phase 3: Enhanced Features (2-4 hours)

#### Day 8: Enhanced Features (2-3 hours)

**1. Add CLI Flags** (30 min):

Add to all tools' argument parsers:
```dart
parser
  ..addOption('test-path', help: 'Explicit test path override')
  ..addOption('source-path', help: 'Explicit source path override')
  ..addOption('module-name', help: 'Explicit module name override');
```

**2. Add Validation** (1 hour):

```dart
// In each tool's main()
try {
  final paths = PathResolver.resolvePaths(inputPath);

  if (!PathResolver.validatePaths(paths.testPath, paths.sourcePath)) {
    print('❌ Error: Could not validate paths');
    print('   Test path: ${paths.testPath} ${await Directory(paths.testPath).exists() ? "✓" : "✗"}');
    print('   Source path: ${paths.sourcePath} ${await Directory(paths.sourcePath).exists() ? "✓" : "✗"}');
    exit(2);
  }

  if (verbose) {
    print('✓ Paths validated successfully');
    print('  Test: ${paths.testPath}');
    print('  Source: ${paths.sourcePath}');
  }
} on ArgumentError catch (e) {
  print('❌ Error: ${e.message}');
  print('\nUsage: dart run test_reporter:analyze_coverage <path>');
  print('  Accepts either test or source path - will auto-resolve the other');
  print('\nExamples:');
  print('  dart run test_reporter:analyze_coverage test/auth/');
  print('  dart run test_reporter:analyze_coverage lib/src/auth/');
  exit(2);
}
```

**3. Add ReportRegistry** (1-1.5 hours):

**Create**: `lib/src/utils/report_registry.dart`

```dart
/// Session-level tracking of generated reports
class ReportRegistry {
  static final List<ReportContext> _reports = [];

  /// Register a report
  static void register(ReportContext context) {
    _reports.add(context);
  }

  /// Get all reports for session
  static List<ReportContext> getReports({ReportType? type}) {
    if (type == null) return List.from(_reports);
    return _reports.where((r) => r.type == type).toList();
  }

  /// Print summary of session
  static void printSummary() {
    if (_reports.isEmpty) {
      print('\nNo reports generated this session.');
      return;
    }

    print('\n📊 Session Summary');
    print('─' * 60);

    for (final type in ReportType.values) {
      final reportsOfType = _reports.where((r) => r.type == type).toList();
      if (reportsOfType.isEmpty) continue;

      print('\n${type.name.toUpperCase()} (${reportsOfType.length})');
      for (final report in reportsOfType) {
        print('  ✓ ${report.moduleName} @ ${report.timestamp.toString().substring(11, 16)}');
      }
    }

    print('\n📁 Reports directory: tests_reports/');
    print('─' * 60);
  }

  /// Clear registry (for testing)
  static void clear() {
    _reports.clear();
  }
}
```

**Integrate into ReportManager**:
```dart
// In writeReport()
ReportRegistry.register(context);
```

**Add to each tool's end**:
```dart
// After all reports generated
if (verbose) {
  ReportRegistry.printSummary();
}
```

#### Day 9: End-to-End Testing & Documentation (1-2 hours)

**1. E2E Testing** (45 min):

Create comprehensive integration test:
```dart
// test/integration/e2e_test.dart
test('full workflow: coverage + tests + suite', () async {
  // Run coverage
  final coverage = await Process.run('dart', [
    'run',
    'test_reporter:analyze_coverage',
    'test/fixtures/',
  ]);
  expect(coverage.exitCode, equals(0));

  // Run tests
  final tests = await Process.run('dart', [
    'run',
    'test_reporter:analyze_tests',
    'test/fixtures/',
  ]);
  expect(tests.exitCode, equals(0));

  // Run suite
  final suite = await Process.run('dart', [
    'run',
    'test_reporter:analyze_suite',
    'test/fixtures/',
  ]);
  expect(suite.exitCode, equals(0));

  // Verify all reports exist with consistent naming
  final reports = Directory('tests_reports/').listSync(recursive: true);
  final mdFiles = reports.where((f) => f.path.endsWith('.md')).toList();

  // Should have: coverage, tests, suite (at least 3)
  expect(mdFiles.length, greaterThanOrEqualTo(3));

  // All should start with same module name
  final basenames = mdFiles.map((f) => path.basename(f.path)).toList();
  expect(basenames.every((name) => name.startsWith('fixtures-fo_')), isTrue);
});
```

**2. Meta-testing** (30 min):

Run all tools on themselves:
```bash
# Analyze test suite
dart run test_reporter:analyze_tests test/ --runs=3

# Analyze coverage
dart run test_reporter:analyze_coverage lib/src/ --test-path=test/

# Run full suite
dart run test_reporter:analyze_suite test/

# Verify reports clean
ls -lh tests_reports/*/*.md
```

**3. Update Documentation** (45 min):

Update `README.md`:
```markdown
## Usage

### Analyze Coverage

```bash
# Auto-resolves paths - accepts either test or source path
dart run test_reporter:analyze_coverage test/auth/
dart run test_reporter:analyze_coverage lib/src/auth/

# With explicit overrides
dart run test_reporter:analyze_coverage lib/src/auth/ --test-path=test/integration/auth/
```

### Analyze Tests

```bash
dart run test_reporter:analyze_tests test/auth/ --runs=5
```

### Analyze Suite (runs both)

```bash
dart run test_reporter:analyze_suite test/auth/
```

All tools now:
- ✅ Auto-detect corresponding paths
- ✅ Use consistent module naming
- ✅ Generate reports with standardized naming: `{module}_{tool}_{type}@{YYYYMMDD-HHMM}.md`
- ✅ Auto-cleanup old reports
```

Update `CHANGELOG.md`:
```markdown
## [3.0.0] - 2025-11-05

### Breaking Changes

- **Report Naming**: New format `{module}_{tool}_{type}@{YYYYMMDD-HHMM}.{ext}`
- **CLI Arguments**: `analyze_coverage` now accepts single path (auto-resolves test/source)
- **API Changes**: `ReportUtils` replaced by `ReportManager`

### Added

- `PathResolver`: Automatic test ↔ source path mapping
- `ModuleIdentifier`: Centralized module naming
- `ReportManager`: Unified report lifecycle management
- `ReportRegistry`: Session-level report tracking
- Path validation with clear error messages
- Verbose mode showing path resolution

### Changed

- All tools use consistent module naming
- Reports now include tool identifier in filename
- Timestamps now use ISO format (YYYYMMDD-HHMM) for sorting
- Auto-cleanup happens during report write (not separate call)

### Removed

- Removed: `ReportUtils.writeUnifiedReport()` - use `ReportManager.writeReport()`
- Removed: `ReportUtils.cleanOldReports()` - automatic now
- Removed: 100+ lines of duplicate path/module extraction code
```

---

## Success Criteria

### Functional Requirements

✅ **Single Command Usage**:
```bash
# Works with test path
dart run test_reporter:analyze_coverage test/auth/

# Works with source path
dart run test_reporter:analyze_coverage lib/src/auth/

# Both produce same module name
```

✅ **Consistent Naming Across Tools**:
```
tests_reports/
├── quality/
│   └── auth-service-fo_analyze-coverage_quality@20251104-1435.md
├── reliability/
│   └── auth-service-fo_analyze-tests_reliability@20251104-1445.md
└── suite/
    └── auth-service-fo_analyze-suite_suite@20251104-1500.md
```

All reports for `auth-service-fo` module have matching names.

✅ **Zero Manual Cleanup**:
- Reports auto-cleaned during write
- No orphaned files
- Latest report always retained

✅ **Validation & Errors**:
```bash
$ dart run test_reporter:analyze_coverage invalid/path/
❌ Error: Could not validate paths
   Test path: test/invalid/ ✗
   Source path: lib/src/invalid/ ✗
```

✅ **Verbose Output**:
```bash
$ dart run test_reporter:analyze_coverage test/auth/ --verbose
✓ Paths validated successfully
  Test: test/auth/
  Source: lib/src/auth/
✓ Module name: auth-fo
Running coverage analysis...
```

### Quality Requirements

✅ **TDD Compliance**:
- All utilities have unit tests (>80% coverage)
- All tools have integration tests
- All tests pass before commit

✅ **Code Quality**:
- `dart analyze`: 0 issues
- `dart format`: No changes needed
- Reduced code: ~200+ lines removed (duplicates)

✅ **Meta-Testing**:
- All tools run successfully on test_reporter itself
- Reports generated with clean output
- No errors or warnings

### Performance Requirements

✅ **No Performance Degradation**:
- Path resolution adds <10ms overhead
- Report generation time unchanged
- Cleanup runs asynchronously (non-blocking)

---


### Technical Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Path inference fails for non-standard structures | Medium | Medium | Provide explicit override flags |
| Report cleanup too aggressive | Low | High | Safety checks (1 hour minimum), dry-run mode, keepCount config |
| Performance degradation | Low | Medium | Benchmark before/after, optimize if needed |
| Module name collisions | Low | Low | Use qualified names with suffixes |

### Project Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Timeline overrun | Medium | Medium | Phased approach, can release Phase 1+2 without Phase 3 |
| Incomplete testing | Low | High | TDD mandatory, meta-testing required before release |

### Mitigation Strategies

**1. Validation**:
- Extensive validation before operations
- Clear error messages guide users
- Dry-run mode for cleanup operations

**2. Testing**:
- TDD for all new code
- Integration tests for all tools
- Meta-testing confirms real-world usage
- E2E test covers full workflow

**3. Documentation**:
- Updated README with examples
- Changelog with breaking changes highlighted
- Clear error messages for unsupported features

---

## Dependencies & Prerequisites

### Required Dart Packages

Already in `pubspec.yaml`:
- ✅ `args` - CLI argument parsing
- ✅ `path` - Path manipulation
- ✅ `io` - File I/O
- ✅ `test` - Testing framework

No new dependencies needed!

### Development Tools

- ✅ Dart SDK ≥3.6.0 (already required)
- ✅ `dart analyze` (built-in)
- ✅ `dart format` (built-in)
- ✅ `dart test` (built-in)

### Testing Requirements

- Test fixtures directory: `test/fixtures/`
- Sample test files for integration tests
- Temporary report directory for unit tests

---

## Rollout Plan

### Phase 1: Internal Release (v3.0.0-alpha.1)

**Audience**: Development team only

**Goals**:
- Validate new utilities work
- Identify issues with path inference
- Test meta-testing on self

**Duration**: 1 week

**Checklist**:
- [ ] All unit tests pass
- [ ] All integration tests pass
- [ ] Meta-testing succeeds
- [ ] Code coverage >80%

### Phase 2: Beta Release (v3.0.0-beta.1)

**Audience**: Early adopters / testers

**Goals**:
- Gather feedback on new UX
- Test in real projects

**Duration**: 1-2 weeks

**Checklist**:
- [ ] CHANGELOG updated
- [ ] README updated
- [ ] All breaking changes documented

### Phase 3: Stable Release (v3.0.0)

**Audience**: All users

**Goals**:
- Production-ready release
- Full documentation
- Clean v3 architecture

**Duration**: Ongoing

**Checklist**:
- [ ] All beta feedback addressed
- [ ] Full documentation published
- [ ] Release notes published
- [ ] GitHub release created
- [ ] pub.dev published

---

## Maintenance & Future Work

### Post-Release Support

**v3.0.x Patches**:
- Bug fixes for path inference
- Performance optimizations
- Additional validation
- Community-reported issues

### Future Enhancements (v3.1+)

**Potential Features**:
- [ ] Custom path mapping rules (config file)
- [ ] Multi-project support (monorepos)
- [ ] Report export formats (HTML, PDF)
- [ ] Dashboard visualization
- [ ] CI/CD integrations
- [ ] Slack/Discord notifications

**Not in Scope for v3.0**:
- Custom report templates
- Cloud storage integration
- Real-time monitoring
- GraphQL API

---

## Conclusion

This re-engineering effort addresses fundamental architectural flaws in test_reporter v2.x by:

1. **Centralizing path logic** → PathResolver utility
2. **Standardizing naming** → ModuleIdentifier utility
3. **Unifying report management** → ReportManager utility
4. **Simplifying UX** → Auto-path detection, consistent CLI
5. **Improving maintainability** → Removing 200+ lines of duplicate code

**Expected Outcomes**:
- ✅ Better user experience (auto-detection)
- ✅ More maintainable codebase (DRY principles)
- ✅ Consistent behavior across tools
- ✅ Clearer error messages and validation
- ✅ Foundation for future enhancements

**Timeline**: 16-21 hours over 2-3 weeks

**Risk Level**: Medium (breaking changes, but well-mitigated)

**Recommendation**: Proceed with phased rollout (alpha → beta → stable)

---

**Document Version**: 1.0
**Status**: Approved for Implementation
**Next Steps**: Create feature branch, begin Phase 1 (PathResolver)
