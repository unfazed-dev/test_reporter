/// Mock File System infrastructure for testing bin/ analyzers
///
/// Provides MockFile, MockDirectory, and MockFileSystem
/// to mock File I/O and directory operations in integration tests.
///
/// Usage:
/// ```dart
/// final fs = MockFileSystem();
/// fs.addFile('/test/file.txt', 'content');
/// fs.addDirectory('/test/dir');
///
/// final file = fs.getFile('/test/file.txt');
/// print(file?.readAsStringSync()); // 'content'
///
/// final dir = fs.getDirectory('/test/dir');
/// final files = dir?.listSync(recursive: true);
/// ```

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Mock implementation of File for file operations
class MockFile implements File {
  MockFile({
    required this.path,
    required String content,
    bool? exists,
    MockFileSystem? fileSystem,
  })  : _content = content,
        _exists = exists ?? true,
        _fileSystem = fileSystem;

  @override
  final String path;

  String _content;
  bool _exists;
  final MockFileSystem? _fileSystem;

  @override
  String readAsStringSync({Encoding encoding = utf8}) {
    _trackOperation('read');
    if (!_exists) {
      throw FileSystemException('Cannot read file', path);
    }
    return _content;
  }

  @override
  List<String> readAsLinesSync({Encoding encoding = utf8}) {
    _trackOperation('read');
    if (!_exists) {
      throw FileSystemException('Cannot read file', path);
    }
    return _content.split('\n');
  }

  @override
  void writeAsStringSync(
    String contents, {
    FileMode mode = FileMode.write,
    Encoding encoding = utf8,
    bool flush = false,
  }) {
    _trackOperation('write');
    if (!_exists) {
      throw FileSystemException('Cannot write to file', path);
    }
    _content = contents;
  }

  @override
  bool existsSync() {
    return _exists;
  }

  @override
  int lengthSync() {
    if (!_exists) {
      throw FileSystemException('Cannot get length of non-existent file', path);
    }
    return _content.length;
  }

  @override
  void deleteSync({bool recursive = false}) {
    _trackOperation('delete');
    if (!_exists) {
      throw FileSystemException('Cannot delete non-existent file', path);
    }
    _exists = false;
    _fileSystem?._removeFile(path);
  }

  void _trackOperation(String operation) {
    _fileSystem?._trackOperation(path, operation);
  }

  // Unimplemented File methods (not needed for our tests)
  @override
  Directory get parent => throw UnimplementedError();

  @override
  Uri get uri => throw UnimplementedError();

  @override
  File get absolute => throw UnimplementedError();

  @override
  Future<File> copy(String newPath) => throw UnimplementedError();

  @override
  File copySync(String newPath) => throw UnimplementedError();

  @override
  Future<File> create({bool recursive = false, bool exclusive = false}) =>
      throw UnimplementedError();

  @override
  void createSync({bool recursive = false, bool exclusive = false}) =>
      throw UnimplementedError();

  @override
  Future<FileSystemEntity> delete({bool recursive = false}) =>
      throw UnimplementedError();

  @override
  Future<bool> exists() => throw UnimplementedError();

  @override
  Future<DateTime> lastAccessed() => throw UnimplementedError();

  @override
  DateTime lastAccessedSync() => throw UnimplementedError();

  @override
  Future<DateTime> lastModified() => throw UnimplementedError();

  @override
  DateTime lastModifiedSync() => throw UnimplementedError();

  @override
  Future<int> length() => throw UnimplementedError();

  @override
  Future<RandomAccessFile> open({FileMode mode = FileMode.read}) =>
      throw UnimplementedError();

  @override
  Stream<List<int>> openRead([int? start, int? end]) =>
      throw UnimplementedError();

  @override
  RandomAccessFile openSync({FileMode mode = FileMode.read}) =>
      throw UnimplementedError();

  @override
  IOSink openWrite({
    FileMode mode = FileMode.write,
    Encoding encoding = utf8,
  }) =>
      throw UnimplementedError();

  @override
  Future<Uint8List> readAsBytes() => throw UnimplementedError();

  @override
  Uint8List readAsBytesSync() => throw UnimplementedError();

  @override
  Future<List<String>> readAsLines({Encoding encoding = utf8}) =>
      throw UnimplementedError();

  @override
  Future<String> readAsString({Encoding encoding = utf8}) =>
      throw UnimplementedError();

  @override
  Future<File> rename(String newPath) => throw UnimplementedError();

  @override
  File renameSync(String newPath) => throw UnimplementedError();

  @override
  Future<String> resolveSymbolicLinks() => throw UnimplementedError();

  @override
  String resolveSymbolicLinksSync() => throw UnimplementedError();

  @override
  Future setLastAccessed(DateTime time) => throw UnimplementedError();

  @override
  void setLastAccessedSync(DateTime time) => throw UnimplementedError();

  @override
  Future setLastModified(DateTime time) => throw UnimplementedError();

  @override
  void setLastModifiedSync(DateTime time) => throw UnimplementedError();

  @override
  Future<FileStat> stat() => throw UnimplementedError();

  @override
  FileStat statSync() => throw UnimplementedError();

  @override
  Stream<FileSystemEvent> watch({
    int events = FileSystemEvent.all,
    bool recursive = false,
  }) =>
      throw UnimplementedError();

  @override
  Future<File> writeAsBytes(
    List<int> bytes, {
    FileMode mode = FileMode.write,
    bool flush = false,
  }) =>
      throw UnimplementedError();

  @override
  void writeAsBytesSync(
    List<int> bytes, {
    FileMode mode = FileMode.write,
    bool flush = false,
  }) =>
      throw UnimplementedError();

  @override
  Future<File> writeAsString(
    String contents, {
    FileMode mode = FileMode.write,
    Encoding encoding = utf8,
    bool flush = false,
  }) =>
      throw UnimplementedError();

  @override
  bool get isAbsolute => throw UnimplementedError();
}

/// Mock implementation of Directory for directory operations
class MockDirectory implements Directory {
  MockDirectory({
    required this.path,
    List<String>? files,
    bool? exists,
    MockFileSystem? fileSystem,
  })  : _files = files ?? [],
        _exists = exists ?? true,
        _fileSystem = fileSystem;

  @override
  final String path;

  final List<String> _files;
  bool _exists;
  final MockFileSystem? _fileSystem;

  @override
  bool existsSync() {
    return _exists;
  }

  @override
  List<FileSystemEntity> listSync({
    bool recursive = false,
    bool followLinks = true,
  }) {
    if (!_exists) {
      throw FileSystemException('Cannot list non-existent directory', path);
    }

    final entities = <FileSystemEntity>[];

    for (final filePath in _files) {
      // Check if file is in this directory
      final relativePath =
          filePath.replaceFirst(path, '').replaceFirst('/', '');

      if (recursive) {
        // Include all files recursively
        entities.add(MockFile(
          path: filePath,
          content: _fileSystem?.getFile(filePath)?.readAsStringSync() ?? '',
          fileSystem: _fileSystem,
        ));
      } else {
        // Only include files directly in this directory (no subdirectories)
        if (!relativePath.contains('/')) {
          entities.add(MockFile(
            path: filePath,
            content: _fileSystem?.getFile(filePath)?.readAsStringSync() ?? '',
            fileSystem: _fileSystem,
          ));
        }
      }
    }

    return entities;
  }

  @override
  void deleteSync({bool recursive = false}) {
    if (!_exists) {
      throw FileSystemException('Cannot delete non-existent directory', path);
    }
    _exists = false;
    _fileSystem?._removeDirectory(path);
  }

  // Unimplemented Directory methods (not needed for our tests)
  @override
  Directory get absolute => throw UnimplementedError();

  @override
  Future<Directory> create({bool recursive = false}) =>
      throw UnimplementedError();

  @override
  void createSync({bool recursive = false}) => throw UnimplementedError();

  @override
  Future<Directory> createTemp([String? prefix]) => throw UnimplementedError();

  @override
  Directory createTempSync([String? prefix]) => throw UnimplementedError();

  @override
  Future<FileSystemEntity> delete({bool recursive = false}) =>
      throw UnimplementedError();

  @override
  Future<bool> exists() => throw UnimplementedError();

  @override
  bool get isAbsolute => throw UnimplementedError();

  @override
  Stream<FileSystemEntity> list({
    bool recursive = false,
    bool followLinks = true,
  }) =>
      throw UnimplementedError();

  @override
  Directory get parent => throw UnimplementedError();

  @override
  Future<Directory> rename(String newPath) => throw UnimplementedError();

  @override
  Directory renameSync(String newPath) => throw UnimplementedError();

  @override
  Future<String> resolveSymbolicLinks() => throw UnimplementedError();

  @override
  String resolveSymbolicLinksSync() => throw UnimplementedError();

  @override
  Future<FileStat> stat() => throw UnimplementedError();

  @override
  FileStat statSync() => throw UnimplementedError();

  @override
  Uri get uri => throw UnimplementedError();

  @override
  Stream<FileSystemEvent> watch({
    int events = FileSystemEvent.all,
    bool recursive = false,
  }) =>
      throw UnimplementedError();
}

/// Manages mock files and directories for testing
///
/// Provides a virtual file system for testing file I/O operations
/// without touching the real file system.
class MockFileSystem {
  final Map<String, MockFile> _files = {};
  final Map<String, MockDirectory> _directories = {};
  final Map<String, List<String>> _operations = {};

  /// Get all files in the file system
  List<MockFile> get files => _files.values.toList();

  /// Get all directories in the file system
  List<MockDirectory> get directories => _directories.values.toList();

  /// Add a file to the file system
  void addFile(String path, String content) {
    _files[path] = MockFile(
      path: path,
      content: content,
      fileSystem: this,
    );
  }

  /// Add a directory to the file system
  void addDirectory(String path, {List<String>? files}) {
    _directories[path] = MockDirectory(
      path: path,
      files: files ?? [],
      fileSystem: this,
    );
  }

  /// Get a file by path
  MockFile? getFile(String path) {
    return _files[path];
  }

  /// Get a directory by path
  MockDirectory? getDirectory(String path) {
    return _directories[path];
  }

  /// Check if a file exists
  bool hasFile(String path) {
    return _files.containsKey(path);
  }

  /// Check if a directory exists
  bool hasDirectory(String path) {
    return _directories.containsKey(path);
  }

  /// Reset the file system
  void reset() {
    _files.clear();
    _directories.clear();
    _operations.clear();
  }

  /// Track an I/O operation
  void _trackOperation(String path, String operation) {
    _operations.putIfAbsent(path, () => []).add(operation);
  }

  /// Get tracked operations for a path
  List<String> getOperations(String path) {
    return _operations[path] ?? [];
  }

  /// Remove a file from the file system
  void _removeFile(String path) {
    _files.remove(path);
  }

  /// Remove a directory from the file system
  void _removeDirectory(String path) {
    _directories.remove(path);
  }
}
