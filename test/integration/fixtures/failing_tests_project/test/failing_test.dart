import 'package:test/test.dart';
import '../lib/buggy_code.dart';

void main() {
  group('BuggyCode', () {
    late BuggyCode buggy;

    setUp(() {
      buggy = BuggyCode();
    });

    test('addition should work correctly (FAILS)', () {
      // This will fail due to the bug
      expect(buggy.addBuggy(2, 3), equals(5));
    });

    test('greeting should handle null (FAILS)', () {
      // This will fail with null error
      expect(buggy.greet(null), equals('Hello, null!'));
    });

    test('randomResult is flaky (FLAKY)', () {
      // This test is flaky and may pass or fail randomly
      expect(buggy.randomResult(10), equals(10));
    });

    test('this test passes', () {
      // At least one test should pass
      expect(true, isTrue);
    });
  });
}
