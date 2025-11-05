import 'dart:io';

// Path pattern constants
const _testPrefix = 'test/';
const _libPrefix = 'lib/';
const _srcPrefix = 'src/';
const _testSuffix = '_test.dart';
const _dartExtension = '.dart';

/// Categories for path types
enum PathCategory {
  /// Path starts with test/
  test,

  /// Path starts with lib/
  source,

  /// Path doesn't match test/ or lib/
  unknown,
}

/// Resolves bidirectional mappings between test and source paths.
///
/// This utility provides automatic path inference between test and source
/// directories, enabling tools to accept either path type and automatically
/// resolve the corresponding path.
///
/// **Path Inference Rules:**
///
/// Test → Source:
/// - `test/` → `lib/`
/// - `test/auth/` → `lib/src/auth/`
/// - `test/auth_test.dart` → `lib/src/auth.dart`
///
/// Source → Test:
/// - `lib/` → `test/`
/// - `lib/src/auth/` → `test/auth/`
/// - `lib/src/auth.dart` → `test/auth_test.dart`
///
/// **Example Usage:**
/// ```dart
/// // Auto-resolve from test path
/// final paths = PathResolver.resolvePaths('test/auth/');
/// print(paths.testPath);   // test/auth/
/// print(paths.sourcePath); // lib/src/auth/
///
/// // Auto-resolve from source path
/// final paths2 = PathResolver.resolvePaths('lib/src/auth/');
/// print(paths2.testPath);   // test/auth/
/// print(paths2.sourcePath); // lib/src/auth/
///
/// // Explicit overrides
/// final paths3 = PathResolver.resolvePaths(
///   'lib/src/auth/',
///   explicitTestPath: 'test/integration/auth/',
/// );
/// ```
class PathResolver {
  /// Infer source path from test path
  ///
  /// Examples:
  /// - test/ → lib/
  /// - test/auth/ → lib/src/auth/
  /// - test/auth_test.dart → lib/src/auth.dart
  ///
  /// Returns null if inference fails
  static String? inferSourcePath(String testPath) {
    // Normalize path (handle Windows backslashes)
    final normalized = _normalizePath(testPath);

    // Must start with test/
    if (!normalized.startsWith(_testPrefix)) {
      return null;
    }

    // test/ → lib/
    if (normalized == _testPrefix) {
      return _libPrefix;
    }

    // Remove test/ prefix
    final relativePath = normalized.substring(_testPrefix.length);

    // Handle file: test/auth_test.dart → lib/src/auth.dart
    if (relativePath.endsWith(_testSuffix)) {
      final baseName = relativePath.substring(
        0,
        relativePath.length - _testSuffix.length,
      );
      return '$_libPrefix$_srcPrefix$baseName$_dartExtension';
    }

    // Handle directory: test/auth/ → lib/src/auth/
    return '$_libPrefix$_srcPrefix$relativePath';
  }

  /// Infer test path from source path
  ///
  /// Examples:
  /// - lib/ → test/
  /// - lib/src/auth/ → test/auth/
  /// - lib/auth.dart → test/auth_test.dart
  ///
  /// Returns null if inference fails
  static String? inferTestPath(String sourcePath) {
    // Normalize path (handle Windows backslashes)
    final normalized = _normalizePath(sourcePath);

    // Must start with lib/
    if (!normalized.startsWith(_libPrefix)) {
      return null;
    }

    // lib/ → test/
    if (normalized == _libPrefix) {
      return _testPrefix;
    }

    // Remove lib/ prefix
    var relativePath = normalized.substring(_libPrefix.length);

    // Remove src/ if present
    if (relativePath.startsWith(_srcPrefix)) {
      relativePath = relativePath.substring(_srcPrefix.length);
    }

    // Handle file: lib/src/auth.dart → test/auth_test.dart
    if (relativePath.endsWith(_dartExtension)) {
      final baseName = relativePath.substring(
        0,
        relativePath.length - _dartExtension.length,
      );
      return '$_testPrefix$baseName$_testSuffix';
    }

    // Handle directory: lib/src/auth/ → test/auth/
    return '$_testPrefix$relativePath';
  }

  /// Validate that paths exist on filesystem
  static bool validatePaths(String? testPath, String? sourcePath) {
    if (testPath == null || sourcePath == null) {
      return false;
    }

    final testDir = Directory(testPath);
    final sourceDir = Directory(sourcePath);

    return testDir.existsSync() && sourceDir.existsSync();
  }

  /// Smart resolution - accepts either path, returns both
  ///
  /// If only inputPath provided:
  /// - Infers the other path automatically
  /// - Validates both paths exist (if validation enabled)
  ///
  /// If explicit paths provided:
  /// - Uses them directly
  ///
  /// Throws ArgumentError if paths invalid
  static ({String testPath, String sourcePath}) resolvePaths(
    String inputPath, {
    String? explicitTestPath,
    String? explicitSourcePath,
  }) {
    String? testPath = explicitTestPath;
    String? sourcePath = explicitSourcePath;

    // Categorize input path
    final category = categorizePath(inputPath);

    // If explicit paths not provided, infer them
    if (testPath == null && sourcePath == null) {
      switch (category) {
        case PathCategory.test:
          testPath = inputPath;
          sourcePath = inferSourcePath(inputPath);
          break;
        case PathCategory.source:
          sourcePath = inputPath;
          testPath = inferTestPath(inputPath);
          break;
        case PathCategory.unknown:
          throw ArgumentError(
            'Could not categorize path: $inputPath. '
            'Path must start with "test/" or "lib/"',
          );
      }
    } else {
      // Use explicit overrides
      testPath ??= inputPath;
      sourcePath ??= inputPath;
    }

    // Validate inference succeeded
    if (testPath == null || sourcePath == null) {
      throw ArgumentError(
        'Could not infer paths from: $inputPath',
      );
    }

    return (testPath: testPath, sourcePath: sourcePath);
  }

  /// Determine if path is test or source
  static PathCategory categorizePath(String path) {
    final normalized = _normalizePath(path);

    if (normalized.isEmpty) {
      return PathCategory.unknown;
    }

    if (normalized.startsWith(_testPrefix)) {
      return PathCategory.test;
    }

    if (normalized.startsWith(_libPrefix)) {
      return PathCategory.source;
    }

    return PathCategory.unknown;
  }

  /// Normalize path by converting Windows backslashes to forward slashes
  static String _normalizePath(String path) {
    return path.replaceAll(r'\', '/');
  }
}
