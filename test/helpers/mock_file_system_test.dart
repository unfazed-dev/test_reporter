/// Tests for MockFileSystem infrastructure
///
/// Coverage Target: 100% of mock_file_system.dart
/// Test Strategy: Unit tests for mocking File and Directory operations
/// TDD Approach: 🔴 RED → 🟢 GREEN → ♻️ REFACTOR → 🔄 META-TEST
///
/// This infrastructure enables testing of all bin/ analyzers by mocking
/// file system operations (File I/O, directory listing, path resolution).

import 'dart:io';

import 'package:test/test.dart';

import 'mock_file_system.dart';

void main() {
  group('MockFile', () {
    test('should create file with content', () {
      final file = MockFile(
        path: '/test/file.txt',
        content: 'test content',
      );

      expect(file.path, equals('/test/file.txt'));
      expect(file.readAsStringSync(), equals('test content'));
    });

    test('should read file content as string', () {
      final file = MockFile(
        path: '/test/file.txt',
        content: 'line 1\nline 2\nline 3',
      );

      final content = file.readAsStringSync();
      expect(content, equals('line 1\nline 2\nline 3'));
    });

    test('should read file content as lines', () {
      final file = MockFile(
        path: '/test/file.txt',
        content: 'line 1\nline 2\nline 3',
      );

      final lines = file.readAsLinesSync();
      expect(lines, equals(['line 1', 'line 2', 'line 3']));
    });

    test('should check if file exists', () {
      final file = MockFile(
        path: '/test/file.txt',
        content: 'content',
      );

      expect(file.existsSync(), isTrue);
    });

    test('should return file length', () {
      final file = MockFile(
        path: '/test/file.txt',
        content: 'hello world',
      );

      expect(file.lengthSync(), equals(11)); // 'hello world' = 11 chars
    });

    test('should write to file', () {
      final file = MockFile(
        path: '/test/file.txt',
        content: 'original',
      );

      file.writeAsStringSync('updated content');
      expect(file.readAsStringSync(), equals('updated content'));
    });

    test('should delete file', () {
      final file = MockFile(
        path: '/test/file.txt',
        content: 'content',
      );

      expect(file.existsSync(), isTrue);
      file.deleteSync();
      expect(file.existsSync(), isFalse);
    });

    test('should handle file not found error', () {
      final file = MockFile(
        path: '/test/missing.txt',
        content: '',
        exists: false,
      );

      expect(file.existsSync(), isFalse);
      expect(
        () => file.readAsStringSync(),
        throwsA(isA<FileSystemException>()),
      );
    });
  });

  group('MockDirectory', () {
    test('should create directory', () {
      final dir = MockDirectory(path: '/test/dir');

      expect(dir.path, equals('/test/dir'));
      expect(dir.existsSync(), isTrue);
    });

    test('should check if directory exists', () {
      final dir = MockDirectory(
        path: '/test/dir',
        exists: true,
      );

      expect(dir.existsSync(), isTrue);
    });

    test('should list files recursively', () {
      final dir = MockDirectory(
        path: '/test',
        files: [
          '/test/file1.txt',
          '/test/subdir/file2.txt',
          '/test/subdir/nested/file3.txt',
        ],
      );

      final files = dir.listSync(recursive: true);
      expect(files, hasLength(3));
      expect(
          files.map((f) => f.path),
          containsAll([
            '/test/file1.txt',
            '/test/subdir/file2.txt',
            '/test/subdir/nested/file3.txt',
          ]));
    });

    test('should list files non-recursively', () {
      final dir = MockDirectory(
        path: '/test',
        files: [
          '/test/file1.txt',
          '/test/file2.txt',
          '/test/subdir/file3.txt', // Should not be included
        ],
      );

      final files = dir.listSync(recursive: false);
      expect(files, hasLength(2));
      expect(
          files.map((f) => f.path),
          containsAll([
            '/test/file1.txt',
            '/test/file2.txt',
          ]));
    });

    test('should delete directory', () {
      final dir = MockDirectory(path: '/test/dir');

      expect(dir.existsSync(), isTrue);
      dir.deleteSync(recursive: true);
      expect(dir.existsSync(), isFalse);
    });

    test('should handle directory not found error', () {
      final dir = MockDirectory(
        path: '/test/missing',
        exists: false,
      );

      expect(dir.existsSync(), isFalse);
      expect(
        () => dir.listSync(),
        throwsA(isA<FileSystemException>()),
      );
    });
  });

  group('MockFileSystem', () {
    test('should create virtual file system', () {
      final fs = MockFileSystem();

      expect(fs, isNotNull);
      expect(fs.files, isEmpty);
      expect(fs.directories, isEmpty);
    });

    test('should add files to virtual file system', () {
      final fs = MockFileSystem();

      fs.addFile('/test/file1.txt', 'content 1');
      fs.addFile('/test/file2.txt', 'content 2');

      expect(fs.files, hasLength(2));
      expect(fs.getFile('/test/file1.txt')?.readAsStringSync(),
          equals('content 1'));
      expect(fs.getFile('/test/file2.txt')?.readAsStringSync(),
          equals('content 2'));
    });

    test('should add directories to virtual file system', () {
      final fs = MockFileSystem();

      fs.addDirectory('/test/dir1');
      fs.addDirectory('/test/dir2');

      expect(fs.directories, hasLength(2));
      expect(fs.getDirectory('/test/dir1')?.existsSync(), isTrue);
      expect(fs.getDirectory('/test/dir2')?.existsSync(), isTrue);
    });

    test('should query files and directories', () {
      final fs = MockFileSystem();

      fs.addFile('/test/file.txt', 'content');
      fs.addDirectory('/test/dir');

      expect(fs.hasFile('/test/file.txt'), isTrue);
      expect(fs.hasFile('/test/missing.txt'), isFalse);
      expect(fs.hasDirectory('/test/dir'), isTrue);
      expect(fs.hasDirectory('/test/missing'), isFalse);
    });

    test('should reset file system', () {
      final fs = MockFileSystem();

      fs.addFile('/test/file.txt', 'content');
      fs.addDirectory('/test/dir');

      expect(fs.files, hasLength(1));
      expect(fs.directories, hasLength(1));

      fs.reset();

      expect(fs.files, isEmpty);
      expect(fs.directories, isEmpty);
    });

    test('should track I/O operations', () {
      final fs = MockFileSystem();

      fs.addFile('/test/file.txt', 'content');
      final file = fs.getFile('/test/file.txt')!;

      file.readAsStringSync();
      file.writeAsStringSync('new content');

      final operations = fs.getOperations('/test/file.txt');
      expect(operations, contains('read'));
      expect(operations, contains('write'));
      expect(operations, hasLength(2));
    });
  });
}
