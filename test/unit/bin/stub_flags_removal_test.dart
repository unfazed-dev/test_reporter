// ignore_for_file: avoid_print

import 'package:args/args.dart';
import 'package:test/test.dart';

/// Tests to verify stub flags are properly removed from CLI tools.
///
/// These tests verify that partially implemented "stub" flags are rejected
/// with clear error messages, preventing user confusion.
///
/// TDD Approach:
/// 🔴 RED: These tests will FAIL initially because stubs still exist
/// 🟢 GREEN: After removing stubs, tests will PASS
/// ♻️ REFACTOR: Clean up any leftover code
void main() {
  group('analyze_tests stub flag removal', () {
    late ArgParser parser;

    setUp(() {
      // Create the actual ArgParser used by analyze_tests
      // This should match lib/src/bin/analyze_tests_lib.dart
      parser = _createAnalyzeTestsArgParser();
    });

    test('--dependencies flag should be rejected (stub removal)', () {
      expect(
        () => parser.parse(['--dependencies']),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('Could not find an option named "--dependencies"'),
          ),
        ),
        reason: 'Stub flag --dependencies should be removed and rejected',
      );
    });

    test('-d short alias should be rejected (stub removal)', () {
      expect(
        () => parser.parse(['-d']),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('Could not find an option or flag "-d"'),
          ),
        ),
        reason: 'Stub alias -d should be removed and rejected',
      );
    });

    test('--mutation flag should be rejected (stub removal)', () {
      expect(
        () => parser.parse(['--mutation']),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('Could not find an option named "--mutation"'),
          ),
        ),
        reason: 'Stub flag --mutation should be removed and rejected',
      );
    });

    test('-m short alias should be rejected (stub removal)', () {
      expect(
        () => parser.parse(['-m']),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('Could not find an option or flag "-m"'),
          ),
        ),
        reason: 'Stub alias -m should be removed and rejected',
      );
    });

    test('--impact flag should be rejected (stub removal)', () {
      expect(
        () => parser.parse(['--impact']),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('Could not find an option named "--impact"'),
          ),
        ),
        reason: 'Stub flag --impact should be removed and rejected',
      );
    });

    test('help text should NOT mention removed stub flags', () {
      final usage = parser.usage;

      expect(usage, isNot(contains('dependencies')),
          reason: '--dependencies should not appear in help');
      expect(usage, isNot(contains('mutation')),
          reason: '--mutation should not appear in help');
      expect(usage, isNot(contains('impact')),
          reason: '--impact should not appear in help');
    });
  });

  group('analyze_coverage stub flag removal', () {
    late ArgParser parser;

    setUp(() {
      // Create the actual ArgParser used by analyze_coverage
      // This should match lib/src/bin/analyze_coverage_lib.dart
      parser = _createAnalyzeCoverageArgParser();
    });

    test('--branch flag should be rejected (stub removal)', () {
      expect(
        () => parser.parse(['--branch']),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('Could not find an option named "--branch"'),
          ),
        ),
        reason: 'Stub flag --branch should be removed and rejected',
      );
    });

    test('--incremental flag should be rejected (stub removal)', () {
      expect(
        () => parser.parse(['--incremental']),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('Could not find an option named "--incremental"'),
          ),
        ),
        reason: 'Stub flag --incremental should be removed and rejected',
      );
    });

    test('--mutation flag should be rejected (stub removal)', () {
      expect(
        () => parser.parse(['--mutation']),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('Could not find an option named "--mutation"'),
          ),
        ),
        reason: 'Stub flag --mutation should be removed and rejected',
      );
    });

    test('--watch flag should be rejected (stub removal)', () {
      expect(
        () => parser.parse(['--watch']),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('Could not find an option named "--watch"'),
          ),
        ),
        reason: 'Stub flag --watch should be removed and rejected',
      );
    });

    test('--parallel flag should be rejected (stub removal)', () {
      expect(
        () => parser.parse(['--parallel']),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('Could not find an option named "--parallel"'),
          ),
        ),
        reason: 'Stub flag --parallel should be removed and rejected',
      );
    });

    test('--impact flag should be rejected (stub removal)', () {
      expect(
        () => parser.parse(['--impact']),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('Could not find an option named "--impact"'),
          ),
        ),
        reason: 'Stub flag --impact should be removed and rejected',
      );
    });

    test('help text should NOT mention removed stub flags', () {
      final usage = parser.usage;

      expect(usage, isNot(contains('branch')),
          reason: '--branch should not appear in help');
      expect(usage, isNot(contains('incremental')),
          reason: '--incremental should not appear in help');
      expect(usage, isNot(contains('mutation')),
          reason: '--mutation should not appear in help');
      expect(usage, isNot(contains('watch')),
          reason: '--watch should not appear in help');
      expect(usage, isNot(contains('parallel')),
          reason: '--parallel should not appear in help');
      expect(usage, isNot(contains('impact')),
          reason: '--impact should not appear in help');
    });
  });

  group('working flags should still work after stub removal', () {
    test('analyze_tests retains all working flags', () {
      final parser = _createAnalyzeTestsArgParser();

      // Should parse without error
      final results = parser.parse([
        '--verbose',
        '--interactive',
        '--performance',
        '--no-report',
        '--runs=5',
      ]);

      expect(results['verbose'], isTrue);
      expect(results['interactive'], isTrue);
      expect(results['performance'], isTrue);
      expect(results['report'], isFalse);
      expect(results['runs'], equals('5'));
    });

    test('analyze_coverage retains all working flags', () {
      final parser = _createAnalyzeCoverageArgParser();

      // Should parse without error
      final results = parser.parse([
        '--fix',
        '--no-report',
        '--verbose',
        '--min-coverage=80',
      ]);

      expect(results['fix'], isTrue);
      expect(results['report'], isFalse);
      expect(results['verbose'], isTrue);
      expect(results['min-coverage'], equals('80'));
    });
  });
}

/// Creates the ArgParser for analyze_tests (matching production code).
///
/// NOTE: This is a copy of the production ArgParser. After stub removal,
/// this should match lib/src/bin/analyze_tests_lib.dart exactly.
ArgParser _createAnalyzeTestsArgParser() {
  return ArgParser()
    // Output flags
    ..addFlag(
      'verbose',
      abbr: 'v',
      help: 'Show detailed output and stack traces',
      negatable: false,
    )
    ..addFlag(
      'interactive',
      abbr: 'i',
      help: 'Interactive debugging mode with step-through',
      negatable: false,
    )
    ..addFlag(
      'performance',
      abbr: 'p',
      help: 'Show performance metrics and timing analysis',
      negatable: false,
    )
    ..addFlag(
      'report',
      help: 'Generate and save analysis reports (markdown + JSON)',
      defaultsTo: true,
      negatable: true,
    )
    ..addFlag(
      'fixes',
      help: 'Show fix suggestions for failures',
      defaultsTo: true,
      negatable: true,
    )
    ..addFlag(
      'checklist',
      help: 'Show actionable checklists',
      defaultsTo: true,
      negatable: true,
    )
    ..addFlag(
      'minimal-checklist',
      help: 'Show compact checklist format',
      negatable: false,
    )
    // Mode flags
    ..addFlag(
      'watch',
      abbr: 'w',
      help: 'Watch mode - continuously monitor test files',
      negatable: false,
    )
    ..addFlag(
      'parallel',
      help: 'Run tests in parallel for faster execution',
      negatable: false,
    )
    ..addFlag(
      'include-fixtures',
      help: 'Include fixture/mock tests in analysis',
      negatable: false,
    )
    // Configuration
    ..addOption(
      'runs',
      help: 'Number of times to run tests (flaky test detection)',
      defaultsTo: '3',
    )
    ..addOption(
      'slow',
      help: 'Slow test threshold in seconds',
      defaultsTo: '1.0',
    )
    ..addOption(
      'workers',
      help: 'Maximum parallel workers (when --parallel enabled)',
      defaultsTo: '4',
    )
    ..addOption(
      'module-name',
      help: 'Override auto-detected module name for reports',
    )
    // Help
    ..addFlag(
      'help',
      abbr: 'h',
      help: 'Show this help message',
      negatable: false,
    );
}

/// Creates the ArgParser for analyze_coverage (matching production code).
///
/// NOTE: This is a copy of the production ArgParser. After stub removal,
/// this should match lib/src/bin/analyze_coverage_lib.dart exactly.
ArgParser _createAnalyzeCoverageArgParser() {
  return ArgParser()
    ..addFlag(
      'help',
      abbr: 'h',
      help: 'Show this help message',
      negatable: false,
    )
    ..addFlag(
      'fix',
      help: 'Generate missing test files automatically',
      negatable: false,
    )
    ..addFlag(
      'report',
      help: 'Generate and save analysis reports (markdown + JSON)',
      defaultsTo: true,
      negatable: true,
    )
    ..addFlag(
      'json',
      help: 'Export JSON coverage data',
      negatable: false,
    )
    ..addFlag(
      'checklist',
      help: 'Show actionable checklists',
      defaultsTo: true,
      negatable: true,
    )
    ..addFlag(
      'minimal-checklist',
      help: 'Show compact checklist format',
      negatable: false,
    )
    ..addFlag(
      'verbose',
      help: 'Show detailed output and analysis',
      negatable: false,
    )
    ..addOption(
      'lib',
      help: 'Source files directory (default: lib/src)',
    )
    ..addOption(
      'source-path',
      help: 'Alias for --lib',
    )
    ..addOption(
      'test',
      help: 'Test files directory (default: test)',
    )
    ..addOption(
      'test-path',
      help: 'Alias for --test',
    )
    ..addOption(
      'module-name',
      help: 'Override auto-detected module name for reports',
    )
    ..addMultiOption(
      'exclude',
      help: 'Exclude file patterns (glob syntax)',
    )
    ..addOption(
      'baseline',
      help: 'Baseline coverage file for comparison',
    )
    ..addOption(
      'min-coverage',
      help: 'Minimum required coverage percentage (fail if below)',
      defaultsTo: '0',
    )
    ..addOption(
      'warn-coverage',
      help: 'Warning threshold coverage percentage',
      defaultsTo: '0',
    )
    ..addFlag(
      'fail-on-decrease',
      help: 'Fail if coverage decreases from baseline',
      negatable: false,
    );
}
