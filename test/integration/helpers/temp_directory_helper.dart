/// Helper for managing temporary directories in integration tests
///
/// Provides utilities for creating isolated test environments,
/// copying fixtures, and cleaning up after tests.

import 'dart:io';
import 'package:path/path.dart' as p;

/// Helper for creating and managing temporary test directories
class TempTestDirectory {
  TempTestDirectory({String? prefix})
      : prefix = prefix ?? 'test_reporter_integration_';

  final String prefix;
  Directory? _tempDir;

  /// Get the current temporary directory
  Directory get directory {
    if (_tempDir == null) {
      throw StateError('Temp directory not created. Call create() first.');
    }
    return _tempDir!;
  }

  /// Get the path to the temporary directory
  String get path => directory.path;

  /// Check if temp directory has been created
  bool get isCreated => _tempDir != null;

  /// Create a new temporary directory
  Future<Directory> create() async {
    if (_tempDir != null) {
      throw StateError('Temp directory already created');
    }

    final systemTemp = Directory.systemTemp;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final dirName = '$prefix$timestamp';
    _tempDir = Directory(p.join(systemTemp.path, dirName));

    await _tempDir!.create(recursive: true);
    return _tempDir!;
  }

  /// Create a subdirectory within the temp directory
  Future<Directory> createSubdirectory(String name) async {
    final subdir = Directory(p.join(path, name));
    await subdir.create(recursive: true);
    return subdir;
  }

  /// Create a file in the temp directory
  Future<File> createFile(String relativePath, String content) async {
    final file = File(p.join(path, relativePath));
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
    return file;
  }

  /// Copy a file to the temp directory
  Future<File> copyFile(String sourcePath, String destRelativePath) async {
    final source = File(sourcePath);
    final dest = File(p.join(path, destRelativePath));
    await dest.parent.create(recursive: true);
    await source.copy(dest.path);
    return dest;
  }

  /// Copy a directory to the temp directory
  Future<Directory> copyDirectory(
    String sourcePath,
    String destRelativePath,
  ) async {
    final source = Directory(sourcePath);
    final dest = Directory(p.join(path, destRelativePath));
    await dest.create(recursive: true);

    await for (final entity in source.list(recursive: true)) {
      final relativePath = p.relative(entity.path, from: source.path);
      final destPath = p.join(dest.path, relativePath);

      if (entity is File) {
        await entity.copy(destPath);
      } else if (entity is Directory) {
        await Directory(destPath).create(recursive: true);
      }
    }

    return dest;
  }

  /// Setup a fixture project in the temp directory
  Future<void> setupFixture(String fixtureName) async {
    final fixturesDir = Directory('test/integration/fixtures');
    final fixturePath = p.join(fixturesDir.path, fixtureName);
    final fixtureDir = Directory(fixturePath);

    if (!await fixtureDir.exists()) {
      throw ArgumentError('Fixture not found: $fixtureName');
    }

    await copyDirectory(fixturePath, '.');
  }

  /// Create a minimal Dart project structure
  Future<void> createDartProject({
    required String name,
    List<String>? dependencies,
  }) async {
    // Create pubspec.yaml
    final pubspecContent = '''
name: $name
version: 1.0.0
environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
${dependencies?.map((dep) => '  $dep').join('\n') ?? ''}

dev_dependencies:
  test: ^1.25.0
''';
    await createFile('pubspec.yaml', pubspecContent);

    // Create lib directory
    await createSubdirectory('lib');

    // Create test directory
    await createSubdirectory('test');

    // Create analysis_options.yaml
    await createFile(
        'analysis_options.yaml', 'include: package:lints/recommended.yaml\n');
  }

  /// Create a minimal Flutter project structure
  Future<void> createFlutterProject({
    required String name,
    List<String>? dependencies,
  }) async {
    // Create pubspec.yaml
    final pubspecContent = '''
name: $name
version: 1.0.0
environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
${dependencies?.map((dep) => '  $dep').join('\n') ?? ''}

dev_dependencies:
  flutter_test:
    sdk: flutter
  test: ^1.25.0
''';
    await createFile('pubspec.yaml', pubspecContent);

    // Create lib directory
    await createSubdirectory('lib');

    // Create test directory
    await createSubdirectory('test');

    // Create analysis_options.yaml
    await createFile('analysis_options.yaml',
        'include: package:flutter_lints/flutter.yaml\n');
  }

  /// Cleanup the temporary directory
  Future<void> cleanup() async {
    if (_tempDir != null && await _tempDir!.exists()) {
      try {
        await _tempDir!.delete(recursive: true);
      } catch (e) {
        // Ignore cleanup errors in tests
        stderr.writeln('Warning: Failed to cleanup temp directory: $e');
      }
      _tempDir = null;
    }
  }

  /// Get a file within the temp directory
  File file(String relativePath) => File(p.join(path, relativePath));

  /// Get a directory within the temp directory
  Directory dir(String relativePath) => Directory(p.join(path, relativePath));

  /// Check if a file exists in the temp directory
  Future<bool> fileExists(String relativePath) async {
    return file(relativePath).exists();
  }

  /// Check if a directory exists in the temp directory
  Future<bool> dirExists(String relativePath) async {
    return dir(relativePath).exists();
  }

  /// Read file contents
  Future<String> readFile(String relativePath) async {
    return file(relativePath).readAsString();
  }

  /// List files in a directory
  Future<List<FileSystemEntity>> listDir(String relativePath) async {
    final directory = dir(relativePath);
    return directory.list().toList();
  }
}

/// Create a temporary directory for a test and automatically cleanup
Future<T> withTempDirectory<T>(
  Future<T> Function(TempTestDirectory tempDir) callback, {
  String? prefix,
}) async {
  final tempDir = TempTestDirectory(prefix: prefix);
  try {
    await tempDir.create();
    return await callback(tempDir);
  } finally {
    await tempDir.cleanup();
  }
}
