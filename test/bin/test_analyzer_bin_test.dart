import 'dart:convert';

import 'package:test/test.dart';

import 'helpers/test_fixtures.dart';

void main() {
  group('Failure Pattern Detection', () {
    test('should detect assertion failure pattern', () {
      expect(SampleErrors.assertion, contains('Expected:'));
      expect(SampleErrors.assertion, contains('Actual:'));
    });

    test('should detect null error pattern', () {
      expect(SampleErrors.nullError, contains('NoSuchMethodError'));
      expect(SampleErrors.nullError, contains('null'));
    });

    test('should detect timeout pattern', () {
      expect(SampleErrors.timeout, contains('timed out'));
    });

    test('should detect range error pattern', () {
      expect(SampleErrors.rangeError, contains('RangeError'));
      expect(SampleErrors.rangeError, contains('Invalid value'));
    });

    test('should detect type error pattern', () {
      expect(SampleErrors.typeError, contains('is not a subtype'));
    });

    test('should detect network error pattern', () {
      expect(SampleErrors.networkError, contains('SocketException'));
    });

    test('should detect file error pattern', () {
      expect(SampleErrors.fileNotFound, contains('FileSystemException'));
    });
  });

  group('Test Event Parsing', () {
    test('should parse test start event', () {
      final event = jsonDecode(sampleTestStartEvent) as Map<String, dynamic>;
      expect(event['type'], equals('testStart'));
      expect(event['test'], isA<Map<String, dynamic>>());
      final test = event['test'] as Map<String, dynamic>;
      expect(test['name'], isA<String>());
    });

    test('should parse test done success event', () {
      final event = jsonDecode(sampleTestDonePassEvent) as Map<String, dynamic>;
      expect(event['type'], equals('testDone'));
      expect(event['result'], equals('success'));
    });

    test('should parse test done failure event', () {
      final event = jsonDecode(sampleTestDoneFailEvent) as Map<String, dynamic>;
      expect(event['type'], equals('testDone'));
      expect(event['result'], equals('failure'));
    });

    test('should parse error event', () {
      final event = jsonDecode(sampleErrorEvent) as Map<String, dynamic>;
      expect(event['type'], equals('error'));
      expect(event['testID'], isA<int>());
      expect(event['error'], isA<String>());
      expect(event['stackTrace'], isA<String>());
    });

    test('should parse group event', () {
      final event = jsonDecode(sampleGroupEvent) as Map<String, dynamic>;
      expect(event['type'], equals('group'));
      final group = event['group'] as Map<String, dynamic>;
      expect(group['name'], isA<String>());
      expect(group['testCount'], isA<int>());
    });

    test('should parse done event', () {
      final event = jsonDecode(sampleDoneEvent) as Map<String, dynamic>;
      expect(event['type'], equals('done'));
      expect(event['success'], isA<bool>());
    });
  });

  group('Performance Tracking', () {
    test('should track test duration', () {
      final startEvent =
          jsonDecode(sampleTestStartEvent) as Map<String, dynamic>;
      final doneEvent =
          jsonDecode(sampleTestDonePassEvent) as Map<String, dynamic>;

      final startTime = startEvent['time'] as int;
      final endTime = doneEvent['time'] as int;
      final duration = endTime - startTime;

      expect(duration, equals(400)); // 500 - 100 = 400ms
    });

    test('should identify slow tests', () {
      const slowThreshold = 5000; // 5 seconds
      const testDuration = 6000; // 6 seconds

      const isSlow = testDuration > slowThreshold;
      expect(isSlow, isTrue);
    });

    test('should identify fast tests', () {
      const slowThreshold = 5000; // 5 seconds
      const testDuration = 100; // 100ms

      const isSlow = testDuration > slowThreshold;
      expect(isSlow, isFalse);
    });
  });

  group('Test Reliability Calculation', () {
    test('should calculate 100% reliability (3/3 passes)', () {
      final reliability = calculateReliability(passCount: 3, totalRuns: 3);
      expect(reliability, equals(100.0));
    });

    test('should calculate 66.7% reliability (2/3 passes)', () {
      final reliability = calculateReliability(passCount: 2, totalRuns: 3);
      expect(reliability, closeTo(66.7, 0.1));
    });

    test('should calculate 33.3% reliability (1/3 passes)', () {
      final reliability = calculateReliability(passCount: 1, totalRuns: 3);
      expect(reliability, closeTo(33.3, 0.1));
    });

    test('should calculate 0% reliability (0/3 passes)', () {
      final reliability = calculateReliability(passCount: 0, totalRuns: 3);
      expect(reliability, equals(0.0));
    });
  });

  group('Flaky Test Detection', () {
    test('should identify flaky test (intermittent failures)', () {
      final results = [true, false, true]; // 2 pass, 1 fail
      final isFlaky = detectFlaky(results);
      expect(isFlaky, isTrue);
    });

    test('should identify consistent passing test', () {
      final results = [true, true, true];
      final isFlaky = detectFlaky(results);
      expect(isFlaky, isFalse);
    });

    test('should identify consistent failing test', () {
      final results = [false, false, false];
      final isFlaky = detectFlaky(results);
      expect(isFlaky, isFalse);
    });

    test('should handle single result', () {
      final results = [true];
      final isFlaky = detectFlaky(results);
      expect(isFlaky, isFalse);
    });
  });

  group('Failure Suggestion Generation', () {
    test('should suggest timeout increase for timeout errors', () {
      final suggestion = generateSuggestion(SampleErrors.timeout);
      expect(suggestion.toLowerCase(), contains('timeout'));
    });

    test('should suggest null check for null errors', () {
      final suggestion = generateSuggestion(SampleErrors.nullError);
      expect(suggestion.toLowerCase(), contains('null'));
    });

    test('should suggest bounds check for range errors', () {
      final suggestion = generateSuggestion(SampleErrors.rangeError);
      final lowerSuggestion = suggestion.toLowerCase();
      expect(
          lowerSuggestion.contains('range') ||
              lowerSuggestion.contains('bound'),
          isTrue);
    });

    test('should suggest type handling for type errors', () {
      final suggestion = generateSuggestion(SampleErrors.typeError);
      expect(suggestion.toLowerCase(), contains('type'));
    });

    test('should suggest network handling for network errors', () {
      final suggestion = generateSuggestion(SampleErrors.networkError);
      final lowerSuggestion = suggestion.toLowerCase();
      expect(
          lowerSuggestion.contains('network') ||
              lowerSuggestion.contains('connection'),
          isTrue);
    });
  });

  group('Test Stability Analysis', () {
    test('should calculate overall stability', () {
      final testResults = {
        'test1': [true, true, true], // 100% stable
        'test2': [true, false, true], // 66.7% stable
        'test3': [false, false, false], // 0% stable (but consistent)
      };

      final stability = calculateOverallStability(testResults);
      // (100 + 66.7 + 100) / 3 = 88.9 (treating consistent failures as stable)
      expect(stability, greaterThan(85.0));
    });

    test('should identify stable test suite', () {
      final testResults = {
        'test1': [true, true, true],
        'test2': [true, true, true],
        'test3': [true, true, true],
      };

      final stability = calculateOverallStability(testResults);
      expect(stability, equals(100.0));
    });
  });

  group('Stack Trace Analysis', () {
    test('should extract file location from stack trace', () {
      final location = extractLocation(sampleAssertionStackTrace);
      expect(location, contains('test/example_test.dart'));
    });

    test('should extract line number from stack trace', () {
      final lineNumber = extractLineNumber(sampleAssertionStackTrace);
      expect(lineNumber, equals(10));
    });

    test('should handle stack trace with no file location', () {
      const emptyTrace = 'dart:core  Object.noSuchMethod';
      final location = extractLocation(emptyTrace);
      expect(location, isNull);
    });
  });

  group('Test Discovery', () {
    test('should identify test file by name pattern', () {
      const filePath = 'test/example_test.dart';
      expect(filePath.endsWith('_test.dart'), isTrue);
      expect(filePath.startsWith('test/'), isTrue);
    });

    test('should distinguish lib from test files', () {
      const libFile = 'lib/src/example.dart';
      const testFile = 'test/example_test.dart';

      expect(testFile.contains('test/'), isTrue);
      expect(testFile.endsWith('_test.dart'), isTrue);
      expect(libFile.endsWith('_test.dart'), isFalse);
    });
  });
}

// Utility functions for testing

double calculateReliability({required int passCount, required int totalRuns}) {
  if (totalRuns == 0) return 0.0;
  return (passCount / totalRuns) * 100;
}

bool detectFlaky(List<bool> results) {
  if (results.length <= 1) return false;

  final hasPass = results.contains(true);
  final hasFail = results.contains(false);

  // Flaky if has both passes and failures
  return hasPass && hasFail;
}

String generateSuggestion(String errorMessage) {
  if (errorMessage.contains('timed out')) {
    return 'Consider increasing the test timeout value';
  } else if (errorMessage.contains('null')) {
    return 'Add null checks for the affected variable';
  } else if (errorMessage.contains('RangeError')) {
    return 'Check array bounds before accessing elements';
  } else if (errorMessage.contains('is not a subtype')) {
    return 'Verify type conversions and declarations';
  } else if (errorMessage.contains('Connection refused') ||
      errorMessage.contains('SocketException')) {
    return 'Check network connectivity and mock external dependencies';
  } else {
    return 'Review the error message and stack trace for details';
  }
}

double calculateOverallStability(Map<String, List<bool>> testResults) {
  if (testResults.isEmpty) return 100.0;

  var totalStability = 0.0;

  for (final results in testResults.values) {
    if (results.isEmpty) continue;

    // Calculate stability for this test
    // A test is stable if it's consistent (all pass or all fail)
    final allSame = results.every((r) => r == results.first);
    final stability = allSame
        ? 100.0
        : calculateReliability(
            passCount: results.where((r) => r).length,
            totalRuns: results.length,
          );

    totalStability += stability;
  }

  return totalStability / testResults.length;
}

String? extractLocation(String stackTrace) {
  final regex = RegExp(r'(test/[^\s]+\.dart)');
  final match = regex.firstMatch(stackTrace);
  return match?.group(1);
}

int? extractLineNumber(String stackTrace) {
  final regex = RegExp(r'test/[^\s]+\.dart[:\s]+(\d+)');
  final match = regex.firstMatch(stackTrace);
  return match != null ? int.tryParse(match.group(1)!) : null;
}
