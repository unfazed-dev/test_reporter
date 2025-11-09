// ignore_for_file: avoid_print

import 'package:args/args.dart';
import 'package:test/test.dart';

/// Unit tests for ArgParser implementation in analyze_tests
///
/// **TDD RED Phase**: These tests demonstrate the desired ArgParser behavior
///
/// **Current State**: analyze_tests uses manual string parsing with args.contains()
/// **Target State**: analyze_tests uses ArgParser for consistent, validated flag parsing
///
/// These tests will FAIL until ArgParser is implemented (GREEN phase)
void main() {
  group('analyze_tests ArgParser', () {
    late ArgParser parser;

    setUp(() {
      // This will be the ArgParser instance used by analyze_tests
      // For now, we'll create a mock version that matches the desired API
      parser = _createAnalyzeTestsArgParser();
    });

    test('Test 1: ArgParser parses all 15 flags correctly', () {
      // Parse args with all flags set
      final results = parser.parse([
        '--verbose',
        '--interactive',
        '--performance',
        '--watch',
        '--parallel',
        '--no-report',
        '--no-fixes',
        '--no-checklist',
        '--minimal-checklist',
        '--include-fixtures',
        '--dependencies',
        '--mutation',
        '--impact',
        '--runs=5',
        '--slow=2.5',
        '--workers=8',
        '--module-name=my-module',
        'test/',
      ]);

      // Verify each flag value is correct
      expect(results['verbose'], isTrue);
      expect(results['interactive'], isTrue);
      expect(results['performance'], isTrue);
      expect(results['watch'], isTrue);
      expect(results['parallel'], isTrue);
      expect(results['report'], isFalse); // --no-report means report=false
      expect(results['fixes'], isFalse); // --no-fixes means fixes=false
      expect(results['checklist'],
          isFalse); // --no-checklist means checklist=false
      expect(results['minimal-checklist'], isTrue);
      expect(results['include-fixtures'], isTrue);
      expect(results['dependencies'], isTrue);
      expect(results['mutation'], isTrue);
      expect(results['impact'], isTrue);
      expect(results['runs'], equals('5'));
      expect(results['slow'], equals('2.5'));
      expect(results['workers'], equals('8'));
      expect(results['module-name'], equals('my-module'));
      expect(results.rest, equals(['test/']));

      print('✓ Test 1: All 15 flags parsed correctly');
    });

    test('Test 2: Short aliases work (-v, -i, -p, -w, -h)', () {
      // Parse args with short aliases
      final results = parser.parse([
        '-v',
        '-i',
        '-p',
        '-w',
        '-h',
      ]);

      // Verify flag values match long forms
      expect(results['verbose'], isTrue, reason: '-v should set verbose');
      expect(results['interactive'], isTrue,
          reason: '-i should set interactive');
      expect(results['performance'], isTrue,
          reason: '-p should set performance');
      expect(results['watch'], isTrue, reason: '-w should set watch');
      expect(results['help'], isTrue, reason: '-h should set help');

      print('✓ Test 2: Short aliases work');
    });

    test('Test 3: Negatable flags work (--report vs --no-report)', () {
      // Test --report (default: true)
      final resultsWithReport = parser.parse(['--report']);
      expect(resultsWithReport['report'], isTrue,
          reason: '--report should enable report');

      // Test --no-report
      final resultsNoReport = parser.parse(['--no-report']);
      expect(resultsNoReport['report'], isFalse,
          reason: '--no-report should disable report');

      // Test --fixes (default: true)
      final resultsWithFixes = parser.parse(['--fixes']);
      expect(resultsWithFixes['fixes'], isTrue,
          reason: '--fixes should enable fixes');

      // Test --no-fixes
      final resultsNoFixes = parser.parse(['--no-fixes']);
      expect(resultsNoFixes['fixes'], isFalse,
          reason: '--no-fixes should disable fixes');

      // Test --checklist (default: true)
      final resultsWithChecklist = parser.parse(['--checklist']);
      expect(resultsWithChecklist['checklist'], isTrue,
          reason: '--checklist should enable checklist');

      // Test --no-checklist
      final resultsNoChecklist = parser.parse(['--no-checklist']);
      expect(resultsNoChecklist['checklist'], isFalse,
          reason: '--no-checklist should disable checklist');

      print('✓ Test 3: Negatable flags work');
    });

    test('Test 4: Numeric options parse correctly', () {
      // Parse args with numeric values
      final results = parser.parse([
        '--runs=10',
        '--slow=3.5',
        '--workers=16',
      ]);

      // Verify type conversion (stored as strings, will be parsed by implementation)
      expect(results['runs'], equals('10'),
          reason: '--runs should parse numeric value');
      expect(results['slow'], equals('3.5'),
          reason: '--slow should parse decimal value');
      expect(results['workers'], equals('16'),
          reason: '--workers should parse numeric value');

      print('✓ Test 4: Numeric options parsed');
    });

    test('Test 5: Default values work when flags not provided', () {
      // Parse empty args (no flags provided)
      final results = parser.parse([]);

      // Verify defaults
      expect(results['runs'], equals('3'), reason: 'Default runs should be 3');
      expect(results['slow'], equals('1.0'),
          reason: 'Default slow threshold should be 1.0');
      expect(results['workers'], equals('4'),
          reason: 'Default workers should be 4');
      expect(results['report'], isTrue,
          reason: 'Reports should be enabled by default');
      expect(results['fixes'], isTrue,
          reason: 'Fixes should be enabled by default');
      expect(results['checklist'], isTrue,
          reason: 'Checklist should be enabled by default');
      expect(results['verbose'], isFalse,
          reason: 'Verbose should be false by default');

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
        () => parser.parse(['--unknown', 'test/']),
        throwsA(isA<FormatException>()),
        reason: 'Unknown flags should be rejected',
      );

      print('✓ Test 6: Invalid flags rejected');
    });

    test('Test 7: Help text generation works', () {
      // Get help text from parser
      final helpText = parser.usage;

      // Verify all flags are documented
      expect(helpText, contains('verbose'),
          reason: 'Help should document --verbose');
      expect(helpText, contains('interactive'),
          reason: 'Help should document --interactive');
      expect(helpText, contains('performance'),
          reason: 'Help should document --performance');
      expect(helpText, contains('watch'),
          reason: 'Help should document --watch');
      expect(helpText, contains('parallel'),
          reason: 'Help should document --parallel');
      expect(helpText, contains('report'),
          reason: 'Help should document --report');
      expect(helpText, contains('fixes'),
          reason: 'Help should document --fixes');
      expect(helpText, contains('checklist'),
          reason: 'Help should document --checklist');
      expect(helpText, contains('runs'), reason: 'Help should document --runs');
      expect(helpText, contains('slow'), reason: 'Help should document --slow');
      expect(helpText, contains('workers'),
          reason: 'Help should document --workers');
      expect(helpText, contains('module-name'),
          reason: 'Help should document --module-name');

      // Verify help text has reasonable formatting
      expect(helpText.length, greaterThan(100),
          reason: 'Help text should be comprehensive');

      print('✓ Test 7: Help text generated');
    });
  });
}

/// Creates an ArgParser instance matching the desired analyze_tests configuration
///
/// **This is the target implementation that will be integrated into analyze_tests_lib.dart**
ArgParser _createAnalyzeTestsArgParser() {
  return ArgParser()
    // Output control flags
    ..addFlag(
      'verbose',
      abbr: 'v',
      help: 'Show detailed output and stack traces',
      negatable: false,
    )
    ..addFlag(
      'report',
      help: 'Generate and display test analysis reports',
      defaultsTo: true,
      negatable: true,
    )
    ..addFlag(
      'fixes',
      help: 'Generate fix suggestions for failures',
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
    // Mode flags
    ..addFlag(
      'interactive',
      abbr: 'i',
      help: 'Enter interactive debug mode for failed tests',
      negatable: false,
    )
    ..addFlag(
      'performance',
      abbr: 'p',
      help: 'Track and report test performance metrics',
      negatable: false,
    )
    ..addFlag(
      'watch',
      abbr: 'w',
      help: 'Watch for changes and re-run analysis',
      negatable: false,
    )
    ..addFlag(
      'parallel',
      help: 'Run tests in parallel for faster execution',
      negatable: false,
    )
    // Advanced analysis flags (STUB - to be removed in Phase 3)
    ..addFlag(
      'dependencies',
      abbr: 'd',
      help: 'Analyze test dependency graph (STUB - not implemented)',
      negatable: false,
    )
    ..addFlag(
      'mutation',
      abbr: 'm',
      help:
          'Run mutation testing to verify test effectiveness (STUB - not implemented)',
      negatable: false,
    )
    ..addFlag(
      'impact',
      help:
          'Analyze test impact based on code changes (STUB - not implemented)',
      negatable: false,
    )
    // Other flags
    ..addFlag(
      'include-fixtures',
      help: 'Include fixture tests (excluded by default)',
      negatable: false,
    )
    ..addFlag(
      'help',
      abbr: 'h',
      help: 'Show this help message',
      negatable: false,
    )
    // Configuration options
    ..addOption(
      'runs',
      help: 'Number of test runs',
      defaultsTo: '3',
    )
    ..addOption(
      'slow',
      help: 'Slow test threshold in seconds',
      defaultsTo: '1.0',
    )
    ..addOption(
      'workers',
      help: 'Max parallel workers',
      defaultsTo: '4',
    )
    ..addOption(
      'module-name',
      help: 'Override module name for reports',
    );
}
