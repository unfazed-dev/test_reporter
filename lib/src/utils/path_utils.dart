import 'dart:io';
import 'package:path/path.dart' as p;

/// Path manipulation utilities
class PathUtils {
  /// Extract meaningful name from test path for reports
  static String extractPathName(String path, {bool stripTest = true}) {
    var name = path.replaceAll('/', '_').replaceAll('\\', '_');

    if (stripTest && name.startsWith('test_')) {
      name = name.substring(5);
    }

    if (name.endsWith('_')) {
      name = name.substring(0, name.length - 1);
    }

    return name.isEmpty ? 'unknown' : name;
  }

  /// Get relative path from current directory
  static String getRelativePath(String fullPath) {
    final cwd = Directory.current.path;
    if (fullPath.startsWith(cwd)) {
      return fullPath.substring(cwd.length + 1);
    }
    return fullPath;
  }

  /// Normalize path (handles backslashes, relative paths)
  static String normalizePath(String path) {
    return p.normalize(path);
  }
}
