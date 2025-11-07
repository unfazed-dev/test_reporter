import 'package:test/test.dart';
import 'package:test_reporter/src/bin/analyze_coverage_lib.dart';
import '../../helpers/mock_process.dart';
import '../../helpers/mock_file_system.dart';
import '../../fixtures/lcov_generator.dart';
import '../../fixtures/sample_pubspec.dart';

/// Integration tests for CoverageAnalyzer LCOV Parsing (Phase 2.2)
///
/// Tests the LCOV parsing and coverage calculation logic:
/// - Basic LCOV file parsing
/// - Branch coverage data extraction
/// - Multi-file aggregation
/// - Line hit count tracking
/// - Malformed data handling
/// - Coverage percentage calculations
///
/// Uses mocked Process and FileSystem to simulate coverage data.
void main() {
  group('Coverage Analyzer LCOV Parsing Tests', () {
    late MockProcessManager processManager;
    late MockFileSystem fileSystem;

    setUp(() {
      processManager = MockProcessManager();
      fileSystem = MockFileSystem();
    });

    // Suite 1: LCOV Parsing Tests (8 tests)

    test('should parse basic LCOV file format', () async {
      // Arrange: Simple LCOV with one file
      fileSystem
        ..addFile(
          'pubspec.yaml',
          SamplePubspec.generateDartPackage(
            name: 'test_package',
            version: '1.0.0',
          ),
        )
        ..addFile('lib/src/simple.dart', 'class Simple {}')
        ..addFile('test/test.dart', 'void main() {}')
        ..addDirectory('coverage')
        ..addFile(
          'coverage/lcov.info',
          '''
SF:lib/src/simple.dart
DA:1,1
DA:2,1
DA:3,0
DA:4,1
DA:5,0
end_of_record
''',
        );

      processManager.mockProcessRun(
        command: 'dart',
        args: ['test', '--coverage=coverage'],
        result: MockProcessResult(stdout: '', stderr: '', exitCode: 0),
      );

      // Act
      final analyzer = CoverageAnalyzer(
        testPath: 'test',
        libPath: 'lib/src',
        processManager: processManager,
        fileSystem: fileSystem,
      );
      await analyzer.run();

      // Assert: 3 covered out of 5 lines = 60%
      expect(analyzer.totalLines, equals(5));
      expect(analyzer.coveredLines, equals(3));
      expect(analyzer.overallCoverage, equals(60.0));
    });

    test('should parse LCOV with branch coverage data', () async {
      // Arrange: LCOV with BRDA (branch data) records
      fileSystem
        ..addFile(
          'pubspec.yaml',
          SamplePubspec.generateDartPackage(
            name: 'test_package',
            version: '1.0.0',
          ),
        )
        ..addFile('lib/src/branched.dart', 'class Branched {}')
        ..addFile('test/test.dart', 'void main() {}')
        ..addDirectory('coverage')
        ..addFile(
          'coverage/lcov.info',
          '''
SF:lib/src/branched.dart
DA:1,1
DA:2,1
DA:3,1
BRDA:3,0,0,1
BRDA:3,0,1,0
BRDA:5,0,0,1
BRDA:5,0,1,1
end_of_record
''',
        );

      processManager.mockProcessRun(
        command: 'dart',
        args: ['test', '--coverage=coverage'],
        result: MockProcessResult(stdout: '', stderr: '', exitCode: 0),
      );

      // Act
      final analyzer = CoverageAnalyzer(
        testPath: 'test',
        libPath: 'lib/src',
        branchCoverage: true,
        processManager: processManager,
        fileSystem: fileSystem,
      );
      await analyzer.run();

      // Assert: Line coverage + branch coverage
      expect(analyzer.totalLines, equals(3));
      expect(analyzer.coveredLines, equals(3));
      expect(analyzer.totalBranches, equals(4));
      expect(analyzer.coveredBranches, equals(3)); // One branch not covered
      expect(analyzer.branchCoveragePercent, equals(75.0)); // 3/4 = 75%
    });

    test('should parse LCOV with multiple files', () async {
      // Arrange: LCOV with 3 different files
      fileSystem
        ..addFile(
          'pubspec.yaml',
          SamplePubspec.generateDartPackage(
            name: 'test_package',
            version: '1.0.0',
          ),
        )
        ..addFile('lib/src/file1.dart', 'class File1 {}')
        ..addFile('lib/src/file2.dart', 'class File2 {}')
        ..addFile('lib/src/file3.dart', 'class File3 {}')
        ..addFile('test/test.dart', 'void main() {}')
        ..addDirectory('coverage')
        ..addFile(
          'coverage/lcov.info',
          '''
SF:lib/src/file1.dart
DA:1,1
DA:2,1
DA:3,1
end_of_record
SF:lib/src/file2.dart
DA:1,1
DA:2,0
DA:3,0
DA:4,0
end_of_record
SF:lib/src/file3.dart
DA:1,1
DA:2,1
end_of_record
''',
        );

      processManager.mockProcessRun(
        command: 'dart',
        args: ['test', '--coverage=coverage'],
        result: MockProcessResult(stdout: '', stderr: '', exitCode: 0),
      );

      // Act
      final analyzer = CoverageAnalyzer(
        testPath: 'test',
        libPath: 'lib/src',
        processManager: processManager,
        fileSystem: fileSystem,
      );
      await analyzer.run();

      // Assert: 3 files, total 9 lines, 6 covered = 66.67%
      expect(analyzer.fileCount, equals(3));
      expect(analyzer.totalLines, equals(9));
      expect(analyzer.coveredLines, equals(6));
      expect(analyzer.overallCoverage, closeTo(66.67, 0.01));
    });

    test('should extract covered lines correctly', () async {
      // Arrange: LCOV with mix of covered/uncovered lines
      fileSystem
        ..addFile(
          'pubspec.yaml',
          SamplePubspec.generateDartPackage(
            name: 'test_package',
            version: '1.0.0',
          ),
        )
        ..addFile('lib/src/module.dart', 'class Module {}')
        ..addFile('test/test.dart', 'void main() {}')
        ..addDirectory('coverage')
        ..addFile(
          'coverage/lcov.info',
          '''
SF:lib/src/module.dart
DA:1,5
DA:2,10
DA:3,0
DA:4,1
DA:5,0
DA:6,3
end_of_record
''',
        );

      processManager.mockProcessRun(
        command: 'dart',
        args: ['test', '--coverage=coverage'],
        result: MockProcessResult(stdout: '', stderr: '', exitCode: 0),
      );

      // Act
      final analyzer = CoverageAnalyzer(
        testPath: 'test',
        libPath: 'lib/src',
        processManager: processManager,
        fileSystem: fileSystem,
      );
      await analyzer.run();

      // Assert: Lines 1,2,4,6 covered (4 out of 6)
      expect(analyzer.totalLines, equals(6));
      expect(analyzer.coveredLines, equals(4));
      expect(analyzer.overallCoverage, closeTo(66.67, 0.01));
    });

    test('should extract uncovered lines correctly', () async {
      // Arrange: LCOV with specific uncovered lines
      fileSystem
        ..addFile(
          'pubspec.yaml',
          SamplePubspec.generateDartPackage(
            name: 'test_package',
            version: '1.0.0',
          ),
        )
        ..addFile('lib/src/partial.dart', 'class Partial {}')
        ..addFile('test/test.dart', 'void main() {}')
        ..addDirectory('coverage')
        ..addFile(
          'coverage/lcov.info',
          '''
SF:lib/src/partial.dart
DA:1,1
DA:2,0
DA:3,0
DA:4,1
DA:5,1
DA:6,0
DA:7,1
DA:8,1
DA:9,0
DA:10,1
end_of_record
''',
        );

      processManager.mockProcessRun(
        command: 'dart',
        args: ['test', '--coverage=coverage'],
        result: MockProcessResult(stdout: '', stderr: '', exitCode: 0),
      );

      // Act
      final analyzer = CoverageAnalyzer(
        testPath: 'test',
        libPath: 'lib/src',
        processManager: processManager,
        fileSystem: fileSystem,
      );
      await analyzer.run();

      // Assert: 6 covered, 4 uncovered (lines 2,3,6,9)
      expect(analyzer.totalLines, equals(10));
      expect(analyzer.coveredLines, equals(6));
      expect(analyzer.overallCoverage, equals(60.0));
    });

    test('should extract line hit counts', () async {
      // Arrange: LCOV with various hit counts
      fileSystem
        ..addFile(
          'pubspec.yaml',
          SamplePubspec.generateDartPackage(
            name: 'test_package',
            version: '1.0.0',
          ),
        )
        ..addFile('lib/src/hits.dart', 'class Hits {}')
        ..addFile('test/test.dart', 'void main() {}')
        ..addDirectory('coverage')
        ..addFile(
          'coverage/lcov.info',
          '''
SF:lib/src/hits.dart
DA:1,100
DA:2,50
DA:3,1
DA:4,0
DA:5,25
end_of_record
''',
        );

      processManager.mockProcessRun(
        command: 'dart',
        args: ['test', '--coverage=coverage'],
        result: MockProcessResult(stdout: '', stderr: '', exitCode: 0),
      );

      // Act
      final analyzer = CoverageAnalyzer(
        testPath: 'test',
        libPath: 'lib/src',
        processManager: processManager,
        fileSystem: fileSystem,
      );
      await analyzer.run();

      // Assert: Any hit count > 0 means covered
      expect(analyzer.totalLines, equals(5));
      expect(analyzer.coveredLines, equals(4)); // Lines 1,2,3,5
      expect(analyzer.overallCoverage, equals(80.0));
    });

    test('should handle malformed LCOV gracefully', () async {
      // Arrange: LCOV with invalid/incomplete records
      fileSystem
        ..addFile(
          'pubspec.yaml',
          SamplePubspec.generateDartPackage(
            name: 'test_package',
            version: '1.0.0',
          ),
        )
        ..addFile('lib/src/module.dart', 'class Module {}')
        ..addFile('test/test.dart', 'void main() {}')
        ..addDirectory('coverage')
        ..addFile(
          'coverage/lcov.info',
          '''
SF:lib/src/module.dart
DA:1,1
INVALID_LINE
DA:2,invalid
DA:3,1
BRDA:malformed
end_of_record
''',
        );

      processManager.mockProcessRun(
        command: 'dart',
        args: ['test', '--coverage=coverage'],
        result: MockProcessResult(stdout: '', stderr: '', exitCode: 0),
      );

      // Act
      final analyzer = CoverageAnalyzer(
        testPath: 'test',
        libPath: 'lib/src',
        processManager: processManager,
        fileSystem: fileSystem,
      );
      final exitCode = await analyzer.run();

      // Assert: Should parse valid lines only
      expect(exitCode, equals(0));
      expect(analyzer.totalLines, equals(2)); // Only valid DA lines
      expect(analyzer.coveredLines, equals(2));
    });

    test('should handle empty LCOV file', () async {
      // Arrange: Empty LCOV file
      fileSystem
        ..addFile(
          'pubspec.yaml',
          SamplePubspec.generateDartPackage(
            name: 'test_package',
            version: '1.0.0',
          ),
        )
        ..addFile('lib/src/module.dart', 'class Module {}')
        ..addFile('test/test.dart', 'void main() {}')
        ..addDirectory('coverage')
        ..addFile('coverage/lcov.info', '');

      processManager.mockProcessRun(
        command: 'dart',
        args: ['test', '--coverage=coverage'],
        result: MockProcessResult(stdout: '', stderr: '', exitCode: 0),
      );

      // Act
      final analyzer = CoverageAnalyzer(
        testPath: 'test',
        libPath: 'lib/src',
        processManager: processManager,
        fileSystem: fileSystem,
      );
      await analyzer.run();

      // Assert: Zero coverage
      expect(analyzer.totalLines, equals(0));
      expect(analyzer.coveredLines, equals(0));
      expect(analyzer.overallCoverage, equals(0.0));
      expect(analyzer.fileCount, equals(0));
    });

    // Suite 2: Coverage Calculation Tests (6 tests)

    test('should calculate file coverage percentage', () async {
      // Arrange: Single file with specific coverage
      fileSystem
        ..addFile(
          'pubspec.yaml',
          SamplePubspec.generateDartPackage(
            name: 'test_package',
            version: '1.0.0',
          ),
        )
        ..addFile('lib/src/single.dart', 'class Single {}')
        ..addFile('test/test.dart', 'void main() {}')
        ..addDirectory('coverage')
        ..addFile(
          'coverage/lcov.info',
          LcovGenerator.generate(
            filePath: 'lib/src/single.dart',
            totalLines: 80,
            coveredLines: 72,
          ),
        );

      processManager.mockProcessRun(
        command: 'dart',
        args: ['test', '--coverage=coverage'],
        result: MockProcessResult(stdout: '', stderr: '', exitCode: 0),
      );

      // Act
      final analyzer = CoverageAnalyzer(
        testPath: 'test',
        libPath: 'lib/src',
        processManager: processManager,
        fileSystem: fileSystem,
      );
      await analyzer.run();

      // Assert: 72/80 = 90%
      expect(analyzer.overallCoverage, equals(90.0));
    });

    test('should calculate overall coverage percentage', () async {
      // Arrange: Multiple files with different coverage
      fileSystem
        ..addFile(
          'pubspec.yaml',
          SamplePubspec.generateDartPackage(
            name: 'test_package',
            version: '1.0.0',
          ),
        )
        ..addFile('lib/src/file1.dart', 'class File1 {}')
        ..addFile('lib/src/file2.dart', 'class File2 {}')
        ..addFile('lib/src/file3.dart', 'class File3 {}')
        ..addFile('test/test.dart', 'void main() {}')
        ..addDirectory('coverage')
        ..addFile(
          'coverage/lcov.info',
          LcovGenerator.generateMultiple([
            LcovFileData(
              filePath: 'lib/src/file1.dart',
              totalLines: 50,
              coveredLines: 50, // 100%
            ),
            LcovFileData(
              filePath: 'lib/src/file2.dart',
              totalLines: 50,
              coveredLines: 25, // 50%
            ),
            LcovFileData(
              filePath: 'lib/src/file3.dart',
              totalLines: 100,
              coveredLines: 75, // 75%
            ),
          ]),
        );

      processManager.mockProcessRun(
        command: 'dart',
        args: ['test', '--coverage=coverage'],
        result: MockProcessResult(stdout: '', stderr: '', exitCode: 0),
      );

      // Act
      final analyzer = CoverageAnalyzer(
        testPath: 'test',
        libPath: 'lib/src',
        processManager: processManager,
        fileSystem: fileSystem,
      );
      await analyzer.run();

      // Assert: (50+25+75)/(50+50+100) = 150/200 = 75%
      expect(analyzer.overallCoverage, equals(75.0));
    });

    test('should calculate branch coverage percentage', () async {
      // Arrange: File with branch coverage
      fileSystem
        ..addFile(
          'pubspec.yaml',
          SamplePubspec.generateDartPackage(
            name: 'test_package',
            version: '1.0.0',
          ),
        )
        ..addFile('lib/src/branched.dart', 'class Branched {}')
        ..addFile('test/test.dart', 'void main() {}')
        ..addDirectory('coverage')
        ..addFile(
          'coverage/lcov.info',
          LcovGenerator.generateWithBranches(
            filePath: 'lib/src/branched.dart',
            totalLines: 100,
            coveredLines: 85,
            totalBranches: 40,
            coveredBranches: 32,
          ),
        );

      processManager.mockProcessRun(
        command: 'dart',
        args: ['test', '--coverage=coverage'],
        result: MockProcessResult(stdout: '', stderr: '', exitCode: 0),
      );

      // Act
      final analyzer = CoverageAnalyzer(
        testPath: 'test',
        libPath: 'lib/src',
        branchCoverage: true,
        processManager: processManager,
        fileSystem: fileSystem,
      );
      await analyzer.run();

      // Assert: Branch coverage = 32/40 = 80%
      expect(analyzer.branchCoveragePercent, equals(80.0));
    });

    test('should handle 0 lines case', () async {
      // Arrange: LCOV with no DA lines
      fileSystem
        ..addFile(
          'pubspec.yaml',
          SamplePubspec.generateDartPackage(
            name: 'test_package',
            version: '1.0.0',
          ),
        )
        ..addFile('lib/src/module.dart', 'class Module {}')
        ..addFile('test/test.dart', 'void main() {}')
        ..addDirectory('coverage')
        ..addFile(
          'coverage/lcov.info',
          '''
SF:lib/src/module.dart
end_of_record
''',
        );

      processManager.mockProcessRun(
        command: 'dart',
        args: ['test', '--coverage=coverage'],
        result: MockProcessResult(stdout: '', stderr: '', exitCode: 0),
      );

      // Act
      final analyzer = CoverageAnalyzer(
        testPath: 'test',
        libPath: 'lib/src',
        processManager: processManager,
        fileSystem: fileSystem,
      );
      await analyzer.run();

      // Assert: 0 lines, 0% coverage (avoid division by zero)
      expect(analyzer.totalLines, equals(0));
      expect(analyzer.coveredLines, equals(0));
      expect(analyzer.overallCoverage, equals(0.0));
    });

    test('should handle 100% coverage case', () async {
      // Arrange: All lines covered
      fileSystem
        ..addFile(
          'pubspec.yaml',
          SamplePubspec.generateDartPackage(
            name: 'test_package',
            version: '1.0.0',
          ),
        )
        ..addFile('lib/src/perfect.dart', 'class Perfect {}')
        ..addFile('test/test.dart', 'void main() {}')
        ..addDirectory('coverage')
        ..addFile(
          'coverage/lcov.info',
          LcovGenerator.generate(
            filePath: 'lib/src/perfect.dart',
            totalLines: 150,
            coveredLines: 150,
          ),
        );

      processManager.mockProcessRun(
        command: 'dart',
        args: ['test', '--coverage=coverage'],
        result: MockProcessResult(stdout: '', stderr: '', exitCode: 0),
      );

      // Act
      final analyzer = CoverageAnalyzer(
        testPath: 'test',
        libPath: 'lib/src',
        processManager: processManager,
        fileSystem: fileSystem,
      );
      await analyzer.run();

      // Assert: Perfect 100%
      expect(analyzer.totalLines, equals(150));
      expect(analyzer.coveredLines, equals(150));
      expect(analyzer.overallCoverage, equals(100.0));
    });

    test('should aggregate coverage across multiple files', () async {
      // Arrange: 5 files with varying coverage
      fileSystem
        ..addFile(
          'pubspec.yaml',
          SamplePubspec.generateDartPackage(
            name: 'test_package',
            version: '1.0.0',
          ),
        )
        ..addFile('lib/src/file1.dart', 'class File1 {}')
        ..addFile('lib/src/file2.dart', 'class File2 {}')
        ..addFile('lib/src/file3.dart', 'class File3 {}')
        ..addFile('lib/src/file4.dart', 'class File4 {}')
        ..addFile('lib/src/file5.dart', 'class File5 {}')
        ..addFile('test/test.dart', 'void main() {}')
        ..addDirectory('coverage')
        ..addFile(
          'coverage/lcov.info',
          LcovGenerator.generateMultiple([
            LcovFileData(
              filePath: 'lib/src/file1.dart',
              totalLines: 20,
              coveredLines: 20, // 100%
            ),
            LcovFileData(
              filePath: 'lib/src/file2.dart',
              totalLines: 30,
              coveredLines: 15, // 50%
            ),
            LcovFileData(
              filePath: 'lib/src/file3.dart',
              totalLines: 25,
              coveredLines: 0, // 0%
            ),
            LcovFileData(
              filePath: 'lib/src/file4.dart',
              totalLines: 40,
              coveredLines: 30, // 75%
            ),
            LcovFileData(
              filePath: 'lib/src/file5.dart',
              totalLines: 35,
              coveredLines: 35, // 100%
            ),
          ]),
        );

      processManager.mockProcessRun(
        command: 'dart',
        args: ['test', '--coverage=coverage'],
        result: MockProcessResult(stdout: '', stderr: '', exitCode: 0),
      );

      // Act
      final analyzer = CoverageAnalyzer(
        testPath: 'test',
        libPath: 'lib/src',
        processManager: processManager,
        fileSystem: fileSystem,
      );
      await analyzer.run();

      // Assert: (20+15+0+30+35)/(20+30+25+40+35) = 100/150 = 66.67%
      expect(analyzer.fileCount, equals(5));
      expect(analyzer.totalLines, equals(150));
      expect(analyzer.coveredLines, equals(100));
      expect(analyzer.overallCoverage, closeTo(66.67, 0.01));
    });

    // Suite 3: Manual Analysis Tests (4 tests)
    // Note: These tests are for future features when LCOV is missing
    // For now, they test that the analyzer doesn't crash without LCOV

    test('should handle missing LCOV file gracefully', () async {
      // Arrange: No LCOV file exists
      fileSystem
        ..addFile(
          'pubspec.yaml',
          SamplePubspec.generateDartPackage(
            name: 'test_package',
            version: '1.0.0',
          ),
        )
        ..addFile('lib/src/module.dart', 'class Module {}')
        ..addFile('test/test.dart', 'void main() {}')
        ..addDirectory('coverage');
      // No lcov.info file

      processManager.mockProcessRun(
        command: 'dart',
        args: ['test', '--coverage=coverage'],
        result: MockProcessResult(stdout: '', stderr: '', exitCode: 0),
      );

      // Act
      final analyzer = CoverageAnalyzer(
        testPath: 'test',
        libPath: 'lib/src',
        processManager: processManager,
        fileSystem: fileSystem,
      );
      final exitCode = await analyzer.run();

      // Assert: Should not crash, return 0 coverage
      expect(exitCode, equals(0));
      expect(analyzer.overallCoverage, equals(0.0));
      expect(analyzer.totalLines, equals(0));
    });

    test('should handle missing coverage directory', () async {
      // Arrange: No coverage directory at all
      fileSystem
        ..addFile(
          'pubspec.yaml',
          SamplePubspec.generateDartPackage(
            name: 'test_package',
            version: '1.0.0',
          ),
        )
        ..addFile('lib/src/module.dart', 'class Module {}')
        ..addFile('test/test.dart', 'void main() {}');
      // No coverage directory

      processManager.mockProcessRun(
        command: 'dart',
        args: ['test', '--coverage=coverage'],
        result: MockProcessResult(stdout: '', stderr: '', exitCode: 0),
      );

      // Act
      final analyzer = CoverageAnalyzer(
        testPath: 'test',
        libPath: 'lib/src',
        processManager: processManager,
        fileSystem: fileSystem,
      );
      final exitCode = await analyzer.run();

      // Assert: Should not crash
      expect(exitCode, equals(0));
      expect(analyzer.overallCoverage, equals(0.0));
    });

    test('should handle LCOV with no source files', () async {
      // Arrange: LCOV exists but has no SF records
      fileSystem
        ..addFile(
          'pubspec.yaml',
          SamplePubspec.generateDartPackage(
            name: 'test_package',
            version: '1.0.0',
          ),
        )
        ..addFile('lib/src/module.dart', 'class Module {}')
        ..addFile('test/test.dart', 'void main() {}')
        ..addDirectory('coverage')
        ..addFile(
          'coverage/lcov.info',
          '''
TN:
LH:0
LF:0
end_of_record
''',
        );

      processManager.mockProcessRun(
        command: 'dart',
        args: ['test', '--coverage=coverage'],
        result: MockProcessResult(stdout: '', stderr: '', exitCode: 0),
      );

      // Act
      final analyzer = CoverageAnalyzer(
        testPath: 'test',
        libPath: 'lib/src',
        processManager: processManager,
        fileSystem: fileSystem,
      );
      await analyzer.run();

      // Assert: Zero coverage, zero files
      expect(analyzer.fileCount, equals(0));
      expect(analyzer.overallCoverage, equals(0.0));
    });

    test('should handle mixed valid and invalid LCOV records', () async {
      // Arrange: LCOV with some valid, some invalid records
      fileSystem
        ..addFile(
          'pubspec.yaml',
          SamplePubspec.generateDartPackage(
            name: 'test_package',
            version: '1.0.0',
          ),
        )
        ..addFile('lib/src/file1.dart', 'class File1 {}')
        ..addFile('lib/src/file2.dart', 'class File2 {}')
        ..addFile('test/test.dart', 'void main() {}')
        ..addDirectory('coverage')
        ..addFile(
          'coverage/lcov.info',
          '''
SF:lib/src/file1.dart
DA:1,1
DA:2,1
DA:3,0
end_of_record
INVALID_RECORD
SF:lib/src/file2.dart
DA:1,1
DA:2,abc
DA:3,1
MALFORMED
end_of_record
''',
        );

      processManager.mockProcessRun(
        command: 'dart',
        args: ['test', '--coverage=coverage'],
        result: MockProcessResult(stdout: '', stderr: '', exitCode: 0),
      );

      // Act
      final analyzer = CoverageAnalyzer(
        testPath: 'test',
        libPath: 'lib/src',
        processManager: processManager,
        fileSystem: fileSystem,
      );
      final exitCode = await analyzer.run();

      // Assert: Should parse valid records only
      expect(exitCode, equals(0));
      expect(analyzer.fileCount, equals(2));
      // file1: 2/3, file2: 2/2 valid lines = 4/5 = 80%
      expect(analyzer.totalLines, equals(5));
      expect(analyzer.coveredLines, equals(4));
      expect(analyzer.overallCoverage, equals(80.0));
    });
  });
}
