/// Code with intentional bugs for testing
class BuggyCode {
  /// This has a bug - always returns wrong result
  int addBuggy(int a, int b) => a + b + 1; // Off by one

  /// This throws an unexpected error
  String greet(String? name) {
    return 'Hello, $name!'; // Will fail if name is null
  }

  /// This has inconsistent behavior
  int randomResult(int input) {
    // Simulates flaky behavior
    return DateTime.now().millisecond > 500 ? input : -input;
  }
}
