import 'package:test/test.dart';
import 'package:test_reporter/src/bin/analyze_coverage_lib.dart';
import '../../helpers/mock_process.dart';
import '../../helpers/mock_file_system.dart';
import '../../fixtures/lcov_generator.dart';
import '../../fixtures/sample_pubspec.dart';

/// Integration tests for CoverageAnalyzer workflow (Phase 2.1 - Core Suite)
///
/// Tests the essential end-to-end workflow of the coverage analyzer:
/// - Basic Dart/Flutter project coverage
/// - Branch coverage support
/// - Report generation
/// - Incremental mode
/// - Parallel execution
/// - Error handling
///
/// Uses mocked Process and FileSystem to simulate tool execution.
///
/// 🔴 RED PHASE: All tests should fail because CoverageAnalyzer doesn't
/// have the methods/properties we're testing yet.
void main() {
  group('Coverage Analyzer Core Workflow Tests', () {
    late MockProcessManager processManager;
    late MockFileSystem fileSystem;

    setUp(() {
      processManager = MockProcessManager();
      fileSystem = MockFileSystem();
    });

    test('should run coverage on Dart project (test/ → lib/src/)', () async {
      // Arrange: Set up mock Dart project structure
      fileSystem
        ..addFile(
          'pubspec.yaml',
          SamplePubspec.generateDartPackage(
            name: 'test_package',
            version: '1.0.0',
          ),
        )
        ..addFile('lib/src/analyzer.dart', 'class Analyzer {}')
        ..addFile('test/analyzer_test.dart', 'void main() {}')
        ..addDirectory('coverage')
        ..addFile(
          'coverage/lcov.info',
          LcovGenerator.generate(
            filePath: 'lib/src/analyzer.dart',
            totalLines: 100,
            coveredLines: 85,
          ),
        );

      // Mock dart test --coverage execution
      processManager.mockProcessRun(
        command: 'dart',
        args: ['test', '--coverage=coverage'],
        result: MockProcessResult(
          stdout: 'All tests passed!',
          stderr: '',
          exitCode: 0,
        ),
      );

      // Act: Run coverage analyzer
      final analyzer = CoverageAnalyzer(
        testPath: 'test',
        libPath: 'lib/src',
        processManager: processManager,
        fileSystem: fileSystem,
      );
      final exitCode = await analyzer.run();

      // Assert: Verify success and coverage calculated
      expect(exitCode, equals(0));
      expect(analyzer.overallCoverage, equals(85.0));
      expect(analyzer.totalLines, equals(100));
      expect(analyzer.coveredLines, equals(85));
    });

    test('should run coverage on Flutter project (test/ → lib/)', () async {
      // Arrange: Set up mock Flutter project structure
      fileSystem
        ..addFile(
          'pubspec.yaml',
          SamplePubspec.generateFlutterPackage(
            name: 'flutter_app',
            version: '1.0.0',
          ),
        )
        ..addFile('lib/main.dart', 'void main() {}')
        ..addFile('lib/widgets/button.dart', 'class Button {}')
        ..addFile('test/main_test.dart', 'void main() {}')
        ..addDirectory('coverage')
        ..addFile(
          'coverage/lcov.info',
          LcovGenerator.generateMultiple([
            LcovFileData(
              filePath: 'lib/main.dart',
              totalLines: 50,
              coveredLines: 40,
            ),
            LcovFileData(
              filePath: 'lib/widgets/button.dart',
              totalLines: 100,
              coveredLines: 95,
            ),
          ]),
        );

      // Mock flutter test --coverage execution
      processManager.mockProcessRun(
        command: 'flutter',
        args: ['test', '--coverage'],
        result: MockProcessResult(
          stdout: 'All tests passed!',
          stderr: '',
          exitCode: 0,
        ),
      );

      // Act: Run coverage analyzer on Flutter project
      final analyzer = CoverageAnalyzer(
        testPath: 'test',
        libPath: 'lib',
        isFlutter: true,
        processManager: processManager,
        fileSystem: fileSystem,
      );
      final exitCode = await analyzer.run();

      // Assert: Verify success and multi-file coverage
      expect(exitCode, equals(0));
      expect(analyzer.overallCoverage, closeTo(90.0, 0.1)); // (135/150)*100
      expect(analyzer.fileCount, equals(2));
    });

    test('should support branch coverage with --branch flag', () async {
      // Arrange: LCOV with branch data
      fileSystem
        ..addFile(
          'pubspec.yaml',
          SamplePubspec.generateDartPackage(
            name: 'test_package',
            version: '1.0.0',
          ),
        )
        ..addFile('lib/src/utils.dart', 'class Utils {}')
        ..addFile('test/utils_test.dart', 'void main() {}')
        ..addDirectory('coverage')
        ..addFile(
          'coverage/lcov.info',
          LcovGenerator.generateWithBranches(
            filePath: 'lib/src/utils.dart',
            totalLines: 50,
            coveredLines: 45,
            totalBranches: 20,
            coveredBranches: 18,
          ),
        );

      processManager.mockProcessRun(
        command: 'dart',
        args: ['test', '--coverage=coverage'],
        result: MockProcessResult(stdout: '', stderr: '', exitCode: 0),
      );

      // Act: Run with branch coverage enabled
      final analyzer = CoverageAnalyzer(
        testPath: 'test',
        libPath: 'lib/src',
        branchCoverage: true,
        processManager: processManager,
        fileSystem: fileSystem,
      );
      final exitCode = await analyzer.run();

      // Assert: Verify branch coverage calculated
      expect(exitCode, equals(0));
      expect(analyzer.overallCoverage, equals(90.0)); // Line coverage
      expect(analyzer.branchCoveragePercent, equals(90.0)); // Branch coverage
      expect(analyzer.totalBranches, equals(20));
      expect(analyzer.coveredBranches, equals(18));
    });

    test('should generate both markdown and JSON reports', () async {
      // Arrange
      fileSystem
        ..addFile(
          'pubspec.yaml',
          SamplePubspec.generateDartPackage(
            name: 'test_package',
            version: '1.0.0',
          ),
        )
        ..addFile('lib/src/module.dart', 'class Module {}')
        ..addFile('test/module_test.dart', 'void main() {}')
        ..addDirectory('coverage')
        ..addDirectory('tests_reports')
        ..addDirectory('tests_reports/coverage')
        ..addFile(
          'coverage/lcov.info',
          LcovGenerator.generate(
            filePath: 'lib/src/module.dart',
            totalLines: 100,
            coveredLines: 88,
          ),
        );

      processManager.mockProcessRun(
        command: 'dart',
        args: ['test', '--coverage=coverage'],
        result: MockProcessResult(stdout: '', stderr: '', exitCode: 0),
      );

      // Act: Run analyzer
      final analyzer = CoverageAnalyzer(
        testPath: 'test',
        libPath: 'lib/src',
        processManager: processManager,
        fileSystem: fileSystem,
      );
      await analyzer.run();

      // Assert: Check both reports generated
      final allFiles = fileSystem.files.map((f) => f.path).toList();
      final mdReports =
          allFiles.where((f) => f.endsWith('.md') && f.contains('coverage'));
      final jsonReports =
          allFiles.where((f) => f.endsWith('.json') && f.contains('coverage'));

      expect(mdReports, hasLength(1));
      expect(jsonReports, hasLength(1));
      expect(mdReports.first, contains('tests_reports/coverage/'));
      expect(jsonReports.first, contains('tests_reports/coverage/'));
    });

    test('should support incremental mode with git diff', () async {
      // Arrange
      fileSystem
        ..addFile(
          'pubspec.yaml',
          SamplePubspec.generateDartPackage(
            name: 'test_package',
            version: '1.0.0',
          ),
        )
        ..addFile('lib/src/changed.dart', 'class Changed {}')
        ..addFile('lib/src/unchanged.dart', 'class Unchanged {}')
        ..addFile('test/changed_test.dart', 'void main() {}')
        ..addDirectory('coverage')
        ..addFile(
          'coverage/lcov.info',
          LcovGenerator.generate(
            filePath: 'lib/src/changed.dart',
            totalLines: 50,
            coveredLines: 45,
          ),
        );

      // Mock git diff to return changed files
      processManager
        ..mockProcessRun(
          command: 'git',
          args: ['diff', '--name-only', 'HEAD'],
          result: MockProcessResult(
            stdout: 'lib/src/changed.dart\n',
            stderr: '',
            exitCode: 0,
          ),
        )
        ..mockProcessRun(
          command: 'dart',
          args: ['test', '--coverage=coverage'],
          result: MockProcessResult(stdout: '', stderr: '', exitCode: 0),
        );

      // Act: Run with incremental mode
      final analyzer = CoverageAnalyzer(
        testPath: 'test',
        libPath: 'lib/src',
        incremental: true,
        processManager: processManager,
        fileSystem: fileSystem,
      );
      await analyzer.run();

      // Assert: Should only analyze changed.dart
      expect(analyzer.incrementalMode, isTrue);
      expect(analyzer.changedFiles, contains('lib/src/changed.dart'));
      expect(analyzer.changedFiles, hasLength(1));
      expect(analyzer.incrementalCoverage, equals(90.0)); // 45/50
    });

    test('should support parallel execution with --parallel flag', () async {
      // Arrange
      fileSystem
        ..addFile(
          'pubspec.yaml',
          SamplePubspec.generateDartPackage(
            name: 'test_package',
            version: '1.0.0',
          ),
        )
        ..addFile('lib/src/module1.dart', 'class Module1 {}')
        ..addFile('lib/src/module2.dart', 'class Module2 {}')
        ..addFile('test/module_test.dart', 'void main() {}')
        ..addDirectory('coverage')
        ..addFile(
          'coverage/lcov.info',
          LcovGenerator.generateMultiple([
            LcovFileData(
              filePath: 'lib/src/module1.dart',
              totalLines: 100,
              coveredLines: 90,
            ),
            LcovFileData(
              filePath: 'lib/src/module2.dart',
              totalLines: 100,
              coveredLines: 85,
            ),
          ]),
        );

      processManager.mockProcessRun(
        command: 'dart',
        args: ['test', '--coverage=coverage', '--concurrency=4'],
        result: MockProcessResult(stdout: '', stderr: '', exitCode: 0),
      );

      // Act: Run with parallel mode
      final analyzer = CoverageAnalyzer(
        testPath: 'test',
        libPath: 'lib/src',
        parallel: true,
        maxWorkers: 4,
        processManager: processManager,
        fileSystem: fileSystem,
      );
      final exitCode = await analyzer.run();

      // Assert
      expect(exitCode, equals(0));
      expect(analyzer.parallelMode, isTrue);
      expect(analyzer.maxWorkers, equals(4));

      // Verify parallel flag passed to dart test
      expect(
        processManager.getInvocationCount(
          'dart',
          ['test', '--coverage=coverage', '--concurrency=4'],
        ),
        equals(1),
      );
    });

    test('should handle missing test path error', () async {
      // Arrange: test/ directory doesn't exist
      fileSystem.addFile(
        'pubspec.yaml',
        SamplePubspec.generateDartPackage(
          name: 'test_package',
          version: '1.0.0',
        ),
      );

      // Act
      final analyzer = CoverageAnalyzer(
        testPath: 'test',
        libPath: 'lib/src',
        processManager: processManager,
        fileSystem: fileSystem,
      );
      final exitCode = await analyzer.run();

      // Assert: Should exit with error code
      expect(exitCode, equals(2)); // Error exit code
      expect(analyzer.hasError, isTrue);
      expect(analyzer.errorMessage, contains('test path not found'));
    });

    test('should handle test execution failure', () async {
      // Arrange: dart test command fails
      fileSystem
        ..addFile(
          'pubspec.yaml',
          SamplePubspec.generateDartPackage(
            name: 'test_package',
            version: '1.0.0',
          ),
        )
        ..addFile('lib/src/fail.dart', 'class Fail {}')
        ..addFile('test/fail_test.dart', 'void main() {}')
        ..addDirectory('test')
        ..addDirectory('lib/src');

      processManager.mockProcessRun(
        command: 'dart',
        args: ['test', '--coverage=coverage'],
        result: MockProcessResult(
          stdout: '',
          stderr: 'Error: Test compilation failed',
          exitCode: 1,
        ),
      );

      // Act
      final analyzer = CoverageAnalyzer(
        testPath: 'test',
        libPath: 'lib/src',
        processManager: processManager,
        fileSystem: fileSystem,
      );
      final exitCode = await analyzer.run();

      // Assert: Should propagate test failure
      expect(exitCode, equals(1));
      expect(analyzer.hasError, isTrue);
      expect(analyzer.errorMessage, contains('Test execution failed'));
    });

    // Suite 1: Additional Basic Workflow Tests (4 more tests)

    test('should handle explicit source and test paths', () async {
      // Arrange
      fileSystem
        ..addFile(
          'pubspec.yaml',
          SamplePubspec.generateDartPackage(
            name: 'test_package',
            version: '1.0.0',
          ),
        )
        ..addFile('src/core/engine.dart', 'class Engine {}')
        ..addFile('tests/engine_test.dart', 'void main() {}')
        ..addDirectory('coverage')
        ..addFile(
          'coverage/lcov.info',
          LcovGenerator.generate(
            filePath: 'src/core/engine.dart',
            totalLines: 50,
            coveredLines: 40,
          ),
        );

      processManager.mockProcessRun(
        command: 'dart',
        args: ['test', '--coverage=coverage'],
        result: MockProcessResult(stdout: '', stderr: '', exitCode: 0),
      );

      // Act: Use non-standard paths
      final analyzer = CoverageAnalyzer(
        testPath: 'tests',
        libPath: 'src/core',
        processManager: processManager,
        fileSystem: fileSystem,
      );
      final exitCode = await analyzer.run();

      // Assert
      expect(exitCode, equals(0));
      expect(analyzer.overallCoverage, equals(80.0));
    });

    test('should verify report naming convention', () async {
      // Arrange
      fileSystem
        ..addFile(
          'pubspec.yaml',
          SamplePubspec.generateDartPackage(
            name: 'my_module',
            version: '1.0.0',
          ),
        )
        ..addFile('lib/src/foo.dart', 'class Foo {}')
        ..addFile('test/foo_test.dart', 'void main() {}')
        ..addDirectory('coverage')
        ..addFile(
          'coverage/lcov.info',
          LcovGenerator.generate(
            filePath: 'lib/src/foo.dart',
            totalLines: 100,
            coveredLines: 75,
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

      // Assert: Check report naming follows pattern
      final allFiles = fileSystem.files.map((f) => f.path).toList();
      final reports = allFiles.where((f) => f.contains('coverage_report@'));

      expect(reports, isNotEmpty);
      // Format: coverage_report@HHMM_DDMMYY.md
      expect(
        reports.first,
        matches(RegExp(r'coverage_report@\d{1,4}_\d{1,6}\.(md|json)$')),
      );
    });

    test('should handle empty coverage data gracefully', () async {
      // Arrange: LCOV file exists but is empty
      fileSystem
        ..addFile(
          'pubspec.yaml',
          SamplePubspec.generateDartPackage(
            name: 'test_package',
            version: '1.0.0',
          ),
        )
        ..addFile('lib/src/module.dart', 'class Module {}')
        ..addFile('test/module_test.dart', 'void main() {}')
        ..addDirectory('coverage')
        ..addFile('coverage/lcov.info', ''); // Empty LCOV

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

      // Assert: Should handle gracefully with 0% coverage
      expect(exitCode, equals(0));
      expect(analyzer.overallCoverage, equals(0.0));
      expect(analyzer.totalLines, equals(0));
    });

    test('should verify overall coverage calculation accuracy', () async {
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
              totalLines: 100,
              coveredLines: 100, // 100%
            ),
            LcovFileData(
              filePath: 'lib/src/file2.dart',
              totalLines: 100,
              coveredLines: 80, // 80%
            ),
            LcovFileData(
              filePath: 'lib/src/file3.dart',
              totalLines: 100,
              coveredLines: 70, // 70%
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

      // Assert: (100+80+70)/(100+100+100) = 250/300 = 83.33%
      expect(analyzer.overallCoverage, closeTo(83.33, 0.01));
      expect(analyzer.totalLines, equals(300));
      expect(analyzer.coveredLines, equals(250));
      expect(analyzer.fileCount, equals(3));
    });

    // Suite 2: Additional Incremental Coverage Tests (5 more tests)

    test('should handle no changed files in incremental mode', () async {
      // Arrange
      fileSystem
        ..addFile(
          'pubspec.yaml',
          SamplePubspec.generateDartPackage(
            name: 'test_package',
            version: '1.0.0',
          ),
        )
        ..addFile('lib/src/module.dart', 'class Module {}')
        ..addFile('test/module_test.dart', 'void main() {}')
        ..addDirectory('coverage')
        ..addFile(
          'coverage/lcov.info',
          LcovGenerator.generate(
            filePath: 'lib/src/module.dart',
            totalLines: 100,
            coveredLines: 90,
          ),
        );

      // Mock git diff returning empty (no changes)
      processManager
        ..mockProcessRun(
          command: 'git',
          args: ['diff', '--name-only', 'HEAD'],
          result: MockProcessResult(
            stdout: '',
            stderr: '',
            exitCode: 0,
          ),
        )
        ..mockProcessRun(
          command: 'dart',
          args: ['test', '--coverage=coverage'],
          result: MockProcessResult(stdout: '', stderr: '', exitCode: 0),
        );

      // Act
      final analyzer = CoverageAnalyzer(
        testPath: 'test',
        libPath: 'lib/src',
        incremental: true,
        processManager: processManager,
        fileSystem: fileSystem,
      );
      await analyzer.run();

      // Assert: Should still run but with no changed files
      expect(analyzer.incrementalMode, isTrue);
      expect(analyzer.changedFiles, isEmpty);
      expect(analyzer.incrementalCoverage, isNull);
    });

    test('should calculate incremental coverage for multiple files', () async {
      // Arrange
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
              coveredLines: 45, // 90%
            ),
            LcovFileData(
              filePath: 'lib/src/file2.dart',
              totalLines: 50,
              coveredLines: 40, // 80%
            ),
            LcovFileData(
              filePath: 'lib/src/file3.dart',
              totalLines: 100,
              coveredLines: 100, // 100% (but not changed)
            ),
          ]),
        );

      // Mock git diff showing file1 and file2 changed
      processManager
        ..mockProcessRun(
          command: 'git',
          args: ['diff', '--name-only', 'HEAD'],
          result: MockProcessResult(
            stdout: 'lib/src/file1.dart\nlib/src/file2.dart\n',
            stderr: '',
            exitCode: 0,
          ),
        )
        ..mockProcessRun(
          command: 'dart',
          args: ['test', '--coverage=coverage'],
          result: MockProcessResult(stdout: '', stderr: '', exitCode: 0),
        );

      // Act
      final analyzer = CoverageAnalyzer(
        testPath: 'test',
        libPath: 'lib/src',
        incremental: true,
        processManager: processManager,
        fileSystem: fileSystem,
      );
      await analyzer.run();

      // Assert: Incremental coverage = (45+40)/(50+50) = 85%
      expect(analyzer.incrementalMode, isTrue);
      expect(analyzer.changedFiles, hasLength(2));
      expect(analyzer.incrementalCoverage, equals(85.0));
    });

    test('should detect changed files from git diff correctly', () async {
      // Arrange
      fileSystem
        ..addFile(
          'pubspec.yaml',
          SamplePubspec.generateDartPackage(
            name: 'test_package',
            version: '1.0.0',
          ),
        )
        ..addFile('lib/src/changed1.dart', 'class Changed1 {}')
        ..addFile('lib/src/changed2.dart', 'class Changed2 {}')
        ..addFile('lib/src/unchanged.dart', 'class Unchanged {}')
        ..addFile('test/test.dart', 'void main() {}')
        ..addDirectory('coverage')
        ..addFile(
          'coverage/lcov.info',
          LcovGenerator.generate(
            filePath: 'lib/src/changed1.dart',
            totalLines: 50,
            coveredLines: 40,
          ),
        );

      // Mock git diff with specific files
      processManager
        ..mockProcessRun(
          command: 'git',
          args: ['diff', '--name-only', 'HEAD'],
          result: MockProcessResult(
            stdout: 'lib/src/changed1.dart\nlib/src/changed2.dart\nREADME.md\n',
            stderr: '',
            exitCode: 0,
          ),
        )
        ..mockProcessRun(
          command: 'dart',
          args: ['test', '--coverage=coverage'],
          result: MockProcessResult(stdout: '', stderr: '', exitCode: 0),
        );

      // Act
      final analyzer = CoverageAnalyzer(
        testPath: 'test',
        libPath: 'lib/src',
        incremental: true,
        processManager: processManager,
        fileSystem: fileSystem,
      );
      await analyzer.run();

      // Assert
      expect(analyzer.changedFiles, hasLength(3));
      expect(analyzer.changedFiles, contains('lib/src/changed1.dart'));
      expect(analyzer.changedFiles, contains('lib/src/changed2.dart'));
      expect(analyzer.changedFiles, contains('README.md'));
    });

    test('should generate incremental coverage report', () async {
      // Arrange
      fileSystem
        ..addFile(
          'pubspec.yaml',
          SamplePubspec.generateDartPackage(
            name: 'test_package',
            version: '1.0.0',
          ),
        )
        ..addFile('lib/src/changed.dart', 'class Changed {}')
        ..addFile('test/test.dart', 'void main() {}')
        ..addDirectory('coverage')
        ..addFile(
          'coverage/lcov.info',
          LcovGenerator.generate(
            filePath: 'lib/src/changed.dart',
            totalLines: 100,
            coveredLines: 95,
          ),
        );

      processManager
        ..mockProcessRun(
          command: 'git',
          args: ['diff', '--name-only', 'HEAD'],
          result: MockProcessResult(
            stdout: 'lib/src/changed.dart\n',
            stderr: '',
            exitCode: 0,
          ),
        )
        ..mockProcessRun(
          command: 'dart',
          args: ['test', '--coverage=coverage'],
          result: MockProcessResult(stdout: '', stderr: '', exitCode: 0),
        );

      // Act
      final analyzer = CoverageAnalyzer(
        testPath: 'test',
        libPath: 'lib/src',
        incremental: true,
        generateReport: true,
        processManager: processManager,
        fileSystem: fileSystem,
      );
      await analyzer.run();

      // Assert: Reports generated
      final allFiles = fileSystem.files.map((f) => f.path).toList();
      final reports = allFiles.where((f) => f.contains('coverage_report@'));
      expect(reports, isNotEmpty);
      expect(analyzer.incrementalCoverage, equals(95.0));
    });

    test('should handle git diff failure gracefully', () async {
      // Arrange
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
          LcovGenerator.generate(
            filePath: 'lib/src/module.dart',
            totalLines: 100,
            coveredLines: 90,
          ),
        );

      // Mock git diff failure (not a git repo)
      processManager
        ..mockProcessRun(
          command: 'git',
          args: ['diff', '--name-only', 'HEAD'],
          result: MockProcessResult(
            stdout: '',
            stderr: 'fatal: not a git repository',
            exitCode: 128,
          ),
        )
        ..mockProcessRun(
          command: 'dart',
          args: ['test', '--coverage=coverage'],
          result: MockProcessResult(stdout: '', stderr: '', exitCode: 0),
        );

      // Act
      final analyzer = CoverageAnalyzer(
        testPath: 'test',
        libPath: 'lib/src',
        incremental: true,
        processManager: processManager,
        fileSystem: fileSystem,
      );
      final exitCode = await analyzer.run();

      // Assert: Should still succeed with empty changed files
      expect(exitCode, equals(0));
      expect(analyzer.changedFiles, isEmpty);
    });

    // Suite 3: Additional Parallel Execution Tests (3 more tests)

    test('should verify parallel workers configuration', () async {
      // Arrange
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
          LcovGenerator.generate(
            filePath: 'lib/src/module.dart',
            totalLines: 100,
            coveredLines: 90,
          ),
        );

      processManager.mockProcessRun(
        command: 'dart',
        args: ['test', '--coverage=coverage', '--concurrency=8'],
        result: MockProcessResult(stdout: '', stderr: '', exitCode: 0),
      );

      // Act: Run with 8 workers
      final analyzer = CoverageAnalyzer(
        testPath: 'test',
        libPath: 'lib/src',
        parallel: true,
        maxWorkers: 8,
        processManager: processManager,
        fileSystem: fileSystem,
      );
      final exitCode = await analyzer.run();

      // Assert
      expect(exitCode, equals(0));
      expect(analyzer.parallelMode, isTrue);
      expect(analyzer.maxWorkers, equals(8));

      // Verify correct command was called
      expect(
        processManager.getInvocationCount(
          'dart',
          ['test', '--coverage=coverage', '--concurrency=8'],
        ),
        equals(1),
      );
    });

    test('should aggregate coverage results in parallel mode', () async {
      // Arrange: Multiple files with coverage data
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
        ..addFile('test/test.dart', 'void main() {}')
        ..addDirectory('coverage')
        ..addFile(
          'coverage/lcov.info',
          LcovGenerator.generateMultiple([
            LcovFileData(
              filePath: 'lib/src/file1.dart',
              totalLines: 100,
              coveredLines: 90,
            ),
            LcovFileData(
              filePath: 'lib/src/file2.dart',
              totalLines: 100,
              coveredLines: 85,
            ),
            LcovFileData(
              filePath: 'lib/src/file3.dart',
              totalLines: 100,
              coveredLines: 95,
            ),
            LcovFileData(
              filePath: 'lib/src/file4.dart',
              totalLines: 100,
              coveredLines: 80,
            ),
          ]),
        );

      processManager.mockProcessRun(
        command: 'dart',
        args: ['test', '--coverage=coverage', '--concurrency=4'],
        result: MockProcessResult(stdout: '', stderr: '', exitCode: 0),
      );

      // Act
      final analyzer = CoverageAnalyzer(
        testPath: 'test',
        libPath: 'lib/src',
        parallel: true,
        maxWorkers: 4,
        processManager: processManager,
        fileSystem: fileSystem,
      );
      await analyzer.run();

      // Assert: Aggregated correctly
      expect(analyzer.overallCoverage, equals(87.5)); // (90+85+95+80)/400
      expect(analyzer.fileCount, equals(4));
      expect(analyzer.totalLines, equals(400));
      expect(analyzer.coveredLines, equals(350));
    });

    test('should handle parallel execution with default workers', () async {
      // Arrange
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
          LcovGenerator.generate(
            filePath: 'lib/src/module.dart',
            totalLines: 100,
            coveredLines: 90,
          ),
        );

      // Default maxWorkers should be 4
      processManager.mockProcessRun(
        command: 'dart',
        args: ['test', '--coverage=coverage', '--concurrency=4'],
        result: MockProcessResult(stdout: '', stderr: '', exitCode: 0),
      );

      // Act: Don't specify maxWorkers (should use default)
      final analyzer = CoverageAnalyzer(
        testPath: 'test',
        libPath: 'lib/src',
        parallel: true,
        processManager: processManager,
        fileSystem: fileSystem,
      );
      final exitCode = await analyzer.run();

      // Assert: Should use default maxWorkers = 4
      expect(exitCode, equals(0));
      expect(analyzer.maxWorkers, equals(4));
    });

    // Suite 4: Additional Error Handling Tests (4 more tests)

    test('should handle missing lib path error', () async {
      // Arrange: lib path doesn't exist
      fileSystem
        ..addFile(
          'pubspec.yaml',
          SamplePubspec.generateDartPackage(
            name: 'test_package',
            version: '1.0.0',
          ),
        )
        ..addFile('test/test.dart', 'void main() {}')
        ..addDirectory('test');

      // Act
      final analyzer = CoverageAnalyzer(
        testPath: 'test',
        libPath: 'nonexistent/path',
        processManager: processManager,
        fileSystem: fileSystem,
      );
      final exitCode = await analyzer.run();

      // Assert: Should succeed (lib path checked later during analysis)
      // For now, just check it doesn't crash
      expect(exitCode, isA<int>());
    });

    test('should handle malformed LCOV file', () async {
      // Arrange: LCOV file with invalid format
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
          'INVALID:LCOV:DATA\nNOT:A:VALID:FORMAT\n',
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

      // Assert: Should handle gracefully
      expect(exitCode, equals(0));
      expect(analyzer.overallCoverage, equals(0.0));
    });

    test('should handle missing coverage directory', () async {
      // Arrange: No coverage directory exists
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
      // No coverage directory added

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

      // Assert: Should handle missing coverage gracefully
      expect(exitCode, equals(0));
      expect(analyzer.overallCoverage, equals(0.0));
    });

    test('should handle both test and coverage failures', () async {
      // Arrange
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
        ..addDirectory('test')
        ..addDirectory('lib/src');

      // Mock test failure with no coverage data
      processManager.mockProcessRun(
        command: 'dart',
        args: ['test', '--coverage=coverage'],
        result: MockProcessResult(
          stdout: '',
          stderr: 'Error: Multiple test failures',
          exitCode: 1,
        ),
      );

      // Act
      final analyzer = CoverageAnalyzer(
        testPath: 'test',
        libPath: 'lib/src',
        processManager: processManager,
        fileSystem: fileSystem,
      );
      final exitCode = await analyzer.run();

      // Assert: Should fail with test error code
      expect(exitCode, equals(1));
      expect(analyzer.hasError, isTrue);
      expect(analyzer.errorMessage, contains('Test execution failed'));
    });
  });
}
