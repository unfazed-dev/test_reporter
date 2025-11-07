/// Mock Process infrastructure for testing bin/ analyzers
///
/// Provides MockProcess, MockProcessResult, and MockProcessManager
/// to mock Process.run() and Process.start() calls in integration tests.
///
/// Usage:
/// ```dart
/// final manager = MockProcessManager();
/// manager.mockProcessRun(
///   command: 'dart',
///   args: ['test'],
///   result: MockProcessResult(exitCode: 0, stdout: 'All tests passed'),
/// );
///
/// final result = await manager.run('dart', ['test']);
/// print(result.stdout); // 'All tests passed'
/// ```

import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Mock implementation of Process for Process.start() calls
class MockProcess implements Process {
  MockProcess({
    required Stream<List<int>> stdout,
    Stream<List<int>>? stderr,
    required int exitCode,
    int? pid,
  })  : _stdout = stdout,
        _stderr = stderr ?? Stream.empty(),
        _exitCodeCompleter = Completer<int>()..complete(exitCode),
        _pid = pid ?? 0 {
    // Complete exit code immediately
  }

  /// Create a mock process with delayed output
  factory MockProcess.withDelayedOutput({
    required String output,
    required Duration delay,
    required int exitCode,
  }) {
    final controller = StreamController<List<int>>();

    // Schedule delayed output
    Future.delayed(delay, () {
      controller.add(utf8.encode(output));
      controller.close();
    });

    return MockProcess(
      stdout: controller.stream,
      exitCode: exitCode,
    );
  }

  /// Create a mock process that simulates timeout
  ///
  /// The exitCode future will never complete, causing a timeout.
  factory MockProcess.withTimeout({
    required Duration timeout,
  }) {
    final exitCodeCompleter = Completer<int>(); // Never completes!
    return MockProcess._internal(
      stdout: Stream.empty(),
      stderr: Stream.empty(),
      exitCodeCompleter: exitCodeCompleter,
      pid: 0,
    );
  }

  /// Internal constructor for special cases
  MockProcess._internal({
    required Stream<List<int>> stdout,
    required Stream<List<int>> stderr,
    required Completer<int> exitCodeCompleter,
    required int pid,
  })  : _stdout = stdout,
        _stderr = stderr,
        _exitCodeCompleter = exitCodeCompleter,
        _pid = pid;

  final Stream<List<int>> _stdout;
  final Stream<List<int>> _stderr;
  final Completer<int> _exitCodeCompleter;
  final int _pid;
  final List<String> _invocations = [];
  bool _killed = false;

  @override
  Stream<List<int>> get stdout => _stdout;

  @override
  Stream<List<int>> get stderr => _stderr;

  @override
  Future<int> get exitCode => _exitCodeCompleter.future;

  @override
  int get pid => _pid;

  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) {
    _killed = true;
    _invocations.add('kill');
    return true;
  }

  /// Check if process was killed
  bool get killed => _killed;

  /// Get list of method invocations for verification
  List<String> get invocations => List.unmodifiable(_invocations);

  // Unused Process methods (not needed for our tests)
  @override
  IOSink get stdin => throw UnimplementedError();
}

/// Mock implementation of ProcessResult for Process.run() calls
///
/// Note: ProcessResult is a final class, so we create a compatible class
/// with the same interface instead of implementing it.
class MockProcessResult {
  MockProcessResult({
    required this.exitCode,
    this.stdout = '',
    this.stderr = '',
    this.pid = 0,
  });

  final int exitCode;
  final dynamic stdout;
  final dynamic stderr;
  final int pid;

  /// Convert to a real ProcessResult
  ProcessResult toProcessResult() {
    return ProcessResult(pid, exitCode, stdout, stderr);
  }
}

/// Manages mock processes for testing
///
/// Registers mock responses for Process.run() and Process.start() calls,
/// tracks invocations, and verifies expectations.
class MockProcessManager {
  final Map<_CommandKey, _MockEntry> _mocks = {};
  final Map<_CommandKey, int> _invocations = {};

  /// Register a mock for Process.run()
  MockProcessManager mockProcessRun({
    required String command,
    required List<String> args,
    required MockProcessResult result,
    int? expectedCalls,
  }) {
    final key = _CommandKey(command, args);
    _mocks[key] = _MockEntry(
      runResult: result,
      expectedCalls: expectedCalls,
    );
    return this;
  }

  /// Register a mock for Process.start()
  MockProcessManager mockProcessStart({
    required String command,
    required List<String> args,
    required MockProcess process,
    int? expectedCalls,
  }) {
    final key = _CommandKey(command, args);
    _mocks[key] = _MockEntry(
      startProcess: process,
      expectedCalls: expectedCalls,
    );
    return this;
  }

  /// Execute Process.run() with mocked result
  Future<ProcessResult> run(
    String command,
    List<String> args, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    Encoding? stdoutEncoding = systemEncoding,
    Encoding? stderrEncoding = systemEncoding,
  }) async {
    final key = _CommandKey(command, args);

    if (!_mocks.containsKey(key)) {
      throw StateError(
        'No mock registered for command: $command ${args.join(" ")}\n'
        'Available mocks: ${_mocks.keys.map((k) => '${k.command} ${k.args.join(" ")}').join(", ")}',
      );
    }

    _invocations[key] = (_invocations[key] ?? 0) + 1;

    final mock = _mocks[key]!;
    if (mock.runResult == null) {
      throw StateError(
        'Mock registered for Process.start(), but Process.run() was called',
      );
    }

    return mock.runResult!.toProcessResult();
  }

  /// Execute Process.start() with mocked process
  Future<Process> start(
    String command,
    List<String> args, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    ProcessStartMode mode = ProcessStartMode.normal,
  }) async {
    final key = _CommandKey(command, args);

    if (!_mocks.containsKey(key)) {
      throw StateError(
        'No mock registered for command: $command ${args.join(" ")}',
      );
    }

    _invocations[key] = (_invocations[key] ?? 0) + 1;

    final mock = _mocks[key]!;
    if (mock.startProcess == null) {
      throw StateError(
        'Mock registered for Process.run(), but Process.start() was called',
      );
    }

    return mock.startProcess!;
  }

  /// Check if a mock is registered for the given command
  bool hasMockFor(String command, List<String> args) {
    return _mocks.containsKey(_CommandKey(command, args));
  }

  /// Get the number of times a command was invoked
  int getInvocationCount(String command, List<String> args) {
    return _invocations[_CommandKey(command, args)] ?? 0;
  }

  /// Verify all mocks with expected calls were called the correct number of times
  bool verifyAllCalled() {
    for (final entry in _mocks.entries) {
      final expectedCalls = entry.value.expectedCalls;
      if (expectedCalls != null) {
        final actualCalls = _invocations[entry.key] ?? 0;
        if (actualCalls != expectedCalls) {
          return false;
        }
      }
    }
    return true;
  }

  /// Reset all mocks and invocation counts
  void reset() {
    _mocks.clear();
    _invocations.clear();
  }
}

/// Key for identifying a command + args combination
class _CommandKey {
  const _CommandKey(this.command, this.args);

  final String command;
  final List<String> args;

  @override
  bool operator ==(Object other) =>
      other is _CommandKey &&
      other.command == command &&
      _listEquals(other.args, args);

  @override
  int get hashCode => Object.hash(command, Object.hashAll(args));

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Internal entry for storing mock data
class _MockEntry {
  _MockEntry({
    this.runResult,
    this.startProcess,
    this.expectedCalls,
  });

  final MockProcessResult? runResult;
  final MockProcess? startProcess;
  final int? expectedCalls;
}
