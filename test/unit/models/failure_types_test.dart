import 'package:test/test.dart';
import 'package:test_reporter/src/models/failure_types.dart';

void main() {
  group('FailureType Sealed Class Hierarchy', () {
    test('AssertionFailure should have correct category and suggestion', () {
      const failure = AssertionFailure(
        message: 'Expected: 5, Actual: 3',
        location: 'test/my_test.dart:42',
        expectedValue: '5',
        actualValue: '3',
      );

      expect(failure.category, equals('Assertion Failure'));
      expect(failure.suggestion, contains('Review test assertions'));
      expect(failure.message, equals('Expected: 5, Actual: 3'));
      expect(failure.location, equals('test/my_test.dart:42'));
      expect(failure.expectedValue, equals('5'));
      expect(failure.actualValue, equals('3'));
    });

    test('AssertionFailure with null expected/actual values', () {
      const failure = AssertionFailure(
        message: 'Assertion failed',
        location: 'test.dart:10',
      );

      expect(failure.expectedValue, isNull);
      expect(failure.actualValue, isNull);
    });

    test('NullError should have correct category and suggestion', () {
      const failure = NullError(
        variableName: 'userName',
        location: 'test/auth_test.dart:25',
      );

      expect(failure.category, equals('Null Reference Error'));
      expect(failure.suggestion, contains('Add null checks'));
      expect(failure.suggestion, contains('null-aware operators'));
      expect(failure.variableName, equals('userName'));
      expect(failure.location, equals('test/auth_test.dart:25'));
    });

    test('TimeoutFailure should have correct category and suggestion', () {
      const failure = TimeoutFailure(
        duration: Duration(seconds: 30),
        operation: 'async operation',
      );

      expect(failure.category, equals('Timeout'));
      expect(failure.suggestion, contains('Increase timeout'));
      expect(failure.suggestion, contains('infinite loops'));
      expect(failure.duration, equals(const Duration(seconds: 30)));
      expect(failure.operation, equals('async operation'));
    });

    test('RangeError should have correct category and suggestion', () {
      const failure = RangeError(
        index: 5,
        validRange: '0..3',
      );

      expect(failure.category, equals('Range Error'));
      expect(failure.suggestion, contains('Verify collection sizes'));
      expect(failure.suggestion, contains('elementAtOrNull'));
      expect(failure.index, equals(5));
      expect(failure.validRange, equals('0..3'));
    });

    test('TypeError should have correct category and suggestion', () {
      const failure = TypeError(
        expectedType: 'String',
        actualType: 'int',
        location: 'test/types_test.dart:15',
      );

      expect(failure.category, equals('Type Error'));
      expect(failure.suggestion, contains('type casts'));
      expect(failure.suggestion, contains('pattern matching'));
      expect(failure.expectedType, equals('String'));
      expect(failure.actualType, equals('int'));
      expect(failure.location, equals('test/types_test.dart:15'));
    });

    test('IOError should have correct category and suggestion', () {
      const failure = IOError(
        operation: 'read',
        path: '/tmp/test_file.txt',
      );

      expect(failure.category, equals('I/O Error'));
      expect(failure.suggestion, contains('Check file paths'));
      expect(failure.suggestion, contains('permissions'));
      expect(failure.operation, equals('read'));
      expect(failure.path, equals('/tmp/test_file.txt'));
    });

    test('NetworkError should have correct category and suggestion', () {
      const failure = NetworkError(
        operation: 'GET',
        endpoint: 'https://api.example.com/users',
        statusCode: 404,
      );

      expect(failure.category, equals('Network Error'));
      expect(failure.suggestion, contains('Mock network calls'));
      expect(failure.suggestion, contains('http_mock_adapter'));
      expect(failure.operation, equals('GET'));
      expect(failure.endpoint, equals('https://api.example.com/users'));
      expect(failure.statusCode, equals(404));
    });

    test('NetworkError with null status code', () {
      const failure = NetworkError(
        operation: 'POST',
        endpoint: 'https://api.example.com/data',
      );

      expect(failure.statusCode, isNull);
    });

    test('UnknownFailure should have correct category and null suggestion', () {
      const failure = UnknownFailure(
        message: 'Something went wrong',
      );

      expect(failure.category, equals('Unknown'));
      expect(failure.suggestion, isNull);
      expect(failure.message, equals('Something went wrong'));
    });

    test('Exhaustive pattern matching works for all failure types', () {
      // This test ensures the sealed class hierarchy supports exhaustive matching
      final failures = <FailureType>[
        const AssertionFailure(message: 'test', location: 'loc'),
        const NullError(variableName: 'var', location: 'loc'),
        const TimeoutFailure(duration: Duration(seconds: 1), operation: 'op'),
        const RangeError(index: 0, validRange: '0..10'),
        const TypeError(expectedType: 'A', actualType: 'B', location: 'loc'),
        const IOError(operation: 'read', path: '/path'),
        const NetworkError(operation: 'GET', endpoint: 'http://test'),
        const UnknownFailure(message: 'unknown'),
      ];

      for (final failure in failures) {
        final category = switch (failure) {
          AssertionFailure() => 'Assertion Failure',
          NullError() => 'Null Reference Error',
          TimeoutFailure() => 'Timeout',
          RangeError() => 'Range Error',
          TypeError() => 'Type Error',
          IOError() => 'I/O Error',
          NetworkError() => 'Network Error',
          UnknownFailure() => 'Unknown',
        };

        expect(category, equals(failure.category));
      }
    });
  });

  group('detectFailureType Function', () {
    group('Assertion Failures Detection', () {
      test('detects assertion with expected/actual keywords', () {
        const error = '''
Expected: 5
Actual: 3
        ''';
        const stackTrace = '''
#0      main.<anonymous closure> (test/my_test.dart:42:5)
#1      Declarer.test (package:test)
        ''';

        final failure = detectFailureType(error, stackTrace);

        expect(failure, isA<AssertionFailure>());
        expect(failure.category, equals('Assertion Failure'));
        final assertionFailure = failure as AssertionFailure;
        expect(assertionFailure.expectedValue, equals('5'));
        expect(assertionFailure.actualValue, equals('3'));
        expect(assertionFailure.location, contains('my_test.dart:42'));
      });

      test('detects assertion with lowercase expected/actual', () {
        const error = 'expected: true\nactual: false';
        const stackTrace = 'test.dart:10\n';

        final failure = detectFailureType(error, stackTrace);

        expect(failure, isA<AssertionFailure>());
        final assertionFailure = failure as AssertionFailure;
        expect(assertionFailure.expectedValue, equals('true'));
        expect(assertionFailure.actualValue, equals('false'));
      });

      test('detects assertion with "assertion" keyword', () {
        const error = 'Assertion failed: value should be positive';
        const stackTrace = 'test.dart:5\n';

        final failure = detectFailureType(error, stackTrace);

        expect(failure, isA<AssertionFailure>());
      });
    });

    group('Null Error Detection', () {
      test('detects null reference error', () {
        const error = "The getter 'userName' was called on null";
        const stackTrace = '''
#0      Object.noSuchMethod (dart:core-patch/object_patch.dart:38:5)
#1      main (test/auth_test.dart:20:10)
        ''';

        final failure = detectFailureType(error, stackTrace);

        expect(failure, isA<NullError>());
        final nullError = failure as NullError;
        expect(nullError.variableName, equals('userName'));
        // Extracts first .dart file from stack trace
        expect(nullError.location,
            contains('dart:core-patch/object_patch.dart:38'));
      });

      test('detects NullPointerException', () {
        const error = 'NullPointerException: Cannot access property';
        const stackTrace = 'test.dart:15\n';

        final failure = detectFailureType(error, stackTrace);

        expect(failure, isA<NullError>());
      });

      test('extracts variable name from null error', () {
        const error = "NoSuchMethodError: The method 'data' was called on null";
        const stackTrace = 'test.dart:25\n';

        final failure = detectFailureType(error, stackTrace);

        expect(failure, isA<NullError>());
        final nullError = failure as NullError;
        expect(nullError.variableName, equals('data'));
      });

      test('uses default variable name when extraction fails', () {
        const error = 'Something is null but no variable specified';
        const stackTrace = 'test.dart:30\n';

        final failure = detectFailureType(error, stackTrace);

        expect(failure, isA<NullError>());
        final nullError = failure as NullError;
        expect(nullError.variableName, equals('variable'));
      });
    });

    group('Timeout Failure Detection', () {
      test('detects timeout with duration in seconds', () {
        const error = 'Test timed out after 30 seconds';
        const stackTrace = 'test.dart:40\n';

        final failure = detectFailureType(error, stackTrace);

        expect(failure, isA<TimeoutFailure>());
        final timeoutFailure = failure as TimeoutFailure;
        expect(timeoutFailure.duration, equals(const Duration(seconds: 30)));
      });

      test('detects timeout with duration in milliseconds', () {
        const error = 'Timeout after 5000 ms';
        const stackTrace = 'test.dart:45\n';

        final failure = detectFailureType(error, stackTrace);

        expect(failure, isA<TimeoutFailure>());
        final timeoutFailure = failure as TimeoutFailure;
        expect(timeoutFailure.duration,
            equals(const Duration(milliseconds: 5000)));
      });

      test('detects "timed out" keyword', () {
        const error = 'Operation timed out';
        const stackTrace = 'test.dart:50\n';

        final failure = detectFailureType(error, stackTrace);

        expect(failure, isA<TimeoutFailure>());
      });

      test('extracts async operation type', () {
        const error = 'future timed out after 10 seconds';
        const stackTrace = 'test.dart:55\n';

        final failure = detectFailureType(error, stackTrace);

        expect(failure, isA<TimeoutFailure>());
        final timeoutFailure = failure as TimeoutFailure;
        expect(timeoutFailure.operation, equals('async operation'));
      });

      test('extracts stream operation type', () {
        const error = 'stream timed out after 5 seconds';
        const stackTrace = 'test.dart:60\n';

        final failure = detectFailureType(error, stackTrace);

        expect(failure, isA<TimeoutFailure>());
        final timeoutFailure = failure as TimeoutFailure;
        expect(timeoutFailure.operation, equals('stream operation'));
      });

      test('uses default operation when type unclear', () {
        const error = 'Timeout after 15 seconds';
        const stackTrace = 'test.dart:65\n';

        final failure = detectFailureType(error, stackTrace);

        expect(failure, isA<TimeoutFailure>());
        final timeoutFailure = failure as TimeoutFailure;
        expect(timeoutFailure.operation, equals('operation'));
      });

      test('uses default duration when not specified', () {
        const error = 'Timeout occurred';
        const stackTrace = 'test.dart:70\n';

        final failure = detectFailureType(error, stackTrace);

        expect(failure, isA<TimeoutFailure>());
        final timeoutFailure = failure as TimeoutFailure;
        expect(timeoutFailure.duration, equals(const Duration(seconds: 30)));
      });
    });

    group('Range Error Detection', () {
      test('detects range error with index', () {
        const error = 'RangeError: Index: 5, Range: 0..3';
        const stackTrace = 'test.dart:75\n';

        final failure = detectFailureType(error, stackTrace);

        expect(failure, isA<RangeError>());
        final rangeError = failure as RangeError;
        expect(rangeError.index, equals(5));
        expect(rangeError.validRange, equals('0..3'));
      });

      test('detects "index" keyword', () {
        const error = 'Index out of bounds: 10';
        const stackTrace = 'test.dart:80\n';

        final failure = detectFailureType(error, stackTrace);

        expect(failure, isA<RangeError>());
      });

      test('uses default index when extraction fails', () {
        const error = 'Range error without index specified';
        const stackTrace = 'test.dart:85\n';

        final failure = detectFailureType(error, stackTrace);

        expect(failure, isA<RangeError>());
        final rangeError = failure as RangeError;
        expect(rangeError.index, equals(-1));
      });

      test('uses default valid range when extraction fails', () {
        const error = 'Index: 5 is out of range';
        const stackTrace = 'test.dart:90\n';

        final failure = detectFailureType(error, stackTrace);

        expect(failure, isA<RangeError>());
        final rangeError = failure as RangeError;
        expect(rangeError.validRange, equals('unknown'));
      });
    });

    group('Type Error Detection', () {
      test('detects type mismatch error', () {
        const error =
            "type 'int' is not a subtype of type 'String', got 'double'";
        const stackTrace = 'test.dart:95\n';

        final failure = detectFailureType(error, stackTrace);

        expect(failure, isA<TypeError>());
        final typeError = failure as TypeError;
        expect(typeError.expectedType, equals('int'));
        expect(typeError.actualType, equals('double'));
        expect(typeError.location, equals('test.dart:95'));
      });

      test('detects cast error', () {
        const error = 'CastError: Cannot cast int to String';
        const stackTrace = 'test.dart:100\n';

        final failure = detectFailureType(error, stackTrace);

        expect(failure, isA<TypeError>());
      });

      test('detects "is not a subtype" error', () {
        const error = "Object is not a subtype of List";
        const stackTrace = 'test.dart:105\n';

        final failure = detectFailureType(error, stackTrace);

        expect(failure, isA<TypeError>());
      });

      test('uses default types when extraction fails', () {
        const error = 'Type error occurred';
        const stackTrace = 'test.dart:110\n';

        final failure = detectFailureType(error, stackTrace);

        expect(failure, isA<TypeError>());
        final typeError = failure as TypeError;
        expect(typeError.expectedType, equals('unknown'));
        expect(typeError.actualType, equals('unknown'));
        expect(typeError.location, equals('test.dart:110'));
      });
    });

    group('I/O Error Detection', () {
      test('detects FileNotFoundException', () {
        const error = 'FileNotFoundException: "test_data.json" not found';
        const stackTrace = 'test.dart:115\n';

        final failure = detectFailureType(error, stackTrace);

        expect(failure, isA<IOError>());
        final ioError = failure as IOError;
        expect(ioError.path, equals('test_data.json'));
      });

      test('detects permission error', () {
        const error = 'Permission denied when accessing file';
        const stackTrace = 'test.dart:120\n';

        final failure = detectFailureType(error, stackTrace);

        expect(failure, isA<IOError>());
      });

      test('detects IOException', () {
        const error = 'IOException: Failed to read file';
        const stackTrace = 'test.dart:125\n';

        final failure = detectFailureType(error, stackTrace);

        expect(failure, isA<IOError>());
      });

      test('extracts read operation', () {
        const error = 'FileNotFoundException: Failed to read from "data.txt"';
        const stackTrace = 'test.dart:130\n';

        final failure = detectFailureType(error, stackTrace);

        expect(failure, isA<IOError>());
        final ioError = failure as IOError;
        expect(ioError.operation, equals('read'));
      });

      test('extracts write operation', () {
        const error = 'Permission denied: Failed to write to "output.log"';
        const stackTrace = 'test.dart:135\n';

        final failure = detectFailureType(error, stackTrace);

        expect(failure, isA<IOError>());
        final ioError = failure as IOError;
        expect(ioError.operation, equals('write'));
      });

      test('extracts open operation', () {
        const error = 'IOException: Cannot open file "config.yaml"';
        const stackTrace = 'test.dart:140\n';

        final failure = detectFailureType(error, stackTrace);

        expect(failure, isA<IOError>());
        final ioError = failure as IOError;
        expect(ioError.operation, equals('open'));
      });

      test('uses default operation when unclear', () {
        const error = 'IOException with "file.txt"';
        const stackTrace = 'test.dart:145\n';

        final failure = detectFailureType(error, stackTrace);

        expect(failure, isA<IOError>());
        final ioError = failure as IOError;
        expect(ioError.operation, equals('file operation'));
        expect(ioError.path, equals('file.txt'));
      });

      test('uses default path when extraction fails', () {
        const error = 'FileNotFoundException without path';
        const stackTrace = 'test.dart:150\n';

        final failure = detectFailureType(error, stackTrace);

        expect(failure, isA<IOError>());
        final ioError = failure as IOError;
        expect(ioError.path, equals('unknown'));
      });
    });

    group('Network Error Detection', () {
      test('detects socket error', () {
        const error = 'SocketException: Connection refused';
        const stackTrace = 'test.dart:155\n';

        final failure = detectFailureType(error, stackTrace);

        expect(failure, isA<NetworkError>());
      });

      test('detects HTTP error with status code', () {
        const error = 'HTTP GET failed with status: 404';
        const stackTrace = 'test.dart:160\n';

        final failure = detectFailureType(error, stackTrace);

        expect(failure, isA<NetworkError>());
        final networkError = failure as NetworkError;
        expect(networkError.operation, equals('GET'));
        expect(networkError.statusCode, equals(404));
      });

      test('detects connection error', () {
        const error = 'Connection refused to https://api.example.com/users';
        const stackTrace = 'test.dart:165\n';

        final failure = detectFailureType(error, stackTrace);

        expect(failure, isA<NetworkError>());
        final networkError = failure as NetworkError;
        expect(networkError.endpoint, equals('https://api.example.com/users'));
      });

      test('extracts GET operation', () {
        const error = 'HTTP GET request failed';
        const stackTrace = 'test.dart:170\n';

        final failure = detectFailureType(error, stackTrace);

        expect(failure, isA<NetworkError>());
        final networkError = failure as NetworkError;
        expect(networkError.operation, equals('GET'));
      });

      test('extracts POST operation', () {
        const error = 'HTTP POST request failed';
        const stackTrace = 'test.dart:175\n';

        final failure = detectFailureType(error, stackTrace);

        expect(failure, isA<NetworkError>());
        final networkError = failure as NetworkError;
        expect(networkError.operation, equals('POST'));
      });

      test('extracts PUT operation', () {
        const error = 'HTTP PUT request failed';
        const stackTrace = 'test.dart:180\n';

        final failure = detectFailureType(error, stackTrace);

        expect(failure, isA<NetworkError>());
        final networkError = failure as NetworkError;
        expect(networkError.operation, equals('PUT'));
      });

      test('extracts DELETE operation', () {
        const error = 'HTTP DELETE request failed';
        const stackTrace = 'test.dart:185\n';

        final failure = detectFailureType(error, stackTrace);

        expect(failure, isA<NetworkError>());
        final networkError = failure as NetworkError;
        expect(networkError.operation, equals('DELETE'));
      });

      test('uses default operation when unclear', () {
        const error = 'HTTP error occurred';
        const stackTrace = 'test.dart:190\n';

        final failure = detectFailureType(error, stackTrace);

        expect(failure, isA<NetworkError>());
        final networkError = failure as NetworkError;
        expect(networkError.operation, equals('HTTP request'));
      });

      test('extracts http endpoint', () {
        const error = 'Failed to connect to http://localhost:8080/api';
        const stackTrace = 'test.dart:195\n';

        final failure = detectFailureType(error, stackTrace);

        expect(failure, isA<NetworkError>());
        final networkError = failure as NetworkError;
        expect(networkError.endpoint, equals('http://localhost:8080/api'));
      });

      test('extracts https endpoint', () {
        const error = 'Request to https://secure.example.com/data failed';
        const stackTrace = 'test.dart:200\n';

        final failure = detectFailureType(error, stackTrace);

        expect(failure, isA<NetworkError>());
        final networkError = failure as NetworkError;
        expect(
            networkError.endpoint, equals('https://secure.example.com/data'));
      });

      test('uses unknown endpoint when extraction fails', () {
        const error = 'Socket error without endpoint';
        const stackTrace = 'test.dart:205\n';

        final failure = detectFailureType(error, stackTrace);

        expect(failure, isA<NetworkError>());
        final networkError = failure as NetworkError;
        expect(networkError.endpoint, equals('unknown'));
      });

      test('extracts various status codes', () {
        final testCases = [
          ('HTTP error with status: 200', 200),
          ('HTTP error with status: 404', 404),
          ('HTTP error with status: 500', 500),
          ('Socket error with status: 403', 403),
        ];

        for (final (errorMsg, expectedCode) in testCases) {
          final failure = detectFailureType(
            errorMsg,
            'test.dart:1\n',
          );

          expect(failure, isA<NetworkError>());
          final networkError = failure as NetworkError;
          expect(networkError.statusCode, equals(expectedCode));
        }
      });

      test('returns null status code when not found', () {
        const error = 'Socket connection failed without status code';
        const stackTrace = 'test.dart:210\n';

        final failure = detectFailureType(error, stackTrace);

        expect(failure, isA<NetworkError>());
        final networkError = failure as NetworkError;
        expect(networkError.statusCode, isNull);
      });
    });

    group('Unknown Failure Detection', () {
      test('returns UnknownFailure for unrecognized errors', () {
        const error = 'Something completely unexpected happened';
        const stackTrace = 'test.dart:215\n';

        final failure = detectFailureType(error, stackTrace);

        expect(failure, isA<UnknownFailure>());
        final unknownFailure = failure as UnknownFailure;
        expect(unknownFailure.message, equals(error));
      });

      test('handles empty error message', () {
        const error = '';
        const stackTrace = '';

        final failure = detectFailureType(error, stackTrace);

        expect(failure, isA<UnknownFailure>());
      });
    });

    group('Edge Cases and Stack Trace Handling', () {
      test('handles empty stack trace', () {
        const error = 'Expected: 5, Actual: 3';
        const stackTrace = '';

        final failure = detectFailureType(error, stackTrace);

        expect(failure, isA<AssertionFailure>());
        final assertionFailure = failure as AssertionFailure;
        expect(assertionFailure.location, equals('unknown'));
      });

      test('handles stack trace without file location', () {
        const error = 'Expected: 5, Actual: 3';
        const stackTrace = 'No file information here\n';

        final failure = detectFailureType(error, stackTrace);

        expect(failure, isA<AssertionFailure>());
        final assertionFailure = failure as AssertionFailure;
        expect(assertionFailure.location, equals('unknown'));
      });

      test('extracts location from complex stack trace', () {
        const error = 'Expected: true, Actual: false';
        const stackTrace = '''
#0      main.<anonymous closure> (file:///path/to/test/complex_test.dart:150:9)
#1      _asyncThenWrapperHelper.<anonymous closure> (dart:async/runtime/libasync_patch.dart:77:64)
#2      _rootRun (dart:async/zone.dart:1182:47)
        ''';

        final failure = detectFailureType(error, stackTrace);

        expect(failure, isA<AssertionFailure>());
        final assertionFailure = failure as AssertionFailure;
        expect(assertionFailure.location, contains('complex_test.dart:150'));
      });

      test('handles case-insensitive error detection', () {
        // All detection should work with lowercase
        const testCases = [
          ('EXPECTED: 5', AssertionFailure),
          ('NULL pointer', NullError),
          ('TIMEOUT occurred', TimeoutFailure),
          ('RANGE error', RangeError),
          ('TYPE mismatch', TypeError),
          ('FILENOTFOUND', IOError),
          ('SOCKET error', NetworkError),
        ];

        for (final (error, expectedType) in testCases) {
          final failure = detectFailureType(error, 'test.dart:1\n');
          expect(failure.runtimeType, equals(expectedType));
        }
      });
    });
  });
}
