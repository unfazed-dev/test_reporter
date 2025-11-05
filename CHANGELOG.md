# Changelog

All notable changes to the test_reporter package will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.0.0] - 2025-11-05

### Added - Phase 3 Enhancements

#### CLI Flags (Phase 3.1)
- **--test-path**: Explicit test path override for all tools
- **--source-path**: Explicit source path override (alias for --lib in coverage tool)
- **--module-name**: Override module name for report generation across all tools
- Consistent flag support across all 4 CLI tools (analyze_coverage, analyze_tests, analyze_suite, extract_failures)

#### Input Validation (Phase 3.2)
- Path validation on all 4 tools with existence checks
- Clear error messages showing which paths exist/don't exist
- Helpful usage examples displayed on validation failures
- Exit code 2 for validation errors (distinguishes from test failures)

#### ReportRegistry System (Phase 3.3)
- **ReportRegistry** class for tracking all generated reports across tools
- Cross-tool report discovery and querying capabilities
- Filter reports by toolName, reportType, or moduleName
- printSummary() method for report overview
- 11 comprehensive unit tests with 100% TDD methodology
- Exported in main library (package:test_reporter/test_reporter.dart)

### Changed - Phase 1 & 2 Architecture

#### Foundation Utilities (Phase 1)
- **PathResolver**: Centralized bidirectional path inference (test to source and back)
- **ModuleIdentifier**: Consistent qualified module naming (name-fo/fi/pr format)
- **ReportManager**: Unified report generation and cleanup across tools

#### Tool Refactoring (Phase 2)
- All 4 tools refactored to use new utilities
- Removed 170 lines of duplicate code (79% reduction)
- Consistent module naming convention across all reports
- Centralized path resolution eliminates bugs

### Breaking Changes

- Module names in reports now follow qualified format: {module}-{fo|fi|pr}
  - -fo: folder analysis
  - -fi: file analysis
  - -pr: project-wide analysis
- Report naming convention changed to include module qualifiers
- Path inference now uses PathResolver (may behave differently in edge cases)

### Fixed

- Path resolution consistency across all tools
- Module naming conflicts between tools
- Duplicate code maintenance burden

### Testing

- Added 11 ReportRegistry unit tests (100% passing)
- Total unit tests: 313 passing
- Meta-tested all 4 tools on test_reporter itself
- Validated error messages with invalid paths
- Zero analyzer issues

---

## [2.0.0] - 2024

### Added
- Coverage analysis with branch coverage support
- Flaky test detection with multiple test runs
- Performance profiling and slow test detection
- Failed test extraction and rerun capabilities
- Unified reporting system
- Modern Dart 3+ features (sealed classes, records)

---

## [1.0.0] - Initial Release

- Basic test analysis capabilities
- Simple coverage reporting
- Test failure extraction
