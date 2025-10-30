/// File system mocking infrastructure for integration testing
///
/// Provides in-memory file system for testing file I/O operations
/// without touching actual disk.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// In-memory file system for testing
class MockFileSystem {
  static final Map<String, String> _files = {};
  static final Set<String> _directories = {};

  /// Write file content
  static void writeFile(String path, String content) {
    _files[path] = content;
    // Auto-create parent directories
    final dir = path.substring(0, path.lastIndexOf('/'));
    if (dir.isNotEmpty) {
      createDirectory(dir);
    }
  }

  /// Read file content
  static String? readFile(String path) {
    return _files[path];
  }

  /// Check if file exists
  static bool fileExists(String path) {
    return _files.containsKey(path);
  }

  /// Delete file
  static void deleteFile(String path) {
    _files.remove(path);
  }

  /// Create directory
  static void createDirectory(String path) {
    _directories.add(path);
  }

  /// Check if directory exists
  static bool directoryExists(String path) {
    return _directories.contains(path);
  }

  /// List files in directory
  static List<String> listFiles(String directory) {
    return _files.keys.where((path) => path.startsWith(directory)).toList();
  }

  /// Clear all files and directories
  static void clear() {
    _files.clear();
    _directories.clear();
  }

  /// Get file count
  static int get fileCount => _files.length;

  /// Get directory count
  static int get directoryCount => _directories.length;
}

/// Mock File for testing
class MockFile implements File {
  final String _path;

  MockFile(this._path);

  @override
  String get path => _path;

  @override
  Future<String> readAsString({Encoding encoding = utf8}) async {
    final content = MockFileSystem.readFile(_path);
    if (content == null) {
      throw FileSystemException('File not found', _path);
    }
    return content;
  }

  @override
  Future<File> writeAsString(
    String contents, {
    FileMode mode = FileMode.write,
    Encoding encoding = utf8,
    bool flush = false,
  }) async {
    MockFileSystem.writeFile(_path, contents);
    return this;
  }

  @override
  Future<bool> exists() async {
    return MockFileSystem.fileExists(_path);
  }

  @override
  Future<FileSystemEntity> delete({bool recursive = false}) async {
    MockFileSystem.deleteFile(_path);
    return this;
  }

  // Implement other File methods as needed
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Mock Directory for testing
class MockDirectory implements Directory {
  final String _path;

  MockDirectory(this._path);

  @override
  String get path => _path;

  @override
  Future<bool> exists() async {
    return MockFileSystem.directoryExists(_path);
  }

  @override
  Future<Directory> create({bool recursive = false}) async {
    MockFileSystem.createDirectory(_path);
    return this;
  }

  @override
  Stream<FileSystemEntity> list({
    bool recursive = false,
    bool followLinks = true,
  }) {
    final files = MockFileSystem.listFiles(_path);
    return Stream.fromIterable(
      files.map((path) => MockFile(path) as FileSystemEntity),
    );
  }

  // Implement other Directory methods as needed
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
