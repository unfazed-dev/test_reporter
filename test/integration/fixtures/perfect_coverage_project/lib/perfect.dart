/// A simple class with complete test coverage
class Perfect {
  /// Check if a number is positive
  bool isPositive(int number) => number > 0;

  /// Check if a number is negative
  bool isNegative(int number) => number < 0;

  /// Get absolute value
  int abs(int number) => number < 0 ? -number : number;
}
