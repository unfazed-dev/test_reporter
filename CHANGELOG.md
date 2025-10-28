# Changelog

## [2.0.0] - 2025-01-28

### Added
- Standalone package structure for reusability across projects
- Shared utilities library (formatting, path, report utilities)
- Modern Dart 3.x patterns support
- Enhanced CLI output with colors and progress indicators

### Changed
- **BREAKING:** Moved to standalone package structure
- **BREAKING:** Reports now save to `test_analyzer_reports/` in project root
- Improved error handling throughout
- Better code organization with utilities extraction

### Removed
- Badge generation feature (no longer needed)
- Reduced code duplication (~800 lines) via shared utilities

## [1.0.0] - Previous version embedded in Kinly
