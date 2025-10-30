/// Process mocking infrastructure for integration testing
///
/// Provides mock implementations of Process.run() and Process.start()
/// to test CLI tools without actual process execution.

import 'dart:async';
import 'dart:io';

/// Mock process result for testing
class MockProcessResult {
  final int exitCode;
  final String stdout;
  final String stderr;
  final int pid;

  const MockProcessResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
    this.pid = 12345,
  });

  /// Convert to actual ProcessResult
  ProcessResult toProcessResult() {
    return ProcessResult(pid, exitCode, stdout, stderr);
  }
}

/// Process mocker for registering mock behaviors
class ProcessMocker {
  static final Map<String, MockProcessResult> _commandMocks = {};
  static final List<String> _executedCommands = [];

  /// Register a mock response for a command
  static void registerMock(String command, MockProcessResult result) {
    _commandMocks[command] = result;
  }

  /// Clear all registered mocks
  static void clearMocks() {
    _commandMocks.clear();
    _executedCommands.clear();
  }

  /// Get mock result for command
  static MockProcessResult? getMock(String command) {
    return _commandMocks[command];
  }

  /// Record executed command
  static void recordCommand(String command) {
    _executedCommands.add(command);
  }

  /// Get all executed commands
  static List<String> getExecutedCommands() {
    return List.unmodifiable(_executedCommands);
  }

  /// Verify command was executed
  static bool wasExecuted(String command) {
    return _executedCommands.contains(command);
  }
}

/// Mock Process.run() for testing
Future<ProcessResult> mockProcessRun(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
  Map<String, String>? environment,
  bool includeParentEnvironment = true,
  bool runInShell = false,
  ProcessStartMode mode = ProcessStartMode.normal,
}) async {
  final command = '$executable ${arguments.join(' ')}';
  ProcessMocker.recordCommand(command);

  final mock = ProcessMocker.getMock(command);
  if (mock != null) {
    return mock.toProcessResult();
  }

  // Default: return success with empty output
  return ProcessResult(12345, 0, '', '');
}

/// Helper to create common mock responses
class MockResponses {
  /// Successful test run with coverage
  static MockProcessResult successfulTestWithCoverage() {
    return const MockProcessResult(
      exitCode: 0,
      stdout: '00:01 +324: All tests passed!',
      stderr: '',
    );
  }

  /// Failed test run
  static MockProcessResult failedTest() {
    return const MockProcessResult(
      exitCode: 1,
      stdout: '00:01 +323 -1: Some tests failed.',
      stderr: 'Test failure in auth_test.dart',
    );
  }

  /// Test run with JSON output
  static MockProcessResult testWithJsonOutput() {
    return MockProcessResult(
      exitCode: 0,
      stdout: r"""
{"suite":{"id":0,"path":"test/auth_test.dart"}}
{"test":{"id":1,"name":"should authenticate"}}
{"testDone":{"id":1,"result":"success"}}
{"done":{"success":true}}
""",
      stderr: '',
    );
  }

  /// Coverage generation success
  static MockProcessResult coverageSuccess() {
    return const MockProcessResult(
      exitCode: 0,
      stdout: 'Coverage data written to coverage/lcov.info',
      stderr: '',
    );
  }

  /// LCOV summary output
  static MockProcessResult lcovSummary() {
    return MockProcessResult(
      exitCode: 0,
      stdout: r"""Reading tracefile coverage/lcov.info
  lines......: 85.5% (1234 of 1443 lines)
  functions..: 92.3% (456 of 494 functions)
  branches...: 78.9% (234 of 296 branches)""",
      stderr: '',
    );
  }
}
