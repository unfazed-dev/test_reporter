# Test Analyzer

Comprehensive Flutter/Dart test analysis toolkit with coverage analysis, flaky test detection, and unified reporting.

## Features

- ✅ **Coverage Analysis** - Line & branch coverage with incremental git diff support
- ✅ **Test Analysis** - Flaky test detection, performance profiling, pattern recognition
- ✅ **Failed Test Extraction** - Smart extraction and batch rerun commands
- ✅ **Beautiful CLI** - Colored output, progress indicators, tables
- ✅ **Watch Mode** - Continuous monitoring with auto-rerun

## Installation

### From Git Repository
```yaml
dev_dependencies:
  test_analyzer:
    git:
      url: https://github.com/unfazed-dev/test_analyzer.git
```

### Local Development
```yaml
dev_dependencies:
  test_analyzer:
    path: ../packages/test_analyzer
```

## Usage

### Individual Tools

#### Coverage Analysis
```bash
dart run test_analyzer:coverage-tool lib/src/features
dart run test_analyzer:coverage-tool lib/src/features --min-coverage 95
```

#### Test Analysis
```bash
dart run test_analyzer:test-analyzer test/features
dart run test_analyzer:test-analyzer test/features --performance
```

#### Failed Test Extraction
```bash
dart run test_analyzer:failed-test-extractor
```

### Output

Reports are automatically created in `test_analyzer_reports/` directory in your project root.

**Example:** `test_analyzer_reports/src_features_test_report@1821_281025.md`

**Note:** The `test_analyzer_reports/` directory is automatically created in your project root if it doesn't exist.

## CI/CD Integration

Add to `.gitignore` (optional, if you don't want to commit reports):
```gitignore
# Test analyzer reports (optional - can commit for history)
test_analyzer_reports/
```

## Development

```bash
# Install dependencies
dart pub get

# Run tests
dart test

# Format code
dart format .

# Analyze
dart analyze
```

## License

MIT License - see [LICENSE](LICENSE) file
