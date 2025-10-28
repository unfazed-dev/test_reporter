import 'package:test/test.dart';
import 'package:test_analyzer/src/models/failure_types.dart';

void main() {
  group('AssertionFailure', () {
    test('should create with required fields', () {
      const failure = AssertionFailure(
        message: 'Expected 5, got 3',
        location: 'test.dart:42',
      );

      expect(failure.message, 'Expected 5, got 3');
      expect(failure.location, 'test.dart:42');
      expect(failure.expectedValue, isNull);
      expect(failure.actualValue, isNull);
    });

    test('should create with all fields', () {
      const failure = AssertionFailure(
        message: 'Value mismatch',
        location: 'test.dart:10',
        expectedValue: '5',
        actualValue: '3',
      );

      expect(failure.expectedValue, '5');
      expect(failure.actualValue, '3');
    });

    test('should have correct category and suggestion', () {
      const failure = AssertionFailure(
        message: 'test',
        location: 'test.dart:1',
      );

      expect(failure.category, 'Assertion Failure');
      expect(failure.suggestion, contains('Review test assertions'));
    });
  });

  group('NullError', () {
    test('should create with required fields', () {
      const error = NullError(
        variableName: 'myVariable',
        location: 'test.dart:20',
      );

      expect(error.variableName, 'myVariable');
      expect(error.location, 'test.dart:20');
    });

    test('should have correct category and suggestion', () {
      const error = NullError(
        variableName: 'value',
        location: 'test.dart:1',
      );

      expect(error.category, 'Null Reference Error');
      expect(error.suggestion, contains('Add null checks'));
    });
  });

  group('TimeoutFailure', () {
    test('should create with required fields', () {
      const failure = TimeoutFailure(
        duration: Duration(seconds: 30),
        operation: 'async operation',
      );

      expect(failure.duration, const Duration(seconds: 30));
      expect(failure.operation, 'async operation');
    });

    test('should have correct category and suggestion', () {
      const failure = TimeoutFailure(
        duration: Duration(milliseconds: 500),
        operation: 'test',
      );

      expect(failure.category, 'Timeout');
      expect(failure.suggestion, contains('Increase timeout'));
    });
  });

  group('RangeError', () {
    test('should create with required fields', () {
      const error = RangeError(
        index: 5,
        validRange: '0..3',
      );

      expect(error.index, 5);
      expect(error.validRange, '0..3');
    });

    test('should have correct category and suggestion', () {
      const error = RangeError(
        index: 10,
        validRange: '0..5',
      );

      expect(error.category, 'Range Error');
      expect(error.suggestion, contains('Verify collection sizes'));
    });
  });

  group('TypeError', () {
    test('should create with required fields', () {
      const error = TypeError(
        expectedType: 'int',
        actualType: 'String',
        location: 'test.dart:15',
      );

      expect(error.expectedType, 'int');
      expect(error.actualType, 'String');
      expect(error.location, 'test.dart:15');
    });

    test('should have correct category and suggestion', () {
      const error = TypeError(
        expectedType: 'List',
        actualType: 'Map',
        location: 'test.dart:1',
      );

      expect(error.category, 'Type Error');
      expect(error.suggestion, contains('Check type casts'));
    });
  });

  group('IOError', () {
    test('should create with required fields', () {
      const error = IOError(
        operation: 'read',
        path: '/path/to/file.txt',
      );

      expect(error.operation, 'read');
      expect(error.path, '/path/to/file.txt');
    });

    test('should have correct category and suggestion', () {
      const error = IOError(
        operation: 'write',
        path: '/tmp/test.txt',
      );

      expect(error.category, 'I/O Error');
      expect(error.suggestion, contains('Check file paths'));
    });
  });

  group('NetworkError', () {
    test('should create with required fields', () {
      const error = NetworkError(
        operation: 'GET',
        endpoint: 'https://api.example.com',
      );

      expect(error.operation, 'GET');
      expect(error.endpoint, 'https://api.example.com');
      expect(error.statusCode, isNull);
    });

    test('should create with status code', () {
      const error = NetworkError(
        operation: 'POST',
        endpoint: 'https://api.example.com',
        statusCode: 404,
      );

      expect(error.statusCode, 404);
    });

    test('should have correct category and suggestion', () {
      const error = NetworkError(
        operation: 'GET',
        endpoint: 'http://test.com',
      );

      expect(error.category, 'Network Error');
      expect(error.suggestion, contains('Mock network calls'));
    });
  });

  group('UnknownFailure', () {
    test('should create with message', () {
      const failure = UnknownFailure(message: 'Something went wrong');

      expect(failure.message, 'Something went wrong');
    });

    test('should have correct category and no suggestion', () {
      const failure = UnknownFailure(message: 'error');

      expect(failure.category, 'Unknown');
      expect(failure.suggestion, isNull);
    });
  });

  group('detectFailureType', () {
    test('should detect assertion failures', () {
      const error = 'Expected: 5\nActual: 3';
      const stackTrace = 'test.dart:42:10 in main\n';

      final result = detectFailureType(error, stackTrace);

      expect(result, isA<AssertionFailure>());
      final assertion = result as AssertionFailure;
      expect(assertion.message, error);
      expect(assertion.expectedValue, '5');
      expect(assertion.actualValue, '3');
    });

    test('should detect assertion with different format', () {
      const error = 'assertion failed: value should be positive';
      const stackTrace = '';

      final result = detectFailureType(error, stackTrace);

      expect(result, isA<AssertionFailure>());
    });

    test('should detect null errors', () {
      const error = "'myVar' was null when it shouldn't be";
      const stackTrace = 'test.dart:10:5 in function\n';

      final result = detectFailureType(error, stackTrace);

      expect(result, isA<NullError>());
      final nullError = result as NullError;
      expect(nullError.variableName, 'myVar');
    });

    test('should detect null with different message', () {
      const error = 'NullPointerException occurred';
      const stackTrace = '';

      final result = detectFailureType(error, stackTrace);

      expect(result, isA<NullError>());
    });

    test('should detect timeout failures with seconds', () {
      const error = 'Test timed out after 30 seconds';
      const stackTrace = '';

      final result = detectFailureType(error, stackTrace);

      expect(result, isA<TimeoutFailure>());
      final timeout = result as TimeoutFailure;
      expect(timeout.duration, const Duration(seconds: 30));
    });

    test('should detect timeout failures with milliseconds', () {
      const error = 'Operation timeout after 500ms';
      const stackTrace = '';

      final result = detectFailureType(error, stackTrace);

      expect(result, isA<TimeoutFailure>());
      final timeout = result as TimeoutFailure;
      expect(timeout.duration, const Duration(milliseconds: 500));
    });

    test('should extract operation for timeout with future', () {
      const error = 'timeout waiting for future';
      const stackTrace = '';

      final result = detectFailureType(error, stackTrace);

      expect(result, isA<TimeoutFailure>());
      final timeout = result as TimeoutFailure;
      expect(timeout.operation, 'async operation');
    });

    test('should extract operation for timeout with stream', () {
      const error = 'stream timeout occurred';
      const stackTrace = '';

      final result = detectFailureType(error, stackTrace);

      expect(result, isA<TimeoutFailure>());
      final timeout = result as TimeoutFailure;
      expect(timeout.operation, 'stream operation');
    });

    test('should detect range errors', () {
      const error = 'RangeError: Index: 5, valid range is 0..3';
      const stackTrace = '';

      final result = detectFailureType(error, stackTrace);

      expect(result, isA<RangeError>());
      final rangeError = result as RangeError;
      expect(rangeError.index, 5);
      expect(rangeError.validRange, '0..3');
    });

    test('should detect range error with index keyword', () {
      const error = 'index out of bounds';
      const stackTrace = '';

      final result = detectFailureType(error, stackTrace);

      expect(result, isA<RangeError>());
    });

    test('should detect type errors', () {
      const error = "type 'String' is not a subtype of type 'int'";
      const stackTrace = 'test.dart:25:15 in method\n';

      final result = detectFailureType(error, stackTrace);

      expect(result, isA<TypeError>());
    });

    test('should detect type error with cast', () {
      const error = 'cast error occurred';
      const stackTrace = '';

      final result = detectFailureType(error, stackTrace);

      expect(result, isA<TypeError>());
    });

    test('should extract actual type when present in error', () {
      // Error with 'got' pattern to extract actual type
      const error = "Expected type 'int', got 'String'";
      const stackTrace = 'test.dart:1:1';

      final result = detectFailureType(error, stackTrace);

      expect(result, isA<TypeError>());
      final typeError = result as TypeError;
      expect(typeError.actualType, 'String');
    });

    test('should handle type error without actual type in message', () {
      // This triggers the fallback 'unknown' in _extractActualType
      const error = 'type cast failed from dynamic to int';
      const stackTrace = 'test.dart:1:1';

      final result = detectFailureType(error, stackTrace);

      expect(result, isA<TypeError>());
      final typeError = result as TypeError;
      expect(typeError.actualType, 'unknown');
    });

    test('should detect I/O errors with FileNotFoundException', () {
      const error = "FileNotFoundError: Could not find file 'data.txt'";
      const stackTrace = '';

      final result = detectFailureType(error, stackTrace);

      expect(result, isA<IOError>());
      final ioError = result as IOError;
      expect(ioError.path, 'data.txt');
    });

    test('should detect I/O error with permission', () {
      const error = 'permission denied';
      const stackTrace = '';

      final result = detectFailureType(error, stackTrace);

      expect(result, isA<IOError>());
    });

    test('should detect I/O error with IOException', () {
      const error = 'IOException: read operation failed';
      const stackTrace = '';

      final result = detectFailureType(error, stackTrace);

      expect(result, isA<IOError>());
    });

    test('should extract read operation for I/O', () {
      const error = "IOException: read error on file 'test.dat'";
      const stackTrace = '';

      final result = detectFailureType(error, stackTrace);

      expect(result, isA<IOError>());
      final ioError = result as IOError;
      expect(ioError.operation, 'read');
    });

    test('should extract write operation for I/O', () {
      const error = "IOException: write failed for 'output.txt'";
      const stackTrace = '';

      final result = detectFailureType(error, stackTrace);

      expect(result, isA<IOError>());
      final ioError = result as IOError;
      expect(ioError.operation, 'write');
    });

    test('should extract open operation for I/O', () {
      const error = "IOException: cannot open 'file.log'";
      const stackTrace = '';

      final result = detectFailureType(error, stackTrace);

      expect(result, isA<IOError>());
      final ioError = result as IOError;
      expect(ioError.operation, 'open');
    });

    test('should detect network errors with socket', () {
      const error = 'SocketException: Connection refused';
      const stackTrace = '';

      final result = detectFailureType(error, stackTrace);

      expect(result, isA<NetworkError>());
    });

    test('should detect network error with http', () {
      const error = 'HTTP request failed';
      const stackTrace = '';

      final result = detectFailureType(error, stackTrace);

      expect(result, isA<NetworkError>());
    });

    test('should detect network error with connection', () {
      const error = 'socket connection failed';
      const stackTrace = '';

      final result = detectFailureType(error, stackTrace);

      expect(result, isA<NetworkError>());
    });

    test('should extract endpoint from network error', () {
      const error = 'GET request to https://api.example.com/users failed';
      const stackTrace = '';

      final result = detectFailureType(error, stackTrace);

      expect(result, isA<NetworkError>());
      final networkError = result as NetworkError;
      expect(networkError.endpoint, 'https://api.example.com/users');
      expect(networkError.operation, 'GET');
    });

    test('should extract POST operation', () {
      const error = 'POST to http://api.test.com failed';
      const stackTrace = '';

      final result = detectFailureType(error, stackTrace);

      expect(result, isA<NetworkError>());
      final networkError = result as NetworkError;
      expect(networkError.operation, 'POST');
    });

    test('should extract PUT operation', () {
      const error = 'PUT request to http://api.test.com failed';
      const stackTrace = '';

      final result = detectFailureType(error, stackTrace);

      expect(result, isA<NetworkError>());
      final networkError = result as NetworkError;
      expect(networkError.operation, 'PUT');
    });

    test('should extract DELETE operation', () {
      const error = 'DELETE operation http failed';
      const stackTrace = '';

      final result = detectFailureType(error, stackTrace);

      expect(result, isA<NetworkError>());
      final networkError = result as NetworkError;
      expect(networkError.operation, 'DELETE');
    });

    test('should extract status code from network error', () {
      const error = 'HTTP request failed with status: 404';
      const stackTrace = '';

      final result = detectFailureType(error, stackTrace);

      expect(result, isA<NetworkError>());
      final networkError = result as NetworkError;
      expect(networkError.statusCode, 404);
    });

    test('should return UnknownFailure for unrecognized errors', () {
      const error = 'Some random error message';
      const stackTrace = '';

      final result = detectFailureType(error, stackTrace);

      expect(result, isA<UnknownFailure>());
      final unknown = result as UnknownFailure;
      expect(unknown.message, error);
    });

    test('should extract location from stack trace', () {
      const error = 'Expected: true\nActual: false';
      const stackTrace = 'test/my_test.dart:42:10 in main\nother line';

      final result = detectFailureType(error, stackTrace);

      expect(result, isA<AssertionFailure>());
      final assertion = result as AssertionFailure;
      expect(assertion.location, contains('.dart:'));
    });

    test('should handle empty stack trace', () {
      const error = 'Expected: 1';
      const stackTrace = '';

      final result = detectFailureType(error, stackTrace);

      expect(result, isA<AssertionFailure>());
      final assertion = result as AssertionFailure;
      expect(assertion.location, 'unknown');
    });
  });
}
