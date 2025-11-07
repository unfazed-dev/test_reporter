/// Tests for MockProcess infrastructure
///
/// Coverage Target: 100% of mock_process.dart
/// Test Strategy: Unit tests for mocking Process.run() and Process.start()
/// TDD Approach: 🔴 RED → 🟢 GREEN → ♻️ REFACTOR → 🔄 META-TEST
///
/// This infrastructure enables testing of all bin/ analyzers by mocking
/// external process execution (dart test, flutter test, coverage tools).

import 'dart:async';
import 'dart:convert';

import 'package:test/test.dart';

import 'mock_process.dart';

void main() {
  group('MockProcess', () {
    test('should create mock process with custom stdout', () async {
      final mock = MockProcess(
        stdout: Stream.value(utf8.encode('test output')),
        exitCode: 0,
      );

      expect(mock.stdout, isA<Stream<List<int>>>());
      expect(await mock.exitCode, equals(0));
    });

    test('should create mock process with custom stderr', () async {
      final mock = MockProcess(
        stdout: Stream.empty(),
        stderr: Stream.value(utf8.encode('error output')),
        exitCode: 1,
      );

      expect(mock.stderr, isA<Stream<List<int>>>());
      expect(await mock.exitCode, equals(1));
    });

    test('should create mock process with custom exit code', () async {
      final mock = MockProcess(
        stdout: Stream.empty(),
        stderr: Stream.empty(),
        exitCode: 42,
      );

      final code = await mock.exitCode;
      expect(code, equals(42));
    });

    test('should handle async stdout stream', () async {
      final controller = StreamController<List<int>>();
      final mock = MockProcess(
        stdout: controller.stream,
        exitCode: 0,
      );

      // Schedule async output
      Future.delayed(Duration(milliseconds: 10), () {
        controller.add(utf8.encode('line 1\n'));
        controller.add(utf8.encode('line 2\n'));
        controller.close();
      });

      final output = await mock.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .toList();

      expect(output, equals(['line 1', 'line 2']));
    });

    test('should handle async stderr stream', () async {
      final controller = StreamController<List<int>>();
      final mock = MockProcess(
        stdout: Stream.empty(),
        stderr: controller.stream,
        exitCode: 0,
      );

      // Schedule async output
      Future.delayed(Duration(milliseconds: 10), () {
        controller.add(utf8.encode('error 1\n'));
        controller.add(utf8.encode('error 2\n'));
        controller.close();
      });

      final output = await mock.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .toList();

      expect(output, equals(['error 1', 'error 2']));
    });

    test('should support kill() method', () {
      final mock = MockProcess(
        stdout: Stream.empty(),
        exitCode: 0,
      );

      expect(() => mock.kill(), returnsNormally);
      expect(mock.killed, isTrue);
    });

    test('should have pid property', () {
      final mock = MockProcess(
        stdout: Stream.empty(),
        exitCode: 0,
        pid: 12345,
      );

      expect(mock.pid, equals(12345));
    });

    test('should simulate delayed output', () async {
      final mock = MockProcess.withDelayedOutput(
        output: 'delayed output',
        delay: Duration(milliseconds: 50),
        exitCode: 0,
      );

      final start = DateTime.now();
      final output = await mock.stdout.transform(utf8.decoder).join();
      final elapsed = DateTime.now().difference(start);

      expect(output, equals('delayed output'));
      expect(elapsed.inMilliseconds, greaterThanOrEqualTo(50));
    });

    test('should simulate process timeout', () async {
      final mock = MockProcess.withTimeout(
        timeout: Duration(milliseconds: 100),
      );

      expect(
        () => mock.exitCode.timeout(Duration(milliseconds: 50)),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('should record invocations', () {
      final mock = MockProcess(
        stdout: Stream.empty(),
        exitCode: 0,
      );

      expect(mock.invocations, isEmpty);

      mock.kill();
      expect(mock.invocations, contains('kill'));
    });
  });

  group('MockProcessResult', () {
    test('should create result with all fields', () {
      final result = MockProcessResult(
        exitCode: 0,
        stdout: 'output text',
        stderr: 'error text',
        pid: 999,
      );

      expect(result.exitCode, equals(0));
      expect(result.stdout, equals('output text'));
      expect(result.stderr, equals('error text'));
      expect(result.pid, equals(999));
    });

    test('should handle empty stdout and stderr', () {
      final result = MockProcessResult(
        exitCode: 1,
        stdout: '',
        stderr: '',
      );

      expect(result.stdout, isEmpty);
      expect(result.stderr, isEmpty);
    });
  });

  group('MockProcessManager', () {
    test('should register mock for Process.run()', () {
      final manager = MockProcessManager();

      manager.mockProcessRun(
        command: 'dart',
        args: ['test'],
        result: MockProcessResult(exitCode: 0, stdout: 'All tests passed'),
      );

      expect(manager.hasMockFor('dart', ['test']), isTrue);
    });

    test('should register mock for Process.start()', () {
      final manager = MockProcessManager();

      manager.mockProcessStart(
        command: 'dart',
        args: ['test'],
        process: MockProcess(stdout: Stream.empty(), exitCode: 0),
      );

      expect(manager.hasMockFor('dart', ['test']), isTrue);
    });

    test('should return appropriate mock for command', () async {
      final manager = MockProcessManager();

      manager.mockProcessRun(
        command: 'dart',
        args: ['test'],
        result: MockProcessResult(exitCode: 0, stdout: 'test output'),
      );

      final result = await manager.run('dart', ['test']);
      expect(result.stdout, equals('test output'));
      expect(result.exitCode, equals(0));
    });

    test('should return appropriate mock process for start', () async {
      final manager = MockProcessManager();

      manager.mockProcessStart(
        command: 'dart',
        args: ['test'],
        process: MockProcess(
          stdout: Stream.value(utf8.encode('process output')),
          exitCode: 0,
        ),
      );

      final process = await manager.start('dart', ['test']);
      final output = await process.stdout.transform(utf8.decoder).join();

      expect(output, equals('process output'));
    });

    test('should track invocation count', () async {
      final manager = MockProcessManager();

      manager.mockProcessRun(
        command: 'dart',
        args: ['test'],
        result: MockProcessResult(exitCode: 0, stdout: ''),
      );

      expect(manager.getInvocationCount('dart', ['test']), equals(0));

      await manager.run('dart', ['test']);
      expect(manager.getInvocationCount('dart', ['test']), equals(1));

      await manager.run('dart', ['test']);
      expect(manager.getInvocationCount('dart', ['test']), equals(2));
    });

    test('should verify all expected processes were called', () async {
      final manager = MockProcessManager();

      manager.mockProcessRun(
        command: 'dart',
        args: ['test'],
        result: MockProcessResult(exitCode: 0, stdout: ''),
        expectedCalls: 1,
      );

      // Before calling
      expect(manager.verifyAllCalled(), isFalse);

      // After calling
      await manager.run('dart', ['test']);
      expect(manager.verifyAllCalled(), isTrue);
    });

    test('should handle unexpected process calls', () {
      final manager = MockProcessManager();

      // No mock registered for this command
      expect(
        () => manager.run('unknown', ['command']),
        throwsA(isA<StateError>()),
      );
    });

    test('should reset state between tests', () async {
      final manager = MockProcessManager();

      manager.mockProcessRun(
        command: 'dart',
        args: ['test'],
        result: MockProcessResult(exitCode: 0, stdout: ''),
      );

      await manager.run('dart', ['test']);
      expect(manager.getInvocationCount('dart', ['test']), equals(1));

      manager.reset();
      expect(manager.getInvocationCount('dart', ['test']), equals(0));
      expect(manager.hasMockFor('dart', ['test']), isFalse);
    });

    test('should chain multiple mocks', () async {
      final manager = MockProcessManager();

      manager
          .mockProcessRun(
            command: 'dart',
            args: ['test'],
            result: MockProcessResult(exitCode: 0, stdout: 'tests passed'),
          )
          .mockProcessRun(
            command: 'dart',
            args: ['analyze'],
            result: MockProcessResult(exitCode: 0, stdout: 'no issues'),
          );

      final testResult = await manager.run('dart', ['test']);
      final analyzeResult = await manager.run('dart', ['analyze']);

      expect(testResult.stdout, equals('tests passed'));
      expect(analyzeResult.stdout, equals('no issues'));
    });
  });
}
