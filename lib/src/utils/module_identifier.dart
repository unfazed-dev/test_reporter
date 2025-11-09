// Path pattern constants
const _testPrefix = 'test/';
const _libPrefix = 'lib/';
const _srcPrefix = 'src/';
const _testSuffix = '_test.dart';
const _dartExtension = '.dart';

// Module naming constants
const _folderSuffix = '-fo';
const _fileSuffix = '-fi';
const _projectSuffix = '-pr';

// Validation constants
const _maxNameLength = 150;
const _validNamePattern = r'^[a-z0-9\-]+$';
const _hyphensOnlyPattern = r'^-+$';

/// Path type for module identification
enum PathType {
  /// Individual file (e.g., auth_test.dart)
  file,

  /// Directory/folder (e.g., auth/)
  folder,

  /// Project root (e.g., test/, lib/)
  project,
}

/// Extracts and generates consistent module identifiers from file paths.
///
/// This utility provides module name extraction from paths and generates
/// qualified module names with type suffixes for consistent identification
/// across the test reporter tools.
///
/// **Module Naming Convention:**
/// - Folder: `{module}-fo` (e.g., `auth-fo`)
/// - File: `{module}-fi` (e.g., `auth-test-fi`)
/// - Project: `{module}-pr` (e.g., `all-tests-pr`)
///
/// **Example Usage:**
/// ```dart
/// // Extract module name from path
/// final name = ModuleIdentifier.extractModuleName('test/auth/');
/// print(name); // auth
///
/// // Generate qualified name
/// final qualified = ModuleIdentifier.generateQualifiedName('auth', PathType.folder);
/// print(qualified); // auth-fo
///
/// // Combined extraction and qualification
/// final qualified2 = ModuleIdentifier.getQualifiedModuleName('test/auth/');
/// print(qualified2); // auth-fo
///
/// // Parse qualified name back
/// final parsed = ModuleIdentifier.parseQualifiedName('auth-service-fo');
/// print(parsed?.baseName); // auth-service
/// print(parsed?.type); // PathType.folder
/// ```
class ModuleIdentifier {
  /// Extract base module name from path
  ///
  /// Examples:
  /// - test/auth/ → auth
  /// - lib/src/auth/ → auth
  /// - test/auth_test.dart → auth
  /// - lib/src/auth_service.dart → auth_service
  /// - test/ → all_tests
  /// - lib/ → all_sources
  ///
  /// Returns the extracted module name
  static String extractModuleName(String path) {
    final normalized = _normalizePath(path);

    // Handle special cases: empty path or root directories
    if (normalized.isEmpty || normalized == '/' || normalized == '.') {
      return 'all_tests';
    }
    if (normalized == _testPrefix || normalized == 'test') {
      return 'all_tests';
    }
    if (normalized == _libPrefix || normalized == 'lib') {
      return 'all_sources';
    }

    // Remove test/ or lib/ prefix
    String relativePath = normalized;
    if (relativePath.startsWith(_testPrefix)) {
      relativePath = relativePath.substring(_testPrefix.length);
    } else if (relativePath.startsWith(_libPrefix)) {
      relativePath = relativePath.substring(_libPrefix.length);
      // Also remove src/ if present
      if (relativePath.startsWith(_srcPrefix)) {
        relativePath = relativePath.substring(_srcPrefix.length);
      }
    }

    // Handle files: extract filename and strip _test.dart or .dart suffix
    if (relativePath.endsWith(_testSuffix) ||
        relativePath.endsWith(_dartExtension)) {
      // Get just the filename (last segment)
      final segments =
          relativePath.split('/').where((s) => s.isNotEmpty).toList();
      final filename = segments.isEmpty ? relativePath : segments.last;

      // Strip suffix
      if (filename.endsWith(_testSuffix)) {
        return filename.substring(0, filename.length - _testSuffix.length);
      }
      if (filename.endsWith(_dartExtension)) {
        return filename.substring(0, filename.length - _dartExtension.length);
      }
      return filename;
    }

    // Handle directories: strip trailing slash and take last segment
    if (relativePath.endsWith('/')) {
      relativePath = relativePath.substring(0, relativePath.length - 1);
    }

    // Extract last path segment (most specific directory name)
    final segments =
        relativePath.split('/').where((s) => s.isNotEmpty).toList();
    return segments.isEmpty ? 'unknown' : segments.last;
  }

  /// Generate qualified module name with type suffix
  ///
  /// Examples:
  /// - ('auth', PathType.folder) → auth-fo
  /// - ('auth_test', PathType.file) → auth-test-fi
  /// - ('auth_service', PathType.folder) → auth-service-fo
  /// - ('all_tests', PathType.project) → all-tests-pr
  ///
  /// Throws ArgumentError if name is empty
  static String generateQualifiedName(String baseName, PathType type) {
    if (baseName.isEmpty) {
      throw ArgumentError('Module name cannot be empty');
    }

    // Convert to lowercase and replace underscores with hyphens
    final normalized = baseName.toLowerCase().replaceAll('_', '-');

    // Add appropriate suffix
    final suffix = switch (type) {
      PathType.folder => _folderSuffix,
      PathType.file => _fileSuffix,
      PathType.project => _projectSuffix,
    };

    return '$normalized$suffix';
  }

  /// Get qualified module name from path (combines extraction and qualification)
  ///
  /// Examples:
  /// - test/auth/ → auth-fo
  /// - lib/src/auth_service.dart → auth-service-fi
  /// - test/ → all-tests-pr
  /// - lib/ → all-sources-pr
  static String getQualifiedModuleName(String path) {
    final baseName = extractModuleName(path);
    final type = _detectPathType(path);
    return generateQualifiedName(baseName, type);
  }

  /// Parse qualified name back to base name and type
  ///
  /// Examples:
  /// - auth-service-fo → (baseName: 'auth-service', type: PathType.folder)
  /// - auth-test-fi → (baseName: 'auth-test', type: PathType.file)
  /// - all-tests-pr → (baseName: 'all-tests', type: PathType.project)
  /// - invalid → null
  ///
  /// Returns null if the format is invalid
  static ({String baseName, PathType type})? parseQualifiedName(
      String qualifiedName) {
    if (qualifiedName.isEmpty) {
      return null;
    }

    // Try each suffix type
    final suffixMappings = [
      (_folderSuffix, PathType.folder),
      (_fileSuffix, PathType.file),
      (_projectSuffix, PathType.project),
    ];

    for (final (suffix, type) in suffixMappings) {
      if (qualifiedName.endsWith(suffix)) {
        final baseName =
            qualifiedName.substring(0, qualifiedName.length - suffix.length);
        if (baseName.isEmpty) return null;
        return (baseName: baseName, type: type);
      }
    }

    // No valid suffix found
    return null;
  }

  /// Qualify a manually-specified module name by adding appropriate suffix
  ///
  /// This function handles the `--module-name` flag, ensuring manual names
  /// are properly qualified with type suffixes (-fo/-fi/-pr).
  ///
  /// **Behavior:**
  /// - If name already has a valid suffix, validates it matches the path type
  /// - If name lacks suffix, detects path type and adds appropriate suffix
  /// - Converts underscores to hyphens for consistency
  ///
  /// **Examples:**
  /// ```dart
  /// // Unqualified name → adds suffix based on path
  /// qualifyManualModuleName('utils', 'lib/src/utils/')
  /// // Returns: 'utils-fo'
  ///
  /// // Already qualified → validates match
  /// qualifyManualModuleName('utils-fo', 'lib/src/utils/')
  /// // Returns: 'utils-fo'
  ///
  /// // Mismatched type → throws
  /// qualifyManualModuleName('utils-fi', 'lib/src/utils/')
  /// // Throws ArgumentError (file suffix for folder path)
  /// ```
  ///
  /// Throws ArgumentError if:
  /// - Module name is empty
  /// - Qualified name doesn't match detected path type
  static String qualifyManualModuleName(String manualName, String path) {
    if (manualName.isEmpty) {
      throw ArgumentError('Module name cannot be empty');
    }

    // Normalize: convert underscores to hyphens, lowercase
    final normalized = manualName.toLowerCase().replaceAll('_', '-');

    // Check if already qualified (has valid suffix)
    final parsed = parseQualifiedName(normalized);

    if (parsed != null) {
      // Already qualified - validate it matches path type
      final detectedType = _detectPathType(path);

      if (parsed.type != detectedType) {
        throw ArgumentError(
          'Module name suffix mismatch: "$normalized" has ${parsed.type.name} '
          'suffix but path "$path" is detected as ${detectedType.name}',
        );
      }

      return normalized; // Already qualified and validated
    }

    // Not qualified - add suffix based on detected path type
    final type = _detectPathType(path);
    return generateQualifiedName(normalized, type);
  }

  /// Validate module name format
  ///
  /// Valid names:
  /// - Only lowercase letters, numbers, hyphens
  /// - Not empty
  /// - Not longer than 150 characters
  /// - Not just hyphens
  static bool isValidModuleName(String name) {
    if (name.isEmpty || name.length > _maxNameLength) {
      return false;
    }

    // Check for valid characters (lowercase letters, numbers, hyphens)
    if (!RegExp(_validNamePattern).hasMatch(name)) {
      return false;
    }

    // Not just hyphens
    if (RegExp(_hyphensOnlyPattern).hasMatch(name)) {
      return false;
    }

    return true;
  }

  /// Detect path type (file, folder, or project) from path string
  static PathType _detectPathType(String path) {
    final normalized = _normalizePath(path);

    // Check for project root (with or without trailing slash)
    if (normalized == _testPrefix ||
        normalized == 'test' ||
        normalized == _libPrefix ||
        normalized == 'lib') {
      return PathType.project;
    }

    // Check for file (ends with .dart)
    if (normalized.endsWith(_dartExtension)) {
      return PathType.file;
    }

    // Default to folder
    return PathType.folder;
  }

  /// Normalize path by converting Windows backslashes to forward slashes
  static String _normalizePath(String path) {
    return path.replaceAll(r'\', '/');
  }
}
