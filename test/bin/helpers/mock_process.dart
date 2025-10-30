import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Mock Process for testing CLI tools without actually executing processes
class MockProcess implements Process {
  final int _exitCode;
  final String _stdout;
  final String _stderr;
  final StreamController<List<int>> _stdoutController;
  final StreamController<List<int>> _stderrController;
  final StreamController<List<int>> _stdinController;

  MockProcess({
    int exitCode = 0,
    String stdout = '',
    String stderr = '',
  })  : _exitCode = exitCode,
        _stdout = stdout,
        _stderr = stderr,
        _stdoutController = StreamController<List<int>>(),
        _stderrController = StreamController<List<int>>(),
        _stdinController = StreamController<List<int>>() {
    // Emit stdout data
    if (_stdout.isNotEmpty) {
      _stdoutController.add(utf8.encode(_stdout));
    }
    _stdoutController.close();

    // Emit stderr data
    if (_stderr.isNotEmpty) {
      _stderrController.add(utf8.encode(_stderr));
    }
    _stderrController.close();
  }

  @override
  Future<int> get exitCode async => _exitCode;

  @override
  int get pid => 12345;

  @override
  Stream<List<int>> get stdout => _stdoutController.stream;

  @override
  Stream<List<int>> get stderr => _stderrController.stream;

  @override
  IOSink get stdin => IOSink(_stdinController.sink);

  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) {
    return true;
  }
}

/// Mock ProcessResult for testing Process.run() calls
/// Note: Cannot implement ProcessResult as it's final, so this provides similar interface
class MockProcessResult {
  final int exitCode;
  final int pid;
  final dynamic stdout;
  final dynamic stderr;

  MockProcessResult({
    this.exitCode = 0,
    this.pid = 12345,
    this.stdout = '',
    this.stderr = '',
  });

  /// Convert to actual ProcessResult
  ProcessResult toProcessResult() {
    // We can't create a ProcessResult directly, but we can use this in tests
    // by mocking Process.run() to return this object
    return ProcessResult(pid, exitCode, stdout, stderr);
  }
}

/// Helper class to mock Process.start() calls
class ProcessMocker {
  final Map<String, MockProcess> _processMap = {};
  final Map<String, MockProcessResult> _resultMap = {};

  /// Register a mock process for a specific command
  void registerProcess(String command, MockProcess process) {
    _processMap[command] = process;
  }

  /// Register a mock result for a specific command
  void registerResult(String command, MockProcessResult result) {
    _resultMap[command] = result;
  }

  /// Get mock process for command
  MockProcess? getProcess(String executable, List<String> arguments) {
    final command = '$executable ${arguments.join(' ')}';
    return _processMap[command] ?? _processMap[executable];
  }

  /// Get mock result for command
  MockProcessResult? getResult(String executable, List<String> arguments) {
    final command = '$executable ${arguments.join(' ')}';
    return _resultMap[command] ?? _resultMap[executable];
  }

  /// Clear all registered mocks
  void clear() {
    _processMap.clear();
    _resultMap.clear();
  }
}
