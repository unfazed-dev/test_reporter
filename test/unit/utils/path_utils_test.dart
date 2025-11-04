import 'dart:io';
import 'package:test/test.dart';
import 'package:test_reporter/src/utils/path_utils.dart';
import 'package:path/path.dart' as p;

void main() {
  group('PathUtils', () {
    group('extractPathName', () {
      test('should replace forward slashes with underscores', () {
        expect(
          PathUtils.extractPathName('test/unit/models'),
          equals('unit_models'),
        );
      });

      test('should replace backslashes with underscores', () {
        expect(
          PathUtils.extractPathName(r'test\unit\models'),
          equals('unit_models'),
        );
      });

      test('should replace mixed slashes with underscores', () {
        expect(
          PathUtils.extractPathName(r'test/unit\models'),
          equals('unit_models'),
        );
      });

      test('should strip test_ prefix when stripTest is true (default)', () {
        expect(
          PathUtils.extractPathName('test_unit_models'),
          equals('unit_models'),
        );
      });

      test('should not strip test_ prefix when stripTest is false', () {
        expect(
          PathUtils.extractPathName('test_unit_models', stripTest: false),
          equals('test_unit_models'),
        );
      });

      test('should strip test_ prefix only at the start', () {
        expect(
          PathUtils.extractPathName('test_unit_test_models'),
          equals('unit_test_models'),
        );
      });

      test('should remove trailing underscores', () {
        expect(
          PathUtils.extractPathName('test/unit/models/'),
          equals('unit_models'),
        );
      });

      test('should handle path with no slashes', () {
        expect(
          PathUtils.extractPathName('simple'),
          equals('simple'),
        );
      });

      test('should handle path with test_ prefix and no stripTest', () {
        expect(
          PathUtils.extractPathName('test_simple', stripTest: false),
          equals('test_simple'),
        );
      });

      test('should return unknown for empty path after processing', () {
        expect(
          PathUtils.extractPathName('test_'),
          equals('unknown'),
        );
      });

      test('should return unknown for path that becomes empty', () {
        expect(
          PathUtils.extractPathName('_'),
          equals('unknown'),
        );
      });

      test('should handle multiple trailing underscores', () {
        // Only removes one trailing underscore based on code
        expect(
          PathUtils.extractPathName('test/unit//'),
          equals('unit_'),
        );
      });

      test('should handle complex nested paths', () {
        expect(
          PathUtils.extractPathName('test/integration/bin/analyzers'),
          equals('integration_bin_analyzers'),
        );
      });

      test('should handle paths with dots', () {
        expect(
          PathUtils.extractPathName('test/unit/foo.bar.dart'),
          equals('unit_foo.bar.dart'),
        );
      });

      test('should handle Windows-style paths', () {
        expect(
          PathUtils.extractPathName(r'C:\projects\test\unit\models'),
          equals('C:_projects_test_unit_models'),
        );
      });

      test('should handle absolute Unix paths', () {
        expect(
          PathUtils.extractPathName('/home/user/test/unit/models'),
          equals('_home_user_test_unit_models'),
        );
      });

      test('should combine all transformations correctly', () {
        // test_ prefix strip + slash replacement + trailing underscore removal
        expect(
          PathUtils.extractPathName('test/integration/tests/'),
          equals('integration_tests'),
        );
      });
    });

    group('getRelativePath', () {
      test('should return relative path when path starts with cwd', () {
        final cwd = Directory.current.path;
        final fullPath = p.join(cwd, 'test', 'unit', 'models');

        final result = PathUtils.getRelativePath(fullPath);

        expect(result, equals(p.join('test', 'unit', 'models')));
        expect(result.startsWith(cwd), isFalse);
      });

      test('should return original path when not starting with cwd', () {
        const externalPath = '/some/other/path/file.dart';

        final result = PathUtils.getRelativePath(externalPath);

        expect(result, equals(externalPath));
      });

      test('should return cwd as dot when path equals cwd', () {
        final cwd = Directory.current.path;

        final result = PathUtils.getRelativePath(cwd);

        expect(result, equals('.'));
      });

      test('should handle nested paths relative to cwd', () {
        final cwd = Directory.current.path;
        final deepPath = p.join(cwd, 'lib', 'src', 'utils', 'path_utils.dart');

        final result = PathUtils.getRelativePath(deepPath);

        expect(
            result, equals(p.join('lib', 'src', 'utils', 'path_utils.dart')));
      });

      test('should handle paths with trailing slash', () {
        final cwd = Directory.current.path;
        final pathWithSlash = p.join(cwd, 'test') + p.separator;

        final result = PathUtils.getRelativePath(pathWithSlash);

        // p.relative should handle trailing separator
        expect(result, isNotEmpty);
        expect(result.startsWith(cwd), isFalse);
      });

      test('should return absolute path unchanged if not in cwd', () {
        const absolutePath = '/usr/local/bin/dart';

        final result = PathUtils.getRelativePath(absolutePath);

        expect(result, equals(absolutePath));
      });

      test('should work with current directory reference', () {
        final cwd = Directory.current.path;
        final cwdPath = p.join(cwd, '.', 'test');

        final result = PathUtils.getRelativePath(cwdPath);

        // p.relative normalizes paths and removes redundant ./ prefix
        expect(result, equals('test'));
      });
    });

    group('normalizePath', () {
      test('should normalize simple relative path', () {
        expect(
          PathUtils.normalizePath('test/unit/models'),
          equals(p.normalize('test/unit/models')),
        );
      });

      test('should normalize path with dot references', () {
        expect(
          PathUtils.normalizePath('./test/unit/./models'),
          equals(p.normalize('./test/unit/./models')),
        );
      });

      test('should normalize path with parent directory references', () {
        expect(
          PathUtils.normalizePath('test/unit/../models'),
          equals(p.normalize('test/unit/../models')),
        );
      });

      test('should normalize path with multiple parent references', () {
        expect(
          PathUtils.normalizePath('test/unit/../../lib/models'),
          equals(p.normalize('test/unit/../../lib/models')),
        );
      });

      test('should normalize Windows-style path with backslashes', () {
        // On non-Windows systems, normalize may keep backslashes
        final result = PathUtils.normalizePath(r'test\unit\models');
        expect(result, equals(p.normalize(r'test\unit\models')));
      });

      test('should normalize mixed slashes', () {
        final result = PathUtils.normalizePath(r'test/unit\models');
        expect(result, equals(p.normalize(r'test/unit\models')));
      });

      test('should normalize empty path', () {
        expect(
          PathUtils.normalizePath(''),
          equals(p.normalize('')),
        );
      });

      test('should normalize single dot', () {
        expect(
          PathUtils.normalizePath('.'),
          equals(p.normalize('.')),
        );
      });

      test('should normalize double dot', () {
        expect(
          PathUtils.normalizePath('..'),
          equals(p.normalize('..')),
        );
      });

      test('should normalize absolute Unix path', () {
        expect(
          PathUtils.normalizePath('/usr/local/bin'),
          equals(p.normalize('/usr/local/bin')),
        );
      });

      test('should normalize absolute Windows path', () {
        expect(
          PathUtils.normalizePath(r'C:\Program Files\Dart'),
          equals(p.normalize(r'C:\Program Files\Dart')),
        );
      });

      test('should normalize path with redundant separators', () {
        expect(
          PathUtils.normalizePath('test//unit///models'),
          equals(p.normalize('test//unit///models')),
        );
      });

      test('should normalize complex path', () {
        expect(
          PathUtils.normalizePath('./test/../lib/./src/utils/../models'),
          equals(p.normalize('./test/../lib/./src/utils/../models')),
        );
      });

      test('should be idempotent (normalizing twice gives same result)', () {
        const path = 'test/../lib/./src';
        final normalized1 = PathUtils.normalizePath(path);
        final normalized2 = PathUtils.normalizePath(normalized1);

        expect(normalized1, equals(normalized2));
      });
    });

    group('Integration Tests', () {
      test('extractPathName and normalizePath work together', () {
        final path = r'test\unit\..\models\';
        final normalized = PathUtils.normalizePath(path);
        final extracted = PathUtils.extractPathName(normalized);

        expect(extracted, isNotEmpty);
        expect(extracted, isNot(equals('unknown')));
      });

      test('getRelativePath and extractPathName work together', () {
        final cwd = Directory.current.path;
        final fullPath = p.join(cwd, 'test', 'unit', 'models');

        final relative = PathUtils.getRelativePath(fullPath);
        final extracted = PathUtils.extractPathName(relative);

        expect(extracted, equals('unit_models'));
      });

      test('all three utilities work in sequence', () {
        final cwd = Directory.current.path;
        final messyPath = p.join(cwd, 'test', '.', 'unit', '..', 'integration');

        final normalized = PathUtils.normalizePath(messyPath);
        final relative = PathUtils.getRelativePath(normalized);
        final extracted = PathUtils.extractPathName(relative);

        expect(extracted, isNotEmpty);
        expect(extracted, isNot(equals('unknown')));
      });

      test('extractPathName handles real-world test paths', () {
        const testPaths = [
          'test/unit/models/failure_types_test.dart',
          'test/integration/bin/analyze_tests_integration_test.dart',
          'test/unit/utils/',
        ];

        for (final path in testPaths) {
          final result = PathUtils.extractPathName(path);
          expect(result, isNotEmpty);
          expect(result, isNot(equals('unknown')));
          expect(result.contains('/'), isFalse);
          expect(result.contains(r'\'), isFalse);
        }
      });
    });

    group('Edge Cases', () {
      test('extractPathName handles special characters', () {
        expect(
          PathUtils.extractPathName('test/unit-models'),
          equals('unit-models'),
        );
        expect(
          PathUtils.extractPathName('test/unit@models'),
          equals('unit@models'),
        );
      });

      test('extractPathName handles very long paths', () {
        final longPath = 'test/' + ('unit/' * 50) + 'models';
        final result = PathUtils.extractPathName(longPath);

        expect(result, isNotEmpty);
        expect(result.split('_').length, greaterThan(50));
      });

      test('getRelativePath handles very long nested paths', () {
        final cwd = Directory.current.path;
        var deepPath = cwd;
        for (var i = 0; i < 10; i++) {
          deepPath = p.join(deepPath, 'level$i');
        }

        final result = PathUtils.getRelativePath(deepPath);

        expect(result, isNotEmpty);
        expect(result.startsWith(cwd), isFalse);
      });

      test('normalizePath handles path with only separators', () {
        expect(
          PathUtils.normalizePath('///'),
          equals(p.normalize('///')),
        );
      });

      test('all methods handle null-safe types correctly', () {
        expect(() => PathUtils.extractPathName('test'), returnsNormally);
        expect(() => PathUtils.getRelativePath('/path'), returnsNormally);
        expect(() => PathUtils.normalizePath('path'), returnsNormally);
      });
    });
  });
}
