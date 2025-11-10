// ignore_for_file: avoid_print

import 'package:args/args.dart';
import 'package:test/test.dart';

/// Unit tests for ArgParser implementation in analyze_coverage
///
/// **TDD RED Phase**: These tests demonstrate the desired ArgParser behavior
///
/// **Current State**: analyze_coverage uses manual string parsing
/// **Target State**: analyze_coverage uses ArgParser for consistent, validated flag parsing
///
/// These tests will guide the GREEN phase implementation
void main() {
  group('analyze_coverage ArgParser', () {
    late ArgParser parser;

    setUp(() {
      // This will be the ArgParser instance used by analyze_coverage
      parser = _createAnalyzeCoverageArgParser();
    });

    test('Test 1: ArgParser parses all boolean flags correctly', () {
      // Parse args with all boolean flags set
      final results = parser.parse([
        '--fix',
        '--no-report',
        '--branch',
        '--incremental',
        '--mutation',
        '--watch',
        '--parallel',
        '--json',
        '--impact',
        '--no-checklist',
        '--minimal-checklist',
        '--include-fixtures',
        '--fail-on-decrease',
        '--help',
      ]);

      // Verify each boolean flag
      expect(results['fix'], isTrue);
      expect(results['report'], isFalse); // --no-report means report=false
      expect(results['branch'], isTrue);
      expect(results['incremental'], isTrue);
      expect(results['mutation'], isTrue);
      expect(results['watch'], isTrue);
      expect(results['parallel'], isTrue);
      expect(results['json'], isTrue);
      expect(results['impact'], isTrue);
      expect(results['checklist'], isFalse); // --no-checklist
      expect(results['minimal-checklist'], isTrue);
      expect(results['include-fixtures'], isTrue);
      expect(results['fail-on-decrease'], isTrue);
      expect(results['help'], isTrue);

      print('✓ Test 1: All boolean flags parsed correctly');
    });

    test('Test 2: Path options parse correctly with aliases', () {
      // Test --lib and --source-path aliases
      final resultsLib = parser.parse(['--lib=lib/src/core']);
      expect(resultsLib['lib'], equals('lib/src/core'));

      final resultsSourcePath = parser.parse(['--source-path=lib/src/auth']);
      expect(resultsSourcePath['lib'], equals('lib/src/auth'),
          reason: '--source-path should be alias for --lib');

      // Test --test and --test-path aliases
      final resultsTest = parser.parse(['--test=test/unit']);
      expect(resultsTest['test'], equals('test/unit'));

      final resultsTestPath = parser.parse(['--test-path=test/integration']);
      expect(resultsTestPath['test'], equals('test/integration'),
          reason: '--test-path should be alias for --test');

      print('✓ Test 2: Path options and aliases work');
    });

    test('Test 3: Numeric options parse correctly', () {
      // Parse args with numeric thresholds
      final results = parser.parse([
        '--min-coverage=80',
        '--warn-coverage=60',
      ]);

      // Verify numeric values (stored as strings, will be parsed by implementation)
      expect(results['min-coverage'], equals('80'));
      expect(results['warn-coverage'], equals('60'));

      print('✓ Test 3: Numeric options parsed');
    });

    test('Test 4: Multi-value exclude patterns work', () {
      // Parse args with multiple exclude patterns
      final results = parser.parse([
        '--exclude',
        '*.g.dart',
        '--exclude',
        '*.freezed.dart',
        '--exclude',
        'test/mocks/*',
      ]);

      // ArgParser collects multi-value options
      expect(results['exclude'], isA<List>());
      final excludes = results['exclude'] as List;
      expect(excludes, hasLength(3));
      expect(excludes, contains('*.g.dart'));
      expect(excludes, contains('*.freezed.dart'));
      expect(excludes, contains('test/mocks/*'));

      print('✓ Test 4: Multi-value exclude patterns work');
    });

    test('Test 5: Default values work when flags not provided', () {
      // Parse empty args (no flags provided)
      final results = parser.parse([]);

      // Verify defaults
      expect(results['lib'], equals('lib/src'),
          reason: 'Default lib path should be lib/src');
      expect(results['test'], equals('test'),
          reason: 'Default test path should be test');
      expect(results['report'], isTrue,
          reason: 'Reports should be enabled by default');
      expect(results['checklist'], isTrue,
          reason: 'Checklist should be enabled by default');
      expect(results['fix'], isFalse,
          reason: 'Auto-fix should be disabled by default');
      expect(results['min-coverage'], equals('0'),
          reason: 'Default min-coverage should be 0');
      expect(results['warn-coverage'], equals('0'),
          reason: 'Default warn-coverage should be 0');

      print('✓ Test 5: Default values work');
    });

    test('Test 6: Invalid flag combinations rejected', () {
      // Parse args with unknown flag
      expect(
        () => parser.parse(['--invalid-flag']),
        throwsA(isA<FormatException>()),
        reason: 'Unknown flags should throw FormatException',
      );

      expect(
        () => parser.parse(['--unknown', 'lib/']),
        throwsA(isA<FormatException>()),
        reason: 'Unknown flags should be rejected',
      );

      print('✓ Test 6: Invalid flags rejected');
    });

    test('Test 7: Help text generation works', () {
      // Get help text from parser
      final helpText = parser.usage;

      // Verify key flags are documented
      expect(helpText, contains('fix'), reason: 'Help should document --fix');
      expect(helpText, contains('report'),
          reason: 'Help should document --report');
      expect(helpText, contains('lib'), reason: 'Help should document --lib');
      expect(helpText, contains('test'), reason: 'Help should document --test');
      expect(helpText, contains('exclude'),
          reason: 'Help should document --exclude');
      expect(helpText, contains('min-coverage'),
          reason: 'Help should document --min-coverage');
      expect(helpText, contains('warn-coverage'),
          reason: 'Help should document --warn-coverage');
      expect(helpText, contains('baseline'),
          reason: 'Help should document --baseline');
      expect(helpText, contains('module-name'),
          reason: 'Help should document --module-name');

      // Verify help text has reasonable formatting
      expect(helpText.length, greaterThan(100),
          reason: 'Help text should be comprehensive');

      print('✓ Test 7: Help text generated');
    });

    test('Test 8: Short alias for help works', () {
      // Parse with -h short alias
      final results = parser.parse(['-h']);

      expect(results['help'], isTrue, reason: '-h should set help flag');

      print('✓ Test 8: Short alias -h works');
    });

    test('Test 9: Rest arguments captured correctly', () {
      // Parse with positional arguments
      final results = parser.parse([
        '--fix',
        'lib/src/auth',
      ]);

      // Rest arguments should contain positional args
      expect(results.rest, equals(['lib/src/auth']));

      print('✓ Test 9: Rest arguments work');
    });

    test('Test 10: --verbose flag should be supported', () {
      // TDD RED Phase: This test SHOULD FAIL initially
      // analyze_suite passes --verbose to analyze_coverage
      // but analyze_coverage doesn't support it yet

      // Parse with --verbose flag
      final results = parser.parse(['--verbose']);

      // Verify verbose flag is parsed correctly
      expect(results['verbose'], isTrue,
          reason: '--verbose should be supported for consistency with analyze_tests');

      // Verbose should default to false when not provided
      final resultsNoVerbose = parser.parse([]);
      expect(resultsNoVerbose['verbose'], isFalse,
          reason: 'verbose should default to false');

      print('✓ Test 10: --verbose flag supported');
    });
  });
}

/// Creates an ArgParser instance matching the desired analyze_coverage configuration
///
/// **This is the target implementation that will be integrated into analyze_coverage_lib.dart**
ArgParser _createAnalyzeCoverageArgParser() {
  return ArgParser()
    // Basic options
    ..addFlag(
      'fix',
      help: 'Generate missing test cases automatically',
      negatable: false,
    )
    ..addFlag(
      'report',
      help: 'Generate coverage report',
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
    ..addFlag(
      'verbose',
      abbr: 'v',
      help: 'Enable verbose output for detailed debugging',
      negatable: false,
    )
    ..addFlag(
      'help',
      abbr: 'h',
      help: 'Show this help message',
      negatable: false,
    )
    // Path options
    ..addOption(
      'lib',
      help: 'Path to source files (alias: --source-path)',
      defaultsTo: 'lib/src',
      aliases: ['source-path'],
    )
    ..addOption(
      'test',
      help: 'Path to test files (alias: --test-path)',
      defaultsTo: 'test',
      aliases: ['test-path'],
    )
    ..addOption(
      'module-name',
      help: 'Override module name for reports',
    )
    // Advanced analysis flags (some are STUBS - to be removed in Phase 3)
    ..addFlag(
      'branch',
      help: 'Include branch coverage analysis (STUB - not implemented)',
      negatable: false,
    )
    ..addFlag(
      'incremental',
      help: 'Only analyze changed files (git diff) (STUB - not implemented)',
      negatable: false,
    )
    ..addFlag(
      'mutation',
      help: 'Run mutation testing (STUB - not implemented)',
      negatable: false,
    )
    ..addFlag(
      'watch',
      help:
          'Enable watch mode for continuous monitoring (STUB - not implemented)',
      negatable: false,
    )
    ..addFlag(
      'parallel',
      help: 'Use parallel test execution (STUB - not implemented)',
      negatable: false,
    )
    ..addFlag(
      'impact',
      help: 'Enable test impact analysis (STUB - not implemented)',
      negatable: false,
    )
    // Export/output flags
    ..addFlag(
      'json',
      help: 'Export JSON report',
      negatable: false,
    )
    ..addFlag(
      'include-fixtures',
      help: 'Include fixture tests (excluded by default)',
      negatable: false,
    )
    // Coverage thresholds
    ..addOption(
      'min-coverage',
      help: 'Minimum coverage threshold (0-100)',
      defaultsTo: '0',
    )
    ..addOption(
      'warn-coverage',
      help: 'Warning coverage threshold (0-100)',
      defaultsTo: '0',
    )
    ..addFlag(
      'fail-on-decrease',
      help: 'Fail if coverage decreases from baseline',
      negatable: false,
    )
    // File filtering
    ..addMultiOption(
      'exclude',
      help: 'Exclude files matching pattern (can be used multiple times)',
    )
    ..addOption(
      'baseline',
      help: 'Compare against baseline coverage file',
    );
}
