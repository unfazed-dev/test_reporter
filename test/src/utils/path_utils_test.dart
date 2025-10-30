import 'dart:io';
import 'package:test/test.dart';
import 'package:test_reporter/src/utils/path_utils.dart';

void main() {
  group('PathUtils', () {
    group('extractPathName', () {
      test('should convert path separators to underscores', () {
        const path = 'test/ui/widgets/onboarding';
        final name = PathUtils.extractPathName(path);
        expect(name, 'ui_widgets_onboarding');
      });

      test('should handle backslashes on Windows-style paths', () {
        const path = r'test\ui\widgets\onboarding';
        final name = PathUtils.extractPathName(path);
        expect(name, 'ui_widgets_onboarding');
      });

      test('should strip test_ prefix by default', () {
        const path = 'test/integration';
        final name = PathUtils.extractPathName(path);
        expect(name, 'integration');
      });

      test('should keep test_ prefix when stripTest is false', () {
        const path = 'test/integration';
        final name = PathUtils.extractPathName(path, stripTest: false);
        expect(name, 'test_integration');
      });

      test('should remove trailing underscores', () {
        const path = 'test/mymodule/';
        final name = PathUtils.extractPathName(path);
        expect(name, 'mymodule');
      });

      test('should handle path with multiple trailing slashes', () {
        const path = 'test/ui///';
        final name = PathUtils.extractPathName(path);
        // Multiple slashes become multiple underscores, only one trailing _ is removed
        expect(name, 'ui__');
      });

      test('should return unknown for empty path after processing', () {
        const path = 'test/';
        final name = PathUtils.extractPathName(path);
        // 'test/' becomes 'test_', stripTest removes 'test_', leaving empty which returns 'unknown'
        expect(name, 'unknown');
      });

      test('should handle test-only path without trailing slash', () {
        const path = 'test';
        final name = PathUtils.extractPathName(path, stripTest: false);
        expect(name, 'test');
      });

      test('should handle simple path without test prefix', () {
        const path = 'lib/src/models';
        final name = PathUtils.extractPathName(path);
        expect(name, 'lib_src_models');
      });

      test('should handle single directory', () {
        const path = 'widgets';
        final name = PathUtils.extractPathName(path);
        expect(name, 'widgets');
      });

      test('should handle complex nested paths', () {
        const path = 'test/features/authentication/login/widgets';
        final name = PathUtils.extractPathName(path);
        expect(name, 'features_authentication_login_widgets');
      });
    });

    group('getRelativePath', () {
      test('should return relative path when inside current directory', () {
        final cwd = Directory.current.path;
        final fullPath = '$cwd/test/my_test.dart';
        final relative = PathUtils.getRelativePath(fullPath);
        expect(relative, 'test/my_test.dart');
      });

      test('should return full path when outside current directory', () {
        const fullPath = '/some/other/directory/file.dart';
        final relative = PathUtils.getRelativePath(fullPath);
        expect(relative, fullPath);
      });

      test('should handle paths at root of current directory', () {
        final cwd = Directory.current.path;
        final fullPath = '$cwd/file.dart';
        final relative = PathUtils.getRelativePath(fullPath);
        expect(relative, 'file.dart');
      });

      test('should handle nested paths in current directory', () {
        final cwd = Directory.current.path;
        final fullPath = '$cwd/lib/src/utils/path_utils.dart';
        final relative = PathUtils.getRelativePath(fullPath);
        expect(relative, 'lib/src/utils/path_utils.dart');
      });

      test('should handle subdirectory of current directory', () {
        final cwd = Directory.current.path;
        final fullPath = '$cwd/subdir';
        final relative = PathUtils.getRelativePath(fullPath);
        expect(relative, 'subdir');
      });
    });

    group('normalizePath', () {
      test('should normalize path with relative components', () {
        const path = 'test/ui/./widgets/../widgets';
        final normalized = PathUtils.normalizePath(path);
        expect(normalized, 'test/ui/widgets');
      });

      test('should handle multiple parent directory references', () {
        const path = 'test/ui/deep/nested/../../widgets';
        final normalized = PathUtils.normalizePath(path);
        expect(normalized, 'test/ui/widgets');
      });

      test('should handle current directory references', () {
        const path = 'test/./ui/./widgets/./';
        final normalized = PathUtils.normalizePath(path);
        expect(normalized, 'test/ui/widgets');
      });

      test('should handle simple path without relative components', () {
        const path = 'test/ui/widgets';
        final normalized = PathUtils.normalizePath(path);
        expect(normalized, 'test/ui/widgets');
      });

      test('should handle absolute paths', () {
        const path = '/usr/local/bin/../lib';
        final normalized = PathUtils.normalizePath(path);
        expect(normalized, '/usr/local/lib');
      });

      test('should handle empty path', () {
        const path = '';
        final normalized = PathUtils.normalizePath(path);
        expect(normalized, '.');
      });

      test('should handle single dot', () {
        const path = '.';
        final normalized = PathUtils.normalizePath(path);
        expect(normalized, '.');
      });

      test('should handle parent directory', () {
        const path = '..';
        final normalized = PathUtils.normalizePath(path);
        expect(normalized, '..');
      });
    });
  });
}
