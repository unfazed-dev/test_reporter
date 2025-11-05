import 'package:test/test.dart';
import 'package:test_reporter/src/utils/path_resolver.dart';

void main() {
  group('PathResolver.inferSourcePath', () {
    test('should infer lib/ from test/', () {
      expect(
        PathResolver.inferSourcePath('test/'),
        equals('lib/'),
      );
    });

    test('should infer lib/src/auth/ from test/auth/ (priority 1)', () {
      expect(
        PathResolver.inferSourcePath('test/auth/'),
        equals('lib/src/auth/'),
      );
    });

    test('should handle test/auth_test.dart → lib/src/auth.dart', () {
      expect(
        PathResolver.inferSourcePath('test/auth_test.dart'),
        equals('lib/src/auth.dart'),
      );
    });

    test('should handle nested paths: test/services/auth/', () {
      expect(
        PathResolver.inferSourcePath('test/services/auth/'),
        equals('lib/src/services/auth/'),
      );
    });

    test('should return null for invalid test path', () {
      expect(
        PathResolver.inferSourcePath('invalid/path/'),
        isNull,
      );
    });
  });

  group('PathResolver.inferTestPath', () {
    test('should infer test/ from lib/', () {
      expect(
        PathResolver.inferTestPath('lib/'),
        equals('test/'),
      );
    });

    test('should infer test/auth/ from lib/src/auth/', () {
      expect(
        PathResolver.inferTestPath('lib/src/auth/'),
        equals('test/auth/'),
      );
    });

    test('should infer test/auth/ from lib/auth/', () {
      expect(
        PathResolver.inferTestPath('lib/auth/'),
        equals('test/auth/'),
      );
    });

    test('should handle lib/src/auth.dart → test/auth_test.dart', () {
      expect(
        PathResolver.inferTestPath('lib/src/auth.dart'),
        equals('test/auth_test.dart'),
      );
    });

    test('should return null for invalid source path', () {
      expect(
        PathResolver.inferTestPath('invalid/path/'),
        isNull,
      );
    });
  });

  group('PathResolver.resolvePaths', () {
    test('should resolve from test path input', () {
      final result = PathResolver.resolvePaths('test/');

      expect(result.testPath, equals('test/'));
      expect(result.sourcePath, equals('lib/'));
    });

    test('should resolve from source path input', () {
      final result = PathResolver.resolvePaths('lib/src/auth/');

      expect(result.testPath, equals('test/auth/'));
      expect(result.sourcePath, equals('lib/src/auth/'));
    });

    test('should use explicit test path override', () {
      final result = PathResolver.resolvePaths(
        'lib/src/auth/',
        explicitTestPath: 'test/integration/auth/',
      );

      expect(result.testPath, equals('test/integration/auth/'));
      expect(result.sourcePath, equals('lib/src/auth/'));
    });

    test('should use explicit source path override', () {
      final result = PathResolver.resolvePaths(
        'test/auth/',
        explicitSourcePath: 'lib/auth/',
      );

      expect(result.testPath, equals('test/auth/'));
      expect(result.sourcePath, equals('lib/auth/'));
    });

    test('should throw ArgumentError for invalid paths', () {
      expect(
        () => PathResolver.resolvePaths('invalid/path/'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should handle root test directory', () {
      final result = PathResolver.resolvePaths('test/');

      expect(result.testPath, equals('test/'));
      expect(result.sourcePath, equals('lib/'));
    });

    test('should handle root lib directory', () {
      final result = PathResolver.resolvePaths('lib/');

      expect(result.testPath, equals('test/'));
      expect(result.sourcePath, equals('lib/'));
    });

    test('should handle paths with trailing slashes', () {
      final result = PathResolver.resolvePaths('test/auth/');

      expect(result.testPath, equals('test/auth/'));
      expect(result.sourcePath, equals('lib/src/auth/'));
    });
  });

  group('PathResolver.validatePaths', () {
    test('should return true when both paths exist', () {
      // Assuming test/ and lib/ directories exist in project
      expect(
        PathResolver.validatePaths('test/', 'lib/'),
        isTrue,
      );
    });

    test('should return false when test path missing', () {
      expect(
        PathResolver.validatePaths('test/nonexistent/', 'lib/'),
        isFalse,
      );
    });

    test('should return false when source path missing', () {
      expect(
        PathResolver.validatePaths('test/', 'lib/nonexistent/'),
        isFalse,
      );
    });

    test('should return false when both paths missing', () {
      expect(
        PathResolver.validatePaths('test/missing/', 'lib/missing/'),
        isFalse,
      );
    });
  });

  group('PathResolver.categorizePath', () {
    test('should categorize path starting with test/ as test', () {
      expect(
        PathResolver.categorizePath('test/auth/'),
        equals(PathCategory.test),
      );
    });

    test('should categorize path starting with lib/ as source', () {
      expect(
        PathResolver.categorizePath('lib/src/auth/'),
        equals(PathCategory.source),
      );
    });

    test('should categorize other paths as unknown', () {
      expect(
        PathResolver.categorizePath('src/auth/'),
        equals(PathCategory.unknown),
      );
    });

    test('should categorize empty path as unknown', () {
      expect(
        PathResolver.categorizePath(''),
        equals(PathCategory.unknown),
      );
    });
  });
}
