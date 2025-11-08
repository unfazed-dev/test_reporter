// test/integration/bin/test_analyzer_patterns_test.dart
import 'package:test/test.dart';
import 'package:test_reporter/src/bin/analyze_tests_lib.dart';

/// Phase 3.2: Failure Pattern Detection Tests (Simplified for TDD)
///
/// Tests verify failure pattern detection and smart suggestion generation.
/// Similar to Phase 3.1, we test the core logic directly without full mocks.
///
/// Test Coverage:
/// - Pattern Detection: 12 tests (assertion, null, timeout, range, type, I/O, network, unknown, etc.)
/// - Smart Suggestions: 8 tests (context-aware suggestions, code snippets, actionable fixes)
/// Total: 20 tests
///
/// Methodology: 🔴🟢♻️🔄 TDD (Red-Green-Refactor-MetaTest)
void main() {
  group('Suite 1: Pattern Detection Tests', () {
    test('should detect assertion failures from test output', () {
      final analyzer = TestAnalyzer();
      const output = '''
Expected: true
Actual: false
Expected user to be authenticated
''';

      // This will fail until we implement detectFailureType
      final failure = analyzer.detectFailureType(output);

      expect(failure, isNotNull);
      expect(failure.type, equals(FailurePatternType.assertion));
      expect(failure.errorMessage, contains('Expected'));
    });

    test('should detect null errors from test output', () {
      final analyzer = TestAnalyzer();
      const output = '''
NoSuchMethodError: The getter 'userName' was called on null.
Receiver: null
Tried calling: userName
at profile_service.dart:42
''';

      final failure = analyzer.detectFailureType(output);

      expect(failure, isNotNull);
      expect(failure.type, equals(FailurePatternType.nullError));
      expect(failure.details['variableName'], equals('userName'));
    });

    test('should detect timeout failures from test output', () {
      final analyzer = TestAnalyzer();
      const output = '''
Test timed out after 30 seconds
TimeoutException
at api_test.dart:100
''';

      final failure = analyzer.detectFailureType(output);

      expect(failure, isNotNull);
      expect(failure.type, equals(FailurePatternType.timeout));
      expect(failure.details['duration'], contains('30'));
    });

    test('should detect range errors from test output', () {
      final analyzer = TestAnalyzer();
      const output = '''
RangeError (index): Invalid value: Not in inclusive range 0..2: 5
at list_test.dart:50
''';

      final failure = analyzer.detectFailureType(output);

      expect(failure, isNotNull);
      expect(failure.type, equals(FailurePatternType.rangeError));
      expect(failure.details['index'], equals('5'));
    });

    test('should detect type errors from test output', () {
      final analyzer = TestAnalyzer();
      const output = '''
type 'int' is not a subtype of type 'String' in type cast
at type_test.dart:25
''';

      final failure = analyzer.detectFailureType(output);

      expect(failure, isNotNull);
      expect(failure.type, equals(FailurePatternType.typeError));
      expect(failure.details['expectedType'], equals('String'));
      expect(failure.details['actualType'], equals('int'));
    });

    test('should detect I/O errors from test output', () {
      final analyzer = TestAnalyzer();
      const output = '''
FileSystemException: Cannot open file
path = '/data/config.json'
at io_test.dart:30
''';

      final failure = analyzer.detectFailureType(output);

      expect(failure, isNotNull);
      expect(failure.type, equals(FailurePatternType.fileSystemError));
      expect(failure.details['path'], equals('/data/config.json'));
    });

    test('should detect network errors from test output', () {
      final analyzer = TestAnalyzer();
      const output = '''
SocketException: Failed host lookup: 'api.example.com'
at network_test.dart:15
''';

      final failure = analyzer.detectFailureType(output);

      expect(failure, isNotNull);
      expect(failure.type, equals(FailurePatternType.networkError));
      expect(failure.details['url'], contains('api.example.com'));
    });

    test('should detect unknown error types from test output', () {
      final analyzer = TestAnalyzer();
      const output = '''
CustomException: Something went wrong
at mysterious_test.dart:99
''';

      final failure = analyzer.detectFailureType(output);

      expect(failure, isNotNull);
      expect(failure.type, equals(FailurePatternType.unknown));
      expect(failure.errorMessage, contains('CustomException'));
    });

    test('should extract error messages from failures', () {
      final analyzer = TestAnalyzer();
      const output = '''
ValidationException: Validation failed: input does not match schema
Expected format: [a-zA-Z0-9]+
Actual value: test@123
''';

      final failure = analyzer.detectFailureType(output);

      expect(failure.errorMessage, isNotNull);
      expect(failure.errorMessage, contains('Validation failed'));
      expect(failure.errorMessage, contains('does not match schema'));
    });

    test('should extract stack traces from failures', () {
      final analyzer = TestAnalyzer();
      const output = '''
NoSuchMethodError: The method 'getData' was called on null
#0      Service.fetchData (service.dart:100:5)
#1      main.<anonymous closure> (test.dart:20:10)
#2      _Timer._runTimers (dart:isolate-patch/timer_impl.dart:398:19)
''';

      final failure = analyzer.detectFailureType(output);

      expect(failure.stackTrace, isNotNull);
      expect(failure.stackTrace, contains('service.dart:100'));
      expect(failure.stackTrace, contains('test.dart:20'));
    });

    test('should count pattern occurrences using FailurePattern class', () {
      final analyzer = TestAnalyzer();

      // Add some failures to the analyzer's detected patterns
      analyzer.addDetectedFailure(
        type: FailurePatternType.nullError,
        testName: 'test 1',
        errorMessage: 'Null error 1',
      );
      analyzer.addDetectedFailure(
        type: FailurePatternType.nullError,
        testName: 'test 2',
        errorMessage: 'Null error 2',
      );
      analyzer.addDetectedFailure(
        type: FailurePatternType.nullError,
        testName: 'test 3',
        errorMessage: 'Null error 3',
      );

      final patterns = analyzer.detectedPatterns;

      expect(patterns, isNotEmpty);
      final nullPattern = patterns.firstWhere(
        (p) => p.type == FailurePatternType.nullError,
      );
      expect(nullPattern.count, equals(3));
      expect(nullPattern.testNames, hasLength(3));
    });

    test('should rank patterns by frequency', () {
      final analyzer = TestAnalyzer();

      // Add multiple patterns with different frequencies
      // 3 null errors
      analyzer.addDetectedFailure(
        type: FailurePatternType.nullError,
        testName: 'null test 1',
        errorMessage: 'Null 1',
      );
      analyzer.addDetectedFailure(
        type: FailurePatternType.nullError,
        testName: 'null test 2',
        errorMessage: 'Null 2',
      );
      analyzer.addDetectedFailure(
        type: FailurePatternType.nullError,
        testName: 'null test 3',
        errorMessage: 'Null 3',
      );

      // 2 timeouts
      analyzer.addDetectedFailure(
        type: FailurePatternType.timeout,
        testName: 'timeout test 1',
        errorMessage: 'Timeout 1',
      );
      analyzer.addDetectedFailure(
        type: FailurePatternType.timeout,
        testName: 'timeout test 2',
        errorMessage: 'Timeout 2',
      );

      // 1 assertion
      analyzer.addDetectedFailure(
        type: FailurePatternType.assertion,
        testName: 'assertion test',
        errorMessage: 'Assertion failed',
      );

      final rankedPatterns = analyzer.getRankedPatterns();

      expect(rankedPatterns, hasLength(3));
      expect(rankedPatterns[0].type, equals(FailurePatternType.nullError));
      expect(rankedPatterns[0].count, equals(3));
      expect(rankedPatterns[1].type, equals(FailurePatternType.timeout));
      expect(rankedPatterns[1].count, equals(2));
      expect(rankedPatterns[2].type, equals(FailurePatternType.assertion));
      expect(rankedPatterns[2].count, equals(1));
    });
  });

  group('Suite 2: Smart Suggestion Tests', () {
    test('should generate suggestion for assertion failures', () {
      final analyzer = TestAnalyzer();

      final pattern = FailurePattern(
        type: FailurePatternType.assertion,
        testNames: ['assertion test'],
        errorMessage: 'Expected: true, Actual: false',
      );

      final suggestion = analyzer.generateSuggestion(pattern);

      expect(suggestion, isNotNull);
      expect(suggestion, isNotEmpty);
      expect(suggestion.toLowerCase(), contains('verify'));
    });

    test('should generate suggestion for null errors', () {
      final analyzer = TestAnalyzer();

      final pattern = FailurePattern(
        type: FailurePatternType.nullError,
        testNames: ['null test'],
        errorMessage: 'Null check operator used on null',
        details: {'variableName': 'userData', 'location': 'service.dart:42'},
      );

      final suggestion = analyzer.generateSuggestion(pattern);

      expect(suggestion, isNotNull);
      expect(suggestion, isNotEmpty);
      expect(
          suggestion.toLowerCase(),
          anyOf(
            contains('null'),
            contains('check'),
            contains('validate'),
          ));
      expect(suggestion, contains('userData'));
    });

    test('should generate suggestion for timeout failures', () {
      final analyzer = TestAnalyzer();

      final pattern = FailurePattern(
        type: FailurePatternType.timeout,
        testNames: ['timeout test'],
        errorMessage: 'Test timed out after 30 seconds',
        details: {'duration': '30'},
      );

      final suggestion = analyzer.generateSuggestion(pattern);

      expect(suggestion, isNotNull);
      expect(suggestion, isNotEmpty);
      expect(
          suggestion.toLowerCase(),
          anyOf(
            contains('timeout'),
            contains('duration'),
            contains('increase'),
          ));
    });

    test('should generate suggestion for range errors', () {
      final analyzer = TestAnalyzer();

      final pattern = FailurePattern(
        type: FailurePatternType.rangeError,
        testNames: ['range test'],
        errorMessage: 'RangeError: index out of bounds',
        details: {'index': '10', 'length': '5'},
      );

      final suggestion = analyzer.generateSuggestion(pattern);

      expect(suggestion, isNotNull);
      expect(suggestion, isNotEmpty);
      expect(
          suggestion.toLowerCase(),
          anyOf(
            contains('bounds'),
            contains('length'),
            contains('index'),
          ));
    });

    test('should generate suggestion for type errors', () {
      final analyzer = TestAnalyzer();

      final pattern = FailurePattern(
        type: FailurePatternType.typeError,
        testNames: ['type test'],
        errorMessage: 'type int is not a subtype of String',
        details: {'expectedType': 'String', 'actualType': 'int'},
      );

      final suggestion = analyzer.generateSuggestion(pattern);

      expect(suggestion, isNotNull);
      expect(suggestion, isNotEmpty);
      expect(
          suggestion.toLowerCase(),
          anyOf(
            contains('type'),
            contains('cast'),
            contains('convert'),
          ));
      expect(suggestion, contains('String'));
      expect(suggestion, contains('int'));
    });

    test('should generate context-aware suggestions', () {
      final analyzer = TestAnalyzer();

      final pattern = FailurePattern(
        type: FailurePatternType.nullError,
        testNames: ['authentication token test'],
        errorMessage: 'Null check on authToken',
        details: {
          'variableName': 'authToken',
          'location': 'auth_service.dart:100',
        },
      );

      final suggestion = analyzer.generateSuggestion(pattern);

      expect(suggestion, contains('authToken'));
      expect(suggestion, contains('auth_service.dart:100'));
    });

    test('should include code snippets in suggestions', () {
      final analyzer = TestAnalyzer();

      final pattern = FailurePattern(
        type: FailurePatternType.nullError,
        testNames: ['user profile test'],
        errorMessage: 'Null check on user.profile',
        details: {'variableName': 'user.profile'},
      );

      final suggestion = analyzer.generateSuggestion(pattern);

      expect(
          suggestion,
          anyOf(
            contains('if ('),
            contains('?.'),
            contains('??'),
            contains('!= null'),
          ));
    });

    test('should provide actionable fixes', () {
      final analyzer = TestAnalyzer();

      final pattern = FailurePattern(
        type: FailurePatternType.timeout,
        testNames: ['slow database query test'],
        errorMessage: 'Test timed out after 5 seconds',
        details: {'duration': '5'},
      );

      final suggestion = analyzer.generateSuggestion(pattern);

      expect(
          suggestion,
          anyOf(
            contains('Timeout('),
            contains('timeout:'),
            contains('optimize'),
            contains('mock'),
          ));
    });
  });
}
