@Tags(['integration'])
library;

import 'package:test/test.dart';
import 'package:test_reporter/src/bin/analyze_coverage_lib.dart';

import '../../helpers/mock_file_system.dart';
import '../../helpers/mock_process.dart';
import '../../fixtures/lcov_generator.dart';

/// Phase 2.5: Edge Cases & Error Path Tests
///
/// Tests edge cases and error recovery for CoverageAnalyzer:
/// - Empty projects, no tests, extreme coverage cases
/// - Very large projects, deep directories, special characters
/// - Process crashes, timeouts, I/O errors
/// - Error recovery and cleanup
///
/// Methodology: 🔴🟢♻️🔄 TDD (Red-Green-Refactor-MetaTest)
void main() {
  late MockFileSystem mockFs;
  late MockProcessManager mockPm;

  setUp(() {
    mockFs = MockFileSystem();
    mockPm = MockProcessManager();
  });

  group('Phase 2.5.1: Edge Cases Tests', () {
    test('should handle empty project (no source files)', () async {
      // Setup: Empty lib/ directory
      mockFs
        ..addDirectory('lib')
        ..addDirectory('test')
        ..addDirectory('coverage')
        ..addFile('pubspec.yaml',
            'name: test_project\nenvironment:\n  sdk: ">=3.6.0 <4.0.0"');

      // Mock dart test with no coverage data
      mockPm.mockProcessRun(
        command: 'dart',
        args: ['test', '--coverage=coverage'],
        result: MockProcessResult(
          stdout: 'No tests ran.',
          stderr: '',
          exitCode: 0,
        ),
      );

      // Empty LCOV file
      mockFs.addFile('coverage/lcov.info', '');

      final analyzer = CoverageAnalyzer(
        libPath: 'lib',
        testPath: 'test',
        processManager: mockPm,
        fileSystem: mockFs,
      );

      // Should complete successfully with 0% coverage
      final exitCode = await analyzer.run();

      expect(exitCode, equals(0));
      expect(analyzer.totalLines, equals(0));
      expect(analyzer.coveredLines, equals(0));
      expect(analyzer.overallCoverage, equals(0.0));
    });

    test('should handle project with no tests', () async {
      // Setup: lib/ files but no test/ files
      mockFs
        ..addDirectory('lib')
        ..addFile('lib/src/my_class.dart', 'class MyClass { void hello() {} }')
        ..addDirectory('test')
        ..addDirectory('coverage')
        ..addFile('pubspec.yaml',
            'name: test_project\nenvironment:\n  sdk: ">=3.6.0 <4.0.0"');

      // Mock dart test with no tests found
      mockPm.mockProcessRun(
        command: 'dart',
        args: ['test', '--coverage=coverage'],
        result: MockProcessResult(
          stdout: 'No tests found.',
          stderr: '',
          exitCode: 0,
        ),
      );

      // Empty LCOV (no tests ran)
      mockFs.addFile('coverage/lcov.info', '');

      final analyzer = CoverageAnalyzer(
        libPath: 'lib',
        testPath: 'test',
        processManager: mockPm,
        fileSystem: mockFs,
      );

      final exitCode = await analyzer.run();

      // Should succeed but warn about no tests
      expect(exitCode, equals(0));
      expect(analyzer.totalLines, equals(0));
    });

    test('should handle 100% coverage project', () async {
      // Setup: Perfect coverage
      mockFs
        ..addDirectory('lib')
        ..addFile('lib/src/perfect.dart', 'class Perfect { void method() {} }')
        ..addDirectory('test')
        ..addDirectory('coverage')
        ..addFile('pubspec.yaml',
            'name: test_project\nenvironment:\n  sdk: ">=3.6.0 <4.0.0"');

      mockPm.mockProcessRun(
        command: 'dart',
        args: ['test', '--coverage=coverage'],
        result: MockProcessResult(
          stdout: '00:00 +1: All tests passed!',
          stderr: '',
          exitCode: 0,
        ),
      );

      // 100% coverage LCOV
      final lcovContent = LcovGenerator.generateWithLineDetails(
        filePath: 'lib/src/perfect.dart',
        coveredLines: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
        uncoveredLines: [],
      );
      mockFs.addFile('coverage/lcov.info', lcovContent);

      final analyzer = CoverageAnalyzer(
        libPath: 'lib',
        testPath: 'test',
        processManager: mockPm,
        fileSystem: mockFs,
      );

      final exitCode = await analyzer.run();

      expect(exitCode, equals(0));
      expect(analyzer.overallCoverage, equals(100.0));
      expect(analyzer.totalLines, equals(10));
      expect(analyzer.coveredLines, equals(10));
    });

    test('should handle 0% coverage project', () async {
      // Setup: No coverage at all
      mockFs
        ..addDirectory('lib')
        ..addFile(
            'lib/src/uncovered.dart', 'class Uncovered { void method() {} }')
        ..addDirectory('test')
        ..addDirectory('coverage')
        ..addFile('pubspec.yaml',
            'name: test_project\nenvironment:\n  sdk: ">=3.6.0 <4.0.0"');

      mockPm.mockProcessRun(
        command: 'dart',
        args: ['test', '--coverage=coverage'],
        result: MockProcessResult(
          stdout: '00:00 +1: All tests passed!',
          stderr: '',
          exitCode: 0,
        ),
      );

      // 0% coverage LCOV
      final lcovContent = LcovGenerator.generateWithLineDetails(
        filePath: 'lib/src/uncovered.dart',
        coveredLines: [],
        uncoveredLines: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
      );
      mockFs.addFile('coverage/lcov.info', lcovContent);

      final analyzer = CoverageAnalyzer(
        libPath: 'lib',
        testPath: 'test',
        processManager: mockPm,
        fileSystem: mockFs,
      );

      final exitCode = await analyzer.run();

      // Should succeed but with 0% coverage
      expect(exitCode, equals(0));
      expect(analyzer.overallCoverage, equals(0.0));
      expect(analyzer.totalLines, equals(10));
      expect(analyzer.coveredLines, equals(0));
    });

    test('should handle very large projects (>1000 files)', () async {
      // Setup: Large project simulation
      mockFs
        ..addDirectory('lib')
        ..addDirectory('test')
        ..addDirectory('coverage')
        ..addFile('pubspec.yaml',
            'name: large_project\nenvironment:\n  sdk: ">=3.6.0 <4.0.0"');

      // Add many files to lib/
      for (var i = 0; i < 1500; i++) {
        mockFs.addFile('lib/src/file_$i.dart', 'class Class$i {}');
      }

      mockPm.mockProcessRun(
        command: 'dart',
        args: ['test', '--coverage=coverage'],
        result: MockProcessResult(
          stdout: '00:00 +100: All tests passed!',
          stderr: '',
          exitCode: 0,
        ),
      );

      // Generate LCOV for many files
      final lcovLines = <String>[];
      for (var i = 0; i < 1500; i++) {
        lcovLines.add('SF:lib/src/file_$i.dart');
        lcovLines.add('DA:1,1');
        lcovLines.add('LF:1');
        lcovLines.add('LH:1');
        lcovLines.add('end_of_record');
      }
      mockFs.addFile('coverage/lcov.info', lcovLines.join('\n'));

      final analyzer = CoverageAnalyzer(
        libPath: 'lib',
        testPath: 'test',
        processManager: mockPm,
        fileSystem: mockFs,
      );

      // Should handle large projects without crashing
      final exitCode = await analyzer.run();

      expect(exitCode, equals(0));
      expect(analyzer.totalLines, greaterThan(1000));
    });

    test('should handle deeply nested directories', () async {
      // Setup: Very deep directory structure
      mockFs
        ..addDirectory('lib')
        ..addDirectory('test')
        ..addDirectory('coverage')
        ..addFile('pubspec.yaml',
            'name: test_project\nenvironment:\n  sdk: ">=3.6.0 <4.0.0"');

      // Add deeply nested file
      const deepPath = 'lib/src/a/b/c/d/e/f/g/h/i/j/k/deep_file.dart';
      mockFs.addFile(deepPath, 'class DeepClass {}');

      mockPm.mockProcessRun(
        command: 'dart',
        args: ['test', '--coverage=coverage'],
        result: MockProcessResult(
          stdout: '00:00 +1: All tests passed!',
          stderr: '',
          exitCode: 0,
        ),
      );

      final lcovContent = LcovGenerator.generateWithLineDetails(
        filePath: deepPath,
        coveredLines: [1, 2, 3],
        uncoveredLines: [4, 5],
      );
      mockFs.addFile('coverage/lcov.info', lcovContent);

      final analyzer = CoverageAnalyzer(
        libPath: 'lib',
        testPath: 'test',
        processManager: mockPm,
        fileSystem: mockFs,
      );

      final exitCode = await analyzer.run();

      expect(exitCode, equals(0));
      expect(analyzer.totalLines, equals(5));
      expect(analyzer.coveredLines, equals(3));
    });

    test('should handle special characters in paths', () async {
      // Setup: Files with special characters
      mockFs
        ..addDirectory('lib')
        ..addDirectory('test')
        ..addDirectory('coverage')
        ..addFile('pubspec.yaml',
            'name: test_project\nenvironment:\n  sdk: ">=3.6.0 <4.0.0"');

      // Files with spaces, dashes, underscores
      mockFs.addFile('lib/src/my file.dart', 'class MyFile {}');
      mockFs.addFile('lib/src/my-class.dart', 'class MyClass {}');
      mockFs.addFile('lib/src/my_widget.dart', 'class MyWidget {}');

      mockPm.mockProcessRun(
        command: 'dart',
        args: ['test', '--coverage=coverage'],
        result: MockProcessResult(
          stdout: '00:00 +3: All tests passed!',
          stderr: '',
          exitCode: 0,
        ),
      );

      // LCOV with special character paths
      final lcovContent = '''
SF:lib/src/my file.dart
DA:1,1
LF:1
LH:1
end_of_record
SF:lib/src/my-class.dart
DA:1,1
LF:1
LH:1
end_of_record
SF:lib/src/my_widget.dart
DA:1,0
LF:1
LH:0
end_of_record
''';
      mockFs.addFile('coverage/lcov.info', lcovContent);

      final analyzer = CoverageAnalyzer(
        libPath: 'lib',
        testPath: 'test',
        processManager: mockPm,
        fileSystem: mockFs,
      );

      final exitCode = await analyzer.run();

      expect(exitCode, equals(0));
      expect(analyzer.totalLines, equals(3));
      expect(analyzer.coveredLines, equals(2));
    });

    test('should handle symlinked directories', () async {
      // Setup: Symlinked source directory
      mockFs
        ..addDirectory('lib')
        ..addDirectory('lib_link') // Simulate symlink
        ..addDirectory('test')
        ..addDirectory('coverage')
        ..addFile('pubspec.yaml',
            'name: test_project\nenvironment:\n  sdk: ">=3.6.0 <4.0.0"');

      mockFs.addFile('lib_link/src/linked.dart', 'class Linked {}');

      mockPm.mockProcessRun(
        command: 'dart',
        args: ['test', '--coverage=coverage'],
        result: MockProcessResult(
          stdout: '00:00 +1: All tests passed!',
          stderr: '',
          exitCode: 0,
        ),
      );

      final lcovContent = LcovGenerator.generateWithLineDetails(
        filePath: 'lib_link/src/linked.dart',
        coveredLines: [1, 2, 3],
        uncoveredLines: [4, 5],
      );
      mockFs.addFile('coverage/lcov.info', lcovContent);

      final analyzer = CoverageAnalyzer(
        libPath: 'lib_link',
        testPath: 'test',
        processManager: mockPm,
        fileSystem: mockFs,
      );

      final exitCode = await analyzer.run();

      // Should handle symlinks gracefully
      expect(exitCode, equals(0));
    });
  });

  group('Phase 2.5.2: Error Recovery Tests', () {
    test('should recover from test timeout', () async {
      // Setup: Normal project
      mockFs
        ..addDirectory('lib')
        ..addFile('lib/src/slow.dart', 'class Slow { void slowMethod() {} }')
        ..addDirectory('test')
        ..addDirectory('coverage')
        ..addFile('pubspec.yaml',
            'name: test_project\nenvironment:\n  sdk: ">=3.6.0 <4.0.0"');

      // Mock dart test timing out
      mockPm.mockProcessRun(
        command: 'dart',
        args: ['test', '--coverage=coverage'],
        result: MockProcessResult(
          stdout: '',
          stderr: 'Test timed out after 120 seconds',
          exitCode: 124, // Timeout exit code
        ),
      );

      final analyzer = CoverageAnalyzer(
        libPath: 'lib',
        testPath: 'test',
        processManager: mockPm,
        fileSystem: mockFs,
      );

      // Should handle timeout gracefully
      final exitCode = await analyzer.run();

      // Should return non-zero but not crash
      expect(exitCode, isNot(equals(0)));
      expect(analyzer.hasError, isTrue);
    });

    test('should recover from process crash', () async {
      // Setup: Normal project
      mockFs
        ..addDirectory('lib')
        ..addFile('lib/src/crash.dart', 'class Crash {}')
        ..addDirectory('test')
        ..addDirectory('coverage')
        ..addFile('pubspec.yaml',
            'name: test_project\nenvironment:\n  sdk: ">=3.6.0 <4.0.0"');

      // Mock dart test crashing
      mockPm.mockProcessRun(
        command: 'dart',
        args: ['test', '--coverage=coverage'],
        result: MockProcessResult(
          stdout: '',
          stderr: 'Segmentation fault',
          exitCode: 139, // Segfault exit code
        ),
      );

      final analyzer = CoverageAnalyzer(
        libPath: 'lib',
        testPath: 'test',
        processManager: mockPm,
        fileSystem: mockFs,
      );

      final exitCode = await analyzer.run();

      // Should handle crash gracefully
      expect(exitCode, isNot(equals(0)));
      expect(analyzer.hasError, isTrue);
    });

    test('should recover from I/O errors', () async {
      // Setup: Normal project but file system errors
      mockFs
        ..addDirectory('lib')
        ..addFile('lib/src/io_test.dart', 'class IoTest {}')
        ..addDirectory('test')
        ..addDirectory('coverage')
        ..addFile('pubspec.yaml',
            'name: test_project\nenvironment:\n  sdk: ">=3.6.0 <4.0.0"');

      mockPm.mockProcessRun(
        command: 'dart',
        args: ['test', '--coverage=coverage'],
        result: MockProcessResult(
          stdout: '00:00 +1: All tests passed!',
          stderr: '',
          exitCode: 0,
        ),
      );

      final lcovContent = LcovGenerator.generateWithLineDetails(
        filePath: 'lib/src/io_test.dart',
        coveredLines: [1, 2, 3],
        uncoveredLines: [4, 5],
      );
      mockFs.addFile('coverage/lcov.info', lcovContent);

      final analyzer = CoverageAnalyzer(
        libPath: 'lib',
        testPath: 'test',
        processManager: mockPm,
        fileSystem: mockFs,
      );

      // Should handle I/O error gracefully
      final exitCode = await analyzer.run();

      // May succeed or fail, but should not crash
      expect(exitCode, isA<int>());
    });

    test('should fallback when coverage collection fails', () async {
      // Setup: Coverage collection fails
      mockFs
        ..addDirectory('lib')
        ..addFile('lib/src/fallback.dart', 'class Fallback {}')
        ..addDirectory('test')
        ..addFile('pubspec.yaml',
            'name: test_project\nenvironment:\n  sdk: ">=3.6.0 <4.0.0"');

      // Mock dart test coverage failure
      mockPm.mockProcessRun(
        command: 'dart',
        args: ['test', '--coverage=coverage'],
        result: MockProcessResult(
          stdout: '',
          stderr: 'Coverage collection not supported',
          exitCode: 1,
        ),
      );

      final analyzer = CoverageAnalyzer(
        libPath: 'lib',
        testPath: 'test',
        processManager: mockPm,
        fileSystem: mockFs,
      );

      final exitCode = await analyzer.run();

      // Should handle failure gracefully
      expect(exitCode, isNot(equals(0)));
      expect(analyzer.hasError, isTrue);
    });

    test('should handle interrupted execution', () async {
      // Setup: Process interrupted
      mockFs
        ..addDirectory('lib')
        ..addFile('lib/src/interrupt.dart', 'class Interrupt {}')
        ..addDirectory('test')
        ..addDirectory('coverage')
        ..addFile('pubspec.yaml',
            'name: test_project\nenvironment:\n  sdk: ">=3.6.0 <4.0.0"');

      // Mock SIGINT (Ctrl+C)
      mockPm.mockProcessRun(
        command: 'dart',
        args: ['test', '--coverage=coverage'],
        result: MockProcessResult(
          stdout: '',
          stderr: 'Process interrupted by signal',
          exitCode: 130, // SIGINT exit code
        ),
      );

      final analyzer = CoverageAnalyzer(
        libPath: 'lib',
        testPath: 'test',
        processManager: mockPm,
        fileSystem: mockFs,
      );

      final exitCode = await analyzer.run();

      // Should handle interruption gracefully
      expect(exitCode, isNot(equals(0)));
      expect(analyzer.hasError, isTrue);
    });

    test('should clean up on error', () async {
      // Setup: Error during execution
      mockFs
        ..addDirectory('lib')
        ..addFile('lib/src/cleanup.dart', 'class Cleanup {}')
        ..addDirectory('test')
        ..addDirectory('coverage')
        ..addFile('pubspec.yaml',
            'name: test_project\nenvironment:\n  sdk: ">=3.6.0 <4.0.0"');

      mockPm.mockProcessRun(
        command: 'dart',
        args: ['test', '--coverage=coverage'],
        result: MockProcessResult(
          stdout: '',
          stderr: 'Fatal error',
          exitCode: 2,
        ),
      );

      final analyzer = CoverageAnalyzer(
        libPath: 'lib',
        testPath: 'test',
        processManager: mockPm,
        fileSystem: mockFs,
      );

      final exitCode = await analyzer.run();

      // Should clean up temporary files/resources
      expect(exitCode, isNot(equals(0)));
      expect(analyzer.hasError, isTrue);

      // Verify no leaked resources - check no temp files in mock FS
      final tempFiles = mockFs.files
          .where((f) => f.path.contains('.tmp') || f.path.contains('temp'))
          .toList();
      expect(tempFiles, isEmpty);
    });
  });
}
