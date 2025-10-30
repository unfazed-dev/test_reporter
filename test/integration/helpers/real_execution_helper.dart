/// Helper for executing binaries in integration tests
///
/// Provides utilities for spawning processes, capturing output,
/// and validating execution results.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Result of executing a binary
class ExecutionResult {
  ExecutionResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
    required this.duration,
  });

  final int exitCode;
  final String stdout;
  final String stderr;
  final Duration duration;

  bool get success => exitCode == 0;
  bool get failed => exitCode != 0;

  /// Get all output lines (stdout + stderr)
  List<String> get allOutput => [
        ...stdout.split('\n'),
        ...stderr.split('\n'),
      ];

  @override
  String toString() => '''
ExecutionResult:
  Exit Code: $exitCode
  Duration: ${duration.inMilliseconds}ms
  Stdout Lines: ${stdout.split('\n').length}
  Stderr Lines: ${stderr.split('\n').length}
''';
}

/// Helper class for executing binaries in tests
class BinaryExecutor {
  BinaryExecutor({
    this.workingDirectory,
    this.timeout = const Duration(minutes: 2),
  });

  final String? workingDirectory;
  final Duration timeout;

  /// Execute a binary with arguments and capture output
  Future<ExecutionResult> run(
    String binary,
    List<String> args, {
    Map<String, String>? environment,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      final result = await Process.run(
        binary,
        args,
        workingDirectory: workingDirectory,
        environment: environment,
      ).timeout(timeout);

      stopwatch.stop();

      return ExecutionResult(
        exitCode: result.exitCode,
        stdout: result.stdout.toString(),
        stderr: result.stderr.toString(),
        duration: stopwatch.elapsed,
      );
    } on TimeoutException {
      stopwatch.stop();
      return ExecutionResult(
        exitCode: -1,
        stdout: '',
        stderr: 'Process timed out after ${timeout.inSeconds}s',
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return ExecutionResult(
        exitCode: -1,
        stdout: '',
        stderr: 'Execution error: $e',
        duration: stopwatch.elapsed,
      );
    }
  }

  /// Execute a binary and stream output
  Future<ExecutionResult> runStreaming(
    String binary,
    List<String> args, {
    void Function(String line)? onStdout,
    void Function(String line)? onStderr,
    Map<String, String>? environment,
  }) async {
    final stopwatch = Stopwatch()..start();
    final stdoutBuffer = StringBuffer();
    final stderrBuffer = StringBuffer();

    try {
      final process = await Process.start(
        binary,
        args,
        workingDirectory: workingDirectory,
        environment: environment,
      );

      // Capture stdout
      final stdoutFuture = process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .forEach((line) {
        stdoutBuffer.writeln(line);
        onStdout?.call(line);
      });

      // Capture stderr
      final stderrFuture = process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .forEach((line) {
        stderrBuffer.writeln(line);
        onStderr?.call(line);
      });

      // Wait for process and streams
      final exitCode = await process.exitCode.timeout(timeout);
      await Future.wait([stdoutFuture, stderrFuture]);

      stopwatch.stop();

      return ExecutionResult(
        exitCode: exitCode,
        stdout: stdoutBuffer.toString(),
        stderr: stderrBuffer.toString(),
        duration: stopwatch.elapsed,
      );
    } on TimeoutException {
      stopwatch.stop();
      return ExecutionResult(
        exitCode: -1,
        stdout: stdoutBuffer.toString(),
        stderr:
            '${stderrBuffer.toString()}\nProcess timed out after ${timeout.inSeconds}s',
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return ExecutionResult(
        exitCode: -1,
        stdout: stdoutBuffer.toString(),
        stderr: '${stderrBuffer.toString()}\nExecution error: $e',
        duration: stopwatch.elapsed,
      );
    }
  }

  /// Execute a test_reporter binary
  Future<ExecutionResult> runBinary(
    String binaryName,
    List<String> args, {
    Map<String, String>? environment,
  }) async {
    return run(
      'dart',
      ['run', 'test_reporter:$binaryName', ...args],
      environment: environment,
    );
  }

  /// Execute analyze_coverage binary
  Future<ExecutionResult> analyzeCoverage(
    String libPath, {
    List<String>? extraArgs,
  }) async {
    return runBinary(
      'analyze_coverage',
      [libPath, ...?extraArgs],
    );
  }

  /// Execute analyze_tests binary
  Future<ExecutionResult> analyzeTests(
    String testPath, {
    List<String>? extraArgs,
  }) async {
    return runBinary(
      'analyze_tests',
      [testPath, ...?extraArgs],
    );
  }

  /// Execute extract_failures binary
  Future<ExecutionResult> extractFailures({
    List<String>? extraArgs,
  }) async {
    return runBinary('extract_failures', extraArgs ?? []);
  }

  /// Execute analyze_suite binary
  Future<ExecutionResult> analyzeSuite(
    String path, {
    List<String>? extraArgs,
  }) async {
    return runBinary(
      'analyze_suite',
      [path, ...?extraArgs],
    );
  }
}
